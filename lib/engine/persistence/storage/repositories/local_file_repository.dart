import 'dart:convert';
import 'dart:io';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_file.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_repository.dart';

class LocalFileRepository implements StorageRepository {
  Future<StorageFile> _fromFile(File file) async {
    final FileStat stat = await file.stat();
    return StorageFile(
      id: file.path,
      location: file.parent.path,
      name: getBasename(extractFilenameFromPath(file.path)),
      type: StorageType.LocalFilesystem,
      byteSize: stat.size,
      lastModified: stat.modified,
    );
  }

  @override
  Future<List<StorageFile>> findAll({String? location}) {
    final Directory searchDir = location != null ? Directory(location) : Directory.current;
    return searchDir.list(recursive: false, followLinks: false).where((e) => e is File && e.path.endsWith('.x')).asyncMap((e) => _fromFile(e as File)).toList();
  }

  @override
  Future<bool> exists(StorageFile file) {
    final File possibleFile = File(file.id);
    return possibleFile.exists();
  }

  @override
  Future<bool> nameExists({required String name, String? location}) async {
    final Directory searchDir = location != null ? Directory(location) : Directory.current;
    final String filename = '$name.x';
    try {
      await searchDir.list(recursive: false, followLinks: false).firstWhere((e) => e is File && extractFilenameFromPath(e.path) == filename);
      return true;
    } on StateError {
      return false; // firstWhere() throws StateError when no match
    }
  }

  @override
  Future<StorageFile> create({required String name, String? location, String? initialData}) async {
    final String dirPath = location ?? Directory.current.path;
    final String filePath = '$dirPath${Platform.pathSeparator}$name.x';
    final File newFile = File(filePath);

    File resultFile;
    if (initialData != null) {
      if (await newFile.exists()) {
        throw FileSystemException('File already exists', newFile.path);
      }
      resultFile = await newFile.writeAsString(initialData, encoding: utf8, flush: true);
    } else {
      resultFile = await newFile.create(recursive: true, exclusive: true);
    }
    return _fromFile(resultFile);
  }

  @override
  Future<StorageFile> rename(StorageFile file, String newName) async {
    final File oldFile = File(file.id);

    final String newFilePath = '${file.location}${Platform.pathSeparator}$newName.x';
    final File renamed = await oldFile.rename(newFilePath);
    return _fromFile(renamed);
  }

  @override
  Future<String> read(StorageFile file) {
    final File sourceFile = File(file.id);
    return sourceFile.readAsString(encoding: utf8);
  }

  @override
  Future<StorageFile> update(StorageFile file, String data) async {
    final File targetFile = File(file.id);
    final File resultFile = await targetFile.writeAsString(data, encoding: utf8, flush: true);
    return _fromFile(resultFile);
  }

  @override
  Future<void> delete(StorageFile file) async {
    final File toBeDeleted = File(file.id);
    await toBeDeleted.delete();
  }
}
