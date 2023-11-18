import 'package:flutter_test/flutter_test.dart';
import 'package:passwordmanager/engine/account.dart';

void main() {
  group('Account tests', () {
    test('Account indirect setters', () {
      final Account account = Account(name: null, email: '', info: 'test');
      expect(account.name, 'none');
      expect(account.email, 'none');
      expect(account.info, 'test');
      expect(account.tag, 'none');
      expect(account.password, 'none');
    });

    test('Account sorting', () {
      final List<Account> list = [Account(name: 'b'), Account(name: 'A'), Account(name: 'c')];
      list.sort();
      expect(list.map((e) => e.name), ['A','b','c']);
    });

    test('To formatted string', () {
      final Account account = Account(name: 'name', tag: 'tag', info: 'info', email: 'email', password: 'password');
      const String c = '\u0407';
      expect(account.toString(), '${c}tag${c}name${c}info${c}email${c}password$c');
    });
  });
}