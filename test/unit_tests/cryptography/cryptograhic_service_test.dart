import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:passwordmanager/engine/cryptography/datatypes.dart';
import 'package:passwordmanager/engine/cryptography/base16_codec.dart';
import 'package:passwordmanager/engine/cryptography/service.dart';

void main() {

  group('Cryptograhic service tests', () {
    test('Hashing', () {
      final Uint8List input = base16.decode('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');

      final Uint8List hash = CryptographicService.sha256(input);
      expect(base16.encode(hash), '5df6e0e2761359d30a8275058e299fcc0381534545f55cf43e41983f5d4c9456');
    });

    test('HMac calculation', () {
      final Uint8List data = utf8.encode('Text000000000000');
      final Key key = Key(base16.decode('b675000fb18fcc59b1b1878c89313bb1a8156e4acfe59c2f24d202c665016cb3'));

      final Uint8List hmac = CryptographicService.verificationCodeFrom(key, data);
      expect(base16.encode(hmac), 'e1af6b3bc73bd102b71ce8c3590c993cb902c0bc1354eebc798eb11f70af1c2e');
    });

    test('Expand method', () {
      final Uint8List list = Uint8List.fromList(List.generate(22, (index) => 0));

      final Uint8List expanded = CryptographicService.expand(list, 16);
      expect(expanded.length, 32);

      final Uint8List onceMoreExpanded = CryptographicService.expand(list, 16);
      expect(onceMoreExpanded.length, 32);
    });
  });
}