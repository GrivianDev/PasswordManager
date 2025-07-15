import 'package:passwordmanager/engine/db/accessors/accessor.dart';
import 'package:passwordmanager/engine/db/accessors/accessor_registry.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/engine/persistence/connector/file_connector.dart';
import 'package:passwordmanager/engine/persistence/connector/persistence_connector.dart';

import 'connector/firebase_connector.dart';

/// Source object that models a dynamic source for the [LocalDatabase]. Supports
/// synchronisation between local files or firebase cloud via the [FirebaseConnector] class.
final class Source {
  late final LocalDatabase dbRef;
  final PersistenceConnector connector;
  DataAccessor? _accessor;

  bool _unsavedChanges = false;

  /// Default constructor that requires exactly one valid source. Exceptions are thrown otherwise.
  Source(this.connector);

  String? get name => connector.name;

  String? get accessorVersion => _accessor?.version;

  bool get usesLocalFile => connector is FileConnector;

  bool get usesFirestoreCloud => connector is FirebaseConnector;

  Future<bool> get isValid async => await connector.isAvailable;

  bool get hasUnsavedChanges => _unsavedChanges;

  void claimHasUnsavedChanges() => _unsavedChanges = true;

  /// Asynchronous method to load data from given file or firebase cloud.
  Future<void> loadData({required String password}) async {
    final String formattedData = await connector.load();
    final Map<String, String> properties = Source.readProperties(formattedData);
    final String vaultVersion = properties['version'] ?? 'v0';
    _accessor = DataAccessorRegistry.create(vaultVersion); // Choose correct accessor

    await _accessor!.loadAndDecrypt(dbRef, properties, password);
  }

  /// Write a random encrypted value to that source. That way an initial verification code is set.
  /// If creating a cloud storage then the [cloudDocName] parameter must be set.
  Future<void> initialiseNewSource({required String password, String? cloudDocName}) async {
    _accessor = DataAccessorRegistry.create(DataAccessorRegistry.latestVersion); // Auto create new ones with newest version
    final String formattedData = await _accessor!.encryptAndFormat(dbRef, password);

    if (await connector.isAvailable) {
      await connector.create(formattedData);
    } else {
      throw Exception('Connector was not available');
    }
  }

  /// Asynchronous method to save changes to a local file or the firebase cloud.
  Future<void> saveData() async {
    final String formattedData = await getFormattedData();

    if (await connector.isAvailable) {
      await connector.save(formattedData);
    } else {
      throw Exception('Connector was not available');
    }
    _unsavedChanges = false;
  }

  Future<void> deleteSource() => connector.delete();

  Future<String> getFormattedData() async {
    return await _accessor!.encryptAndFormat(dbRef);
  }

  static Map<String, String> readProperties(String content) {
    Map<String, String> properties = {};

    int start = 0;
    int end = content.indexOf(';', start);
    while (end != -1) {
      final int equalSignIndex = content.indexOf('=', start);
      final String key = content.substring(start, equalSignIndex);
      final String value = content.substring(equalSignIndex + 1, end);
      if (key.isEmpty || value.isEmpty) {
        throw Exception('Error parsing parameters');
      }
      properties[key] = value;

      start = end + 1;
      end = content.indexOf(';', start);
    }

    return properties;
  }
}
