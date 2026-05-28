import 'package:ethercrypt/engine/other/rerun_task.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_repository.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_state.dart';
import 'package:flutter/foundation.dart';

abstract class StorageController with ChangeNotifier {
  final RerunTask _loadTask = RerunTask();

  StorageState get state;

  StorageRepository get repository;

  bool get isConfigured;

  bool get requiresAuth;

  Future<String> getUserStorageLocation();

  Future<void> load() => _loadTask.run(performLoad);

  Future<void> performLoad();

  void applyFileUpdate(StorageFile updatedFile) {
    final index = state.files.indexWhere((f) => f.id == updatedFile.id);

    if (index == -1) {
      state.files.add(updatedFile);
    } else {
      state.files[index] = updatedFile;
    }

    notifyListeners();
  }
}
