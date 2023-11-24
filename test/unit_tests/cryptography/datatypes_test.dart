import 'package:flutter_test/flutter_test.dart';
import 'package:passwordmanager/engine/cryptography/datatypes.dart';
import 'package:passwordmanager/engine/cryptography/base16_codec.dart';

void main() {

  group('Datatypes', () {
    test('Key generation', () {
      final Key key = Key.createSecure('Text000000000000', 32);
      final Key recreatedKey = Key.recreate('Text000000000000', key.salt!, 32);

      expect(base16.encode(recreatedKey.bytes), base16.encode(key.bytes));
      expect(key.bytes.length == key.salt!.length, true);
      expect(key.length, 32);
    });

    test('IV generation', () {
      final IV iv = IV.fromLength(16);
      expect(iv.length, 16);

      final IV other = IV.allZero(16);
      expect(other.bytes.any((element) => element != 0), false);
    });
  });
}