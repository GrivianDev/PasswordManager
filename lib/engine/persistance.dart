import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static late final SharedPreferences _instance;

  static const _keyLightMode = 'mode';
  static const _keyLastOpenedPath = 'path';
  static const _keyAutoSaving = 'saving';

  static Future<void> init() async => _instance = await SharedPreferences.getInstance();

  static Future<void> setLightMode(bool enabled) async => await _instance.setBool(_keyLightMode, enabled);

  static bool isLightMode() => _instance.getBool(_keyLightMode) ?? true;

  static Future<void> setLastOpenedPath(String path) async => await _instance.setString(_keyLastOpenedPath, path);

  static String getLastOpenedPath() => _instance.getString(_keyLastOpenedPath) ?? '';

  static Future<void> setAutoSaving(bool enabled) async => await _instance.setBool(_keyAutoSaving, enabled);

  static bool isAutoSaving() => _instance.getBool(_keyAutoSaving) ?? false;
}
