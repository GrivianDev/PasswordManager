import 'dart:convert';
import 'dart:typed_data';

import 'package:ethercrypt/engine/api/onedrive/onedrive.dart';
import 'package:ethercrypt/engine/other/util.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_repository.dart';

class OneDriveRepository implements StorageRepository {
  final OneDrive onedrive;
  final OneDriveLocation driveLocation;

  OneDriveRepository(this.onedrive, this.driveLocation);

  StorageFile _fromFile(OneDriveItem onedriveFile) {
    return StorageFile(
      id: onedriveFile.id,
      location: onedriveFile.location,
      name: getBasename(onedriveFile.name),
      type: StorageType.OneDrive,
      revision: onedriveFile.eTag,
      byteSize: onedriveFile.size,
      lastModified: onedriveFile.modifiedTime,
    );
  }

  @override
  Future<List<StorageFile>> findAll({String? location}) async {
    try {
      final List<OneDriveItem> items = await onedrive.listItems(location ?? '', location: driveLocation);
      return items.where((i) => i.type == OneDriveItemType.file).map(_fromFile).toList();
    } on OneDriveApiException catch (e) {
      if (e.message == 'itemNotFound') return [];
      rethrow;
    }
  }

  @override
  Future<StorageFile> create({required String name, String? location, String? initialData}) async {
    final OneDriveItem newFile = await onedrive.createFile(
      '${location ?? ''}/$name.x',
      data: utf8.encode(initialData ?? ''),
      location: driveLocation,
    );
    return _fromFile(newFile);
  }

  @override
  Future<bool> exists(StorageFile file) async {
    final OneDriveItem? found = await onedrive.getItem(file.id);
    return found != null;
  }

  @override
  Future<bool> nameExists({required String name, String? location}) async {
    final OneDriveItem? found= await onedrive.getItemByPath(
      path: '${location ?? ''}/$name.x',
      location: driveLocation,
    );
    return found != null;
  }

  @override
  Future<StorageFile> rename(StorageFile file, String newName) async {
    final OneDriveItem renamed = await onedrive.updateItem(
      file.id,
      name: '$newName.x',
      expectedETag: file.revision,
    );
    return _fromFile(renamed);
  }

  @override
  Future<String> read(StorageFile file) async {
    final Uint8List? content = await onedrive.readFile(file.id);
    return utf8.decode(content ?? []);
  }

  @override
  Future<StorageFile> update(StorageFile file, String data) async {
    final OneDriveItem updated = await onedrive.uploadFileContent(
      file.id,
      data: utf8.encode(data),
      expectedETag: file.revision,
    );
    return _fromFile(updated);
  }

  @override
  Future<void> delete(StorageFile file) => onedrive.deleteFile(file.id);
}
