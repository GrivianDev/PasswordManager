import 'package:flutter/material.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';

class StorageProvider with ChangeNotifier {
  final Map<StorageType, StorageController> _controllers;
  final List<StorageFile> _allFiles = [];

  StorageProvider({required Map<StorageType, StorageController> controllers}) : _controllers = controllers {
    for (StorageController controller in _controllers.values) {
      controller.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    _allFiles.clear();
    _allFiles.addAll(_controllers.values.expand((c) => c.state.files).toList());
    _allFiles.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  bool isAvailable(StorageType type) => _controllers[type] != null;

  StorageController controller(StorageType type) => _controllers[type]!;

  List<StorageFile> get allFiles => List.unmodifiable(_allFiles);

  bool get isLoadingAny => _controllers.values.any((s) => s.state.isLoading);

  List<Object> get errors => _controllers.values.map((s) => s.state.error).whereType<Object>().toList();

  Future<void> load(StorageType type) async {
    await _controllers[type]?.load();
  }

  Future<void> loadAll() async {
    await Future.wait(_controllers.keys.map(load));
  }

  @override
  void dispose() {
    for (StorageController controller in _controllers.values) {
      controller.removeListener(_onControllerChanged);
    }
    super.dispose();
  }
}
