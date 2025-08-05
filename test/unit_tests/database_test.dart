import 'package:flutter_test/flutter_test.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/db/local_database.dart';

void main() {
  group('Database tests', () {
    test('Adding accounts', () {
      final LocalDatabase database = LocalDatabase();
      final Account account1 = Account(name: 'A', tag: 'A_Tag');
      final Account account2 = Account(name: 'B', tag: 'A_Tag');
      expect(database.accounts.isEmpty, true);
      expect(database.tags.isEmpty, true);

      database.addAccount(account1);
      expect(database.accounts.contains(account1), true);
      expect(database.accounts.length, 1);
      expect(database.tags.contains('A_Tag'), true);

      database.addAccount(account2);
      expect(database.accounts.contains(account2), true);
      expect(database.accounts.length, 2);
      expect(database.tags.contains('A_Tag') && database.tags.length == 1, true);
    });

    test('Editing accounts', () {
      final LocalDatabase database = LocalDatabase();
      final Account account1 = Account(name: 'A', tag: 'A_Tag');
      final Account account2 = Account(name: 'B', tag: 'A_Tag');

      database.addAccount(account1);
      database.addAccount(account2);

      account1.tag = 'B_Tag';
      database.replaceAccount(account1.id, account1);
      expect(database.tags.contains('B_Tag'), true);
      expect(database.tags.contains('A_Tag'), true);
      expect(database.accounts.contains(account1), true);

      account2.tag = 'B_Tag';
      database.replaceAccount(account2.id, account2);
      expect(database.tags.contains('B_Tag'), true);
      expect(database.tags.contains('A_Tag'), false);
      expect(database.accounts.contains(account2), true);
    });

    test('Removing accounts', () {
      final LocalDatabase database = LocalDatabase();
      final Account account1 = Account(name: 'A', tag: 'A_Tag');
      final Account account2 = Account(name: 'B', tag: 'A_Tag');

      database.addAccount(account1);
      database.addAccount(account2);

      database.removeAccount(account1.id);
      expect(database.accounts.contains(account1), false);
      expect(database.accounts.length, 1);
      expect(database.tags.contains('A_Tag'), true);
    });

    test('Notifications', () {
      final LocalDatabase database = LocalDatabase();
      final Account account = Account(name: 'A');

      bool notifiedOnAdd = false;
      void notificationAdd() {
        notifiedOnAdd = true;
      }
      bool notifiedOnEdit = false;
      void notificationEdit() {
        notifiedOnEdit = true;
      }
      bool notifiedOnRemove = false;
      void notificationRemove() {
        notifiedOnRemove = true;
      }

      database.addListener(notificationAdd);
      database.addAccount(account);
      expect(notifiedOnAdd, true);
      database.removeListener(notificationAdd);

      database.addListener(notificationEdit);
      database.replaceAccount(999999, Account(name: 'Other'));
      expect(notifiedOnEdit, false);
      database.removeListener(notificationEdit);

      database.addListener(notificationRemove);
      database.removeAccount(Account(name: 'Other').id);
      expect(notifiedOnRemove, false);
      database.removeAccount(account.id);
      expect(notifiedOnRemove, true);
      database.removeListener(notificationRemove);
    });
  });
}