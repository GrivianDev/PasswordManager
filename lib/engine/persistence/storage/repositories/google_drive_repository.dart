import 'dart:convert';
import 'dart:typed_data';

import 'package:ethercrypt/engine/api/googledrive/google_drive.dart';
import 'package:ethercrypt/engine/app_exception.dart';
import 'package:ethercrypt/engine/other/util.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_conflict_exception.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_repository.dart';

class GoogleDriveRepository implements StorageRepository {
  final GoogleDrive drive;

  GoogleDriveRepository(this.drive);

  StorageFile _fromDriveFile(GoogleDriveFile file, String location) {
    return StorageFile(
      id: file.id,
      location: location,
      name: getBasename(file.name),
      type: StorageType.GoogleDrive,
      revision: file.appProperties?['revision'] ?? '0',
      byteSize: file.size,
      lastModified: file.modifiedTime,
    );
  }

  Future<GoogleDriveFile> _getLatest(String id) async {
    final GoogleDriveFile? file = await drive.getFile(id);

    if (file == null) {
      throw AppException(
        'File no longer exists.',
        debugContext: 'Google Drive Repository',
      );
    }

    return file;
  }

  GoogleDriveSpace _toSpace(String? location) => GoogleDriveSpace.values.firstWhere((s) => s.value == location);

  @override
  Future<List<StorageFile>> findAll({String? location}) async {
    final GoogleDriveSpace space = _toSpace(location);
    final List<GoogleDriveFile> files = await drive.listFiles(
      query: "name contains '.x' and trashed = false",
      space: space,
    );
    return files.where((f) => f.name.endsWith('.x')).map((doc) => _fromDriveFile(doc, space.value)).toList();
  }

  @override
  Future<StorageFile> create({required String name, String? location, String? initialData}) async {
    final GoogleDriveSpace space = _toSpace(location);

    final GoogleDriveFile file = await drive.createFile(
      name: '$name.x',
      mimeType: 'text/plain',
      parentSpace: space,
      appProperties: {'revision': '0'},
      data: initialData != null ? utf8.encode(initialData) : null,
    );

    return _fromDriveFile(file, space.value);
  }

  @override
  Future<bool> exists(StorageFile file) async {
    return await drive.getFile(file.id) != null;
  }

  @override
  Future<bool> nameExists({required String name, String? location}) async {
    final GoogleDriveSpace space = _toSpace(location);

    final String escapedName = name.replaceAll("'", r"\'");
    final List<GoogleDriveFile> files = await drive.listFiles(
      space: space,
      query: "name = '$escapedName.x' and trashed = false",
      pageSize: 1,
    );

    return files.isNotEmpty;
  }

  @override
  Future<StorageFile> rename(StorageFile file, String newName) async {
    // Best effort conflict detection
    final GoogleDriveFile latest = await _getLatest(file.id);
    if (latest.appProperties?['revision'] != file.revision) throw const StorageConflictException();

    final GoogleDriveFile updated = await drive.updateFile(
      file.id,
      name: '$newName.x',
      mimeType: 'text/plain',
      appProperties: {'revision': _incrementIntString(file.revision)},
    );
    return _fromDriveFile(updated, file.location);
  }

  @override
  Future<String> read(StorageFile file) async {
    final Uint8List? bytes = await drive.readFile(file.id);

    if (bytes == null) {
      throw AppException(
        'File does not exist.',
        debugContext: 'Google Drive Repository',
      );
    }

    return utf8.decode(bytes);
  }

  @override
  Future<StorageFile> update(StorageFile file, String data) async {
    // Best effort conflict detection
    final GoogleDriveFile latest = await _getLatest(file.id);
    if (latest.appProperties?['revision'] != file.revision) throw const StorageConflictException();

    final GoogleDriveFile updated = await drive.updateFile(
      file.id,
      data: utf8.encode(data),
      appProperties: {'revision': _incrementIntString(file.revision)},
    );

    return _fromDriveFile(updated, file.location);
  }

  @override
  Future<void> delete(StorageFile file) => drive.deleteFile(file.id);

  String _incrementIntString(String? value, {int fallback = 0}) {
    final int? parsed = int.tryParse(value ?? '');
    return ((parsed ?? fallback) + 1).toString();
  }
}
