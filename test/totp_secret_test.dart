import 'package:flutter_test/flutter_test.dart';
import 'package:ethercrypt/engine/two_factor_token.dart';

void main() {
  group('TOTPSecret Constructor', () {
    test('Create valid instance with minimal required fields', () {
      final secret = TOTPSecret(
        issuer: 'TEST_ISSUER',
        accountName: 'TEST_ACCOUNT',
        secret: 'FFFFFFFF',
      );

      expect(secret.issuer, 'TEST_ISSUER');
      expect(secret.accountName, 'TEST_ACCOUNT');
      expect(secret.algorithm, TOTPSecret.defaultAlgorithm);
      expect(secret.period, TOTPSecret.defaultPeriod);
      expect(secret.digits, TOTPSecret.defaultDigit);
    });

    test('Throws on unsupported algorithm', () {
      expect(
        () => TOTPSecret(
          issuer: 'TEST_ISSUER',
          accountName: 'TEST_ACCOUNT',
          secret: 'FFFFFFFF',
          algorithm: 'INVALID_ALGO',
        ),
        throwsArgumentError,
      );
    });

    test('Throws on invalid period', () {
      expect(
        () => TOTPSecret(
          issuer: 'TEST_ISSUER',
          accountName: 'TEST_ACCOUNT',
          secret: 'FFFFFFFF',
          period: 0,
        ),
        throwsArgumentError,
      );

      expect(
        () => TOTPSecret(
          issuer: 'TEST_ISSUER',
          accountName: 'TEST_ACCOUNT',
          secret: 'FFFFFFFF',
          period: -1,
        ),
        throwsArgumentError,
      );
    });

    test('Throws on invalid base32 secret', () {
      expect(
        () => TOTPSecret(
          issuer: 'TEST_ISSUER',
          accountName: 'TEST_ACCOUNT',
          secret: '!!!INVALID!!!',
        ),
        throwsArgumentError,
      );
    });
  });

  group('Base32 normalization', () {
    test('Normalizes lowercase and spaces', () {
      final secret = TOTPSecret(
        issuer: 'TEST_ISSUER',
        accountName: 'TEST_ACCOUNT',
        secret: 'kru gkidr ovuwg2',
      );

      expect(secret.secret, isNotEmpty);
      expect(secret.secret.contains(' '), false);
    });

    test('Adds correct padding', () {
      final secret = TOTPSecret(
        issuer: 'TEST_ISSUER',
        accountName: 'TEST_ACCOUNT',
        secret: 'ME',
      );

      expect(secret.secret.endsWith('='), true);
    });
  });

  group('JSON serialization', () {
    test('toJson and fromJson round-trip', () {
      final original = TOTPSecret(
        issuer: 'TEST_ISSUER',
        accountName: 'TEST_ACCOUNT',
        secret: 'ME',
      );

      final restored = TOTPSecret.fromJson(original.toJson());

      expect(restored.issuer, original.issuer);
      expect(restored.accountName, original.accountName);
      expect(restored.algorithm, original.algorithm);
      expect(restored.period, original.period);
      expect(restored.digits, original.digits);
    });

    test('Applies defaults from missing JSON fields', () {
      final json = {
        'issuer': 'TEST_ISSUER',
        'accountName': 'TEST_ACCOUNT',
        'secret': 'ME',
      };

      final secret = TOTPSecret.fromJson(json);

      expect(secret.algorithm, TOTPSecret.defaultAlgorithm);
      expect(secret.period, TOTPSecret.defaultPeriod);
      expect(secret.digits, TOTPSecret.defaultDigit);
    });
  });

  group('Factory fromUri parsing', () {
    test('parses valid otpauth URI', () {
      final uri = 'otpauth://totp/ISSUER:ACCOUNT?secret=ME======&issuer=ISSUER';

      final secret = TOTPSecret.fromUri(uri);

      expect(secret.issuer, equals('ISSUER'));
      expect(secret.accountName, equals('ACCOUNT'));
      expect(secret.secret, equals('ME======'));
    });

    test('Throws on missing secret', () {
      final uri = 'otpauth://totp/ISSUER:ACCOUNT?issuer=ISSUER';

      expect(
        () => TOTPSecret.fromUri(uri),
        throwsFormatException,
      );
    });

    test('Throws on invalid label format', () {
      final uri = 'otpauth://totp/INVALID_LABEL?secret=PLACEHOLDER';

      expect(
        () => TOTPSecret.fromUri(uri),
        throwsFormatException,
      );
    });

    test('Maps SHA256 algorithm correctly', () {
      final uri = 'otpauth://totp/ISSUER:ACCOUNT?secret=PLACEHOLDER&algorithm=SHA256';
      final secret = TOTPSecret.fromUri(uri);

      expect(secret.algorithm, 'SHA-256');
    });

    test('Defaults unknown algorithm to SHA-1', () {
      final uri = 'otpauth://totp/ISSUER:ACCOUNT?secret=PLACEHOLDER&algorithm=UNKNOWN';
      final secret = TOTPSecret.fromUri(uri);

      expect(secret.algorithm, TOTPSecret.defaultAlgorithm);
    });
  });

  group('Method getAuthUrl', () {
    test('Generates valid otpauth url structure', () {
      final secret = TOTPSecret(
        issuer: 'TEST_ISSUER',
        accountName: 'TEST_ACCOUNT',
        secret: 'ME',
      );

      final url = secret.getAuthUrl();

      expect(url, contains('otpauth://totp/'));
      expect(url, contains('secret='));
      expect(url, contains('issuer='));
    });

    test('algorithm normalization removes dash', () {
      final secret = TOTPSecret(
        issuer: 'TEST_ISSUER',
        accountName: 'TEST_ACCOUNT',
        secret: 'ME',
        algorithm: 'SHA-256',
      );

      final url = secret.getAuthUrl();

      expect(url.contains('SHA256'), isTrue);
    });
  });

  group('TOTP generation', () {
    test('Produces stable output for fixed timestamp', () {
      final secret = TOTPSecret(
        issuer: 'TEST_ISSUER',
        accountName: 'TEST_ACCOUNT',
        secret: 'ME',
      );

      final timestamp = DateTime.utc(2025, 1, 1, 0, 0, 0);

      final code1 = secret.generateTOTPCode(timestamp: timestamp);
      final code2 = secret.generateTOTPCode(timestamp: timestamp);

      expect(code1, code2); // deterministic check
    });

    test('Returns correct digit length', () {
      final secret = TOTPSecret(
        issuer: 'TEST',
        accountName: 'TEST',
        secret: 'ME',
        digits: 6,
      );

      final code = secret.generateTOTPCode(
        timestamp: DateTime.utc(2025, 1, 1),
      );

      expect(code.length, 6);
    });
  });
}