import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';

abstract class StorageRepository {
  Future<List<StorageFile>> findAll({String? location});
  Future<bool> exists(StorageFile file);
  Future<bool> nameExists({required String name, String? location});

  Future<StorageFile> create({required String name, String? location, String? initialData});
  Future<StorageFile> rename(StorageFile file, String newName);
  Future<String> read(StorageFile file);
  Future<StorageFile> update(StorageFile file, String data);
  Future<void> delete(StorageFile file);
}
