import 'dart:convert';
import 'dart:io';
import 'package:passwordmanager/engine/cloud_connector.dart';

/// Source object that models a dynamic source for the [LocalDatabase]. Supports
/// synchronisation between local files or firebase cloud via the [FirebaseConnector] class.
/// The exact source can be set in the constructor.
final class Source {
  final File? _sourceFile;
  final FirebaseConnector? _connector;

  /// Default constructor that requires exactly one valid source. Exceptions are thrown otherwise.
  Source({File? sourceFile, FirebaseConnector? connector}) : _sourceFile = sourceFile, _connector = connector {
    if(_sourceFile == null && _connector == null) throw Exception('Source object needs at least one valid source');
    if(_sourceFile != null && _connector != null) throw Exception('Source object does not allow two valid sources');
  }

  bool get isValid => _sourceFile != null ? _sourceFile!.existsSync() : _connector!.isLoggedIn;

  void invalidate() => _connector != null ? _connector!.invalidate() : {};

  /// Asynchronous method to load data from given file or firebase cloud.
  Future<String> load() async {
    if(_connector != null) return await _connector!.getData();
    if(_sourceFile != null) return await _sourceFile!.readAsString(encoding: utf8);
    return '';
  }

  /// Asynchronous method to save changes to a local file or the firebase cloud.
  Future<void> saveChanges(String cipherText) async {
    if(_connector != null) await _connector!.editDocument(newData: cipherText);
    if(_sourceFile != null) {
      if(_sourceFile!.existsSync()) await _sourceFile?.create(recursive: true);
      _sourceFile!.writeAsString(cipherText, encoding: utf8);
    }
  }
}