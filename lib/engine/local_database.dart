import 'dart:convert';
import 'dart:io';
import 'dart:collection';
import 'dart:math';

import 'package:passwordmanager/engine/encryption.dart';

import 'implementation/account.dart';

final class LocalDataBase {
  static final LocalDataBase _instance = LocalDataBase._create();
  static const int _maxCapacity = 1000;
  static const String disallowedCharacter = '\u0407';

  File? _sourceFile;
  String? _password;

  final List<Account> _accounts;
  final Set<String> _tagsUsed;

  static List<Account> getAccountsFromString(String string) {
    String c = LocalDataBase.disallowedCharacter;

    List<Account> accounts = List.empty(growable: true);
    RegExp regex = RegExp('\\$c([^\\$c]+\\$c){5}');
    Iterable<Match> matches = regex.allMatches(string);
    print('Found ${matches.length} matches');
    for(Match match in matches) {
      print(match.group(0));
      List<String>? parts = match.group(0)?.split(c);
      if(parts != null) {
        parts.retainWhere((element) => element.isNotEmpty);
        accounts.add(Account(tag: parts[0], name: parts[1], info: parts[2], email: parts[3], password: parts[4]));
      }
    }
    return accounts;
  }

  static String generateStringFromAccounts(List<Account> accounts) {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rand = Random.secure();
    String string = '';
    for(int i = 0; i < accounts.length; i++) {
      int length = rand.nextInt(64) + 1;
      for(int j = 0; j < length; j++) {
        string += String.fromCharCode(chars.codeUnitAt(rand.nextInt(chars.length)));
      }
      string += accounts.elementAt(i).toString();
    }
    int length = rand.nextInt(64) + 1;
    for(int j = 0; j < length; j++) {
      string += String.fromCharCode(chars.codeUnitAt(rand.nextInt(chars.length)));
    }

    return string;
  }

  LocalDataBase._create()
      : _accounts = List.from(
          [],
          growable: true,
        ),
        _tagsUsed = SplayTreeSet.from(
          [],
          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
        );

  factory LocalDataBase() => _instance;

  List<Account> get accounts => List.unmodifiable(_accounts);

  Set<String> get tags => Set.unmodifiable(_tagsUsed);

  void setSource(File file, String password) {
    _sourceFile = file;
    _password = password;
  }

  Future<void> load() async {
    if(_sourceFile != null && _password != null) {
      List<Account> list = LocalDataBase.getAccountsFromString(EncryptionProvider.encryption.decrypt(encryptedText: await _sourceFile?.readAsString(encoding: utf8) ?? '', password: _password!));
      for(Account acc in list) {
        addAccount(acc);
      }
    } else {
      throw Exception("Tried to load data without a provided file or password");
    }
  }

  Future<void> save() async {
    if(_sourceFile != null && _password != null) {
      if(_sourceFile!.existsSync()) await _sourceFile?.create(recursive: true);
      await _sourceFile?.writeAsString(EncryptionProvider.encryption.encrypt(plainText: LocalDataBase.generateStringFromAccounts(_accounts), password: _password!), encoding: utf8);
    } else {
      throw Exception("Tried to save data without a provided file or password");
    }
  }

  void addAccount(Account acc) {
    if (_accounts.length < LocalDataBase._maxCapacity) {
      _accounts.add(acc);
      _tagsUsed.add(acc.tag);
      _accounts.sort((a, b) => a.compareTo(b));
    } else {
      throw Exception("Maximum amount of accounts reached");
    }
  }

  void removeAccount(Account acc) {
    if (_accounts.remove(acc)) {
      if (!_accounts.any((element) => element.tag == acc.tag)) {
        _tagsUsed.remove(acc.tag);
      }
    }
  }

  List<Account> getAccountsWithTag(String tag) {
    List<Account> list = _accounts.where((element) => element.tag == tag).toList();
    list.sort((a, b) => a.compareTo(b));
    return list;
  }

  void clear() {
    _accounts.clear();
    _tagsUsed.clear();
    _sourceFile = null;
    _password = null;
  }
}