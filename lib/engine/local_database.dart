import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:passwordmanager/engine/encryption.dart';
import 'package:passwordmanager/engine/implementation/account.dart';
import 'package:passwordmanager/engine/source.dart';
import 'package:passwordmanager/engine/implementation/hashing.dart';

/// LocalDatabase is the core class of this project. This object exists only once
/// stored in the [_instance] property as Singelton. The [LocalDatabase] constructor just returns this reference.
/// In addition this class extends the [ChangeNotifier]. Outside calls with [addAccount], [callEditOf], [removeAccount] or [clear] notify all listeners.
/// Uses a [Source] to determine if cloud or local file should be used for saving changes.
final class LocalDatabase extends ChangeNotifier {
  static final LocalDatabase _instance = LocalDatabase._create();
  static const int maxCapacity = 1000;
  static const String disallowedCharacter = '\u0407';

  Source? _source;
  String? _password;

  final List<Account> _accounts;
  final Set<String> _tagsUsed;

  /// Static method to analyse a probably freshly decrypted [string] with a [RegExp].
  /// Returns a List of [Account] instances that were found in the text.
  static List<Account> getAccountsFromString(String string) {
    const String c = LocalDatabase.disallowedCharacter;

    List<Account> accounts = List.empty(growable: true);
    RegExp regex = RegExp('\\$c([^\\$c]+\\$c){5}');
    Iterable<Match> matches = regex.allMatches(string);
    for (Match match in matches) {
      List<String>? parts = match.group(0)?.split(c);
      if (parts != null) {
        parts.retainWhere((element) => element.isNotEmpty);
        accounts.add(Account(tag: parts[0], name: parts[1], info: parts[2], email: parts[3], password: parts[4]));
      }
    }
    return accounts;
  }

  /// Static method to gernerate a String based on the given [accounts] list.
  /// Accounts are put in the String between randomly generated substrings.
  /// This causes the text to be never the same for each encryption process.
  /// Returned string is never empty.
  static String generateStringFromAccounts(List<Account> accounts) {
    const String chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rand = Random.secure();
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < accounts.length; i++) {
      int length = rand.nextInt(8) + 1;
      for (int j = 0; j < length; j++) {
        buffer.write(String.fromCharCode(chars.codeUnitAt(rand.nextInt(chars.length))));
      }
      buffer.write(accounts.elementAt(i).toString());
    }
    for (int j = 0; j < 8; j++) {
      buffer.write(String.fromCharCode(chars.codeUnitAt(rand.nextInt(chars.length))));
    }

