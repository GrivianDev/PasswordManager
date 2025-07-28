import 'dart:convert';
import 'dart:io';
import 'package:passwordmanager/engine/persistence/connector/persistence_connector.dart';

class FileConnector implements PersistenceConnector {
  final File file;

  FileConnector({required this.file});

  @override
  String get name => file.path.split(Platform.pathSeparator).last;

  @override
  Future<bool> get isAvailable => file.exists();

  @override
  Future<String> load() => file.readAsString(encoding: utf8);

  @override
  Future<void> create(String formattedData) async {
    if (!(await file.exists())) {
      await file.create(recursive: true);
    }
    await file.writeAsString(formattedData, encoding: utf8);
  }

  @override
  Future<void> delete() => file.delete();

  @override
  Future<void> save(String formattedData) => file.writeAsString(formattedData, encoding: utf8);
}
