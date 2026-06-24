import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ethercrypt/engine/api/app_lifecycle.dart';
import 'package:ethercrypt/engine/api/http_client.dart';
import 'package:ethercrypt/engine/api/onedrive/onedrive_oauth.dart';
import 'package:http/http.dart' as http;

class OneDriveApiException implements Exception {
  final String message;
  final String raw;
  final int? statusCode;

  OneDriveApiException(
    this.message, {
    required this.raw,
    this.statusCode,
  });

  @override
  String toString() => 'OneDriveApiException(message: $message, http status: $statusCode)';
}

enum OneDriveItemType {
  file,
  folder,
}

class OneDriveItem {
  final String id;
  final String name;
  final String location;
  final int size;

  final OneDriveItemType type;
  final DateTime createdTime;
  final DateTime modifiedTime;

  /// Content version.
  final String eTag;

  /// Folder listing version.
  final String cTag;

  final String? parentId;

  const OneDriveItem({
    required this.id,
    required this.name,
    required this.location,
    required this.size,
    required this.type,
    required this.createdTime,
    required this.modifiedTime,
    required this.eTag,
    required this.cTag,
    required this.parentId,
  });

  factory OneDriveItem.fromJson(Map<String, dynamic> json) {
    OneDriveItemType itemType = OneDriveItemType.file;
    if (json['folder'] != null) {
      itemType = OneDriveItemType.folder;
    }

    return OneDriveItem(
      id: json['id'],
      name: json['name'],
      location: json['parentReference']?['path'] ?? '',
      size: json['size'] ?? 0,
      type: itemType,
      createdTime: DateTime.parse(json['createdDateTime']),
      modifiedTime: DateTime.parse(json['lastModifiedDateTime']),
      eTag: json['eTag'],
      cTag: json['cTag'],
      parentId: json['parentReference']?['id'],
    );
  }
}

enum OneDriveLocation {
  root,
  appRoot,
}

/// OneDrive REST Client.
/// Based on https://learn.microsoft.com/en-us/graph/api/resources/onedrive?view=graph-rest-1.0
class OneDrive {
  static const String _graphAuthority = 'graph.microsoft.com';
  static const String _graphVersion = '/v1.0';

  final OneDriveOAuth auth;

  OneDrive({
    required String clientId,
    required List<OneDriveScope> scopes,
    required AppLifecycle lifecycle,
  }) : auth = OneDriveOAuth(
          clientId: clientId,
          scopes: scopes,
          lifecycle: lifecycle,
        );

  bool get isConfigValid => auth.isConfigValid;

