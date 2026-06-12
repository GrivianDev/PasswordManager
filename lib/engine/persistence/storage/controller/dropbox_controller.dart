import 'dart:async';

import 'package:ethercrypt/engine/api/dropbox/dropbox.dart';
import 'package:ethercrypt/engine/api/dropbox/dropbox_session.dart';
import 'package:ethercrypt/engine/app_exception.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/engine/persistence/storage/repositories/dropbox_repository.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_repository.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_state.dart';
import 'package:ethercrypt/engine/persistence/storage/wrapper/app_exception_repo_wrapper.dart';
import 'package:flutter/foundation.dart';

class DropboxController extends StorageController {
  final AppState _appState;
  final Dropbox api;
  final StorageRepository _storageRepository;
  late final StreamSubscription _sub;

  StorageState _state = const StorageState();

  DropboxController({required AppState appState, required this.api})
      : _appState = appState,
        _storageRepository = AppExceptionRepoWrapper(DropboxRepository(api), debugContext: 'Dropbox') {
    _sub = api.auth.sessionChanges.listen(_onAuthChanged);
  }

  @override
  Future<String> getUserStorageLocation() => Future.value('/');

  @override
  StorageState get state => _state;

  @override
  StorageRepository get repository => _storageRepository;

  @override
  bool get isConfigured => api.isConfigValid;

  @override
  bool get requiresAuth => !api.auth.isLoggedIn;

  Future<void> _onAuthChanged(DropboxSession? session) async {
    if (session == null) {
      _appState.dropboxAuthRefreshToken.value = null;
      await _appState.save();

      _state = const StorageState();
      notifyListeners();
    } else {
      _appState.dropboxAuthRefreshToken.value = session.refreshToken;
      await _appState.save();

      await load();
    }
  }

  @override
  Future<void> performLoad() async {
    _state = const StorageState(isLoading: true);
    notifyListeners();
    try {
      if (_appState.dropboxAuthRefreshToken.value != null && !api.auth.isLoggedIn) {
        await api.auth.authorizeWithRefreshToken(
          _appState.dropboxAuthRefreshToken.value!,
        );
      }

      final String storageLocation = await getUserStorageLocation();
      if (kDebugMode) {
        debugPrint('Looking into "$storageLocation" for dropbox files.');
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
