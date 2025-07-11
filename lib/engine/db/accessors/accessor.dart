
import 'package:passwordmanager/engine/db/local_database.dart';

abstract class DataAccessor {
  String get version;

  Future<void> loadAndDecrypt(LocalDatabase targetDatabase, Map<String, String> properties, String password);

  Future<String> encryptAndFormat(LocalDatabase sourceDatabase, [String? password]);
}