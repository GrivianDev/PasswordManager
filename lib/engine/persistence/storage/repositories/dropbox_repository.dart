import 'dart:convert';

import 'package:ethercrypt/engine/api/dropbox/dropbox.dart';
import 'package:ethercrypt/engine/other/util.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_conflict_exception.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_repository.dart';
import 'package:flutter/foundation.dart';

class DropboxRepository implements StorageRepository {
  final Dropbox dropbox;

  DropboxRepository(this.dropbox);

  StorageFile _fromFile(DropboxFile dropboxFile) {
    return StorageFile(
      id: dropboxFile.id,
      location: getParentPath(dropboxFile.pathDisplay, pathSeparator: '/'),
      name: getBasename(dropboxFile.name),
      type: StorageType.Dropbox,
      revision: dropboxFile.rev,
      byteSize: dropboxFile.size,
      lastModified: dropboxFile.clientModified,
    );
  }

  @override
  Future<List<StorageFile>> findAll({String? location}) async {
    final List<DropboxFile> files = await dropbox.listFiles(path: location ?? '');
    return files.where((file) => file.name.endsWith('.x')).map(_fromFile).toList();
  }

  @override
  Future<StorageFile> create({required String name, String? location, String? initialData}) async {
    final DropboxFile newFile = await dropbox.uploadFile(
      path: '$location$name.x',
      data: utf8.encode(initialData ?? ''),
      overwrite: false,
    );
    return _fromFile(newFile);
  }

  @override
  Future<bool> exists(StorageFile file) async {
    final DropboxFile? foundFile = await dropbox.getFile(file.id);
    return foundFile != null;
  }

  @override
  Future<bool> nameExists({required String name, String? location}) async {
    final DropboxFile? foundFile = await dropbox.getFile('$location$name.x');
    return foundFile != null;
  }

  @override
  Future<StorageFile> rename(StorageFile file, String newName) async {
    final DropboxFile? foundFile = await dropbox.getFile('${file.location}${file.name}.x');
    if (foundFile?.rev != file.revision) throw const StorageConflictException();

    final DropboxFile renamed = await dropbox.moveFile(
      fromPath: '${file.location}${file.name}.x',
      toPath: '${file.location}$newName.x',
    );
    return _fromFile(renamed);
  }

  @override
  Future<String> read(StorageFile file) async {
    final Uint8List? fileContent = await dropbox.downloadFile(file.id);
    return utf8.decode(fileContent!);
  }

  @override
  Future<StorageFile> update(StorageFile file, String data) async {
    final DropboxFile updated = await dropbox.uploadFile(
      path: '${file.location}${file.name}.x',
      data: utf8.encode(data),
      overwrite: true,
    );
    return _fromFile(updated);
  }

  @override
  Future<void> delete(StorageFile file) => dropbox.deleteFile(file.id);
}
