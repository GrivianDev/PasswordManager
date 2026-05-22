import 'package:ethercrypt/engine/app_exception.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_conflict_exception.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_repository.dart';

class AppExceptionRepoWrapper implements StorageRepository {
  final StorageRepository _internal;

  const AppExceptionRepoWrapper(this._internal);

  Never _rethrow(Object error, StackTrace stackTrace, {required String message}) {
    if (error is AppException) throw error;

    if (error is StorageConflictException) {
      throw AppException(
        error.message,
        debugContext: 'Storage Repository',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    throw AppException(
      message,
      debugContext: _internal.runtimeType.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<StorageFile> create({required String name, String? location, String? initialData}) async {
    try {
      return await _internal.create(
        name: name,
        location: location,
        initialData: initialData,
      );
    } catch (e, s) {
      _rethrow(e, s, message: 'Could not create storage file with name "$name"');
    }
  }

  @override
  Future<void> delete(StorageFile file) async {
    try {
      await _internal.delete(file);
    } catch (e, s) {
      _rethrow(e, s, message: 'Could not delete storage file with name "${file.name}"');
    }
  }

  @override
  Future<bool> exists(StorageFile file) async {
    try {
      return await _internal.exists(file);
    } catch (e, s) {
      _rethrow(e, s, message: 'Could not check if storage file "${file.name}" exists');
    }
  }

  @override
  Future<List<StorageFile>> findAll({String? location}) async {
    try {
      return await _internal.findAll(location: location);
    } catch (e, s) {
      _rethrow(e, s, message: 'Could not retrieve storage files');
    }
  }

  @override
  Future<bool> nameExists({required String name, String? location}) async {
    try {
      return await _internal.nameExists(
        name: name,
        location: location,
      );
    } catch (e, s) {
      _rethrow(e, s, message: 'Could not check if storage file with name "$name" exists');
    }
  }

  @override
  Future<String> read(StorageFile file) async {
    try {
      return await _internal.read(file);
    } catch (e, s) {
      _rethrow(e, s, message: 'Could not read storage file "${file.name}"');
    }
  }

  @override
  Future<StorageFile> rename(StorageFile file, String newName) async {
    try {
      return await _internal.rename(file, newName);
    } catch (e, s) {
      _rethrow(e, s, message: 'Could not rename "${file.name}" to "$newName"');
    }
  }

  @override
  Future<StorageFile> update(StorageFile file, String data) async {
    try {
      return await _internal.update(file, data);
    } catch (e, s) {
      _rethrow(e, s, message: 'Could not update storage file "${file.name}"');
    }
  }
}
