import 'package:flutter_test/flutter_test.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/local_database.dart';

void main() {
  group('Database tests', () {
    test('Is singleton', () {
      final LocalDatabase databaseRef1 = LocalDatabase();
      final LocalDatabase databaseRef2 = LocalDatabase();
      expect(databaseRef1 == databaseRef2, true);
    });

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

      database.clear();
    });

    test('Editing accounts', () {
      final LocalDatabase database = LocalDatabase();
      final Account account1 = Account(name: 'A', tag: 'A_Tag');
      final Account account2 = Account(name: 'B', tag: 'A_Tag');

      database.addAccount(account1);
      database.addAccount(account2);

      String oldTag = account1.tag;
      account1.setTag = 'B_Tag';
      database.callEditOf(oldTag, account1);
      expect(database.tags.contains('B_Tag'), true);
      expect(database.tags.contains('A_Tag'), true);
      expect(database.accounts.contains(account1), true);

      oldTag = account2.tag;
      account2.setTag = 'B_Tag';
      database.callEditOf(oldTag, account2);
      expect(database.tags.contains('B_Tag'), true);
      expect(database.tags.contains('A_Tag'), false);
      expect(database.accounts.contains(account2), true);

      database.clear();
    });

    test('Removing accounts', () {
      final LocalDatabase database = LocalDatabase();
      final Account account1 = Account(name: 'A', tag: 'A_Tag');
      final Account account2 = Account(name: 'B', tag: 'A_Tag');

      database.addAccount(account1);
      database.addAccount(account2);

      database.removeAccount(account1);
      expect(database.accounts.contains(account1), false);
      expect(database.accounts.length, 1);
      expect(database.tags.contains('A_Tag'), true);

      database.clear();
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
      notifiedOnAdd = false;
      database.addAccount(account);
      expect(notifiedOnAdd, false);
      database.removeListener(notificationAdd);

      database.addListener(notificationEdit);
      database.callEditOf('none', Account(name: 'Other'));
      expect(notifiedOnEdit, false);
      database.callEditOf('irrelevant', account);
      expect(notifiedOnEdit, true);
      database.removeListener(notificationEdit);

      database.addListener(notificationRemove);
      database.removeAccount(Account(name: 'Other'));
      expect(notifiedOnRemove, false);
      database.removeAccount(account);
      expect(notifiedOnRemove, true);
      database.removeListener(notificationRemove);

      database.clear();
    });
  });
}