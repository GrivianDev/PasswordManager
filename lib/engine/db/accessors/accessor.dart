
import 'package:passwordmanager/engine/db/local_database.dart';

abstract class DataAccessor {
  String get version;

  void definePassword(String password);

  Future<void> loadAndDecrypt(LocalDatabase targetDatabase, Map<String, String> properties);

  Future<String> encryptAndFormat(LocalDatabase sourceDatabase, {bool initWithoutLoad = false});
}