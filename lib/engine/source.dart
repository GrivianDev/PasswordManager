import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' as foundation;
import 'package:passwordmanager/engine/cloud_connector.dart';
import 'package:passwordmanager/engine/cryptography/implementation/aes_encryption.dart';
import 'package:passwordmanager/engine/cryptography/implementation/legacy_aes_decrypter.dart';
import 'package:passwordmanager/engine/cryptography/service.dart';
import 'package:passwordmanager/engine/data_interpreter.dart';
import 'package:passwordmanager/engine/cryptography/datatypes.dart';

/// Source object that models a dynamic source for the [LocalDatabase]. Supports
/// synchronisation between local files or firebase cloud via the [FirebaseConnector] class.
/// The exact source can be set in the constructor. Uses the [DataFormatInterpreter] to extract data from a file or cloud storage.
final class Source {
  final File? _sourceFile;
  final FirebaseConnector? _connector;
  Key? _key;

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

  bool get isValid => _sourceFile != null ? _sourceFile!.existsSync() : _connector!.isLoggedIn;

  void invalidate() => _connector != null ? _connector!.invalidate() : {};

  bool get hasUnsavedChanges => _unsavedChanges;

  void claimHasUnsavedChanges() => _unsavedChanges = true;

  /// Asynchronous method to load data from given file or firebase cloud.
  Future<String> loadData({required String password, bool legacyMode = false}) async {
    final String formattedData = _connector != null ? await _connector!.getData() : await _sourceFile!.readAsString(encoding: utf8);
    final InterpretionResult result = await foundation.compute((message) {
      final DataFormatInterpreter dataFormatInterpreter = DataFormatInterpreter(legacyMode ? LegacyAES256Decrypter() : AES256());
      if(message[2] as bool) {
        return dataFormatInterpreter.legacyInterpretDataWithPassword(message[0] as String, message[1] as String);
      } else {
        return dataFormatInterpreter.interpretDataWithPassword(message[0] as String, message[1] as String);
      }
    }, [formattedData, password, legacyMode]);
    _key = result.key;
    return result.data;
  }

  /// Write a random encrypted value to that source. That way an initial verification code is set.
  /// If creating a cloud storage then the [cloudDocName] parameter must be set.
  Future<void> initialiseNewSource({required String password, String? cloudDocName}) async {
    final InterpretionResult result = await foundation.compute((message) {
      final Key key = CryptographicService.createAES256Key(password: message[0]);
      final DataFormatInterpreter dataFormatInterpreter = DataFormatInterpreter(AES256());
      return dataFormatInterpreter.createFormattedDataWithKey('', key);
    }, [password]);
    _key = result.key;

    if(_connector != null) {
      if(cloudDocName == null) throw Exception('"cloudDocName" parameter must be not null when initialising a cloud storage');
      await _connector!.createDocument(name: cloudDocName, data: result.data);
    }
    if(_sourceFile != null) {
      if (_sourceFile!.existsSync()) await _sourceFile?.create(recursive: true);
      await _sourceFile!.writeAsString(result.data, encoding: utf8);
    }
  }

  /// Asynchronous method to save changes to a local file or the firebase cloud.
  Future<void> saveData(String plainData) async {
    if (_connector != null) {
      await _connector!.editDocument(newData: await getFormattedData(plainData));
    }
    if (_sourceFile != null) {
      if (_sourceFile!.existsSync()) await _sourceFile?.create(recursive: true);
      await _sourceFile!.writeAsString(await getFormattedData(plainData), encoding: utf8);
    }
    _unsavedChanges = false;
  }

  /// Creates a formatted data string that can be persisted.
  Future<String> getFormattedData(String data) async {
    final InterpretionResult result = await foundation.compute((message) {
      final DataFormatInterpreter dataFormatInterpreter = DataFormatInterpreter(AES256());
      return dataFormatInterpreter.createFormattedDataWithKey(message[0] as String, message[1] as Key);
    }, [data, _key]);
    return result.data;
  }
}
