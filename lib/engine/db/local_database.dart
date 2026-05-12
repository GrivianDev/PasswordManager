import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:ethercrypt/engine/account.dart';
import 'package:ethercrypt/engine/db/database_content.dart';
import 'package:ethercrypt/engine/persistence/source.dart';

/// A central class that manages a list of [Account]s and handles loading/saving
/// via a [Source] object.
final class LocalDatabase with ChangeNotifier {
  Source? _source;
  bool _hasUnsavedChanges = false;
  final List<Account> _accounts = [];

  /// Unmodifiable list of all stored [Account]s.
  List<Account> get accounts => List.unmodifiable(_accounts);

  /// Sorted set of all tags currently used by accounts (Does not include null for untagged accounts).
  Set<String> get tags => SplayTreeSet.from(_accounts.where((a) => a.tag != null).map((a) => a.tag));

  /// Currently assigned source used for loading/saving.
  Source? get source => _source;

  /// Whether a source has been set.
  bool get isInitialised => _source != null;

  /// Whether there are unsaved changes since the last save/load.
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  Future<String> get asFormattedData => _source!.getFormattedData(DatabaseContent(accounts: accounts));

  /// Loads accounts from the given [source].
  /// Throws if a source is already set or loading fails.
  Future<void> loadFromSource(Source source) async {
    if (_source != null) {
      throw Exception('Source is already set. Clear the database first.');
    }

    try {
      final DatabaseContent content = await source.loadData();
      _source = source;
      addAllAccounts(content.accounts);
      _hasUnsavedChanges = false;
    } catch (e) {
      clear();
      rethrow;
    }
  }

  /// Saves all data to the currently assigned source.
  /// Throws if no source is set.
  Future<void> save() async {
    if (_source == null) {
      throw Exception('Cannot save: no source set.');
    }

    await _source!.saveData(DatabaseContent(accounts: accounts));
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  void addAllAccounts(List<Account> accounts) {
    if (accounts.isEmpty) return;

    _accounts.addAll(accounts);
    _accounts.sort();
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void addAccount(Account acc) {
    _accounts.add(acc);
    _accounts.sort();
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Replaces the account with the given [oldAccountId] with [newAccount].
  /// Returns false if no match was found / no account was replaced.
  bool replaceAccount(int oldAccountId, Account newAccount) {
    final index = _accounts.indexWhere((e) => e.id == oldAccountId);
    if (index == -1) return false;

    _accounts[index] = newAccount;
    _accounts.sort();
    _hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  /// Removes an account by [id]. Returns true if removed.
  bool removeAccount(int id) {
    final index = _accounts.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    _accounts.removeAt(index);
    _hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  /// Returns all accounts matching the given [tag]. Pass in null to get untagged accounts.
  List<Account> getAccountsWithTag(String? tag) => _accounts.where((a) => a.tag == tag).toList();

  /// Clears all accounts and resets the source.
  void clear() {
    _accounts.clear();
    _source = null;
    _hasUnsavedChanges = false;
    notifyListeners();
  }
}
