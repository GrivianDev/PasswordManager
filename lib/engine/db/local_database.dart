import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/persistence/source.dart';

/// A central class that manages a list of [Account]s and handles loading/saving
/// via a [Source]. Extends [ChangeNotifier] to support UI updates.
final class LocalDatabase extends ChangeNotifier {
  static const int maxCapacity = 1000;
  static const String disallowedCharacter = '\u0407';

  Source? _source;
  bool _hasUnsavedChanges = false;
  final List<Account> _accounts = [];

  /// Unmodifiable list of all stored [Account]s.
  List<Account> get accounts => List.unmodifiable(_accounts);

  /// Sorted set of all tags currently used by accounts.
  Set<String> get tags => SplayTreeSet.from(_accounts.map((a) => a.tag));

  /// Currently assigned source used for loading/saving.
  Source? get source => _source;

  /// Whether a source has been set.
  bool get isInitialised => _source != null;

  /// Whether there are unsaved changes since the last save/load.
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// The current raw database content in string form, provided by the [Source].
  Future<String> get formattedData {
    if (_source == null) {
      throw Exception("Cannot access formatted data: no source set.");
    }
    return _source!.getFormattedData();
  }

  /// Loads accounts from the given [source] using the [password].
  /// Throws if a source is already set or loading fails.
  Future<void> loadFromSource(Source source, {required String password, bool notify = true}) async {
    if (_source != null) {
      throw Exception("Source is already set. Clear the database first.");
    }

    try {
      if (await source.isValid) {
        await source.loadData();
        source.dbRef = this;
        _source = source;
        _hasUnsavedChanges = false;
        if (notify) notifyListeners();
      }
    } catch (e) {
      clear(notify: false);
      rethrow;
    }
  }

  /// Saves all data to the currently assigned source.
  /// Throws if no source is set.
  Future<void> save({bool notify = true}) async {
    if (_source == null) {
      throw Exception("Cannot save: no source set.");
    }

    await _source!.saveData();
    _hasUnsavedChanges = false;
    if (notify) notifyListeners();
  }

  /// Adds multiple [Account]s at once. Throws if this exceeds [maxCapacity].
  /// Notifies listeners once after bulk add.
  void addAllAccounts(List<Account> accounts, {bool notify = true}) {
    if (accounts.isEmpty) return;

    final availableSpace = maxCapacity - _accounts.length;
    if (accounts.length > availableSpace) {
      throw Exception("Adding ${accounts.length} accounts exceeds capacity of $maxCapacity.");
    }

    _accounts.addAll(accounts);
    _accounts.sort();
    _hasUnsavedChanges = true;
    if (notify) notifyListeners();
  }

  /// Adds a single [Account] to the database. Throws if capacity is exceeded.
  /// Notifies listeners if [notify] is true.
  void addAccount(Account acc, {bool notify = true}) {
    if (_accounts.length >= maxCapacity) {
      throw Exception("Account limit ($maxCapacity) reached.");
    }

    _accounts.add(acc);
    _accounts.sort();
    _hasUnsavedChanges = true;
    if (notify) notifyListeners();
  }

  /// Replaces the account with the given [oldAccountId] with [newAccount].
  /// Returns false if no match was found. Sorts and notifies on success.
  bool replaceAccount(int oldAccountId, Account newAccount, {bool notify = true}) {
    final index = _accounts.indexWhere((e) => e.id == oldAccountId);
    if (index == -1) return false;

    _accounts[index] = newAccount;
    _accounts.sort();
    _hasUnsavedChanges = true;
    if (notify) notifyListeners();
    return true;
  }

  /// Removes an account by [id]. Returns true if removed.
  /// Notifies listeners if [notify] is true.
  bool removeAccount(int id, {bool notify = true}) {
    final index = _accounts.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    _accounts.removeAt(index);
    _hasUnsavedChanges = true;
    if (notify) notifyListeners();
    return true;
  }

  /// Returns all accounts matching the given [tag].
  List<Account> getAccountsWithTag(String tag) => _accounts.where((a) => a.tag == tag).toList();

  /// Clears all accounts and resets the source.
  /// Notifies listeners if [notify] is true.
  void clear({bool notify = true}) {
    _accounts.clear();
    _source = null;
    _hasUnsavedChanges = false;
    if (notify) notifyListeners();
  }
}

