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

  final String revision;

  final int? byteSize;
  final DateTime? lastModified;

  StorageFile({
    required this.id,
    required this.location,
    required this.name,
    required this.type,
    required this.revision,
    this.byteSize,
    this.lastModified,
  });
}
