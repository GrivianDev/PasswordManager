import 'package:ethercrypt/engine/db/accessors/accessor.dart';
import 'package:ethercrypt/engine/db/accessors/version/accessor_v0.dart';
import 'package:ethercrypt/engine/db/accessors/version/accessor_v1.dart';
import 'package:ethercrypt/engine/db/database_content.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utility.dart';

const String testPassword = 'testpassword123';

void main() {
  group('Accessor migration', () {
    test('Accessor v0 -> v1', () async {
      final DataAccessor accessorV0 = DataAccessorV0()..setPassword(testPassword);
      final DataAccessor accessorV1 = DataAccessorV1()..setPassword(testPassword);

      final DatabaseContent original = createTestDatabaseContentV0();
      final Map<String, String> propertiesV0 = await accessorV0.pack(original);
      final DatabaseContent deserializedV0 = await accessorV0.unpack(propertiesV0);

      final Map<String, String> propertiesV1 = await accessorV1.pack(deserializedV0);
      final DatabaseContent deserializedV1 = await accessorV1.unpack(propertiesV1);

      expect(compareDatabaseContent(original, deserializedV1), true);
    });
  });
}
