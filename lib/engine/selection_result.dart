import 'dart:io';

final class FileSelectionResult {
  final File file;
  final bool isNewlyCreated;

  FileSelectionResult({required this.file, required this.isNewlyCreated});
}

final class FirestoreSelectionResult {
  final String documentId;
  final String documentName;
  final bool isNewlyCreated;

  FirestoreSelectionResult(this.documentId, this.documentName, this.isNewlyCreated);
}
