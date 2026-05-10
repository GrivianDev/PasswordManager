import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:passwordmanager/engine/app_exception.dart';

/// Defines where a setting is stored.
enum StorageOption {
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
class AppStateField<T> {
  final String key;
  final StorageOption storage;
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

  void reset() => value = defaultValue;
}

/// Holds all application state fields and manages persistent storage.
class AppState with ChangeNotifier {
  // -------- State Fields --------

  /// Whether dark mode is enabled.
  late final darkMode = AppStateField<bool>(
    key: 'ethercrypt.dark_mode',
    storage: StorageOption.shared,
    stype: SerilizationType.bool,
    defaultValue: false,
    onChanged: notifyListeners,
  );

  /// Whether autosaving is enabled.
  late final autosaving = AppStateField<bool>(
    key: 'ethercrypt.autosaving',
    storage: StorageOption.shared,
    stype: SerilizationType.bool,
    defaultValue: false,
    onChanged: notifyListeners,
  );

  late final pwGenMinCharacters = AppStateField<int>(
    key: 'ethercrypt.passwordgeneration.min_chars',
    storage: StorageOption.shared,
    stype: SerilizationType.int,
    defaultValue: 8,
    onChanged: notifyListeners,
  );

  late final pwGenMaxCharacters = AppStateField<int>(
    key: 'ethercrypt.passwordgeneration.max_chars',
    storage: StorageOption.shared,
    stype: SerilizationType.int,
    defaultValue: 32,
    onChanged: notifyListeners,
  );

  /// Whether password generation includes letters.
  late final pwGenUseLetters = AppStateField<bool>(
    key: 'ethercrypt.passwordgeneration.use_letters',
    storage: StorageOption.shared,
    stype: SerilizationType.bool,
    defaultValue: true,
    onChanged: notifyListeners,
  );

  /// Whether password generation includes numbers.
  late final pwGenUseNumbers = AppStateField<bool>(
    key: 'ethercrypt.passwordgeneration.use_numbers',
    storage: StorageOption.shared,
    stype: SerilizationType.bool,
    defaultValue: true,
    onChanged: notifyListeners,
  );

  /// Whether password generation includes special characters.
  late final pwGenUseSpecialChars = AppStateField<bool>(
    key: 'ethercrypt.passwordgeneration.use_special_chars',
    storage: StorageOption.shared,
    stype: SerilizationType.bool,
    defaultValue: true,
    onChanged: notifyListeners,
  );

  late final ntpTimeSyncServer = AppStateField<String>(
    key: 'ethercrypt.ntp.server_adress',
    storage: StorageOption.shared,
    stype: SerilizationType.string,
    defaultValue: 'time.google.com',
    onChanged: notifyListeners,
  );

  /// Path where vaults are stored locally
  late final localSystemStorageLocation = AppStateField<String>(
    key: 'ethercrypt.filesystem.storage_location',
    storage: StorageOption.shared,
    stype: SerilizationType.string,
    defaultValue: '',
    onChanged: notifyListeners,
  );

  late final firebaseProjectId = AppStateField<String?>(
    key: 'ethercrypt.firebase.project_id',
    storage: StorageOption.secure,
    stype: SerilizationType.string,
    defaultValue: null,
    onChanged: notifyListeners,
  );

  late final firebaseApiKey = AppStateField<String?>(
    key: 'ethercrypt.firebase.api_key',
    storage: StorageOption.secure,
    stype: SerilizationType.string,
    defaultValue: null,
    onChanged: notifyListeners,
  );

  /// Email of the last Firebase-authenticated user.
  late final firebaseAuthLastUserEmail = AppStateField<String?>(
    key: 'ethercrypt.firebase.auth.last_user_email',
    storage: StorageOption.secure,
    stype: SerilizationType.string,
    defaultValue: null,
    onChanged: notifyListeners,
  );

  /// Refresh token for the last Firebase-authenticated user.
  late final firebaseAuthRefreshToken = AppStateField<String?>(
    key: 'ethercrypt.firebase.auth.user_refresh_token',
    storage: StorageOption.secure,
    stype: SerilizationType.string,
    defaultValue: null,
    onChanged: notifyListeners,
  );

