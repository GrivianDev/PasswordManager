import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Defines where a setting is stored.
enum StorageType {
  /// Stored in unencrypted shared preferences (accessible to the app).
  shared,

  /// Stored in encrypted secure storage (protected with platform-level encryption).
  secure,
}

enum SerilizationType {
  string,
  int,
  double,
  bool,
}

/// Represents a single application state field with a key, storage type,
/// serialization type, and default value.
///
/// This is a generic class that can store any type `T` supported by the
/// serialization system. It tracks value changes and triggers an
/// `onChanged` callback when updated.
class AppStateField<T> {
  final String key;
  final StorageType storage;
  final SerilizationType _stype;
  final T defaultValue;
  T _value;

  final void Function() _onChanged;

  AppStateField({
    required this.key,
    required this.storage,
    required SerilizationType stype,
    required this.defaultValue,
    required Function() onChanged,
  })  : _value = defaultValue,
        _stype = stype,
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

/// Holds all application state fields and manages persistent storage.
///
/// This class:
/// - Initializes state from persistent storage
/// - Saves changes to storage
/// - Clears all data when requested
/// - Notifies listeners on changes
class AppState extends ChangeNotifier {
  // -------- State Fields --------

  /// Whether dark mode is enabled.
  late final darkMode = AppStateField<bool>(
    key: 'ethercrypt.dark_mode',
    storage: StorageType.shared,
    stype: SerilizationType.bool,
    defaultValue: false,
    onChanged: notifyListeners,
  );

  /// Path to the last opened file.
  late final lastOpenedFilePath = AppStateField<String?>(
    key: 'ethercrypt.last_opened_filepath',
    storage: StorageType.shared,
    stype: SerilizationType.string,
    defaultValue: null,
    onChanged: notifyListeners,
  );

  /// Whether autosaving is enabled.
  late final autosaving = AppStateField<bool>(
    key: 'ethercrypt.autosaving',
    storage: StorageType.shared,
    stype: SerilizationType.bool,
    defaultValue: false,
    onChanged: notifyListeners,
  );

  /// Whether password generation includes letters.
  late final pwGenUseLetters = AppStateField<bool>(
    key: 'ethercrypt.passwordgeneration.use_letters',
    storage: StorageType.shared,
    stype: SerilizationType.bool,
    defaultValue: true,
    onChanged: notifyListeners,
  );

  /// Whether password generation includes numbers.
  late final pwGenUseNumbers = AppStateField<bool>(
    key: 'ethercrypt.passwordgeneration.use_numbers',
    storage: StorageType.shared,
    stype: SerilizationType.bool,
    defaultValue: true,
    onChanged: notifyListeners,
  );

  /// Whether password generation includes special characters.
  late final pwGenUseSpecialChars = AppStateField<bool>(
    key: 'ethercrypt.passwordgeneration.use_special_chars',
    storage: StorageType.shared,
    stype: SerilizationType.bool,
    defaultValue: true,
    onChanged: notifyListeners,
  );

  /// Email of the last Firebase-authenticated user.
  late final firebaseAuthLastUserEmail = AppStateField<String?>(
    key: 'ethercrypt.firebase.auth.last_user_email',
    storage: StorageType.secure,
    stype: SerilizationType.string,
    defaultValue: null,
    onChanged: notifyListeners,
  );

  /// Refresh token for the last Firebase-authenticated user.
  late final firebaseAuthRefreshToken = AppStateField<String?>(
    key: 'ethercrypt.firebase.auth.user_refresh_token',
    storage: StorageType.secure,
    stype: SerilizationType.string,
    defaultValue: null,
    onChanged: notifyListeners,
  );

  /// List of all state fields (used for batch operations).
  late final List<AppStateField> _fields;

  // Storage backends
  late final SharedPreferences _prefs;
  late final FlutterSecureStorage _secure;

  /// Creates a new [AppState] and registers all state fields.
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

  /// Initializes the app state by loading values from storage.
  ///
  /// Returns `true` if all values loaded without errors.
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

  /// Saves all state fields to persistent storage.
  ///
  /// Returns `true` if all values saved without errors.
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

  /// Clears all stored data and resets state fields to default values.
  ///
  /// Returns `true` if clearing succeeded without errors.
  Future<bool> clearAllData() async {
    // Reset all values
    for (final AppStateField<dynamic> field in _fields) {
      field._value = field.defaultValue;
    }

    bool withoutErrors = true;
    try {
      // Clear all persistent storages
      withoutErrors |= await _prefs.clear();
      await _secure.deleteAll();
    } catch (_) {
      withoutErrors = false;
    }
    notifyListeners();

    return withoutErrors;
  }

  // ---- Utility Methods ----

  /// Loads a value from shared preferences for the given [field].
  T _loadFromSharedPreferences<T>(AppStateField<T> field) {
    final Object? raw = _prefs.get(field.key);
    if (raw == null) return field.defaultValue;

    return raw as T;
  }

  /// Loads a value from secure storage for the given [field].
  Future<T> _loadFromSecureStorage<T>(AppStateField<T> field) async {
    final String? raw = await _secure.read(key: field.key);
    if (raw == null) return field.defaultValue;

    try {
      if (field._stype == SerilizationType.string) return raw as T;
      if (field._stype == SerilizationType.int) return int.parse(raw) as T;
      if (field._stype == SerilizationType.double) return double.parse(raw) as T;
      if (field._stype == SerilizationType.bool) return (raw == 'true') as T;
    } catch (_) {}

    return field.defaultValue;
  }

  /// Saves a value to shared preferences for the given [field].
  Future<void> _saveToSharedPreferences(AppStateField field) async {
    if (field._stype == SerilizationType.string) {
      await _prefs.setString(field.key, field.value);
    } else if (field._stype == SerilizationType.bool) {
      await _prefs.setBool(field.key, field.value);
    } else if (field._stype == SerilizationType.int) {
      await _prefs.setInt(field.key, field.value);
    } else if (field._stype == SerilizationType.double) {
      await _prefs.setDouble(field.key, field.value);
    } else {
      throw UnsupportedError("Unsupported type for shared_preferences");
    }
  }
}