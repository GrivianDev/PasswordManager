import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ethercrypt/engine/api/firebase/firebase_user.dart';
import 'package:ethercrypt/engine/api/firebase/firestore.dart';
import 'package:ethercrypt/engine/app_exception.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/engine/persistence/storage/repositories/firestore_repository.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_repository.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_state.dart';

class FirestoreController extends StorageController {
  final AppState _appState;
  final Firestore api;
  final StorageRepository _storageRepository;
  late final StreamSubscription _sub;

  StorageState _state = const StorageState();

  FirestoreController({required AppState appState, required this.api})
      : _appState = appState,
        _storageRepository = FirestoreRepository(api) {
    api.configure(appState.firebaseProjectId.value, appState.firebaseApiKey.value);
    _sub = api.auth.authChanges.listen(_onAuthChanged);
  }

  // User vault path
  @override
  Future<String> getUserStorageLocation() {
    if (!api.isConfigValid || !api.auth.isUserLoggedIn) {
      throw AppException(
        'Cloud Firestore - User is not logged in. Cannot get storage location.',
        debugContext: 'Firestore Controller',
      );
    }
    return Future.value('/ethercrypt-users/${api.auth.user!.userId}/vault');
  }

  @override
  StorageState get state => _state;

  @override
  StorageRepository get repository => _storageRepository;

  @override
  bool get isConfigured => api.isConfigValid;

  @override
  bool get requiresAuth => !api.auth.isUserLoggedIn;

  Future<void> _onAuthChanged(FirebaseUser? user) async {
    if (user == null) {
      _appState.firebaseAuthRefreshToken.value = null;
      await _appState.save();

      _state = const StorageState();
      notifyListeners();
    } else {
      _appState.firebaseAuthLastUserEmail.value = user.email;
      _appState.firebaseAuthRefreshToken.value = user.refreshToken;
      await _appState.save();

      await load();
    }
  }

  @override
  Future<void> performLoad() async {
    if (!api.isConfigValid) {
      _state = const StorageState();
      notifyListeners();
      return;
    }

    _state = const StorageState(isLoading: true);
    notifyListeners();
    try {
      if (_appState.firebaseAuthLastUserEmail.value != null && _appState.firebaseAuthRefreshToken.value != null && !api.auth.isUserLoggedIn) {
        await api.auth.loginWithRefreshToken(
          _appState.firebaseAuthLastUserEmail.value!,
          _appState.firebaseAuthRefreshToken.value!,
        );
      }

      final String storageLocation = await getUserStorageLocation();
      if (kDebugMode) {
        debugPrint('Looking into collection "$storageLocation" for cloud firestore documents.');
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
