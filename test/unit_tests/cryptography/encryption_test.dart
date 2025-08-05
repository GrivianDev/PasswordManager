import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:passwordmanager/engine/cryptography/datatypes.dart';
import 'package:passwordmanager/engine/cryptography/implementation/aes_encryption.dart';
import 'package:passwordmanager/engine/cryptography/encryption.dart';
import 'package:passwordmanager/engine/cryptography/base16_codec.dart';

void main() {

  group('Encryption tests', () {
    test('Valid AES-256 CBC encryption and decryption', () {
      final Uint8List data = utf8.encode('Text000000000000'); // 54657874303030303030303030303030
      final Encryption algorithm = AES256();

      final Key key = Key(base16.decode('b675000fb18fcc59b1b1878c89313bb1a8156e4acfe59c2f24d202c665016cb3'), base16.decode('1625189bdac15f359459c4ab2a2fc5fe9973cf022a657849db9898d5b663aa62'));
      final IV iv = IV(base16.decode('bacacb27ba02dae4a257f6804a030eeb'));

      final Uint8List cipher = algorithm.encrypt(data: data, key: key.bytes, iv: iv);

      final Uint8List recovered = algorithm.decrypt(cipher: cipher, key: key.bytes, iv: iv);

      expect(recovered, data);
      expect(base16.encode(cipher), '43e7883d441339e0dc58d0686b04f021');
    });
  });
}