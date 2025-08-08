import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:passwordmanager/engine/persistence/appstate.dart';

// ----- Global helper functions ------

/// Sends a Firestore HTTP request with:
/// - Automatic retry on auth failure (if [tryReloginIfAuthFailed] is set)
/// - Status code validation against [expectedStatusCodes]
/// - Error handling for network, format, and Firebase error responses
Future<http.Response> _sendFirestoreRequest(Future<http.Response> Function() sendRequest,
    {List<int> expectedStatusCodes = const [200], FirebaseAuth? tryReloginIfAuthFailed}) async {
  if (tryReloginIfAuthFailed != null && !tryReloginIfAuthFailed.isUserLoggedIn) {
    throw Exception('Firestore user is not logged in');
  }
  try {
    http.Response response = await sendRequest();

    if (response.statusCode == 401 && tryReloginIfAuthFailed != null) {
      // Try refreshing auth
      await tryReloginIfAuthFailed.loginWithRefreshToken();
      response = await sendRequest();
    }

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

/// Parses Firebase error messages from a response body.
/// Returns `null` if no error message could be extracted.
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

/// Holds authentication details for a signed-in Firebase user.
class FirestoreUser {
  final String email;

  /// Long-lived refresh token for obtaining new ID tokens
  /// without requiring the user's password again.
  ///
  /// Stored in [AppState] so it can persist across app restarts.
  final String refreshToken;

  /// Firebase Authentication user identifier (`localId` in API responses).
  ///
  /// This is globally unique within the Firebase project.
  final String userId;

  /// Short-lived ID token (JWT) used for authenticating
  /// requests to Firebase services like Firestore.
  ///
  /// Expires after ~1 hour, after which it must be refreshed
  /// using [refreshToken].
  final String idToken;

  FirestoreUser(this.email, this.refreshToken, this.userId, this.idToken);
}

/// Handles Firebase Authentication via REST API.
class FirebaseAuth {
  final Uri _authRefreshTokenUrl;
  final Uri _authSignUpUrl;
  final Uri _authLoginUrl;
  final AppState _appStateRef;

  FirestoreUser? _user;

  /// Creates an auth client using the provided [apiKey] and [appStateRef].
  FirebaseAuth(String apiKey, AppState appStateRef)
      : _authRefreshTokenUrl = Uri.parse('https://securetoken.googleapis.com/v1/token?key=$apiKey'),
        _authSignUpUrl = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey'),
        _authLoginUrl = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey'),
        _appStateRef = appStateRef;

  bool get isUserLoggedIn => _user != null;

  FirestoreUser? get user => _user;

  /// Returns the last email used to sign in, if available.
  String? lastSignedInEmail() => _appStateRef.firebaseAuthLastUserEmail.value;

  /// Creates a new Firebase user account and signs them in.
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

    // Update app state
    _appStateRef.firebaseAuthLastUserEmail.value = email;
    _appStateRef.firebaseAuthRefreshToken.value = refreshToken;
    await _appStateRef.save();

    // Set firestore user
    _user = FirestoreUser(email, refreshToken, userId, idToken);
  }

  /// Signs in an existing Firebase user with [email] and [password].
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

    // Update app state
    _appStateRef.firebaseAuthLastUserEmail.value = email;
    _appStateRef.firebaseAuthRefreshToken.value = refreshToken;
    await _appStateRef.save();

    // Set firestore user
    _user = FirestoreUser(email, refreshToken, userId, idToken);
  }

  /// Logs in using the stored refresh token from [AppState].
  Future<void> loginWithRefreshToken() async {
    String? email = _appStateRef.firebaseAuthLastUserEmail.value;
    String? refreshToken = _appStateRef.firebaseAuthRefreshToken.value;
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

  /// Logs out the current user and clears stored credentials.
  Future<void> logout() async {
    _user = null;
    _appStateRef.firebaseAuthRefreshToken.value = null;
    await _appStateRef.save();
  }
}

/// Provides Firestore document CRUD operations using REST API.
/// All request are automatically retried once.
class Firestore {
  final String projectId;
  final String apiKey;
  final FirebaseAuth auth;

  /// Base path for Firestore REST API requests.
  String get basePath => 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
  /// Path to the signed-in user's vault.
  String get userVaultPath => 'ethercrypt-users/${auth.user!.userId}/vault';

  Firestore(this.projectId, this.apiKey, AppState appState) : auth = FirebaseAuth(apiKey, appState);

  /// Returns `true` if [projectId] or [apiKey] is empty.
  bool get deactivated => projectId.isEmpty || apiKey.isEmpty;

  /// Creates a new document in the given Firestore [collectionPath].
  ///
  /// **Input**:
  /// - [collectionPath] is relative to the database root (e.g. `"users"`, `"users/userId/items"`).
  /// - [data] is a plain Dart map of field names to values.
  ///
  /// **Output**:
  /// - Returns the document's full resource name (string) in the format:
  ///   `"projects/{projectId}/databases/(default)/documents/{collectionPath}/{docId}"`
  ///
  /// **Notes**:
  /// - A random document ID is generated by Firestore.
  /// - Throws if the API key or authentication is invalid.
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

  /// Creates or completely overwrites the document at [docPath].
  ///
  /// **Input**:
  /// - [docPath] must be the full path from the database root, including the document name (e.g. `"users/userId/documentName"`).
  /// - [data] is a plain Dart map of field names to values.
  ///
  /// **Behavior**:
  /// - If the document exists, all existing fields will be replaced.
  /// - If it doesn't exist, it will be created.
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

  /// Retrieves a single document specified by [docPath].
  ///
  /// **Input**:
  /// - [docPath] is the full path from the database root.
  /// - Optional [fieldMask] filters which fields are returned. An empty list only returns the document name.
  ///
  /// **Output**:
  /// - Returns the raw Firestore REST response as a Dart `Map<String, dynamic>`.
  ///   Example structure:
  ///   ```json
  ///   {
  ///     "name": "projects/.../documents/users/userId",
  ///     "fields": {
  ///       "username": {"stringValue": "alice"},
  ///       "age": {"integerValue": "30"}
  ///     },
  ///     "createTime": "...",
  ///     "updateTime": "..."
  ///   }
  ///   ```
  ///
  /// **Note**:
  /// - This does **not** unwrap the `"fields"` map to raw Dart types — caller must handle that.
  Future<Map<String, dynamic>> getDocument(String docPath, {List<String>? fieldMask}) async {
    final uri = Uri.parse('$basePath/$docPath${_buildFieldMask(fieldMask)}');
    final response = await _sendFirestoreRequest(
      () => http.get(uri, headers: _headers()),
      expectedStatusCodes: [200],
      tryReloginIfAuthFailed: auth,
    );
    return jsonDecode(response.body);
  }

  /// Retrieves all documents from a collection at [collectionPath].
  ///
  /// **Input**:
  /// - [collectionPath] is relative to the database root.
  /// - Optional [fieldMask] filters fields for all returned documents. An empty list only returns the document name.
  ///
  /// **Output**:
  /// - Returns a list of raw Firestore REST document maps, same structure as [getDocument].
  /// - If the collection is empty, returns an empty list.
  ///
  /// **Note**:
  /// - Does not auto-paginate — will only return the first page of results from Firestore.
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

  /// Updates one or more fields in an existing document at [docPath].
  ///
  /// **Input**:
  /// - [docPath] is the document path from the database root.
  /// - [data] contains only the fields to update.
  ///
  /// **Behavior**:
  /// - Fields not listed in [data] remain unchanged.
  /// - If [data] is empty, the method returns immediately without making a request.
  Future<void> updateDocument(String docPath, Map<String, dynamic> data) async {
    if (data.isEmpty) return;

    final uri = Uri.parse('$basePath/$docPath?updateMask.fieldPaths=${data.keys.join(",")}');
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

  /// Deletes the document at [docPath].
  ///
  /// **Input**:
  /// - [docPath] is the document path from the database root.
  ///
  /// **Behavior**:
  /// - Removes the document and all of its fields.
  Future<void> deleteDocument(String docPath) async {
    final uri = Uri.parse('$basePath/$docPath');
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
