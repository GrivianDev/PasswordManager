import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_file.dart';

extension StorageTypeUI on StorageType {
  String get label {
    switch (this) {
      case StorageType.LocalFilesystem:
        return 'Local File System';
      case StorageType.CloudFirestore:
        return 'Cloud Firestore';
      case StorageType.OneDrive:
        return 'One Drive';
      case StorageType.GoogleDrive:
        return 'Cloud Firestore';
      case StorageType.Dropbox:
        return 'One Drive';
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
