import 'dart:io';
import 'dart:convert';
import 'package:passwordmanager/engine/accessors/accessor.dart';
import 'package:passwordmanager/engine/accessors/accessor_registry.dart';
import 'package:passwordmanager/engine/cloud_connector.dart';
import 'package:passwordmanager/engine/local_database.dart';

/// Source object that models a dynamic source for the [LocalDatabase]. Supports
/// synchronisation between local files or firebase cloud via the [FirebaseConnector] class.
/// The exact source can be set in the constructor. Uses the [DataFormatInterpreter] to extract data from a file or cloud storage.
final class Source {
  final File? _sourceFile;
  final FirebaseConnector? _connector;
  late final LocalDatabase dbRef;
  DataAccessor? _accessor;

  bool _unsavedChanges = false;

  /// Default constructor that requires exactly one valid source. Exceptions are thrown otherwise.
  Source({File? sourceFile, FirebaseConnector? connector})
      : _sourceFile = sourceFile,
        _connector = connector
       {
    if (_sourceFile == null && _connector == null) throw Exception('Source object needs at least one valid source');
    if (_sourceFile != null && _connector != null) throw Exception('Source object does not allow two valid sources');
  }

  String? get name => _sourceFile != null ? _sourceFile!.path.split(Platform.pathSeparator).last : _connector!.name ?? 'none';

  String? get accessorVersion => _accessor?.version;

  bool get usesLocalFile => _sourceFile != null;

  bool get usesFirestoreCloud => _connector != null;

  bool get isValid => _sourceFile != null ? _sourceFile!.existsSync() : _connector!.isLoggedIn;

  void invalidate() => _connector != null ? _connector!.invalidate() : {};

  bool get hasUnsavedChanges => _unsavedChanges;

  void claimHasUnsavedChanges() => _unsavedChanges = true;

  /// Asynchronous method to load data from given file or firebase cloud.
  Future<void> loadData({required String password}) async {
    final String formattedData = usesFirestoreCloud ? await _connector!.getData() : await _sourceFile!.readAsString(encoding: utf8);
    final Map<String, String> properties = Source.readProperties(formattedData);
    final String vaultVersion = properties['version'] ?? 'v0';
    _accessor = DataAccessorRegistry.create(vaultVersion); // Choose correct accessor

    await _accessor!.loadAndDecrypt(dbRef, properties, password);
  }

  /// Write a random encrypted value to that source. That way an initial verification code is set.
  /// If creating a cloud storage then the [cloudDocName] parameter must be set.
  Future<void> initialiseNewSource({required String password, String? cloudDocName}) async {
    _accessor = DataAccessorRegistry.create(DataAccessorRegistry.latestVersion); // Auto create new ones with newest version
    final String formattedData = await _accessor!.encryptAndFormat(dbRef, password);

    if(usesFirestoreCloud) {
      if(cloudDocName == null) throw Exception('"cloudDocName" parameter must be not null when initialising a cloud storage');
      await _connector!.createDocument(name: cloudDocName, data: formattedData);
    }
    if(usesLocalFile) {
      if (_sourceFile!.existsSync()) await _sourceFile?.create(recursive: true);
      await _sourceFile!.writeAsString(formattedData, encoding: utf8);
    }
  }

  /// Asynchronous method to save changes to a local file or the firebase cloud.
  Future<void> saveData() async {
    final String formattedData = await getFormattedData();

    if (usesFirestoreCloud) {
      await _connector!.editDocument(newData: formattedData);
    }
    if (usesLocalFile) {
      if (_sourceFile!.existsSync()) await _sourceFile?.create(recursive: true);
      await _sourceFile!.writeAsString(formattedData, encoding: utf8);
    }
    _unsavedChanges = false;
  }

  Future<String> getFormattedData() async {
    return await _accessor!.encryptAndFormat(dbRef);
  }

  static Map<String, String> readProperties(String content) {
    Map<String, String> properties = {};

    int start = 0;
    int end = content.indexOf(';', start);
    while (end != -1) {
      final int equalSignIndex = content.indexOf('=', start);
      final String key = content.substring(start, equalSignIndex);
      final String value = content.substring(equalSignIndex + 1, end);
      if (key.isEmpty || value.isEmpty) {
        throw Exception('Error parsing parameters');
      }
      properties[key] = value;

      start = end + 1;
      end = content.indexOf(';', start);
    }

    return properties;
  }
}
