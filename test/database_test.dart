import 'package:ethercrypt/engine/account.dart';
import 'package:ethercrypt/engine/db/local_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalDatabase', () {
    group('Adding accounts', () {
      test('Add account and registers tag', () {
        final database = LocalDatabase();
        final account = Account(name: 'A', tag: 'A_Tag');

        database.addAccount(account);

        expect(database.accounts.contains(account), true);
        expect(database.accounts.length, 1);
        expect(database.tags, contains('A_Tag'));
      });

      test('Does not duplicate tags', () {
        final database = LocalDatabase();
        final account1 = Account(name: 'A', tag: 'A_Tag');
        final account2 = Account(name: 'B', tag: 'A_Tag');

        database.addAccount(account1);
        database.addAccount(account2);

        expect(database.tags.length, 1);
        expect(database.tags, contains('A_Tag'));
      });

      test('Handles multiple accounts with different tags', () {
        final database = LocalDatabase();
        final account1 = Account(name: 'A', tag: 'A_Tag');
        final account2 = Account(name: 'B', tag: 'B_Tag');

        database.addAccount(account1);
        database.addAccount(account2);

        expect(database.tags.length, 2);
        expect(database.tags, containsAll(['A_Tag', 'B_Tag']));
      });
    });

    group('Replacing accounts', () {
      test('Updates tag correctly', () {
        final database = LocalDatabase();
        final account = Account(name: 'A', tag: 'A_Tag');

        database.addAccount(account);

        account.tag = 'B_Tag';
        database.replaceAccount(account.id, account);

        expect(database.tags, contains('B_Tag'));
        expect(database.tags, isNot(contains('A_Tag')));
      });
      test('Removes unused old tag after update', () {
        final database = LocalDatabase();
        final account1 = Account(name: 'A', tag: 'A_Tag');
        final account2 = Account(name: 'B', tag: 'B_Tag');

        database.addAccount(account1);
        database.addAccount(account2);

        account2.tag = 'A_Tag';
        database.replaceAccount(account2.id, account2);

        expect(database.tags, contains('A_Tag'));
        expect(database.tags, isNot(contains('B_Tag')));
      });

      test('Does nothing when id does not exist', () {
        final database = LocalDatabase();
        final account = Account(name: 'A', tag: 'A_Tag');

        database.replaceAccount(999999, account);

        expect(database.accounts.isEmpty, true);
        expect(database.tags.isEmpty, true);
      });
    });

    group('Removing accounts', () {
      test('Remove account', () {
        final database = LocalDatabase();
        final account = Account(name: 'A', tag: 'A_Tag');

        database.addAccount(account);
        database.removeAccount(account.id);

        expect(database.accounts.contains(account), false);
        expect(database.accounts.isEmpty, true);
      });

      test('Keeps tag if still used', () {
        final database = LocalDatabase();
        final account1 = Account(name: 'A', tag: 'A_Tag');
        final account2 = Account(name: 'B', tag: 'A_Tag');

        database.addAccount(account1);
        database.addAccount(account2);

        database.removeAccount(account1.id);

        expect(database.tags, contains('A_Tag'));
      });

      test('Removes tag if no longer used', () {
        final database = LocalDatabase();
        final account = Account(name: 'A', tag: 'A_Tag');

        database.addAccount(account);
        database.removeAccount(account.id);

        expect(database.tags.contains('A_Tag'), false);
      });

      test('Safe on remove unknown id', () {
        final database = LocalDatabase();

        expect(() => database.removeAccount(123456), returnsNormally);
      });
    });
  });
}
