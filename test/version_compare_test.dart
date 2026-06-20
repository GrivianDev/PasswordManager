import 'package:ethercrypt/engine/updates/version_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VersionUtils', () {
    group('compare', () {
      test('Returns 0 for identical versions', () {
        expect(VersionUtils.compare('1.2.3', '1.2.3'), 0);
      });

      test('Returns positive value when version is newer', () {
        expect(VersionUtils.compare('1.2.4', '1.2.3'), greaterThan(0));
      });

      test('Returns negative value when version is older', () {
        expect(VersionUtils.compare('1.2.3', '1.2.4'), lessThan(0));
      });

      test('Handles different segment counts', () {
        expect(VersionUtils.compare('1.0', '1.0.0'), 0);
      });

      test('Handles major version differences', () {
        expect(VersionUtils.compare('2.0.0', '1.9.9'), greaterThan(0));
      });

      test('Handles multi-digit segments correctly', () {
        expect(VersionUtils.compare('1.10.0', '1.2.0'), greaterThan(0));
      });

      test('Treats missing segments as zero', () {
        expect(VersionUtils.compare('1.2', '1.2.0.0'), 0);
      });

      test('Treats invalid segments as zero', () {
        expect(VersionUtils.compare('1.a.0', '1.0.0'), 0);
      });
    });

    group('isGreater', () {
      test('Returns true when version is newer', () {
        expect(VersionUtils.isGreater('1.2.4', '1.2.3'), true);
      });

      test('Returns false when version is older', () {
        expect(VersionUtils.isGreater('1.2.3', '1.2.4'), false);
      });

      test('Returns false when versions are equal', () {
        expect(VersionUtils.isGreater('1.2.3', '1.2.3'), false);
      });
    });

    group('isLess', () {
      test('Returns true when version is older', () {
        expect(VersionUtils.isLess('1.2.3', '1.2.4'), true);
      });

      test('Returns false when version is newer', () {
        expect(VersionUtils.isLess('1.2.4', '1.2.3'), false);
      });

      test('Returns false when versions are equal', () {
        expect(VersionUtils.isLess('1.2.3', '1.2.3'), false);
      });
    });

    group('isEqual', () {
      test('Returns true for identical versions', () {
        expect(VersionUtils.isEqual('1.2.3', '1.2.3'), true);
      });

      test('Returns true when only trailing zeros differ', () {
        expect(VersionUtils.isEqual('1.0', '1.0.0'), true);
      });

      test('Returns false for different versions', () {
        expect(VersionUtils.isEqual('1.2.3', '1.2.4'), false);
      });
    });
  });
}
