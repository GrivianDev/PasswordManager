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
  final GoogleDriveSpace space;

  /// Google Drive API is strictly id-based.
  /// Meaning folder paths need to be manually resolved.
  /// Cache avoids repeated path resolving API requests.
  final Map<String, String> _folderCache = {};

  GoogleDriveRepository({required this.drive, required this.space});

  StorageFile _fromDriveFile(GoogleDriveFile file, String? location) {
    return StorageFile(
      id: file.id,
      location: location ?? '/',
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

  @override
  Future<List<StorageFile>> findAll({String? location}) async {
    final List<GoogleDriveFile> files = await drive.listFiles(
      query: "name contains '.x' and trashed = false",
      space: space,
    );
    return files.where((f) => f.name.endsWith('.x')).map((doc) => _fromDriveFile(doc, location)).toList();
  }

  @override
  Future<StorageFile> create({required String name, String? location, String? initialData}) async {
    final String? parentId = location == null ? null : await _ensureFolder(location);

    final GoogleDriveFile file = await drive.createFile(
      name: '$name.x',
      mimeType: 'text/plain',
      parentId: parentId,
      space: space,
      appProperties: {'revision': '0'},
      data: initialData != null ? utf8.encode(initialData) : null,
    );

    return _fromDriveFile(file, location);
  }

  @override
  Future<bool> exists(StorageFile file) async {
    return await drive.getFile(file.id) != null;
  }

  @override
  Future<bool> nameExists({required String name, String? location}) async {
    final String escapedName = name.replaceAll("'", r"\'");
    final String? parentId = location == null ? null : await _resolveFolder(location);

    if (location != null && parentId == null) {
      return false;
    }

    final String query = [
      "name = '$escapedName.x'",
      'trashed = false',
      if (parentId != null) "'$parentId' in parents",
    ].join(' and ');

    final List<GoogleDriveFile> files = await drive.listFiles(
      space: space,
      query: query,
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

  Future<GoogleDriveFile?> _findChildFolder(
    String parentId,
    String name,
  ) async {
    final String escaped = name.replaceAll("'", r"\'");

    final List<GoogleDriveFile> result = await drive.listFiles(
      space: space,
      pageSize: 1,
      query: """
        mimeType = 'application/vnd.google-apps.folder'
        and name = '$escaped'
        and '$parentId' in parents
        and trashed = false
        """,
    );

    return result.isEmpty ? null : result.first;
  }

  String _normalizePath(String? path) {
    if (path == null || path.trim().isEmpty) {
      return '/';
    }

    final List<String> segments = [];
    for (final String part in path.split('/')) {
      if (part.isEmpty || part == '.') {
        continue;
      }

      if (part == '..') {
        if (segments.isNotEmpty) {
          segments.removeLast();
        }
        continue;
      }

      segments.add(part);
    }

    return '/${segments.join('/')}';
  }

  Future<String?> _resolveFolder(String path) async {
    path = _normalizePath(path);

    if (path == '/' || path.isEmpty) {
      return null; // root
    }

    final String? cached = _folderCache[path];
    if (cached != null) {
      return cached;
    }

    String? currentParent;
    String currentPath = '';

    final List<String> segments = path.split('/').where((e) => e.isNotEmpty).toList();
    for (final String segment in segments) {
      currentPath += '/$segment';

      final String? cached = _folderCache[currentPath];
      if (cached != null) {
        currentParent = cached;
        continue;
      }

      final GoogleDriveFile? folder = await _findChildFolder(currentParent ?? 'root', segment);
      if (folder == null) {
        return null;
      }

      currentParent = folder.id;
      _folderCache[currentPath] = folder.id;
    }

    return currentParent;
  }

  Future<String?> _ensureFolder(String path) async {
    path = _normalizePath(path);
    if (path == '/' || path.isEmpty) {
      return null;
    }

    String? currentParent;
    String currentPath = '';

    final List<String> segments = path.split('/').where((e) => e.isNotEmpty).toList();
    for (final String segment in segments) {
      currentPath += '/$segment';

      final String? cached = _folderCache[currentPath];
      if (cached != null) {
        currentParent = cached;
        continue;
      }

      GoogleDriveFile? folder = await _findChildFolder(currentParent ?? 'root', segment);

      folder ??= await drive.createFile(
        name: segment,
        space: space,
        mimeType: 'application/vnd.google-apps.folder',
        parentId: currentParent,
      );

      currentParent = folder.id;
      _folderCache[currentPath] = folder.id;
    }

    return currentParent;
  }
}