  /// List of all state fields (used for batch operations).
  late final List<AppStateField> _fields;

  // Storage backends
  late final SharedPreferences _prefs;
  late final FlutterSecureStorage _secure;

  Future<void>? _ongoingSave;
  bool _saveQueued = false;
  bool get isSaveQueued => _saveQueued;

  /// Creates a new [AppState] and registers all state fields.
  AppState() {
    // All property fields should be also inserted in this total list !!!
    _fields = [
      darkMode,
      autosaving,
      pwGenMinCharacters,
      pwGenMaxCharacters,
      pwGenUseLetters,
      pwGenUseNumbers,
      pwGenUseSpecialChars,
      ntpTimeSyncServer,
      localSystemStorageLocation,
      firebaseProjectId,
      firebaseApiKey,
      firebaseAuthLastUserEmail,
      firebaseAuthRefreshToken,
    ];
  }

  /// Initializes the app state by loading values from storage.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _secure = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
    } catch (e, s) {
      throw AppException(
        'Could not initialise app state',
        debugContext: 'Init Appstate',
        cause: e,
        stackTrace: s,
      );
    }
  }

  Future<void> load() async {
    for (final AppStateField<dynamic> field in _fields) {
      try {
        switch (field.storage) {
          case StorageOption.shared:
            field._value = _loadFromSharedPreferences(field);
            break;
          case StorageOption.secure:
            field._value = await _loadFromSecureStorage(field);
            break;
        }
        if (kDebugMode) {
          debugPrint('Read property "${field.key}": ${field._value}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error reading property "${field.key}": $e');
        }
        field._value = field.defaultValue;
      }
    }
    notifyListeners();
  }

  /// Saves all state fields to persistent storage.
  Future<void> save() async {
    // If a save is already running -> queue another one
    if (_ongoingSave != null) {
      _saveQueued = true;
      return _ongoingSave;
    }

    try {
      _ongoingSave = _persistFields();
      await _ongoingSave;
    } finally {
      _ongoingSave = null;
    }

    if (_saveQueued) {
      _saveQueued = false;
      return save(); // Run again
    }
  }

  Future<void> _persistFields() async {
    try {
      for (final field in _fields) {
        switch (field.storage) {
          case StorageOption.shared:
            if (field.value == null) {
              await _prefs.remove(field.key);
            } else {
              await _saveToSharedPreferences(field);
            }
            break;
          case StorageOption.secure:
            if (field.value == null) {
              await _secure.delete(key: field.key);
            } else {
              await _secure.write(key: field.key, value: field.value.toString());
            }
            break;
        }
      }
    } catch (e, s) {
      throw AppException(
        'Could not save app state',
        debugContext: 'Save AppState',
        cause: e,
        stackTrace: s,
      );
    }
  }

  /// Clears all stored data and resets state fields to default values.
  Future<void> clearAllData() async {
    try {
      // Reset all values
      for (final AppStateField<dynamic> field in _fields) {
        field._value = field.defaultValue;
      }
      // Clear all persistent storages
      await _prefs.clear();
      await _secure.deleteAll();
    } catch (e, s) {
      throw AppException(
        'Could not clear app state',
        debugContext: 'Clear AppState',
        cause: e,
        stackTrace: s,
      );
    } finally {
      notifyListeners();
    }
  }

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
      return switch (field._stype) {
        SerilizationType.bool => (raw == 'true') as T,
        SerilizationType.int => int.parse(raw) as T,
        SerilizationType.double => double.parse(raw) as T,
        SerilizationType.string => raw as T,
      };
    } catch (_) {}

    return field.defaultValue;
  }

  /// Saves a value to shared preferences for the given [field].
  Future<void> _saveToSharedPreferences(AppStateField field) async {
    switch (field._stype) {
      case SerilizationType.bool:
        await _prefs.setBool(field.key, field.value);
        break;
      case SerilizationType.int:
        await _prefs.setInt(field.key, field.value);
        break;
      case SerilizationType.double:
        await _prefs.setDouble(field.key, field.value);
        break;
      case SerilizationType.string:
        await _prefs.setString(field.key, field.value);
        break;
    }
  }
}
