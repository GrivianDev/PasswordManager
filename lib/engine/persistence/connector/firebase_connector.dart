import 'package:passwordmanager/engine/api/firebase/firebase.dart';
import 'package:passwordmanager/engine/persistence/connector/persistence_connector.dart';

class FirebaseConnector implements PersistenceConnector {
  String _cloudDocId;
  final String _cloudDocName;
  final Firestore _firestoreServiceRef;

  FirebaseConnector({required String cloudDocId, required String cloudDocName, required Firestore firestoreServiceRef})
      : _cloudDocName = cloudDocName,
        _cloudDocId = cloudDocId,
        _firestoreServiceRef = firestoreServiceRef;

  @override
  String get name => _cloudDocName;

  /// Returns true if the connector is ready to be used (e.g., file exists, user is logged in)
  @override
  Future<bool> get isAvailable => Future.value(_firestoreServiceRef.auth.isUserLoggedIn);

  /// Loads the formatted, encrypted data string from the source
  @override
  Future<String> load() async {
    final Map<String, dynamic> doc = await _firestoreServiceRef.getDocument('${_firestoreServiceRef.userVaultPath}/$_cloudDocId', fieldMask: ['data']);
    return doc['fields']['data']['stringValue'];
  }

  /// Saves a new version of the formatted, encrypted data string
  @override
  Future<void> save(String formattedData) async {
    await _firestoreServiceRef.updateDocument('${_firestoreServiceRef.userVaultPath}/$_cloudDocId', {'data': formattedData});
  }

  /// Creates a new document or file with the given content (may be the same as save)
  @override
  Future<void> create(String formattedData) async {
    String totalDocPath = await _firestoreServiceRef.createDocument(_firestoreServiceRef.userVaultPath, {'data': formattedData});
    _cloudDocId = totalDocPath.split('/').last;
  }

  /// Optionally invalidates the session or state (e.g., logout, cache clear)
  @override
  Future<void> delete() async {
    await _firestoreServiceRef.deleteDocument('${_firestoreServiceRef.userVaultPath}/$_cloudDocId');
  }
}