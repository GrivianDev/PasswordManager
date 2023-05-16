import 'manager.dart';

final class Account implements Comparable<Account> {
  static const String _noEntry = 'none';
  static int _idSeed = 0;
  final int id;

  late String _tag;

  late String _name;
  late String _info;
  late String _email;
  late String _password;

  Account(
      {String? tag,
      String? name,
      String? info,
      String? email,
      String? password})
      : id = ++_idSeed {
    setTag = tag;
    setName = name;
    setInfo = info;
    setEmail = email;
    setPassword = password;
  }

  String get tag => _tag;
  String get name => _name;
  String get info => _info;
  String get email => _email;
  String get password => _password;

  set setTag(String? string) =>
      _tag = (string ??= Account._noEntry).isEmpty ? Account._noEntry : string;
  set setName(String? string) =>
      _name = (string ??= Account._noEntry).isEmpty ? Account._noEntry : string;
  set setInfo(String? string) =>
      _info = (string ??= Account._noEntry).isEmpty ? Account._noEntry : string;
  set setEmail(String? string) => _email =
      (string ??= Account._noEntry).isEmpty ? Account._noEntry : string;
  set setPassword(String? string) => _password =
      (string ??= Account._noEntry).isEmpty ? Account._noEntry : string;

  @override
  int compareTo(Account other) {
    return name.toLowerCase().compareTo(other.name.toLowerCase());
  }

  String asString() {
    return '$name:\n\nInfo:\n$info\n\nE-mail:\n$email\n\nPassword:\n$password';
  }

  @override
  String toString() {
    String c = Manager.disallowedCharacter;
    return '$c$tag$c$name$c$info$c$email$c$password$c';
  }
}
