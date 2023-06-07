import 'dart:convert';
import 'dart:io';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:passwordmanager/engine/encryption.dart';
import 'package:passwordmanager/engine/implementation/account.dart';

/// LocalDatabase is the core class of this project. This object exists only once
/// stored in the [_instance] property as Singelton. The [LocalDatabase] constructor just returns this reference.
/// In addition this class extends the [ChangeNotifier]. Outside calls with [addAccount], [callEditOf], [removeAccount] or [clear] notify all listeners.
final class LocalDatabase extends ChangeNotifier {
  static final LocalDatabase _instance = LocalDatabase._create();
  static const int _maxCapacity = 1000;
  static const String disallowedCharacter = '\u0407';

  File? _sourceFile;
  String? _password;

  final List<Account> _accounts;
  final Set<String> _tagsUsed;

  /// Static method to analyse a probably freshly decrypted [string] with a [RegExp].
  /// Returns a List of [Account] instances that were found in the text.
  static List<Account> getAccountsFromString(String string) {
    String c = LocalDatabase.disallowedCharacter;

    List<Account> accounts = List.empty(growable: true);
    RegExp regex = RegExp('\\$c([^\\$c]+\\$c){5}');
    Iterable<Match> matches = regex.allMatches(string);
    for(Match match in matches) {
      List<String>? parts = match.group(0)?.split(c);
      if(parts != null) {
        parts.retainWhere((element) => element.isNotEmpty);
        accounts.add(Account(tag: parts[0], name: parts[1], info: parts[2], email: parts[3], password: parts[4]));
      }
    }
    return accounts;
  }

  /// Static method to gernerate a String based on the given [accounts] list.
  /// Accounts are put in the String between randomly generated substrings.
  /// This causes the text to be never the same for each encryption process.
  static String generateStringFromAccounts(List<Account> accounts) {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rand = Random.secure();
    StringBuffer buffer = StringBuffer();
    for(int i = 0; i < accounts.length; i++) {
      int length = rand.nextInt(64) + 1;
      for(int j = 0; j < length; j++) {
        buffer.write(String.fromCharCode(chars.codeUnitAt(rand.nextInt(chars.length))));
      }
      buffer.write(accounts.elementAt(i).toString());
    }
    int length = rand.nextInt(64) + 1;
    for(int j = 0; j < length; j++) {
      buffer.write(String.fromCharCode(chars.codeUnitAt(rand.nextInt(chars.length))));
    }

    return buffer.toString();
  }

  /// Constructor for initialising this singelton.
  LocalDatabase._create()
      : _accounts = List.empty(growable: true),
        _tagsUsed = SplayTreeSet.from(
          [],
          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
        );

  /// Standard constructor. However this always returns the same reference since this
  /// class is implemented as singelton.
  factory LocalDatabase() => _instance;

  /// Returns all currently stored [Account] references as unmodifiable List.
  List<Account> get accounts => List.unmodifiable(_accounts);

  /// Returns all currently stored tag-string references as unmodifiable List.
  Set<String> get tags => Set.unmodifiable(_tagsUsed);

  File? get source => _sourceFile;

  /// Before calling the [load] or [save] function this method MUST be called to provide
  /// the source File and the password to use for encryption and decryption.
  void setSource(File file, String password) {
    _sourceFile = file;
    _password = password;
  }

  /// Asynchronous method to load [Account] references from the file provided through the [setSource] method.
  /// And exception is thrown if either the [_sourceFile] or [_password] property is null. The encryption method is provided through
  /// the [EncryptionProvider] class.
  Future<void> load() async {
    if(_sourceFile != null && _password != null) {
      List<Account> list = LocalDatabase.getAccountsFromString(EncryptionProvider.encryption.decrypt(encryptedText: await _sourceFile?.readAsString(encoding: utf8) ?? '', password: _password!));
      _addAllAccounts(list);
    } else {
      throw Exception("Tried to load data without a provided file or password");
    }
  }

  /// Asynchronous method to save all stored [Account] references to the file provided through the [setSource] method.
  /// And exception is thrown if either the [_sourceFile] or [_password] property is null. The encryption method is provided through
  /// the [EncryptionProvider] class.
  Future<void> save() async {
    if(_sourceFile != null && _password != null) {
      if(_sourceFile!.existsSync()) await _sourceFile?.create(recursive: true);
      await _sourceFile?.writeAsString(EncryptionProvider.encryption.encrypt(plainText: LocalDatabase.generateStringFromAccounts(_accounts), password: _password!), encoding: utf8);
    } else {
      throw Exception("Tried to save data without a provided file or password");
    }
  }

  /// Private method to add a larger quantity of [Account] objects without notifying all listeners
  /// after each new append call.
  /// * A call to this method notifies all listeners.
  void _addAllAccounts(List<Account> accounts) {
    for(Account acc in accounts) {
      if (_accounts.length < LocalDatabase._maxCapacity) {
        _accounts.add(acc);
        _tagsUsed.add(acc.tag);
        _accounts.sort((a, b) => a.compareTo(b));
      } else {
        throw Exception("Maximum amount of accounts reached");
      }
    }
    notifyListeners();
  }

  /// Method to add a new [Account] to the database. The intern List will sort accounts and tags alphabetically.
  /// If the new Account has a tag that was not used before it will be saved in the [_tagsUsed] property.
  /// If there are to many accounts already present (specified in [LocalDatabase._maxCapacity]) and Exception is thrown.
  /// * A call to this method notifies all listeners if [Account] was added.
  void addAccount(Account acc) {
    if (_accounts.length < LocalDatabase._maxCapacity) {
      _accounts.add(acc);
      _tagsUsed.add(acc.tag);
      _accounts.sort((a, b) => a.compareTo(b));
      notifyListeners();
    } else {
      throw Exception("Maximum amount of accounts reached");
    }
  }

  /// After editing an [Account] this method must be called to ensure the intern List is still sorted
  /// and tags that point to no accounts are removed properly.
  /// * A call to this method notifies all listeners.
  void callEditOf(String oldTag, Account acc) {
    _accounts.sort((a, b) => a.compareTo(b));
    _tagsUsed.add(acc.tag);
    if (!_accounts.any((element) => element.tag == oldTag)) {
      _tagsUsed.remove(oldTag);
    }
    notifyListeners();
  }

  /// Method to remove the given [Account] from the database. If the old tag is not used by
  /// other accounts then this property will be removed from the database.
  /// * A call to this method notifies all listeners if [Account] was removed.
  void removeAccount(Account acc) {
    if (_accounts.remove(acc)) {
      if (!_accounts.any((element) => element.tag == acc.tag)) {
        _tagsUsed.remove(acc.tag);
      }
      notifyListeners();
    }
  }

  /// Returns all [Account] references that have this particular tag.
  List<Account> getAccountsWithTag(String tag) {
    List<Account> list = _accounts.where((element) => element.tag == tag).toList();
    list.sort((a, b) => a.compareTo(b));
    return list;
  }

  /// Completly wipes all data from the database. In addition the [_sourceFile] and [_password] property
  /// will be set to null.
  /// * A call to this method notifies all listeners.
  void clear() {
    _accounts.clear();
    _tagsUsed.clear();
    _sourceFile = null;
    _password = null;
    notifyListeners();
  }
}