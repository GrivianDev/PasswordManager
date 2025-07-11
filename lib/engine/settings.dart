import 'dart:core';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Class providing data like the current theme, the last opened path and if autosaving is activated.
/// This class must be initialised through the [init] call before use.
/// Extends ChangeNotifier and here calling any setter notifies all listeners.
/// Stores the data through SharedPreferences.
/// Implemented that at least one of the properties use letters/numbers/special chars has to be set to true at all times.
class Settings extends ChangeNotifier {
  static late final SharedPreferences _instance;

  static final isWindows = Platform.isWindows;
  static const _keyLightMode = 'ethercrypt.mode';
  static const _keyLastOpenedPath = 'ethercrypt.path';
  static const _keyAutoSaving = 'ethercrypt.saving';
  static const _keyPwGenUseLetters = 'ethercrypt.use_letters';
  static const _keyPwGenUseNumbers = 'ethercrypt.use_numbers';
  static const _keyPwGenUseSpecialChars = 'ethercrypt.use_special_chars';

  Duration? ntpOffset; // NTP time offset (used for accurate 2fa codes)

  /// Initialises the class by setting the [_instance] property.
  static Future<void> init() async => _instance = await SharedPreferences.getInstance();

  /// Change the current theme mode and save it.
  /// * A call to this method notifies all listeners.
  Future<bool> setLightMode(bool enabled) async {
    final bool success = await _instance.setBool(_keyLightMode, enabled);
    notifyListeners();
    return success;
  }

  /// Returns if light mode is active. Default is true.
  bool get isLightMode {
    try {
      return _instance.getBool(_keyLightMode) ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Change the current theme mode and save it.
  /// * A call to this method notifies all listeners.
  Future<bool> setLastOpenedPath(String path) async {
    final bool success = await _instance.setString(_keyLastOpenedPath, path);
    notifyListeners();
    return success;
  }

  /// Returns the last opened path or an empty String if no path was stored.
  String get lastOpenedPath {
    try {
      return _instance.getString(_keyLastOpenedPath) ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Set if autosaving is active and save it.
  /// * A call to this method notifies all listeners.
  Future<bool> setAutoSaving(bool enabled) async {
    final bool success = await _instance.setBool(_keyAutoSaving, enabled);
    notifyListeners();
    return success;
  }

  /// Returns if autosaving is active. Default is false.
  bool get isAutoSaving {
    try {
      return _instance.getBool(_keyAutoSaving) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Set if the password generation should use letters.
  /// * A call to this method notifies all listeners.
  Future<bool> setUseLetters(bool enabled) async {
    if (!(enabled || useNumbersEnabled || useSpecialCharsEnabled)) return false;
    final bool success = await _instance.setBool(_keyPwGenUseLetters, enabled);
    notifyListeners();
    return success;
  }

  /// Returns if the password generation should use letters.
  bool get useLettersEnabled {
    try {
      return _instance.getBool(_keyPwGenUseLetters) ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Set if the password generation should use numbers.
  /// * A call to this method notifies all listeners.
  Future<bool> setUseNumbers(bool enabled) async {
    if (!(enabled || useLettersEnabled || useSpecialCharsEnabled)) return false;
    final bool success = await _instance.setBool(_keyPwGenUseNumbers, enabled);
    notifyListeners();
    return success;
  }

  /// Returns if the password generation should use numbers.
  bool get useNumbersEnabled {
    try {
      return _instance.getBool(_keyPwGenUseNumbers) ?? true;
    } catch (e) {
      return true;
    }
}

  /// Set if the password generation should use special characters.
  /// * A call to this method notifies all listeners.
  Future<bool> setUseSpecialChars(bool enabled) async {
    if (!(enabled || useLettersEnabled || useNumbersEnabled)) return false;
    final bool success = await _instance.setBool(_keyPwGenUseSpecialChars, enabled);
    notifyListeners();
    return success;
  }

  /// Returns if the password generation should use special chars.
  bool get useSpecialCharsEnabled {
    try {
      return _instance.getBool(_keyPwGenUseSpecialChars) ?? true;
    } catch (e) {
      return true;
    }
  }
}
