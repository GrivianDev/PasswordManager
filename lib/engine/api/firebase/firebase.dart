import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ----- Global helper functions ------

Future<http.Response> _sendFirestoreRequest(Future<http.Response> Function() sendRequest,
    {List<int> expectedStatusCodes = const [200], FirebaseAuth? tryReloginIfAuthFailed}) async {
  if (tryReloginIfAuthFailed != null && !tryReloginIfAuthFailed.isUserLoggedIn) {
    throw Exception('Firestore user is not logged in');
  }
  try {
    print('Sending http request...');
    http.Response response = await sendRequest();

    if (response.statusCode == 401 && tryReloginIfAuthFailed != null) {
      // Try refreshing auth
      await tryReloginIfAuthFailed.loginWithRefreshToken();
      response = await sendRequest();
    }

    print('Response code: ${response.statusCode}');
    print(response.body);
    if (!expectedStatusCodes.contains(response.statusCode)) {
      throw HttpException(_extractFirebaseError(response.body) ?? 'Unexpected status code: ${response.statusCode}');
    }

    return response;
  } on SocketException {
    throw Exception('No internet connection');
  } on FormatException {
    throw Exception('Invalid response format from server');
  } catch (e) {
    throw Exception('Unexpected error: $e');
  }
}

String? _extractFirebaseError(String body) {
  try {
    final Map<String, dynamic> data = jsonDecode(body);
    final message = data['error']?['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }
  } catch (_) {
    // Ignore parsing errors
  }
  return null;
}

class FirestoreUser {
  final String email;
  final String refreshToken;
  final String? userId;
  final String? idToken;

  FirestoreUser(this.email, this.refreshToken, this.userId, this.idToken);
}

class FirebaseAuth {
  static late final SharedPreferences _prefs;
  static const _keyEmail = 'ethercrypt.auth.firebase.email';
  static const _keyRefreshToken = 'ethercrypt.auth.firebase.refreshToken';

  final Uri _authRefreshTokenUrl;
  final Uri _authSignUpUrl;
  final Uri _authLoginUrl;

  FirestoreUser? _user;

  FirebaseAuth(String apiKey)
      : _authRefreshTokenUrl = Uri.parse('https://securetoken.googleapis.com/v1/token?key=$apiKey'),
        _authSignUpUrl = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey'),
        _authLoginUrl = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');

  bool get isUserLoggedIn => _user != null;

  bool get isUserAuthenticated => _user?.userId != null && _user?.idToken != null;

  FirestoreUser? get user => _user;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? lastSignedInEmail() {
    String? email;
    try {
      email = _prefs.getString(_keyEmail);
    } catch (_) {}

    return email;
  }

  Future<void> signUp(String email, String password) async {
    final http.Response response = await _sendFirestoreRequest(() =>
        http.post(
            _authSignUpUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'returnSecureToken': true
            })
        ));

    final data = jsonDecode(response.body);

    // Store login info
    final String userId = data['localId'];
    final String idToken = data['idToken'];
    final String refreshToken = data['refreshToken'];
    await _prefs.setString(_keyEmail, email);
    await _prefs.setString(_keyRefreshToken, refreshToken);
    // Set firestore user
    _user = FirestoreUser(email, refreshToken, userId, idToken);
  }

  Future<void> login(String email, String password) async {
    final http.Response response = await _sendFirestoreRequest(() => http.post(
        _authLoginUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true
        })
    ));

    final data = jsonDecode(response.body);

    // Store login info
    final String userId = data['localId'];
    final String idToken = data['idToken'];
    final String refreshToken = data['refreshToken'];
    await _prefs.setString(_keyEmail, email);
    await _prefs.setString(_keyRefreshToken, refreshToken);
    // Set firestore user
    _user = FirestoreUser(email, refreshToken, userId, idToken);
  }

  Future<void> loginWithRefreshToken() async {
    String? email = _prefs.getString(_keyEmail);
    String? refreshToken = _prefs.getString(_keyRefreshToken);
    if (refreshToken == null || email == null) {
      throw Exception('User not logged in, please login again.');
    }

    final http.Response response = await _sendFirestoreRequest(() => http.post(
        _authRefreshTokenUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken
        })
    ));


    final data = jsonDecode(response.body);
    // Store login info
    final String userId = data['user_id'];
    final String idToken = data['id_token'];
    // Set firestore user
    _user = FirestoreUser(email, refreshToken, userId, idToken);
  }

  Future<void> logout() async {
    _user = null;
    _prefs.remove(_keyRefreshToken);
  }
}

