import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ethercrypt/engine/api/app_lifecycle.dart';
import 'package:ethercrypt/engine/api/dropbox/dropbox_oauth.dart';
import 'package:ethercrypt/engine/api/http_client.dart';
import 'package:http/http.dart' as http;

class DropboxApiException implements Exception {
  final String message;
  final String raw;
  final int? statusCode;

  DropboxApiException(
    this.message, {
    required this.raw,
    this.statusCode,
  });

  @override
  String toString() => 'DropboxApiException(message: $message, http status: $statusCode)';
}

class DropboxFile {
  final String id;
  final String name;
  final String pathLower;
  final String pathDisplay;

  final int size;
  final DateTime clientModified;
  final DateTime serverModified;

  final String contentHash;
  final String rev;

  const DropboxFile({
    required this.id,
    required this.name,
    required this.pathLower,
    required this.pathDisplay,
    required this.size,
    required this.clientModified,
    required this.serverModified,
    required this.contentHash,
    required this.rev,
  });

  factory DropboxFile.fromJson(Map<String, dynamic> json) {
    return DropboxFile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      pathLower: json['path_lower'] ?? '',
      pathDisplay: json['path_display'] ?? '',
      size: json['size'] ?? 0,
      clientModified: DateTime.tryParse(json['client_modified'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      serverModified: DateTime.tryParse(json['server_modified'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      contentHash: json['content_hash'] ?? '',
      rev: json['rev'] ?? '',
    );
  }
}

class Dropbox {
  static const String _apiAuthority = 'api.dropboxapi.com';
  static const String _contentAuthority = 'content.dropboxapi.com';

  final DropboxOAuth auth;

  Dropbox({required String clientId, required AppLifecycle lifecycle}) : auth = DropboxOAuth(clientId: clientId, lifecycle: lifecycle);

  bool get isLoggedIn => auth.isLoggedIn;
  bool get isConfigValid => auth.isConfigValid;

  /// Uploads a file to Dropbox.
  ///
  /// When [rev] is specified, the upload only succeeds if the file revision.
  /// When [rev] is null, [overwrite] controls whether an existing file at [path] is replaced or causes a conflict.
  ///
  /// Returns the uploaded file metadata.
  Future<DropboxFile> uploadFile({required String path, required List<int> data, bool overwrite = true, String? rev}) async {
    final dynamic mode;

    if (rev != null) {
      mode = {'.tag': 'update', 'update': rev};
    } else {
      mode = overwrite ? 'overwrite' : 'add';
    }
    final args = {
      'path': path,
      'mode': mode,
      'strict_conflict': true,
      'autorename': false,
      'mute': false,
    };

    final Uri uri = Uri.https(_contentAuthority, '/2/files/upload');
    final http.Response response = await _apiRequestWithReAuth((client) {
      return client.post(
        uri,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer ${auth.session?.accessToken}',
          'Content-Type': 'application/octet-stream',
          'Dropbox-API-Arg': json.encode(args),
        },
        body: data,
      );
    });

    _throwIfNotSuccess(response);

    return DropboxFile.fromJson(json.decode(response.body));
  }

  /// Moves a file or folder to a new location in Dropbox.
  ///
  /// [fromPath] is the current path of the file or folder.
  /// [toPath] is the destination path (including the new name if renaming).
  ///
  /// Returns the updated file after the move.
  Future<DropboxFile> moveFile({
    required String fromPath,
    required String toPath,
    bool autorename = false,
  }) async {
    final Uri uri = Uri.https(_apiAuthority, '/2/files/move_v2');

    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.post(
        uri,
        headers: _headers(),
        body: json.encode({
          'from_path': fromPath,
          'to_path': toPath,
          'autorename': autorename,
        }),
      ),
    );

    _throwIfNotSuccess(response);

    final data = json.decode(response.body);
    return DropboxFile.fromJson(data['metadata']);
  }

  /// Gets file metadata from Dropbox. Returns null if the file does not exist.
  ///
  /// [path] Can either be the file id or a file path starting with `/`.
  Future<DropboxFile?> getFile(String path) async {
    try {
      final Uri uri = Uri.https(_apiAuthority, '/2/files/get_metadata');
      final http.Response response = await _apiRequestWithReAuth(
        (client) => client.post(uri, headers: _headers(), body: json.encode({'path': path, 'include_deleted': false})),
      );

      _throwIfNotSuccess(response);

      return DropboxFile.fromJson(json.decode(response.body));
    } on DropboxApiException catch (e) {
      if (e.message.startsWith('path/not_found')) {
        return null;
      }
      rethrow;
    }
  }

  /// Gets file content from Dropbox. Returns null if the file does not exist.
  ///
  /// [path] Can either be the file id or a file path starting with `/`.
  Future<Uint8List?> downloadFile(String path) async {
    try {
      final Uri uri = Uri.https(_contentAuthority, '/2/files/download');
      final http.Response response = await _apiRequestWithReAuth((client) {
        return client.post(
          uri,
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer ${auth.session?.accessToken}',
            'Dropbox-API-Arg': json.encode({'path': path}),
          },
        );
      });

      _throwIfNotSuccess(response);

      return response.bodyBytes;
    } on DropboxApiException catch (e) {
      if (e.message.startsWith('path/not_found')) {
        return null;
      }
      rethrow;
    }
  }

  /// Lists files and folders inside a Dropbox directory.
  ///
  /// Returns up to [limit] items from [path]. If [path] is empty, lists the root folder.
  /// Note: This does not automatically paginate beyond [limit].
  Future<List<DropboxFile>> listFiles({String path = '', int limit = 100}) async {
    final Uri uri = Uri.https(_apiAuthority, '/2/files/list_folder');
    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.post(uri, headers: _headers(), body: json.encode({'path': path, 'limit': limit})),
    );

    _throwIfNotSuccess(response);

    final data = json.decode(response.body);
    final List entries = data['entries'] ?? [];

    return entries.map((e) => DropboxFile.fromJson(e)).toList();
  }

  /// Deletes a file or folder at the given [path].
  Future<void> deleteFile(String path) async {
    final Uri uri = Uri.https(_apiAuthority, '/2/files/delete_v2');
    final http.Response response = await _apiRequestWithReAuth(
      (client) => client.post(uri, headers: _headers(), body: json.encode({'path': path})),
    );

    _throwIfNotSuccess(response);
  }

  // ---------------- HELPERS ----------------

  Future<http.Response> _apiRequestWithReAuth(
    Future<http.Response> Function(http.Client client) apiCall,
  ) async {
    if (!auth.isLoggedIn) {
      throw Exception('Dropbox user is not logged in');
    }

    final client = LoggingHttpClient();

    try {
      http.Response response = await apiCall(client);

      if (response.statusCode == HttpStatus.unauthorized) {
        await auth.authorizeWithRefreshToken(auth.session!.refreshToken);
        response = await apiCall(client);
      }

      return response;
    } finally {
      client.close();
    }
  }

  void _throwIfNotSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      dynamic data;

      try {
        data = json.decode(response.body);
      } catch (_) {}

      throw DropboxApiException(
        data?['error_summary'] ?? 'UNKNOWN_ERROR',
        raw: response.body,
        statusCode: response.statusCode,
      );
    }
  }

  Map<String, String> _headers() {
    return {
      HttpHeaders.authorizationHeader: 'Bearer ${auth.session?.accessToken}',
      HttpHeaders.contentTypeHeader: 'application/json',
    };
  }
}