    return buffer.toString();
  }

  /// Private constructor for initialising this singelton.
  LocalDatabase._create()
      : _accounts = List.empty(growable: true),
        _tagsUsed = SplayTreeSet.from(
          const Iterable<String>.empty(),
          (a, b) => a.compareTo(b),
        );

  /// Standard constructor. However this always returns the same reference since this
  /// class is implemented as singelton.
  factory LocalDatabase() => _instance;

  /// Returns all currently stored [Account] references as unmodifiable List.
  List<Account> get accounts => List.unmodifiable(_accounts);

  /// Returns all currently stored tag-string references as unmodifiable Set.
  Set<String> get tags => Set.unmodifiable(_tagsUsed);

  Source? get source => _source;

  /// Returns the double hashed password by calling [Hashing.sha256DoubledHash] or null if [_password] was null.
  Uint8List? get doubleHash => _password != null ? Hashing.sha256DoubledHash(utf8.encode(_password!)) : null;

  /// Returns the encrypted cipher of currently stored accounts. Uses the encryption provided through [EncryptionProvider.encryption].
  String? get cipher => _password != null
      ? EncryptionProvider.encryption.encrypt(plainText: LocalDatabase.generateStringFromAccounts(_accounts), password: _password!)
      : null;

  /// Before calling the [load] or [save] function this method MUST be called to provide
  /// the source File and the password to use for encryption and decryption.
  void setSource(Source source, String password) {
    _source = source;
    _password = password;
  }

  /// Asynchronous method to load [Account] references from the source provided through the [setSource] method.
  /// And exception is thrown if either the [_source] or [_password] property is null. The encryption method is provided through
  /// the [EncryptionProvider] class.
  Future<void> load() async {
    if (_source != null && _password != null) {
      if (_source!.isValid) {
        List<Account> list =
            LocalDatabase.getAccountsFromString(EncryptionProvider.encryption.decrypt(encryptedText: await _source!.load(), password: _password!));
        _addAllAccounts(list);
      }
    } else {
      throw Exception("Tried to load data without a provided source or password");
    }
  }

  /// Asynchronous method to save all stored [Account] references to the source provided through the [setSource] method.
  /// And exception is thrown if either the [_source] or [_password] property is null. The encryption method is provided through
  /// the [EncryptionProvider] class.
  Future<void> save() async {
    if (_source != null && _password != null) {
      await _source!.saveChanges(cipher!);
    } else {
      throw Exception("Tried to save data without a provided source or password");
    }
  }

  /// Private method to add a larger quantity of [Account] objects without notifying all listeners
  /// after each new append call.
  /// * A call to this method notifies all listeners.
  void _addAllAccounts(List<Account> accounts) {
    for (Account acc in accounts) {
      if (_accounts.length < LocalDatabase.maxCapacity) {
        _accounts.add(acc);
        _tagsUsed.add(acc.tag);
      } else {
        throw Exception("Maximum amount of accounts reached");
      }
    }
    _accounts.sort();
    notifyListeners();
  }

  /// Method to add a new [Account] to the database. The intern List will sort accounts and tags alphabetically.
  /// If the new Account has a tag that was not used before it will be saved in the [_tagsUsed] property.
  /// If there are to many accounts already present (specified in [LocalDatabase.maxCapacity]) and Exception is thrown.
  /// * A call to this method notifies all listeners if [Account] was added.
  void addAccount(Account acc, {bool notify = true}) {
    if (_accounts.length < LocalDatabase.maxCapacity) {
      _accounts.add(acc);
      _tagsUsed.add(acc.tag);
      _accounts.sort();
      if (notify) notifyListeners();
    } else {
      throw Exception("Maximum amount of accounts reached");
    }
  }

  /// After editing an [Account] this method must be called to ensure the intern List is still sorted
  /// and tags that point to no accounts are removed properly.
  /// * A call to this method notifies all listeners.
  void callEditOf(String oldTag, Account acc, {bool notify = true}) {
    _accounts.sort();
    _tagsUsed.add(acc.tag);
    if (!_accounts.any((element) => element.tag == oldTag)) {
      _tagsUsed.remove(oldTag);
    }
    if (notify) notifyListeners();
  }

  /// Method to remove the given [Account] from the database. If the old tag is not used by
  /// other accounts then this property will be removed from the database.
  /// * A call to this method notifies all listeners if [Account] was removed.
  void removeAccount(Account acc, {bool notify = true}) {
    _accounts.removeWhere((element) => element.id == acc.id);
    if (!_accounts.any((element) => element.tag == acc.tag)) {
      _tagsUsed.remove(acc.tag);
    }
    if (notify) notifyListeners();
  }

  /// Returns all [Account] references that have this particular tag.
  List<Account> getAccountsWithTag(String tag) {
    List<Account> list = _accounts.where((element) => element.tag == tag).toList();
    list.sort();
    return list;
  }

  /// Completly wipes all data from the database. In addition the [_source] and [_password] property
  /// will be set to null.
  /// * A call to this method notifies all listeners.
  void clear({bool notify = true}) {
    _accounts.clear();
    _tagsUsed.clear();
    if (_source != null) _source!.invalidate();
    _source = null;
    _password = null;
    if (notify) notifyListeners();
  }
}
