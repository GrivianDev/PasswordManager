import 'dart:async';

import 'package:ethercrypt/engine/api/googledrive/google_drive.dart';
import 'package:ethercrypt/engine/api/googledrive/google_drive_session.dart';
import 'package:ethercrypt/engine/app_exception.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/engine/persistence/storage/repositories/google_drive_repository.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_repository.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_state.dart';
import 'package:ethercrypt/engine/persistence/storage/wrapper/app_exception_repo_wrapper.dart';
import 'package:flutter/foundation.dart';

class GoogleDriveController extends StorageController {
  final AppState _appState;
  final GoogleDrive api;
  final StorageRepository _storageRepository;
  late final StreamSubscription _sub;

  StorageState _state = const StorageState();

  GoogleDriveController({required AppState appState, required this.api})
      : _appState = appState,
        _storageRepository = AppExceptionRepoWrapper(GoogleDriveRepository(api), debugContext: 'Google Drive') {
    _sub = api.auth.sessionChanges.listen(_onAuthChanged);
  }

  // Private app data folder on google drive
  @override
  Future<String> getUserStorageLocation() => Future.value(GoogleDriveSpace.appDataFolder.value);

  @override
  StorageState get state => _state;

  @override
  StorageRepository get repository => _storageRepository;

  @override
  bool get isConfigured => api.isConfigValid;

  @override
  bool get requiresAuth => !api.auth.isLoggedIn;

  Future<void> _onAuthChanged(GoogleDriveSession? session) async {
    if (session == null) {
      _appState.googleDriveAuthRefreshToken.value = null;
      await _appState.save();

      _state = const StorageState();
      notifyListeners();
    } else {
      _appState.googleDriveAuthRefreshToken.value = session.refreshToken;
      await _appState.save();

      await load();
    }
  }

  @override
  Future<void> performLoad() async {
    _state = const StorageState(isLoading: true);
    notifyListeners();
    try {
      if (_appState.googleDriveAuthRefreshToken.value != null && !api.auth.isLoggedIn) {
        await api.auth.authorizeWithRefreshToken(
          _appState.googleDriveAuthRefreshToken.value!,
        );
      }

      final String storageLocation = await getUserStorageLocation();
      if (kDebugMode) {
        debugPrint('Looking into space "$storageLocation" for google drive files.');
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

  @override
  Future<void> dispose() async {
    await _sub.cancel();
    super.dispose();
  }
}
