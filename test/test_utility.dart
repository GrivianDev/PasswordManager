import 'package:ethercrypt/engine/account.dart';
import 'package:ethercrypt/engine/db/database_content.dart';
import 'package:ethercrypt/engine/two_factor_token.dart';

DatabaseContent createTestDatabaseContentV1() {
  return DatabaseContent(
    accounts: [
      Account(
        tag: 'personal',
        name: 'GitHub',
        info: 'Dev account',
        email: 'alice@github.com',
        password: 'pass123',
        twoFactorSecret: TOTPSecret(
          issuer: 'GitHub',
          accountName: 'alice@github.com',
          secret: 'JBSWY3DPEHPK3PXP',
        ),
      ),
      Account(
        tag: 'work',
        name: 'Google',
        info: 'Work account',
        email: 'alice@company.com',
        password: 'securePass!',
        twoFactorSecret: TOTPSecret(
          issuer: 'Google',
          accountName: 'alice@company.com',
          secret: 'KRSXG5DSMFZWE===',
          algorithm: 'SHA-256',
          period: 30,
          digits: 6,
        ),
      ),
      Account(
        tag: 'bank',
        name: 'Bank App',
        info: 'Finance account',
        email: 'alice@bank.com',
        password: 'verySecure!',
        twoFactorSecret: null,
      ),
      Account(
        tag: 'social',
        name: 'Twitter/X',
        info: 'Social media',
        email: 'alice@social.com',
        password: 'tweetpass',
        twoFactorSecret: TOTPSecret(
          issuer: 'X',
          accountName: 'alice@social.com',
          secret: 'MZXW6YTBOI======',
          algorithm: 'SHA-1',
          period: 30,
          digits: 6,
        ),
      ),
    ],
  );
}

DatabaseContent createTestDatabaseContentV0() {
  return DatabaseContent(
    accounts: [
      Account(
        tag: 'personal',
        name: 'GitHub',
        info: 'Dev account',
        email: 'alice@github.com',
        password: 'pass123',
        twoFactorSecret: null,
      ),
      Account(
        tag: 'work',
        name: 'Google',
        info: 'Work account',
        email: 'alice@company.com',
        password: 'securePass!',
        twoFactorSecret: null,
      ),
      Account(
        tag: 'bank',
        name: 'Bank App',
        info: 'Finance account',
        email: 'alice@bank.com',
        password: 'verySecure!',
        twoFactorSecret: null,
      ),
      Account(
        tag: 'social',
        name: 'Twitter/X',
        info: 'Social media',
        email: 'alice@social.com',
        password: 'tweetpass',
        twoFactorSecret: null,
      ),
    ],
  );
}

bool compareTOTPSecret(TOTPSecret a, TOTPSecret b) {
  return a.issuer == b.issuer && a.accountName == b.accountName && a.secret == b.secret && a.algorithm == b.algorithm && a.period == b.period && a.digits == b.digits;
}

bool compareAccounts(Account a, Account b) {
  return a.tag == b.tag &&
      a.name == b.name &&
      a.info == b.info &&
      a.email == b.email &&
      a.password == b.password &&
      ((a.twoFactorSecret == null && b.twoFactorSecret == null) || (a.twoFactorSecret != null && b.twoFactorSecret != null && compareTOTPSecret(a.twoFactorSecret!, b.twoFactorSecret!)));
}

bool compareDatabaseContent(DatabaseContent a, DatabaseContent b) {
  final x = a.accounts;
  final y = b.accounts;

  if (x.length != y.length) return false;

  for (int i = 0; i < x.length; i++) {
    if (!compareAccounts(x[i], y[i])) {
      return false;
    }
  }

  return true;
}
