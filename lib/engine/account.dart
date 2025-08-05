import 'package:passwordmanager/engine/two_factor_token.dart';

/// Core class that holds information about an account.
/// Implements the [Comparable] interface. The natural order of
/// instances is the lowercase alphabetical order.
final class Account implements Comparable<Account> {
  static int _idCounter = 0;
  final int id;

  String? tag;
  String? name;
  String? info;
  String? email;
  String? password;
  TOTPSecret? twoFactorSecret;

  Account({
      this.tag,
      this.name,
      this.info,
      this.email,
      this.password,
      this.twoFactorSecret
  }) : id = ++_idCounter;

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      tag: json['tag'] as String?,
      name: json['name'] as String?,
      info: json['info'] as String?,
      email: json['email'] as String?,
      password: json['password'] as String?,
      twoFactorSecret: json['twoFactorSecret'] != null
          ? TOTPSecret.fromJson(json['twoFactorSecret'])
          : null,
    );
  }

  @override
  int compareTo(Account other) {
    if (name == null && other.name == null) return 0;
    if (name == null) return 1; // null > non-null => nulls last
    if (other.name == null) return -1;

    return name!.toLowerCase().compareTo(other.name!.toLowerCase());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    void add(String key, dynamic value) {
      if (value != null) data[key] = value;
    }

    add('tag', tag);
    add('name', name);
    add('info', info);
    add('email', email);
    add('password', password);
    add('twoFactorSecret', twoFactorSecret?.toJson());
    return data;
  }

  /// Returns a format that is human readable.
  @override
  String toString() {
    return 'Account(tag=$tag, name=$name, info=$info, email=$email, password=$password), twoFactorSecret=$twoFactorSecret';
  }
}
