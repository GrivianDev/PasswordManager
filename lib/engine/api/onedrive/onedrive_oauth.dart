import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ethercrypt/engine/api/app_lifecycle.dart';
import 'package:ethercrypt/engine/api/http_client.dart';
import 'package:ethercrypt/engine/api/oauth_success_web_page.dart';
import 'package:ethercrypt/engine/api/onedrive/onedrive_session.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/digests/sha256.dart';
import 'package:url_launcher/url_launcher.dart';

class OneDriveAuthException implements Exception {
  final String message;
  final String raw;
  final int? statusCode;

  OneDriveAuthException(
    this.message, {
    required this.raw,
    this.statusCode,
  });

  @override
  String toString() => 'OneDriveAuthException(error: $message, http status: $statusCode)';
}

enum OneDriveScope {
  /// Sign in and read profile.
  openId('openid'),
  /// Required for refresh tokens.
  offlineAccess('offline_access'),
  /// Read user files.
  filesRead('Files.Read'),
  /// Read/write user files.
  filesReadWrite('Files.ReadWrite'),
  /// Read all files accessible to the user.
  filesReadAll('Files.Read.All'),
  /// Read/write all files accessible to the user.
  filesReadWriteAll('Files.ReadWrite.All'),
  /// Read/write all files inside app folder.
  fileReadWriteAppFolder('Files.ReadWrite.AppFolder'),
  /// Read basic user profile.
  userRead('User.Read');

  final String value;

  const OneDriveScope(this.value);
}

class OneDriveOAuth {
  final String _clientId;

  final AppLifecycle lifecycle;

  final List<OneDriveScope> scopes;

  final Uri _oauth2TokenUrl = Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token');

  final StreamController<OneDriveSession?> _sessionController = StreamController.broadcast();

  OneDriveSession? _session;

  OneDriveOAuth({
    required String clientId,
    required this.scopes,
    required this.lifecycle,
  }) : _clientId = clientId;

  String get _scopeString => scopes.map((e) => e.value).join(' ');

  OneDriveSession? get session => _session;

  bool get isLoggedIn => _session != null;

  bool get isConfigValid => _clientId.trim().isNotEmpty;

  Stream<OneDriveSession?> get sessionChanges => _sessionController.stream;

  String _generateCodeVerifier([int byteLength = 32]) {
    final Random random = Random.secure();

    final Uint8List verifier = Uint8List.fromList(
      List.generate(byteLength, (_) => random.nextInt(0xFF)),
    );

    return base64UrlEncode(verifier).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final Uint8List bytes = utf8.encode(verifier);
    final Uint8List digest = SHA256Digest().process(bytes);

    return base64UrlEncode(digest).replaceAll('=', '');
  }

  void _setSession(OneDriveSession? session) {
    _session = session;
    _sessionController.add(session);
  }

  Future<void> authorize() async {
    final String verifier = _generateCodeVerifier();
    final String challenge = _generateCodeChallenge(verifier);

    final HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    final String redirectUri = 'http://localhost:${server.port}/oauth_redirect';

    final Uri authUri = Uri.https(
      'login.microsoftonline.com',
      '/common/oauth2/v2.0/authorize',
      {
        'client_id': _clientId,
        'response_type': 'code',
        'redirect_uri': redirectUri,
        'scope': _scopeString,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'response_mode': 'query',
      },
    );

    if (!await launchUrl(authUri)) {
      throw Exception('Could not launch browser');
    }

    final HttpRequest request = await server.first;

    final String? code = request.uri.queryParameters['code'];

    request.response
      ..headers.contentType = ContentType.html
      ..write(getOAuthSuccessPage('OneDrive'));

    await request.response.close();
    await server.close(force: true);

    if (code == null) {
      throw OneDriveAuthException(
        'Missing authorization code',
        raw: 'callback without code',
      );
    }

    final OneDriveSession session = await _exchangeCodeForToken(
      code,
      verifier,
      redirectUri,
    );

    _setSession(session);
  }

  Future<OneDriveSession> _exchangeCodeForToken(
    String code,
    String verifier,
    String redirectUri,
  ) async {
    await lifecycle.waitUntilReady();

    final http.Client httpClient = LoggingHttpClient();

    try {
      final response = await httpClient.post(
        _oauth2TokenUrl,
        body: {
          'client_id': _clientId,
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'code_verifier': verifier,
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OneDriveAuthException(
          'Token exchange failed',
          raw: response.body,
          statusCode: response.statusCode,
        );
      }

      final data = json.decode(response.body);

      final expiresIn = data['expires_in'] as int;

      return OneDriveSession(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        expiresAt: DateTime.now().add(
          Duration(seconds: expiresIn),
        ),
      );
    } finally {
      httpClient.close();
    }
  }

  Future<void> authorizeWithRefreshToken(
    String refreshToken,
  ) async {
    final http.Client httpClient = LoggingHttpClient();

    try {
      final response = await httpClient.post(
        _oauth2TokenUrl,
        body: {
          'client_id': _clientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OneDriveAuthException(
          'Refresh token failed',
          raw: response.body,
          statusCode: response.statusCode,
        );
      }

      final data = json.decode(response.body);

      final expiresIn = data['expires_in'] as int;

      _setSession(
        OneDriveSession(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'] ?? refreshToken,
          expiresAt: DateTime.now().add(
            Duration(seconds: expiresIn),
          ),
        ),
      );
    } finally {
      httpClient.close();
    }
  }

  void revokeAccess() {
    _setSession(null);
  }
}
