import 'package:passwordmanager/engine/api/firebase/firebase.dart';
import 'package:passwordmanager/engine/persistence/connector/persistence_connector.dart';

class FirebaseConnector implements PersistenceConnector {
  String _cloudDocId;
  final String _cloudDocName;

  FirebaseConnector({required String cloudDocId, required String cloudDocName}) : _cloudDocName = cloudDocName, _cloudDocId = cloudDocId;

  @override
  String get name => _cloudDocName;

  /// Returns true if the connector is ready to be used (e.g., file exists, user is logged in)
  @override
  Future<bool> get isAvailable async => Firestore.instance.auth.isUserLoggedIn;

  /// Loads the formatted, encrypted data string from the source
  @override
  Future<String> load() async {
    final Map<String, dynamic> doc = await Firestore.instance.getDocument('${Firestore.instance.userVaultPath}/$_cloudDocId', fieldMask: ['data']);
    return doc['fields']['data']['stringValue'];
  }

  /// Saves a new version of the formatted, encrypted data string
  @override
  Future<void> save(String formattedData) async {
    await Firestore.instance.updateDocument('${Firestore.instance.userVaultPath}/$_cloudDocId', {'data': formattedData});
  }

  /// Creates a new document or file with the given content (may be the same as save)
  @override
  Future<void> create(String formattedData) async {
    String totalDocPath = await Firestore.instance.createDocument(Firestore.instance.userVaultPath, {'data': formattedData});
    _cloudDocId = totalDocPath.split('/').last;
  }

  /// Optionally invalidates the session or state (e.g., logout, cache clear)
  @override
  Future<void> delete() async {
    await Firestore.instance.deleteDocument('${Firestore.instance.userVaultPath}/$_cloudDocId');
  }
}