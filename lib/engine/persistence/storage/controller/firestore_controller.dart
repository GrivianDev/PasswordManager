import 'dart:async';
import 'dart:convert';

import 'package:ethercrypt/engine/api/firebase/firebase_session.dart';
import 'package:ethercrypt/engine/api/firebase/firestore.dart';
import 'package:ethercrypt/engine/app_exception.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/engine/persistence/storage/repositories/firestore_repository.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_repository.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_state.dart';
import 'package:ethercrypt/engine/persistence/storage/wrapper/app_exception_repo_wrapper.dart';
import 'package:flutter/foundation.dart';

class FirestoreController extends StorageController {
  final AppState _appState;
  final Firestore api;
  final StorageRepository _storageRepository;
  late final StreamSubscription _sub;

  StorageState _state = const StorageState();

  FirestoreController({required AppState appState, required this.api})
      : _appState = appState,
        _storageRepository = AppExceptionRepoWrapper(FirestoreRepository(api), debugContext: 'Firestore') {
    api.configure(appState.firebaseProjectId.value, appState.firebaseApiKey.value);
    try {
      api.auth.setInitialSession(FirebaseSession.fromJson(json.decode(appState.firebaseAuthCredentials.value!)));
    } catch (_) {}
    _sub = api.auth.authChanges.listen(_onAuthChanged);
  }

  // User vault path
  @override
  Future<String> getUserStorageLocation() {
    if (!api.isConfigValid || !api.auth.isLoggedIn) {
      throw AppException(
        'User is not logged in. Cannot get storage location.',
        debugContext: 'Firestore Controller',
      );
    }
    return Future.value('/ethercrypt-users/${api.auth.session!.userId}/vault');
  }

  @override
  StorageState get state => _state;

  @override
  StorageRepository get repository => _storageRepository;

  @override
  bool get isEnabled => _appState.firebaseEnabled.value;

  @override
  bool get isConfigured => api.isConfigValid;

  @override
  bool get requiresAuth => !api.auth.isLoggedIn;

  Future<void> _onAuthChanged(FirebaseSession? session) async {
    if (session == null) {
      _appState.firebaseAuthCredentials.value = null;
      await _appState.save();

      _state = const StorageState();
      notifyListeners();
    } else {
      _appState.firebaseAuthCredentials.value = json.encode(session.toJson());
      await _appState.save();

      await load();
    }
  }

  @override
  Future<void> performLoad() async {
    if (!api.isConfigValid || !isEnabled) {
      _state = const StorageState();
      notifyListeners();
      return;
    }

    _state = const StorageState(isLoading: true);
    notifyListeners();
    try {
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
