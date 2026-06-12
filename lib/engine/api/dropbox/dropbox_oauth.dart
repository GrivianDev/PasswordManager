import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ethercrypt/engine/api/app_lifecycle.dart';
import 'package:ethercrypt/engine/api/dropbox/dropbox_session.dart';
import 'package:ethercrypt/engine/api/http_client.dart';
import 'package:ethercrypt/engine/api/oauth_success_web_page.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/digests/sha256.dart';
import 'package:url_launcher/url_launcher.dart';

class DropboxAuthException implements Exception {
  final String message;
  final String raw;
  final int? statusCode;

  DropboxAuthException(this.message, {required this.raw, this.statusCode});

  @override
  String toString() => 'DropboxAuthException(error: $message, http status: $statusCode)';
}

class DropboxOAuth {
  final String _clientId;
  final Uri _oauth2TokenUrl = Uri.parse('https://api.dropboxapi.com/oauth2/token');

  final StreamController<DropboxSession?> _sessionController = StreamController.broadcast();

  final AppLifecycle lifecycle;

  DropboxSession? _session;

  DropboxOAuth({required String clientId, required this.lifecycle}) : _clientId = clientId;

  DropboxSession? get session => _session;
  bool get isLoggedIn => _session != null;
  bool get isConfigValid => _clientId.trim().isNotEmpty;

  Stream<DropboxSession?> get sessionChanges => _sessionController.stream;

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

  void _setSession(DropboxSession? session) {
    _session = session;
    _sessionController.add(session);
  }

  Future<void> authorize() async {
    final String verifier = _generateCodeVerifier();
    final String challenge = _generateCodeChallenge(verifier);

    final HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final String redirectUri = 'http://127.0.0.1:${server.port}/callback';

    final Uri authUri = Uri.https(
      'www.dropbox.com',
      'oauth2/authorize',
      {
        'client_id': _clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'token_access_type': 'offline',
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
      ..write(getOAuthSuccessPage('Dropbox'));

    await request.response.close();
    await server.close(force: true);

    if (code == null) {
      throw DropboxAuthException('Missing authorization code', raw: 'callback without code');
    }

    final DropboxSession session = await _exchangeCodeForToken(
      code,
      verifier,
      redirectUri,
    );

    _setSession(session);
  }

  Future<DropboxSession> _exchangeCodeForToken(String code, String verifier, String redirectUri) async {
    await lifecycle.waitUntilReady();

    final http.Client httpClient = LoggingHttpClient();
    try {
      final response = await httpClient.post(
        _oauth2TokenUrl,
        body: {
          'client_id': _clientId,
          // 'client_secret': _appSecret, // Apparently not used
          'code': code,
          'code_verifier': verifier,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DropboxAuthException(
          'Token exchange failed',
          raw: response.body,
          statusCode: response.statusCode,
        );
      }

      final data = json.decode(response.body);

      final expiresIn = data['expires_in'] as int;

      return DropboxSession(
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
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DropboxAuthException(
          'Refresh token failed',
          raw: response.body,
          statusCode: response.statusCode,
        );
      }

      final data = json.decode(response.body);
      final expiresIn = data['expires_in'] as int;

      _setSession(
        DropboxSession(
          accessToken: data['access_token'],
          refreshToken: refreshToken,
          expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
        ),
      );
    } finally {
      httpClient.close();
    }
  }

  Future<void> revokeAccess() async {
    if (_session?.accessToken != null) {
      final http.Client httpClient = LoggingHttpClient();
      try {
        final response = await httpClient.post(
          _oauth2TokenUrl,
          body: {
            'client_id': _clientId,
            'refresh_token': _session!.accessToken,
            'grant_type': 'refresh_token',
          },
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw DropboxAuthException(
            'Revoking session failed',
            raw: response.body,
            statusCode: response.statusCode,
          );
        }
      } finally {
        httpClient.close();
      }
    }
    _setSession(null);
  }
}
