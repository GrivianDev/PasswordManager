import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:flutter/material.dart';

extension StorageTypeUI on StorageType {
  String get label {
    switch (this) {
      case StorageType.LocalFilesystem:
        return 'Local File System';
      case StorageType.CloudFirestore:
        return 'Cloud Firestore';
      case StorageType.OneDrive:
        return 'OneDrive';
      case StorageType.GoogleDrive:
        return 'Google Drive';
      case StorageType.Dropbox:
        return 'Dropbox';
    }
  }

  IconData get icon {
    switch (this) {
      case StorageType.LocalFilesystem:
        return Icons.storage;
      case StorageType.CloudFirestore:
        return Icons.whatshot;
      case StorageType.OneDrive:
        return Icons.cloud;
      case StorageType.GoogleDrive:
        return Icons.add_to_drive;
      case StorageType.Dropbox:
        return Icons.question_mark;
    }
  }
}
