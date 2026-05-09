import 'package:flutter/foundation.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_repository.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_state.dart';

abstract class StorageController with ChangeNotifier {
  StorageState get state;
  
  StorageRepository get repository;

  bool get isConfigured;

  bool get requiresAuth;
  
  Future<String> getUserStorageLocation();

  Future<void> load();
}