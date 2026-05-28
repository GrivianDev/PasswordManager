import 'dart:convert';
import 'dart:typed_data';

import 'package:ethercrypt/engine/cryptography/base16_codec.dart';
import 'package:ethercrypt/engine/cryptography/datatypes.dart';
import 'package:ethercrypt/engine/cryptography/encryption.dart';
import 'package:ethercrypt/engine/cryptography/implementation/aes_encryption.dart';
import 'package:ethercrypt/engine/cryptography/padding_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Encryption tests', () {
    test('Valid AES-256 CBC encryption and decryption - No Padding', () {
      final Uint8List data = utf8.encode('Text000000000000'); // 54657874303030303030303030303030
      final Encryption algorithm = AES256CBC(padding: PaddingMode.none);

      final Key key = Key(base16.decode('b675000fb18fcc59b1b1878c89313bb1a8156e4acfe59c2f24d202c665016cb3'), Uint8List.fromList([]));
      final IV iv = IV(base16.decode('bacacb27ba02dae4a257f6804a030eeb'));

      final Uint8List cipher = algorithm.encrypt(data: data, key: key.bytes, iv: iv);

      final Uint8List recovered = algorithm.decrypt(cipher: cipher, key: key.bytes, iv: iv);

      expect(recovered, data);
      expect(base16.encode(cipher), '43e7883d441339e0dc58d0686b04f021');
    });

    test('Valid AES-256 CBC encryption and decryption - PKCS#7 Padding', () {
      final Uint8List data = utf8.encode('Text');
      final Encryption algorithm = AES256CBC(padding: PaddingMode.pkcs7);

      final Key key = Key(base16.decode('b675000fb18fcc59b1b1878c89313bb1a8156e4acfe59c2f24d202c665016cb3'), Uint8List.fromList([]));
      final IV iv = IV(base16.decode('bacacb27ba02dae4a257f6804a030eeb'));

      final Uint8List cipher = algorithm.encrypt(data: data, key: key.bytes, iv: iv);

      final Uint8List recovered = algorithm.decrypt(cipher: cipher, key: key.bytes, iv: iv);

      expect(recovered, data);
    });
  });
}
