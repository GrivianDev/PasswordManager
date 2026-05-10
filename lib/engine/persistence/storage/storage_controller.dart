import 'package:flutter/foundation.dart';
import 'package:passwordmanager/engine/other/rerun_task.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_repository.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_state.dart';

abstract class StorageController with ChangeNotifier {
  final RerunTask _loadTask = RerunTask();

  StorageState get state;
  
  StorageRepository get repository;

  bool get isConfigured;

  bool get requiresAuth;
  
  Future<String> getUserStorageLocation();

  Future<void> load() => _loadTask.run(performLoad);

  Future<void> performLoad();
}