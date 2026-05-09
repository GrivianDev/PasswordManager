enum StorageType {
  LocalFilesystem,
  Dropbox,
  OneDrive,
  GoogleDrive,
  CloudFirestore,
}

final class StorageFile {
  final String id;
  final String location;
  final String name;
  final StorageType type;
  final int? byteSize;
  final DateTime? lastModified;

  StorageFile({
    required this.id,
    required this.location,
    required this.name,
    required this.type,
    this.byteSize,
    this.lastModified,
  });
}
