import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/source.dart';

/// LocalDatabase is the core class of this project. This object exists only once
/// stored in the [_instance] property as Singleton. The [LocalDatabase] constructor just returns this reference.
/// In addition this class extends the [ChangeNotifier]. Outside calls with [addAccount], [addAllAccounts], [callEditOf], [removeAccount] or [clear] notify all listeners.
/// Uses a [Source] to determine if cloud or local file should be used for saving changes.
final class LocalDatabase extends ChangeNotifier {
  static final LocalDatabase _instance = LocalDatabase._create();
  static const int maxCapacity = 1000;
  static const String disallowedCharacter = '\u0407';

  Source? _source;

  final List<Account> _accounts;
  final Set<String> _tagsUsed;

  /// Private constructor for initialising this singleton.
  LocalDatabase._create()
      : _accounts = List.empty(growable: true),
        _tagsUsed = SplayTreeSet.from(
          const Iterable<String>.empty(),
          (a, b) => a.compareTo(b),
        );

  /// Standard constructor. However this always returns the same reference since this
  /// class is implemented as singleton.
  factory LocalDatabase() => _instance;

  /// Returns all currently stored [Account] references as unmodifiable List.
  List<Account> get accounts => List.unmodifiable(_accounts);

  /// Returns all currently stored tag-string references as unmodifiable Set.
  Set<String> get tags => Set.unmodifiable(_tagsUsed);

  Source? get source => _source;

  Future<String> get formattedData async {
    if(_source == null) throw Exception("Called getter for formatted data but source is not set in database.");
    return await _source!.getFormattedData();
  }

  /// Before calling the [load] or [save] function this method MUST be called to provide
  /// the source File or cloud data to use for encryption and decryption.
  void setSource(Source source) {
    _source = source;
    _source!.dbRef = this;
  }

  /// Asynchronous method to load [Account] references from the source provided through the [setSource] method.
  /// And exception is thrown if the [_source] property is null.
  Future<void> load({required String password}) async {
    if (_source != null) {
      if (_source!.isValid) {
        _accounts.clear();
        _tagsUsed.clear();
        await _source!.loadData(password: password);
      }
    } else {
      throw Exception("Tried to load data without a provided source");
    }
  }

  /// Asynchronous method to save all stored [Account] references to the source provided through the [setSource] method.
  /// And exception is thrown if the [_source] property is null.
  Future<void> save() async {
    if (_source != null) {
      await _source!.saveData();
    } else {
      throw Exception("Tried to save data without a provided source");
    }
  }

  /// Private method to add a larger quantity of [Account] objects without notifying all listeners
  /// after each new append call.
  /// * A call to this method notifies all listeners.
  void addAllAccounts(List<Account> accounts) {
    for (Account acc in accounts) {
      if (_accounts.length < LocalDatabase.maxCapacity) {
        _accounts.add(acc);
        _tagsUsed.add(acc.tag);
      } else {
        throw Exception("Maximum amount of accounts reached");
      }
    }
    _accounts.sort();
    notifyAll();
  }

  /// Method to add a new [Account] to the database. The intern List will sort accounts and tags alphabetically.
  /// If the new Account has a tag that was not used before it will be saved in the [_tagsUsed] property.
  /// Does not add instances that are already present. If there are to many accounts already
  /// present (specified in [LocalDatabase.maxCapacity]) and Exception is thrown.
  /// * A call to this method notifies all listeners if [Account] was added.
  void addAccount(Account acc, {bool notify = true}) {
    if (_accounts.length < LocalDatabase.maxCapacity) {
      if (!_accounts.any((element) => element.id == acc.id)) {
        _accounts.add(acc);
        _tagsUsed.add(acc.tag);
        _accounts.sort();
        source?.claimHasUnsavedChanges();
        if (notify) notifyAll();
      }
    } else {
      throw Exception("Maximum amount of accounts reached");
    }
  }

  /// After editing an [Account] this method must be called to ensure the intern List is still sorted
  /// and tags that point to no accounts are removed properly.
  /// * A call to this method notifies all listeners.
  void callEditOf(String oldTag, Account acc, {bool notify = true}) {
    if (_accounts.any((element) => element.id == acc.id)) {
      _accounts.sort();
      _tagsUsed.add(acc.tag);
      if (!_accounts.any((element) => element.tag == oldTag)) {
        _tagsUsed.remove(oldTag);
      }
      source?.claimHasUnsavedChanges();
      if (notify) notifyAll();
    }
  }

  /// Method to remove the given [Account] from the database. If the old tag is not used by
  /// other accounts then this property will be removed from the database.
  /// * A call to this method notifies all listeners if [Account] was removed.
  void removeAccount(Account acc, {bool notify = true}) {
    if (_accounts.any((element) => element.id == acc.id)) {
      _accounts.removeWhere((element) => element.id == acc.id);
      if (!_accounts.any((element) => element.tag == acc.tag)) {
        _tagsUsed.remove(acc.tag);
      }
      source?.claimHasUnsavedChanges();
      if (notify) notifyAll();
    }
  }

  /// Returns all [Account] references that have this particular tag.
  List<Account> getAccountsWithTag(String tag) {
    List<Account> list = _accounts.where((element) => element.tag == tag).toList();
    list.sort();
    return list;
  }

  /// Completely wipes all data from the database. In addition the [_source] and [_password] property
  /// will be set to null.
  /// * A call to this method notifies all listeners.
  void clear({bool notify = true}) {
    _accounts.clear();
    _tagsUsed.clear();
    if (_source != null) _source!.invalidate();
    _source = null;
    if (notify) notifyAll();
  }

  /// Just notifies all listeners
  void notifyAll() {
    notifyListeners();
  }
}
