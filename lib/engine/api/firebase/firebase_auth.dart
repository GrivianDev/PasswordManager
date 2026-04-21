import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:passwordmanager/engine/api/firebase/firebase_user.dart';
import 'package:passwordmanager/engine/api/http_client.dart';

class FirebaseAuthException implements Exception {
  final String code;
  final int? statusCode;
  final dynamic raw;

  FirebaseAuthException(this.code, {this.statusCode, this.raw});

  @override
  String toString() => 'FirebaseAuthException(error: $code, http status: $statusCode)';
}

/// Handles Firebase Authentication via REST API.
class FirebaseAuth {
  String? _apiKey;
  Uri? _authRefreshTokenUrl;
  Uri? _authSignUpUrl;
  Uri? _authLoginUrl;

  final StreamController<FirebaseUser?> _authController;
  FirebaseUser? _user;

  FirebaseAuth() : _authController = StreamController<FirebaseUser?>.broadcast();

  Stream<FirebaseUser?> get authChanges => _authController.stream;

  bool get isUserLoggedIn => _user != null;

  FirebaseUser? get user => _user;

  String? get apiKey => _apiKey;

  set apiKey(String? apiKey) {
    _apiKey = apiKey;
    _authRefreshTokenUrl = Uri.parse('https://securetoken.googleapis.com/v1/token?key=$apiKey');
    _authSignUpUrl = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');
    _authLoginUrl = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');
    logout();
  }

  void _extractAndThrowAuthError(http.Response response) {
    dynamic data;
    try {
      // Response may have json formatted error info
      data = json.decode(response.body);
    } catch (_) {}
    // Logout if suddenly unauthorized
    if (response.statusCode == HttpStatus.unauthorized && isUserLoggedIn) {
      logout();
    }
    throw FirebaseAuthException(
      data?['error']?['message'] ?? 'UNKNOWN',
      statusCode: response.statusCode,
      raw: response.body,
    );
  }

  void _setUser(FirebaseUser? user) {
    _user = user;
    _authController.add(user);
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

      if (response.statusCode != HttpStatus.ok) {
        _extractAndThrowAuthError(response);
      }

      final data = json.decode(response.body);
      final String userId = data['localId'];
      final String idToken = data['idToken'];
      final String refreshToken = data['refreshToken'];
      _setUser(FirebaseUser(email, refreshToken, userId, idToken));
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

      if (response.statusCode != HttpStatus.ok) {
        _extractAndThrowAuthError(response);
      }

      final data = json.decode(response.body);
      final String userId = data['localId'];
      final String idToken = data['idToken'];
      final String refreshToken = data['refreshToken'];
      _setUser(FirebaseUser(email, refreshToken, userId, idToken));
    } finally {
      httpClient.close();
    }
  }

  /// Logs in using a refresh token.
  Future<void> loginWithRefreshToken(String email, String refreshToken) async {
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

      if (response.statusCode != HttpStatus.ok) {
        _extractAndThrowAuthError(response);
      }

      final data = json.decode(response.body);
      // (Different keys compared to sign up / login)
      final String userId = data['user_id'];
      final String idToken = data['id_token'];
      _setUser(FirebaseUser(email, refreshToken, userId, idToken));
    } finally {
      httpClient.close();
    }
  }

  /// Logs out the current user
  void logout() => _setUser(null);
}
