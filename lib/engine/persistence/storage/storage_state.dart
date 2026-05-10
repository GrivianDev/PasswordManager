import 'package:passwordmanager/engine/persistence/storage/storage_file.dart';

class StorageState {
  final bool isLoading;
  final Object? error;
  final List<StorageFile> files;

  const StorageState({
    this.isLoading = false,
    this.error,
    this.files = const [],
  });
}