class Firestore {
  static late final Firestore instance;

  final String projectId;
  final String apiKey;
  final FirebaseAuth auth;
  String get basePath => 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
  String get userVaultPath => 'ethercrypt-users/${auth.user?.userId}/vault';

  Firestore(this.projectId, this.apiKey) : auth = FirebaseAuth(apiKey);

  static Future<void> init(String projectId, String apiKey) async {
    instance = Firestore(projectId, apiKey);
    await instance.auth.init();
  }

  Future<String> createDocument(String collectionPath, Map<String, dynamic> data) async {
    final uri = Uri.parse('$basePath/$collectionPath');
    final response = await _sendFirestoreRequest(
      () => http.post(
        uri,
        headers: _headers(),
        body: jsonEncode({'fields': _wrapFields(data)}),
      ),
      expectedStatusCodes: [200],
      tryReloginIfAuthFailed: auth,
    );

    final json = jsonDecode(response.body);
    return json['name'];
  }

  Future<void> setDocument(String docPath, Map<String, dynamic> data) async {
    final uri = Uri.parse('$basePath/$docPath');
    await _sendFirestoreRequest(
      () => http.patch(
        uri,
        headers: _headers(),
        body: jsonEncode({'fields': _wrapFields(data)}),
      ),
      expectedStatusCodes: [200],
      tryReloginIfAuthFailed: auth,
    );
  }

  Future<Map<String, dynamic>> getDocument(String docPath, {List<String>? fieldMask}) async {
    final uri = Uri.parse('$basePath/$docPath${_buildFieldMask(fieldMask)}');
    final response = await _sendFirestoreRequest(
      () => http.get(uri, headers: _headers()),
      expectedStatusCodes: [200],
      tryReloginIfAuthFailed: auth,
    );
    return jsonDecode(response.body);
  }

  Future<List<Map<String, dynamic>>> getCollection(String collectionPath, {List<String>? fieldMask}) async {
    final uri = Uri.parse('$basePath/$collectionPath${_buildFieldMask(fieldMask)}');
    final response = await _sendFirestoreRequest(
      () => http.get(uri, headers: _headers()),
      expectedStatusCodes: [200],
    );
    final json = jsonDecode(response.body);
    final docs = (json['documents'] as List?) ?? [];
    return docs.cast<Map<String, dynamic>>();
  }

  Future<void> updateDocument(String path, Map<String, dynamic> data) async {
    if (data.isEmpty) return;

    final uri = Uri.parse('$basePath/$path?updateMask.fieldPaths=${data.keys.join(",")}');
    await _sendFirestoreRequest(
      () => http.patch(
        uri,
        headers: _headers(),
        body: jsonEncode({'fields': _wrapFields(data)}),
      ),
      expectedStatusCodes: [200],
      tryReloginIfAuthFailed: auth,
    );
  }

  Future<void> deleteDocument(String path) async {
    final uri = Uri.parse('$basePath/$path');
    print(uri);
    await _sendFirestoreRequest(
      () => http.delete(uri, headers: _headers()),
      expectedStatusCodes: [200, 204], // 204 is often used for successful deletions
      tryReloginIfAuthFailed: auth,
    );
  }


  // ----------- Helpers ------------
  Map<String, String> _headers() => {
    'Authorization': 'Bearer ${auth.user?.idToken}',
    'Content-Type': 'application/json',
  };

  String _buildFieldMask(List<String>? fieldMask) {
    if (fieldMask == null) return '';
    if (fieldMask.isEmpty) return '?mask.fieldPaths=__name__'; // Firestore internal var to indicate only to document id to be returned
    final encoded = fieldMask.map(Uri.encodeQueryComponent).join(',');
    return '?mask.fieldPaths=$encoded';
  }

  /// Converts a plain map to Firestore 'fields' format
  Map<String, dynamic> _wrapFields(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _wrapValue(value)));
  }

  // Firestores field format
  Map<String, dynamic> _wrapValue(dynamic value) {
    if (value is String) return {'stringValue': value};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is Map) return {'mapValue': {'fields': _wrapFields(value as Map<String, dynamic>)}};
    if (value is List) {
      return {
        'arrayValue': {
          'values': value.map(_wrapValue).toList(),
        }
      };
    }
    throw Exception('Unsupported Firestore type: ${value.runtimeType}');
  }
}
