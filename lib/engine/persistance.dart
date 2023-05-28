import 'dart:core';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ChangeNotifier {
  static late final SharedPreferences _instance;

  static const _keyLightMode = 'mode';
  static const _keyLastOpenedPath = 'path';
  static const _keyAutoSaving = 'saving';

  static Future<void> init() async => _instance = await SharedPreferences.getInstance();

  Future<void> setLightMode(bool enabled) async {
    await _instance.setBool(_keyLightMode, enabled);
    notifyListeners();
  }

  bool get isLightMode => _instance.getBool(_keyLightMode) ?? true;

  Future<void> setLastOpenedPath(String path) async {
    await _instance.setString(_keyLastOpenedPath, path);
    notifyListeners();
  }

  String get lastOpenedPath => _instance.getString(_keyLastOpenedPath) ?? '';

  Future<void> setAutoSaving(bool enabled) async {
    await _instance.setBool(_keyAutoSaving, enabled);
    notifyListeners();
  }

  bool get isAutoSaving => _instance.getBool(_keyAutoSaving) ?? false;
}
