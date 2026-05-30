import 'package:ethercrypt/engine/db/accessors/accessor.dart';
import 'package:ethercrypt/engine/db/accessors/accessor_registry.dart';
import 'package:ethercrypt/engine/db/database_content.dart';
import 'package:ethercrypt/engine/db/local_database.dart';
import 'package:ethercrypt/engine/other/property_codec.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';

/// Represents a single storage source for a [LocalDatabase].
final class Source {
  final StorageController _controller;
  StorageFile _file;
  DataAccessor? _accessor;
  String _password;

  Source(this._controller, {required StorageFile file, required String password})
      : _file = file,
        _password = password;

  /// Version of the currently active [DataAccessor] used for interpreting and encrypting data.
  String? get accessorVersion => _accessor?.version;

  StorageFile get file => _file;

  /// Creates a new source with an initial encrypted value to set up verification.
  ///
  /// Uses the latest [DataAccessor] version for formatting and encryption.
  static Future<Source> initialiseNew(StorageController controller, {required String name, required String location, required String password}) async {
    DataAccessor accessor = DataAccessorRegistry.create(DataAccessorRegistry.latestVersion); // Auto create new ones with newest version
    accessor.setPassword(password);

    final Map<String, String> properties = await accessor.pack(DatabaseContent.empty());
    final StorageFile file = await controller.repository.create(
      name: name,
      location: location,
      initialData: PropertyCodec.encode(properties),
    );
    return Source(controller, file: file, password: password);
  }

  /// Changes the encryption password for the source and applies it to the active [DataAccessor].
  void changePassword(String newPassword) {
    _password = newPassword;
    _accessor?.setPassword(_password);
  }

  /// Loads and decrypts data from the source.
  Future<DatabaseContent> loadData() async {
    final String formattedData = await _controller.repository.read(_file);
    final Map<String, String> properties = PropertyCodec.decode(formattedData);
    final String vaultVersion = properties['version'] ?? 'v0';

    _accessor = DataAccessorRegistry.create(vaultVersion); // Choose correct accessor
    _accessor!.setPassword(_password);

    return _accessor!.unpack(properties);
  }

  Future<void> saveData(DatabaseContent dbContent) async {
    // Auto upgrade
    if (_accessor?.version != DataAccessorRegistry.latestVersion) {
      _accessor = DataAccessorRegistry.create(DataAccessorRegistry.latestVersion);
      _accessor!.setPassword(_password);
    }

    final String formattedData = await getFormattedData(dbContent);
    final StorageFile previous = _file;
    _file = await _controller.repository.update(previous, formattedData);
    _controller.applyFileUpdate(previous, _file);
  }

  Future<String> getFormattedData(DatabaseContent dbContent) async {
    if (_accessor == null) {
      throw Exception('Source not initialized');
    }

    final Map<String, String> properties = await _accessor!.pack(dbContent);
    return PropertyCodec.encode(properties);
  }
}
