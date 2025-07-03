import 'dart:io';

final class FileSelectionResult {
  final File file;
  final bool isNewlyCreated;

  FileSelectionResult({required this.file, required this.isNewlyCreated});
}
