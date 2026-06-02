import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ethercrypt/engine/api/googledrive/google_drive_oauth.dart';
import 'package:ethercrypt/engine/api/http_client.dart';
import 'package:http/http.dart' as http;

class GoogleDriveApiException implements Exception {
  final String message;
  final String raw;
  final int? statusCode;

  GoogleDriveApiException(
    this.message, {
    required this.raw,
    this.statusCode,
  });

  @override
  String toString() => 'GoogleDriveApiException(message: $message, http status: $statusCode)';
}

enum GoogleDriveSpace {
  /// Normal user-visible Google Drive.
  drive('drive'),

  /// Hidden app-specific storage.
  appDataFolder('appDataFolder');

  final String value;

  const GoogleDriveSpace(this.value);
}

class GoogleDriveFile {
  final String id;
  final String name;
  final String mimeType;

  final DateTime createdTime;
  final DateTime modifiedTime;
  final int size;
  final List<String> parents;
  final String version;

  final Map<String, String>? appProperties;

  const GoogleDriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.parents,
    required this.createdTime,
    required this.modifiedTime,
    required this.size,
    required this.version,
    this.appProperties,
  });

  factory GoogleDriveFile.fromJson(Map<String, dynamic> json) {
    return GoogleDriveFile(
      id: json['id'],
      name: json['name'],
      mimeType: json['mimeType'],
      parents: ((json['parents'] as List<dynamic>?) ?? []).cast<String>(),
      createdTime: DateTime.parse(json['createdTime']),
      modifiedTime: DateTime.parse(json['modifiedTime']),
      size: int.tryParse(json['size']?.toString() ?? '') ?? 0,
      version: json['version'],
      appProperties: (json['appProperties'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }
}

/// Google Drive CRUD wrapper using the REST API.
class GoogleDrive {
  static const String _driveAuthority = 'www.googleapis.com';
  static const String _driveApiPath = '/drive/v3/files';
  static const String _uploadApiPath = '/upload/drive/v3/files';

  final GoogleDriveOAuth auth;

  GoogleDrive({required String oAuthClientId, required String oAuthClientSecret})
      : auth = GoogleDriveOAuth(clientId: oAuthClientId, clientSecret: oAuthClientSecret, scopes: const [GoogleDriveScope.appData]);

  bool get isLoggedIn => auth.isLoggedIn;

  bool get isConfigValid => auth.isConfigValid;

  /// Creates a file in appDataFolder.
  ///
  /// If [data] is omitted, an empty metadata-only file is created.
  Future<GoogleDriveFile> createFile({
    required String name,
    required String mimeType,
    required GoogleDriveSpace parentSpace,
    List<int>? data,
    Map<String, String>? appProperties,
  }) async {
    final Map<String, dynamic> fileMetadata = {
      'name': name,
      'parents': [parentSpace.value],
      'mimeType': mimeType,
      if (appProperties != null && appProperties.isNotEmpty) 'appProperties': appProperties,
    };

    final http.Response response;

    if (data != null) {
      final Uri uri = Uri.https(_driveAuthority, _uploadApiPath, {'uploadType': 'multipart', 'fields': _defaultFields.join(',')});
      final String boundary = 'drive-boundary-${DateTime.now().millisecondsSinceEpoch}';

      final List<int> body = _buildMultipartBody(
        boundary: boundary,
        metadata: fileMetadata,
        data: data,
        mimeType: mimeType,
      );

      response = await _apiRequestWithReAuth(
        (client) => client.post(
          uri,
          headers: {
            ..._driveApiHeaders(),
            HttpHeaders.contentTypeHeader: 'multipart/related; boundary=$boundary',
          },
          body: body,
        ),
      );
    } else {
      final Uri uri = Uri.https(_driveAuthority, _driveApiPath, _buildFieldsQuery());
      response = await _apiRequestWithReAuth(
        (client) => client.post(uri, headers: _driveApiHeaders(), body: json.encode(fileMetadata)),
      );
    }

    _throwIfNotSuccessResponse(response);

    return GoogleDriveFile.fromJson(json.decode(response.body));
  }

  /// Retrieves a file metadata object.
  ///
  /// Returns null if the file does not exist.
  Future<GoogleDriveFile?> getFile(String fileId) async {
    final Uri uri = Uri.https(_driveAuthority, '$_driveApiPath/$fileId', _buildFieldsQuery());
    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.get(uri, headers: _driveApiHeaders()),
    );

    if (response.statusCode == HttpStatus.notFound) {
      return null;
    }

    _throwIfNotSuccessResponse(response);

    return GoogleDriveFile.fromJson(json.decode(response.body));
  }

  /// Downloads raw file bytes.
  ///
  /// Returns null if the file does not exist.
  Future<Uint8List?> readFile(String fileId) async {
    final Uri uri = Uri.https(_driveAuthority, '$_driveApiPath/$fileId', {'alt': 'media'});
    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.get(uri, headers: _driveApiHeaders()),
    );

    if (response.statusCode == HttpStatus.notFound) {
      return null;
    }

    _throwIfNotSuccessResponse(response);

    return response.bodyBytes;
  }

  /// Lists files inside space.
  ///
  /// Does not auto paginate.
  Future<List<GoogleDriveFile>> listFiles({String? query, int pageSize = 100, required GoogleDriveSpace space}) async {
    final Uri uri = Uri.https(
      _driveAuthority,
      _driveApiPath,
      {
        'spaces': space.value,
        'pageSize': pageSize.toString(),
        'q': query,
        'fields': 'files(${_defaultFields.join(',')})',
      },
    );

    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.get(uri, headers: _driveApiHeaders()),
    );

    _throwIfNotSuccessResponse(response);

    final Map<String, dynamic> data = json.decode(response.body);
    final List<dynamic> files = data['files'] ?? [];

    return files.map((e) => GoogleDriveFile.fromJson(e)).toList();
  }

  /// Updates file metadata and/or contents.
  ///
  /// - If [data] is supplied, file contents are replaced.
  /// - If [name] is supplied, the filename is updated.
  Future<GoogleDriveFile> updateFile(
    String fileId, {
    String? name,
    String? mimeType,
    List<int>? data,
    Map<String, dynamic>? appProperties,
  }) async {
    final Map<String, dynamic> updateMetadata = {
      if (name != null) 'name': name,
      if (mimeType != null) 'mimeType': mimeType,
      if (appProperties != null && appProperties.isNotEmpty) 'appProperties': appProperties,
    };

    final http.Response response;

    if (data != null) {
      final Uri uri = Uri.https(_driveAuthority, '$_uploadApiPath/$fileId', {'uploadType': 'multipart', 'fields': _defaultFields.join(',')});
      final String boundary = 'drive-boundary-${DateTime.now().millisecondsSinceEpoch}';

      final List<int> body = _buildMultipartBody(
        boundary: boundary,
        metadata: updateMetadata,
        data: data,
        mimeType: mimeType ?? 'application/octet-stream',
      );

      response = await _apiRequestWithReAuth(
        (client) => client.patch(
          uri,
          headers: {
            ..._driveApiHeaders(),
            HttpHeaders.contentTypeHeader: 'multipart/related; boundary=$boundary',
          },
          body: body,
        ),
      );
    } else {
      final Uri uri = Uri.https(_driveAuthority, '$_driveApiPath/$fileId', _buildFieldsQuery());

      response = await _apiRequestWithReAuth(
        (client) => client.patch(uri, headers: _driveApiHeaders(), body: json.encode(updateMetadata)),
      );
    }

    _throwIfNotSuccessResponse(response);

    return GoogleDriveFile.fromJson(json.decode(response.body));
  }

  Future<void> deleteFile(String fileId) async {
    final Uri uri = Uri.https(_driveAuthority, '$_driveApiPath/$fileId');
    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.delete(uri, headers: _driveApiHeaders()),
    );

    _throwIfNotSuccessResponse(response);
  }

  // ----------- Helpers ------------

  Future<http.Response> _apiRequestWithReAuth(Future<http.Response> Function(http.Client client) apiCall) async {
    if (!auth.isLoggedIn) {
      throw Exception('Google Drive user is not logged in');
    }

    final http.Client httpClient = LoggingHttpClient();

    try {
      http.Response response = await apiCall(httpClient);
      if (response.statusCode == HttpStatus.unauthorized) {
        await auth.authorizeWithRefreshToken(auth.session!.refreshToken);
        response = await apiCall(httpClient);
      }

      return response;
    } finally {
      httpClient.close();
    }
  }

  void _throwIfNotSuccessResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      dynamic data;

      try {
        data = json.decode(response.body);
      } catch (_) {}

      throw GoogleDriveApiException(
        data?['error']?['message'] ?? 'UNKNOWN',
        raw: response.body,
        statusCode: response.statusCode,
      );
    }
  }

  Map<String, String> _driveApiHeaders() {
    return {
      HttpHeaders.authorizationHeader: 'Bearer ${auth.session?.accessToken}',
      HttpHeaders.contentTypeHeader: ContentType.json.value,
    };
  }

  Map<String, String>? _buildFieldsQuery() {
    return _defaultFields.isEmpty ? null : {'fields': _defaultFields.join(',')};
  }

  List<int> _buildMultipartBody({
    required String boundary,
    required Map<String, dynamic> metadata,
    required List<int> data,
    required String mimeType,
  }) {
    final String metadataPart = json.encode(metadata);

    final BytesBuilder builder = BytesBuilder();

    builder.add(utf8.encode('--$boundary\r\n'));
    builder.add(utf8.encode('Content-Type: application/json; charset=UTF-8\r\n\r\n'));
    builder.add(utf8.encode(metadataPart));
    builder.add(utf8.encode('\r\n'));

    builder.add(utf8.encode('--$boundary\r\n'));
    builder.add(utf8.encode('Content-Type: $mimeType\r\n\r\n'));
    builder.add(data);
    builder.add(utf8.encode('\r\n'));

    builder.add(utf8.encode('--$boundary--'));

    return builder.toBytes();
  }

  static const List<String> _defaultFields = [
    'id',
    'name',
    'mimeType',
    'parents',
    'createdTime',
    'modifiedTime',
    'size',
    'version',
    'appProperties',
  ];
}