  /// Creates or uploads a new file at the given [path] in OneDrive.
  ///
  /// - If the file does not exist → it is created.
  /// - If the file exists → it is overwritten.
  ///
  /// ### Notes
  /// - This is a *simple upload* (not chunked upload session).
  /// - Suitable only for small/medium files (Graph recommends < 4MB for simple upload).
  ///
  /// ### Returns
  /// - The created or updated `OneDriveItem` metadata after upload completes.
  Future<OneDriveItem> createFile(
    String path, {
    required List<int> data,
    OneDriveLocation location = OneDriveLocation.root,
  }) async {
    final Uri uri = Uri.https(_graphAuthority, '${_basePath(location)}${_graphPathSegment(path)}/content');
    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.put(
        uri,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer ${auth.session?.accessToken}',
          HttpHeaders.contentTypeHeader: ContentType.binary.value,
        },
        body: data,
      ),
    );

    _throwIfNotSuccess(response);

    return OneDriveItem.fromJson(json.decode(response.body));
  }

  /// Retrieves metadata for a OneDrive item using its stable unique [itemId].
  /// Returns file or folder metadata if the item exists, null otherwise.
  Future<OneDriveItem?> getItem(String itemId) async {
    final Uri uri = Uri.https(_graphAuthority, '$_graphVersion/me/drive/items/$itemId');
    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.get(uri, headers: _headers()),
    );

    if (response.statusCode == HttpStatus.notFound) {
      return null;
    }

    _throwIfNotSuccess(response);

    return OneDriveItem.fromJson(json.decode(response.body));
  }

  /// Retrieves metadata for a file or folder at a given [path].
  /// Returns file or folder metadata if the item exists, null otherwise.
  Future<OneDriveItem?> getItemByPath({
    required String path,
    OneDriveLocation location = OneDriveLocation.root,
  }) async {
    final Uri uri = Uri.https(_graphAuthority, '${_basePath(location)}${_graphPathSegment(path)}');
    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.get(uri, headers: _headers()),
    );

    if (response.statusCode == HttpStatus.notFound) {
      return null;
    }

    _throwIfNotSuccess(response);

    return OneDriveItem.fromJson(json.decode(response.body));
  }

  /// Downloads the raw binary content of a file identified by [fileId].
  Future<Uint8List?> readFile(String fileId) async {
    final Uri uri = Uri.https(_graphAuthority, '$_graphVersion/me/drive/items/$fileId/content');
    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.get(uri, headers: _headers()),
    );

    if (response.statusCode == HttpStatus.notFound) {
      return null;
    }

    _throwIfNotSuccess(response);

    return response.bodyBytes;
  }

  /// Lists children (files and folders) inside a directory.
  ///
  /// ### Behavior
  /// - Returns all items directly inside the folder.
  /// - If [path] is null or empty, lists root directory.
  ///
  /// ### Notes
  /// - This method does NOT paginate automatically.
  Future<List<OneDriveItem>> listItems(String? path, {OneDriveLocation location = OneDriveLocation.root}) async {
    final Uri uri = Uri.https(_graphAuthority, '${_basePath(location)}${_graphPathSegment(path ?? '')}/children');
    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.get(uri, headers: _headers()),
    );

    _throwIfNotSuccess(response);

    final Map<String, dynamic> data = json.decode(response.body);

    final List<dynamic> files = data['value'] ?? [];

    return files.map((e) => OneDriveItem.fromJson(e)).toList();
  }

  /// Replaces the content of an existing file identified by [itemId].
  /// Concurrency Control via provided [expectedETag] is possible.
  ///
  /// ### Behavior
  /// - Completely overwrites the file content.
  ///
  /// ### Notes
  /// - Recommended for files typically under ~4MB (Graph limit guidance).
  Future<OneDriveItem> uploadFileContent(String itemId, {required List<int> data, String? expectedETag}) async {
    final Uri uri = Uri.https(_graphAuthority, '$_graphVersion/me/drive/items/$itemId/content');
    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.put(
        uri,
        headers: {
          ..._headers(),
          HttpHeaders.contentTypeHeader: 'application/octet-stream',
          if (expectedETag != null) 'If-Match': expectedETag,
        },
        body: data,
      ),
    );

    _throwIfNotSuccess(response);

    return OneDriveItem.fromJson(json.decode(response.body));
  }

  /// Updates metadata for a OneDrive item (rename or move).
  /// Concurrency Control via provided [expectedETag] is possible.
  ///
  /// ### Behavior
  /// - `name` → renames the file or folder
  /// - `parentId` → moves item to a different folder
  Future<OneDriveItem> updateItem(
    String itemId, {
    String? name,
    String? parentId,
    String? expectedETag,
  }) async {
    if (name == null && parentId == null) {
      throw ArgumentError(
        'At least one property must be updated.',
      );
    }

    final body = {
      if (name != null) 'name': name,
      if (parentId != null)
        'parentReference': {
          'id': parentId,
        },
    };

    final Uri uri = Uri.https(_graphAuthority, '$_graphVersion/me/drive/items/$itemId');
    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.patch(
        uri,
        headers: {
          ..._headers(),
          if (expectedETag != null) 'If-Match': expectedETag,
        },
        body: json.encode(body),
      ),
    );

    _throwIfNotSuccess(response);

    return OneDriveItem.fromJson(
      json.decode(response.body),
    );
  }

  /// Deletes a file or folder from OneDrive.
  /// Concurrency Control via provided [expectedETag] is possible.
  Future<void> deleteFile(String fileId, {String? expectedETag}) async {
    final Uri uri = Uri.https(_graphAuthority, '$_graphVersion/me/drive/items/$fileId');
    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.delete(
        uri,
        headers: {
          ..._headers(),
          if (expectedETag != null) 'If-Match': expectedETag,
        },
      ),
    );

    _throwIfNotSuccess(response);
  }

  // ---------------- HELPERS ----------------

  Future<http.Response> _apiRequestWithReAuth(
    Future<http.Response> Function(http.Client client) apiCall,
  ) async {
    if (!auth.isLoggedIn) {
      throw Exception('OneDrive user is not logged in');
    }

    final http.Client httpClient = LoggingHttpClient();

    try {
      http.Response response = await apiCall(httpClient);

      if (response.statusCode == HttpStatus.unauthorized) {
        await auth.authorizeWithRefreshToken(
          auth.session!.refreshToken,
        );

        response = await apiCall(httpClient);
      }

      return response;
    } finally {
      httpClient.close();
    }
  }

  String _basePath(OneDriveLocation location) {
    switch (location) {
      case OneDriveLocation.root:
        return '$_graphVersion/me/drive/root';
      case OneDriveLocation.appRoot:
        return '$_graphVersion/me/drive/special/approot';
    }
  }

  String _normalizePath(String path) {
    if (path.isEmpty || path == '/') return '';
    return path.split('/').where((p) => p.isNotEmpty).join('/');
  }

  String _graphPathSegment(String path) {
    final String normalized = _normalizePath(path);
    return normalized.isEmpty ? '' : ':/$normalized:';
  }

  void _throwIfNotSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    dynamic data;

    try {
      data = json.decode(response.body);
    } catch (_) {}

    throw OneDriveApiException(
      data?['error']?['code'] ?? data?['error']?['message'] ?? 'UNKNOWN',
      raw: response.body,
      statusCode: response.statusCode,
    );
  }

  Map<String, String> _headers() {
    return {
      HttpHeaders.authorizationHeader: 'Bearer ${auth.session?.accessToken}',
      HttpHeaders.contentTypeHeader: ContentType.json.value,
    };
  }
}
