import 'package:firedart/auth/firebase_auth.dart';
import 'package:firedart/auth/token_store.dart';
import 'package:firedart/firestore/firestore.dart';
import 'package:firedart/firestore/models.dart';
import 'package:firedart/firestore/token_authenticator.dart';

import 'keys/access.dart';

/// Doesn't actually persist tokens. Useful for testing or in environments where
/// persistence isn't available but it's fine signing in for each session.
class VolatileStore extends TokenStore {
  @override
  Token? read() => null;

  @override
  void write(Token? token) {}

  @override
  void delete() {}
}

/// Main class for managing the connection to the firebase cloud.
/// Needs to be initialized through a call to the [init] function and can optionally be deactivated.
final class FirebaseConnector {
  static late final bool deactivated;
  static late final Firestore _firestore;
  static late final FirebaseAuth _auth;
  static late CollectionReference _storage;

  String _id = '';
  String? _name;

  bool get isLoggedIn => _auth.isSignedIn;

  String? get name => _name;

  /// Deletes the id of the last active document
  void invalidate() {
    _id = '';
    _name = null;
  }

  /// Method to initialize the [FirebaseConnector] class. An own [Firestore] and [FirebaseAuth] object are
  /// created for authentication. In addition a reference to the core collection is stored.
  static Future<void> init({bool deactivate = false}) async {
    deactivated = deactivate;
    if (!deactivated) {
      _auth = FirebaseAuth(KeyStore.apiKey, VolatileStore());
      _firestore = Firestore(KeyStore.projectId, authenticator: TokenAuthenticator.from(_auth)?.authenticate);
      _storage = _firestore.collection('ethercrypt-storage');
    }
  }

  /// Performs a optional login action. Ethercrypt alone is granted access through strict security rules to the cloud data, so the app needs
  /// to be logged in to manipulate data. An exception might be thrown if:
  /// * Failed login
  /// * Internet connection is missing
  Future<void> login() async {
    try {
      if (!isLoggedIn) await _auth.signIn('ethercrypt@access.de', KeyStore.accessCode);
    } catch (e) {
      throw Exception('Could not access cloud storage');
    }
  }

  /// Logs out the app if it was logged in.
  void logout() {
    if (isLoggedIn) {
      _auth.signOut();
      invalidate();
    }
  }

  /// Checks if there is a storage present inside the cloud with the specified name. Return true if it exists, false otherwise.
  /// Cases this method throws exceptions:
  /// * Permission is denied
  /// * Internet connection is missing
  Future<bool> docExists(String name) async {
    try {
      await login();
      final List<Document> docs = await _storage.where('name', isEqualTo: name).get();
      return docs.isNotEmpty;
    } catch (e) {
      throw Exception('Could not test if document exists');
    }
  }

  /// Set the active document for manipulation.
  /// Cases this method throws exceptions:
  /// * Permission is denied
  /// * Internet connection is missing
  /// * Document does not exist
  Future<void> setActiveDocument(String name) async {
    try {
      await login();
      final List<Document> docs = await _storage.where('name', isEqualTo: name).get();
      _name = name;
      _id = docs[0].id;
    } catch (e) {
      throw Exception('Could not set active document');
    }
  }

  /// Creates a Document with the specified properties.
  /// Cases this method throws exceptions:
  /// * Permission is denied
  /// * Internet connection is missing
  Future<void> createDocument({required String name, required String data}) async {
    try {
      await login();
      await _storage.add({
        'name': name,
        'data': data,
      });
    } catch (e) {
      throw Exception('Could not add new document');
    }
  }

  /// Returns the encrypted data stored at the "data" key in the cloud. Identifies document via [_id] property.
  /// Cases this method throws exceptions:
  /// * Permission is denied
  /// * Internet connection is missing
  Future<String> getData() async {
    try {
      await login();
      final Document doc = await _storage.document(_id).get();
      return doc.map['data'];
    } catch (e) {
      throw Exception('Could not access data');
    }
  }

  /// Overwrites the "data" property in the firebase cloud. Identifies document via [_id] property.
  /// Cases this method throws exceptions:
  /// * Permission is denied
  /// * Internet connection is missing
  Future<void> editDocument({required String newData}) async {
    try {
      await login();
      await _storage.document(_id).update({
        'data': newData,
      });
    } catch (e) {
      throw Exception('Could not edit document');
    }
  }

  /// Deletes the currently active storage. Identifies document via [_id] property.
  /// Cases this method throws exceptions:
  /// * Permission is denied
  /// * Internet connection is missing
  Future<void> deleteDocument() async {
    try {
      await login();
      await _storage.document(_id).delete();
      invalidate();
    } catch (e) {
      throw Exception('Could not delete document');
    }
  }
}
