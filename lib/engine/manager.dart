import 'dart:collection';

import 'account.dart';

final class Manager {
  static final Manager _instance = Manager._create();
  static const int _maxCapacity = 1000;
  static const String disallowedCharacter = '\u0407';

  final List<Account> _accounts;
  final Set<String> _tagsUsed;

  Manager._create()
      : _accounts = List.from(
          [],
          growable: true,
        ),
        _tagsUsed = SplayTreeSet.from(
          [],
          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
        );

  factory Manager() => _instance;

  void addAccount(Account acc) {
    if (_accounts.length < Manager._maxCapacity) {
      _accounts.add(acc);
      _tagsUsed.add(acc.tag);
      _accounts.sort((a, b) => a.compareTo(b));
    } else {
      throw Exception("Maximum amount of accounts reached");
    }
  }

  void removeAccount(Account acc) {
    if (_accounts.remove(acc)) {
      if (_accounts.any((element) => element.tag == acc.tag)) {
        _tagsUsed.remove(acc.tag);
      }
    }
  }

  int accountCount() {
    return _accounts.length;
  }

  Account? getAccountAt(int index) {
    return _accounts.elementAt(index);
  }

  void testData() {
    for(int i = 0; i < 20; i++) {
      _accounts.add(Account(name: "Fortnite"));
    }
  }
}