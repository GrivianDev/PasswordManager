import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ethercrypt/engine/api/app_lifecycle.dart';
import 'package:ethercrypt/engine/api/googledrive/google_drive_session.dart';
import 'package:ethercrypt/engine/api/http_client.dart';
import 'package:ethercrypt/engine/api/oauth_success_web_page.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/digests/sha256.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleAuthException implements Exception {
  final String message;
  final String raw;
  final int? statusCode;

  GoogleAuthException(this.message, {required this.raw, this.statusCode});

  @override
  String toString() => 'GoogleAuthException(error: $message, http status: $statusCode)';
}

enum GoogleDriveScope {
  /// Hidden app-only storage (appDataFolder).
  appData('drive.appdata'),

  /// Access files created/opened by the app.
  file('drive.file'),

  /// Full read/write access to entire Drive.
  full('drive'),

  /// Read-only access to entire Drive.
  readonly('drive.readonly'),

  /// Read-only access to file metadata only.
  metadataReadonly('drive.metadata.readonly');

  static const String _scopePrefix = 'https://www.googleapis.com/auth/';

  final String value;

  const GoogleDriveScope(this.value);

  String get uri => '$_scopePrefix$value';
}

class GoogleDriveOAuth {
  final String _clientId;
  final String _clientSecret;
  final Uri _oauth2TokenUrl = Uri.parse('https://oauth2.googleapis.com/token');

  final AppLifecycle lifecycle;

  final List<GoogleDriveScope> scopes;

  final StreamController<GoogleDriveSession?> _sessionController = StreamController.broadcast();

  GoogleDriveSession? _session;

  GoogleDriveOAuth({required String clientId, required String clientSecret, required this.scopes, required this.lifecycle})
      : _clientId = clientId,
        _clientSecret = clientSecret;

  String get _scopeString => scopes.map((e) => e.uri).join(' ');

  GoogleDriveSession? get session => _session;
  bool get isLoggedIn => _session != null;
  bool get isConfigValid => _clientId.trim().isNotEmpty && _clientSecret.trim().isNotEmpty;

  Stream<GoogleDriveSession?> get sessionChanges => _sessionController.stream;

  String _generateCodeVerifier([int byteLength = 32]) {
    final Random random = Random.secure();
    final Uint8List verifier = Uint8List.fromList(List.generate(byteLength, (_) => random.nextInt(0xFF)));
    return base64UrlEncode(verifier).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final Uint8List bytes = utf8.encode(verifier);
    final Uint8List digest = SHA256Digest().process(bytes);
    return base64UrlEncode(digest).replaceAll('=', '');
  }

  void _setSession(GoogleDriveSession? session) {
    _session = session;
    _sessionController.add(session);
  }

  Future<void> authorize() async {
    final String verifier = _generateCodeVerifier();
    final String challenge = _generateCodeChallenge(verifier);

    final HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final String redirectUri = 'http://127.0.0.1:${server.port}/callback';

    final Uri authUri = Uri.https(
      'accounts.google.com',
      '/o/oauth2/v2/auth',
      {
        'client_id': _clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': _scopeString,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'access_type': 'offline',
        'prompt': 'consent',
      },
    );

    if (!await launchUrl(authUri)) {
      throw Exception('Could not launch browser');
    }

    final HttpRequest request = await server.first;
    final String? code = request.uri.queryParameters['code'];

    request.response
      ..headers.contentType = ContentType.html
      ..write(getOAuthSuccessPage('Google Drive'));

    await request.response.close();
    await server.close(force: true);

    if (code == null) {
      throw GoogleAuthException('Missing authorization code', raw: 'callback without code');
    }

    final GoogleDriveSession session = await _exchangeCodeForToken(
      code,
      verifier,
      redirectUri,
    );

    _setSession(session);
  }

  Future<GoogleDriveSession> _exchangeCodeForToken(String code, String verifier, String redirectUri) async {
    await lifecycle.waitUntilReady();
    
    final http.Client httpClient = LoggingHttpClient();
    try {
      final response = await httpClient.post(
        _oauth2TokenUrl,
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'code_verifier': verifier,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GoogleAuthException(
          'Token exchange failed',
          raw: response.body,
          statusCode: response.statusCode,
        );
      }

      final data = json.decode(response.body);

      final expiresIn = data['expires_in'] as int;

      return GoogleDriveSession(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      );
    } finally {
      httpClient.close();
    }
  }

  Future<void> authorizeWithRefreshToken(String refreshToken) async {
    final http.Client httpClient = LoggingHttpClient();
    try {
      final response = await httpClient.post(
        _oauth2TokenUrl,
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GoogleAuthException(
          'Refresh token failed',
          raw: response.body,
          statusCode: response.statusCode,
        );
      }

      final data = json.decode(response.body);
      final expiresIn = data['expires_in'] as int;

      _setSession(
        GoogleDriveSession(
          accessToken: data['access_token'],
          refreshToken: refreshToken,
          expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
        ),
      );
    } finally {
      httpClient.close();
    }
  }

  void revokeAccess() => _setSession(null);
}
