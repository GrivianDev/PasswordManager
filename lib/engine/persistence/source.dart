import 'package:passwordmanager/engine/db/accessors/accessor.dart';
import 'package:passwordmanager/engine/db/accessors/accessor_registry.dart';
import 'package:passwordmanager/engine/db/database_content.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/engine/other/property_codec.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_file.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_repository.dart';

/// Represents a single storage source for a [LocalDatabase].
final class Source {
  final StorageRepository _repository;
  final StorageFile file;
  DataAccessor? _accessor;
  String _password;

  Source(this._repository, {required this.file, required String password}) : _password = password;

  /// Version of the currently active [DataAccessor] used for interpreting and encrypting data.
  String? get accessorVersion => _accessor?.version;

  /// Creates a new source with an initial encrypted value to set up verification.
  ///
  /// Uses the latest [DataAccessor] version for formatting and encryption.
  static Future<Source> initialiseNew(StorageRepository repository, {required String name, required String location, required String password}) async {
    DataAccessor accessor = DataAccessorRegistry.create(DataAccessorRegistry.latestVersion); // Auto create new ones with newest version
    accessor.setPassword(password);

    final Map<String, String> properties = await accessor.pack(DatabaseContent.empty());
    final StorageFile file = await repository.create(
      name: name,
      location: location,
      initialData: PropertyCodec.encode(properties),
    );
    return Source(repository, file: file, password: password);
  }

  /// Changes the encryption password for the source and applies it to the active [DataAccessor].
  void changePassword(String newPassword) {
    _password = newPassword;
    _accessor?.setPassword(_password);
  }

  /// Loads and decrypts data from the source.
  Future<DatabaseContent> loadData() async {
    final String formattedData = await _repository.read(file);
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
    await _repository.update(file, formattedData);
  }

  Future<String> getFormattedData(DatabaseContent dbContent) async {
    if (_accessor == null) {
      throw Exception('Source not initialized');
    }

    final Map<String, String> properties = await _accessor!.pack(dbContent);
    return PropertyCodec.encode(properties);
  }
}
