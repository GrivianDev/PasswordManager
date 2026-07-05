import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ethercrypt/engine/api/firebase/firebase_session.dart';
import 'package:ethercrypt/engine/api/http_client.dart';
import 'package:http/http.dart' as http;

class FirebaseAuthException implements Exception {
  final String message;
  final String raw;
  final int? statusCode;

  FirebaseAuthException(this.message, {required this.raw, this.statusCode});

  @override
  String toString() => 'FirebaseAuthException(error: $message, http status: $statusCode)';
}

/// Handles Firebase Authentication via REST API.
class FirebaseAuth {
  String? _apiKey;
  Uri? _authRefreshTokenUrl;
  Uri? _authSignUpUrl;
  Uri? _authLoginUrl;
  Uri? _authDeleteAccountUrl;

  final StreamController<FirebaseSession?> _authController;
  FirebaseSession? _session;

  FirebaseAuth() : _authController = StreamController<FirebaseSession?>.broadcast();

  Stream<FirebaseSession?> get authChanges => _authController.stream;

  bool get isLoggedIn => _session != null;

  FirebaseSession? get session => _session;

  String? get apiKey => _apiKey;

  set apiKey(String? apiKey) {
    _apiKey = apiKey;
    _authRefreshTokenUrl = Uri.https('securetoken.googleapis.com', '/v1/token', {'key': apiKey});
    _authSignUpUrl = Uri.https('identitytoolkit.googleapis.com', '/v1/accounts:signUp', {'key': apiKey});
    _authLoginUrl = Uri.https('identitytoolkit.googleapis.com', '/v1/accounts:signInWithPassword', {'key': apiKey});
    _authDeleteAccountUrl = Uri.https('identitytoolkit.googleapis.com', '/v1/accounts:delete', {'key': apiKey});
    logout();
  }

  void setInitialSession(FirebaseSession? session) => _session = session;

  void _setSession(FirebaseSession? session) {
    _session = session;
    _authController.add(session);
  }

  void _throwIfNotSuccessResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      dynamic data;
      try {
        // Response may have json formatted error info
        data = json.decode(response.body);
      } catch (_) {}
      // Logout if suddenly unauthorized
      if (response.statusCode == HttpStatus.unauthorized && isLoggedIn) {
        _setSession(null);
      }
      throw FirebaseAuthException(
        data?['error']?['message'] ?? 'UNKNOWN',
        raw: response.body,
        statusCode: response.statusCode,
      );
    }
  }

  void _extractAndApplyUser(String userString, {bool otherKeyNames = false}) {
    final data = json.decode(userString);
    if (otherKeyNames) {
      final String userId = data['user_id'];
      final String idToken = data['access_token'];
      final String refreshToken = data['refresh_token'];
      final int? expiresIn = int.tryParse(data['expires_in']);
      _session = FirebaseSession(
        userId: userId,
        idToken: idToken,
        expiresAt: DateTime.now().toUtc().add(Duration(seconds: expiresIn!)),
        refreshToken: refreshToken,
      );
      _authController.add(session);
    } else {
      final String userId = data['localId'];
      final String idToken = data['idToken'];
      final String refreshToken = data['refreshToken'];
      final int? expiresIn = int.tryParse(data['expiresIn']);
      _session = FirebaseSession(
        userId: userId,
        idToken: idToken,
        expiresAt: DateTime.now().toUtc().add(Duration(seconds: expiresIn!)),
        refreshToken: refreshToken,
      );
      _authController.add(session);
    }
  }

  /// Creates a new Firebase user account and signs them in.
  Future<void> signUp(String email, String password) async {
    final http.Client httpClient = LoggingHttpClient();
    try {
      final response = await httpClient.post(
        _authSignUpUrl!,
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.value},
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      _throwIfNotSuccessResponse(response);

      _extractAndApplyUser(response.body);
    } finally {
      httpClient.close();
    }
  }

  /// Signs in an existing Firebase user with [email] and [password].
  Future<void> login(String email, String password) async {
    final http.Client httpClient = LoggingHttpClient();
    try {
      final response = await httpClient.post(
        _authLoginUrl!,
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.value},
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      _throwIfNotSuccessResponse(response);

      _extractAndApplyUser(response.body);
    } finally {
      httpClient.close();
    }
  }

  /// Logs in using a refresh token.
  Future<void> authorizeWithRefreshToken(String refreshToken) async {
    final http.Client httpClient = LoggingHttpClient();
    try {
      final response = await httpClient.post(
        _authRefreshTokenUrl!,
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.value},
        body: json.encode({
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        }),
      );

      _throwIfNotSuccessResponse(response);

      // (Different keys compared to sign up / login)
      _extractAndApplyUser(response.body, otherKeyNames: true);
    } finally {
      httpClient.close();
    }
  }

  // Delets an account from firebase
  Future<void> deleteAccount() async {
    final http.Client httpClient = LoggingHttpClient();

    try {
      final response = await httpClient.post(
        _authDeleteAccountUrl!,
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.value},
        body: json.encode({'idToken': _session!.idToken}),
      );

      _throwIfNotSuccessResponse(response);

      _setSession(null);
    } finally {
      httpClient.close();
    }
  }

  /// Logs out the current user
  void logout() {
    if (isLoggedIn) {
      _setSession(null);
    }
  }
}
