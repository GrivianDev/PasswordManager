import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum StorageType { shared, secure }

class AppStateField<T> {
  final String key;
  final StorageType storage;
  final T defaultValue;
  T _value;

  final void Function() _onChanged;

  AppStateField({
    required this.key,
    required this.storage,
    required this.defaultValue,
    required Function() onChanged,
  })  : _value = defaultValue,
        _onChanged = onChanged;

  T get value => _value;

  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      _onChanged(); // Notify listeners
    }
  }

  bool get isDefault => value == defaultValue;
}

AndroidOptions _getAndroidOptions() => const AndroidOptions(
  encryptedSharedPreferences: true,
);

class AppState extends ChangeNotifier {
  // All App properties
  late final darkMode = AppStateField<bool>(
    key: 'ethercrypt.dark_mode',
    storage: StorageType.shared,
    defaultValue: false,
    onChanged: notifyListeners,
  );

  late final lastOpenedFilePath = AppStateField<String?>(
    key: 'ethercrypt.last_opened_filepath',
    storage: StorageType.shared,
    defaultValue: null,
    onChanged: notifyListeners,
  );

  late final autosaving = AppStateField<bool>(
    key: 'ethercrypt.autosaving',
    storage: StorageType.shared,
    defaultValue: false,
    onChanged: notifyListeners,
  );

  late final pwGenUseLetters = AppStateField<bool>(
    key: 'ethercrypt.passwordgeneration.use_letters',
    storage: StorageType.shared,
    defaultValue: true,
    onChanged: notifyListeners,
  );

  late final pwGenUseNumbers = AppStateField<bool>(
    key: 'ethercrypt.passwordgeneration.use_numbers',
    storage: StorageType.shared,
    defaultValue: true,
    onChanged: notifyListeners,
  );

  late final pwGenUseSpecialChars = AppStateField<bool>(
    key: 'ethercrypt.passwordgeneration.use_special_chars',
    storage: StorageType.shared,
    defaultValue: true,
    onChanged: notifyListeners,
  );

  late final firebaseAuthLastUserEmail = AppStateField<String?>(
    key: 'ethercrypt.firebase.auth.last_user_email',
    storage: StorageType.secure,
    defaultValue: null,
    onChanged: notifyListeners,
  );

  late final firebaseAuthRefreshToken = AppStateField<String?>(
    key: 'ethercrypt.firebase.auth.user_refresh_token',
    storage: StorageType.secure,
    defaultValue: null,
    onChanged: notifyListeners,
  );

  late final List<AppStateField> _fields;

  // Storage backends
  late final SharedPreferences _prefs;
  late final FlutterSecureStorage _secure;

  AppState() {
    // All property fields should be also inserted in this total list !!!
    _fields = [
      darkMode,
      lastOpenedFilePath,
      autosaving,
      pwGenUseLetters,
      pwGenUseNumbers,
      pwGenUseSpecialChars,
      firebaseAuthLastUserEmail,
      firebaseAuthRefreshToken,
    ];
  }

  Future<bool> init() async {
    _prefs = await SharedPreferences.getInstance();
    _secure = FlutterSecureStorage(aOptions: _getAndroidOptions());

    bool withoutErrors = true;
    for (final AppStateField<dynamic> field in _fields) {
      try {
        switch (field.storage) {
          case StorageType.shared:
            field._value = _loadFromSharedPreferences(field);
            break;
          case StorageType.secure:
            field._value = await _loadFromSecureStorage(field);
            break;
        }
      } catch (e) {
        withoutErrors = false;
      }
    }
    notifyListeners();
    return withoutErrors;
  }

  Future<bool> save() async {
    bool withoutErrors = true;
    for (final field in _fields) {
      try {
        switch (field.storage) {
          case StorageType.shared:
            if (field.value == null) {
              await _prefs.remove(field.key);
            } else {
              await _saveToSharedPreferences(field);
            }
            break;
          case StorageType.secure:
            if (field.value == null) {
              await _secure.delete(key: field.key);
            } else {
              await _secure.write(key: field.key, value: field.value.toString());
            }
            break;
        }
      } catch (e) {
        withoutErrors = false;
      }
    }
    return withoutErrors;
  }

  // ---- Utility Methods ----

  T _loadFromSharedPreferences<T>(AppStateField<T> field) {
    final Object? raw = _prefs.get(field.key);
    if (raw is T) return raw;
    return field.defaultValue;
  }

  Future<T> _loadFromSecureStorage<T>(AppStateField<T> field) async {
    final String? raw = await _secure.read(key: field.key);
    if (raw == null) return field.defaultValue;

    try {
      if (T == String) return raw as T;
      if (T == int) return int.parse(raw) as T;
      if (T == double) return double.parse(raw) as T;
      if (T == bool) return (raw == 'true') as T;
    } catch (_) {}

    return field.defaultValue;
  }

  Future<void> _saveToSharedPreferences(AppStateField field) async {
    final key = field.key;
    final val = field.value;

    if (val is String) {
      await _prefs.setString(key, val);
    } else if (val is bool) {
      await _prefs.setBool(key, val);
    } else if (val is int) {
      await _prefs.setInt(key, val);
    } else if (val is double) {
      await _prefs.setDouble(key, val);
    } else {
      throw UnsupportedError("Unsupported type for shared_preferences");
    }
  }
}