import 'package:ethercrypt/engine/db/accessors/accessor.dart';
import 'package:ethercrypt/engine/db/accessors/version/accessor_v0.dart';
import 'package:ethercrypt/engine/db/accessors/version/accessor_v1.dart';
import 'package:ethercrypt/engine/db/database_content.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utility.dart';

const String testPassword = 'testpassword123';

void main() {
  group('Accessor integrity', () {
    test('Accessor v0', () async {
      final DataAccessor accessor = DataAccessorV0()..setPassword(testPassword);

      final DatabaseContent content = createTestDatabaseContentV0();
      final Map<String, String> properties = await accessor.pack(content);
      final DatabaseContent unpackedContent = await accessor.unpack(properties);
      expect(compareDatabaseContent(content, unpackedContent), true);
    });

    test('Accessor v1', () async {
      final DataAccessor accessor = DataAccessorV1()..setPassword(testPassword);

      final DatabaseContent content = createTestDatabaseContentV1();
      final Map<String, String> properties = await accessor.pack(content);
      final DatabaseContent unpackedContent = await accessor.unpack(properties);
      expect(compareDatabaseContent(content, unpackedContent), true);
    });
  });
}
