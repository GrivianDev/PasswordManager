final class StorageConflictException implements Exception {
  final String message;

  const StorageConflictException([this.message = 'Conflict: the storage file was modified by another source.']);

  @override
  String toString() => 'StorageConflictException: $message';
}
