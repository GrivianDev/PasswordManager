import 'package:passwordmanager/engine/db/accessors/accessor.dart';
import 'package:passwordmanager/engine/db/accessors/accessor_registry.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/engine/persistence/connector/file_connector.dart';
import 'package:passwordmanager/engine/persistence/connector/persistence_connector.dart';

import 'connector/firebase_connector.dart';

/// Represents a single dynamic storage source for a [LocalDatabase].
///
/// A `Source` acts as the bridge between a [LocalDatabase] and a physical or remote
/// storage location, defined by its [PersistenceConnector] (e.g., a local file, Firebase cloud).
final class Source {
  final LocalDatabase dbRef;
  final PersistenceConnector connector;
  DataAccessor? _accessor;
  String _password;

  /// Creates a new source bound to a given [connector] and [LocalDatabase] reference.
  ///
  /// [password] is the encryption key for this source. Must be provided.
  Source(this.connector, this.dbRef, {required String password}) : _password = password;

  String? get displayName => connector.name;

  /// Version of the currently active [DataAccessor] used for interpreting and encrypting data.
  String? get accessorVersion => _accessor?.version;

  /// Whether the source is backed by a local file.
  bool get usesLocalFile => connector is FileConnector;

  /// Whether the source is backed by a Firebase Firestore cloud connector.
  bool get usesFirestoreCloud => connector is FirebaseConnector;

  /// Whether the source is currently available for load/save operations.
  Future<bool> get isValid => connector.isAvailable;

  /// Changes the encryption password for the source and applies it to the active [DataAccessor].
  void changePassword(String newPassword) {
    _password = newPassword;
    _accessor?.definePassword(_password);
  }

  /// Loads and decrypts data from the source into the [LocalDatabase].
  ///
  /// Throws an [Exception] if the connector is unavailable or the stored data
  /// cannot be parsed.
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

  /// Creates a new source with an initial encrypted value to set up verification.
  ///
  /// Uses the latest [DataAccessor] version for formatting and encryption.
  Future<void> initialiseNewSource() async {
    _accessor = DataAccessorRegistry.create(DataAccessorRegistry.latestVersion); // Auto create new ones with newest version
    _accessor!.definePassword(_password);

    await connector.create(await getFormattedData());
  }

  /// Saves the current [LocalDatabase] state to the source, encrypting it first.
  ///
  /// Throws an [Exception] if the connector is unavailable.
  Future<void> saveData() async {
    if (!(await connector.isAvailable)) {
      throw Exception('Connector was not available');
    }

    await connector.save(await getFormattedData());
  }

  /// Upgrades the source to use the latest [DataAccessor] format and saves it.
  ///
  /// Throws an [Exception] if the connector is unavailable.
  Future<void> upgradeSource() async {
    if (!(await connector.isAvailable)) {
      throw Exception('Connector was not available');
    }

    _accessor = DataAccessorRegistry.create(DataAccessorRegistry.latestVersion);
    _accessor!.definePassword(_password);

    await connector.save(await getFormattedData());
  }

  /// Deletes the its underlying storage.
  Future<void> deleteSource() => connector.delete();

  /// Encrypts the [LocalDatabase] contents and formats them for storage.
  Future<String> getFormattedData() async {
    return await _accessor!.encryptAndFormat(dbRef);
  }

  /// Parses a `key=value;` formatted string into a [Map] of properties.
  ///
  /// Throws an [Exception] if any property key or value is empty.
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
