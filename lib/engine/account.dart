import 'package:ethercrypt/engine/two_factor_token.dart';

/// Core class that holds information about an account.
final class Account {
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
