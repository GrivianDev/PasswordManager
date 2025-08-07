import 'package:passwordmanager/engine/db/accessors/accessor.dart';
import 'package:passwordmanager/engine/db/accessors/accessor_registry.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/engine/persistence/connector/file_connector.dart';
import 'package:passwordmanager/engine/persistence/connector/persistence_connector.dart';

import 'connector/firebase_connector.dart';

/// Source object that models a dynamic source for the [LocalDatabase]. Depending on the [PersistenceConnector] subclass,
/// actions can be done to a local file or a cloud storage for example.
final class Source {
  final LocalDatabase dbRef;
  final PersistenceConnector connector;
  DataAccessor? _accessor;
  String _password;

  /// Default constructor that requires exactly one valid source. Exceptions are thrown otherwise.
  Source(this.connector, this.dbRef, {required String password}) : _password = password;

  String? get name => connector.name;

  String? get accessorVersion => _accessor?.version;

  bool get usesLocalFile => connector is FileConnector;

  bool get usesFirestoreCloud => connector is FirebaseConnector;

  Future<bool> get isValid => connector.isAvailable;

  void changePassword(String newPassword) {
    _password = newPassword;
    _accessor?.definePassword(_password);
  }

  /// Asynchronous method to load data from given file or firebase cloud.
  Future<void> loadData() async {
    if (!(await connector.isAvailable)) {
      throw Exception('Connector was not available');
    }

    final String formattedData = await connector.load();
    final Map<String, String> properties = Source.readProperties(formattedData);
    final String vaultVersion = properties['version'] ?? 'v0';

    _accessor = DataAccessorRegistry.create(vaultVersion); // Choose correct accessor
    _accessor!.definePassword(_password);

    await _accessor!.loadAndDecrypt(dbRef, properties);
  }

  /// Write a random encrypted value to that source. That way an initial verification code is set.
  Future<void> initialiseNewSource() async {
    _accessor = DataAccessorRegistry.create(DataAccessorRegistry.latestVersion); // Auto create new ones with newest version
    _accessor!.definePassword(_password);

    await connector.create(await getFormattedData());
  }

  /// Asynchronous method to save changes to a local file or the firebase cloud.
  Future<void> saveData() async {
    if (!(await connector.isAvailable)) {
      throw Exception('Connector was not available');
    }

    await connector.save(await getFormattedData());
  }

  Future<void> upgradeSource() async {
    if (!(await connector.isAvailable)) {
      throw Exception('Connector was not available');
    }

    _accessor = DataAccessorRegistry.create(DataAccessorRegistry.latestVersion);
    _accessor!.definePassword(_password);

    await connector.save(await getFormattedData());
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
