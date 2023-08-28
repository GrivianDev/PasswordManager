import 'dart:core';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Class providing data like the current theme, the last opened path and if autosaving is activated.
/// This class must be initialised through the [init] call before use.
/// Extends ChangeNotifier and here calling any setter notifies all listeners.
/// Stores the data through SharedPreferences.
/// Implemented that at least one of the propertys use letters/numbers/special chars has to be set to true at al times.
class Settings extends ChangeNotifier {
  static late final SharedPreferences _instance;

  static final isWindows = Platform.isWindows;
  static const _keyLightMode = 'mode';
  static const _keyLastOpenedPath = 'path';
  static const _keyAutoSaving = 'saving';
  static const _keyOnlineMode = 'online';
  static const _keyLastOpenedCloudDoc = 'cloud_docname';
  static const _keyPwGenUseLetters = 'use_letters';
  static const _keyPwGenUseNumbers = 'use_numbers';
  static const _keyPwGenUseSpecialChars = 'use_special_chars';

  /// Initialises the class by setting the [_instance] property.
  static Future<void> init() async => _instance = await SharedPreferences.getInstance();

  /// Change the current theme mode and save it.
  /// * A call to this method notifies all listeners.
  Future<void> setLightMode(bool enabled) async {
    await _instance.setBool(_keyLightMode, enabled);
    notifyListeners();
  }

  /// Returns if light mode is active. Default is true.
  bool get isLightMode => _instance.getBool(_keyLightMode) ?? true;

  /// Change the current theme mode and save it.
  /// * A call to this method notifies all listeners.
  Future<void> setLastOpenedPath(String path) async {
    await _instance.setString(_keyLastOpenedPath, path);
    notifyListeners();
  }

  /// Returns the last opened path or an empty String if no path was stored.
  String get lastOpenedPath => _instance.getString(_keyLastOpenedPath) ?? '';

  /// Set if autosaving is active and save it.
  /// * A call to this method notifies all listeners.
  Future<void> setAutoSaving(bool enabled) async {
    await _instance.setBool(_keyAutoSaving, enabled);
    notifyListeners();
  }

  /// Returns if autosaving is active. Default is false.
  bool get isAutoSaving => _instance.getBool(_keyAutoSaving) ?? false;

  /// Set if onlinemode is active and save it.
  /// * A call to this method notifies all listeners.
  Future<void> setOnlineMode(bool enabled) async {
    await _instance.setBool(_keyOnlineMode, enabled);
    notifyListeners();
  }

  /// Returns if the onlinemode is enabled. Default is false.
  bool get isOnlineModeEnabled => _instance.getBool(_keyOnlineMode) ?? false;

  /// Set the name of the last opened cloud storage and save it.
  /// * A call to this method notifies all listeners.
  Future<void> setLastOpenedCloudDoc(String name) async {
    await _instance.setString(_keyLastOpenedCloudDoc, name);
    notifyListeners();
  }

  /// Returns the name of the last opened cloud storage or an empty string if nothing was stored.
  String get lastOpenedCloudDoc => _instance.getString(_keyLastOpenedCloudDoc) ?? '';

  /// Set if the password generation should use letters.
  /// * A call to this method notifies all listeners.
  Future<bool> setUseLetters(bool enabled) async {
    if(!(enabled || useNumbersEnabled || useSpecialCharsEnabled)) return false;
    final bool success = await _instance.setBool(_keyPwGenUseLetters, enabled);
    notifyListeners();
    return success;
  }

  /// Returns if the password generation should use letters.
  bool get useLettersEnabled => _instance.getBool(_keyPwGenUseLetters) ?? true;

  /// Set if the password generation should use numbers.
  /// * A call to this method notifies all listeners.
  Future<bool> setUseNumbers(bool enabled) async {
    if(!(enabled || useLettersEnabled || useSpecialCharsEnabled)) return false;
    final bool success = await _instance.setBool(_keyPwGenUseNumbers, enabled);
    notifyListeners();
    return success;
  }

  /// Returns if the password generation should use numbers.
  bool get useNumbersEnabled => _instance.getBool(_keyPwGenUseNumbers) ?? true;

  /// Set if the password generation should use special characters.
  /// * A call to this method notifies all listeners.
  Future<bool> setUseSpecialChars(bool enabled) async {
    if(!(enabled || useLettersEnabled || useNumbersEnabled)) return false;
    final bool success = await _instance.setBool(_keyPwGenUseSpecialChars, enabled);
    notifyListeners();
    return success;
  }

  /// Returns if the password generation should use special chars.
  bool get useSpecialCharsEnabled => _instance.getBool(_keyPwGenUseSpecialChars) ?? true;
}
