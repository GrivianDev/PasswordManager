import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ethercrypt/engine/app_exception.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/engine/persistence/storage/repositories/local_file_repository.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_repository.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_state.dart';

class LocalFileController extends StorageController {
  final AppState _appState;
  final StorageRepository _storageRepository;

  StorageState _state = const StorageState();

  LocalFileController({required AppState appState})
      : _appState = appState,
        _storageRepository = LocalFileRepository();

  @override
  Future<String> getUserStorageLocation() async {
    try {
      if (Platform.isLinux || Platform.isWindows) {
        // On desktop environments: use possible custom storage location
        if (!_appState.localSystemStorageLocation.isDefault) {
          return Future.value(_appState.localSystemStorageLocation.value);
        }
      }
      final Directory dir = await getApplicationSupportDirectory();
      return dir.path;
    } catch (e, s) {
      throw AppException(
        'Failed to determine local file storage location',
        debugContext: 'Local Filesystem Controller',
        cause: e,
        stackTrace: s,
      );
    }
  }

  @override
  StorageState get state => _state;

  @override
  StorageRepository get repository => _storageRepository;

  @override
  bool get isConfigured => true;

  @override
  bool get requiresAuth => false;

  @override
  Future<void> performLoad() async {
    _state = const StorageState(isLoading: true);
    notifyListeners();
    try {
      final String storageLocation = await getUserStorageLocation();
      if (kDebugMode) {
        debugPrint('Looking into "$storageLocation" for local files.');
      }
      final List<StorageFile> files = await _storageRepository.findAll(location: storageLocation);
      _state = StorageState(
        isLoading: false,
        files: files,
      );
    } catch (e, s) {
      _state = StorageState(error: e is AppException ? e : AppException.unknown(cause: e, stackTrace: s));
    }
    notifyListeners();
  }
}
