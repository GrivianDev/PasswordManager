import 'dart:typed_data';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:passwordmanager/engine/cryptography/datatypes.dart';
import 'package:passwordmanager/engine/cryptography/encryption.dart';

/// An implementation of the AES 256 bit encryption algorithm.
/// Overrides the [encrypt] and [decrypt] method of the [Encryption] interface.
final class AES256 implements Encryption {

  /// Plain data is encrypted using a 256 bit key.
  @override
  Uint8List encrypt({required Uint8List data, required Key key, required IV iv}) {
    if(key.length != 32) throw Exception('Expected key length for AES-256 is 32 bytes but got ${key.length} bytes');
    if(iv.length != 16) throw Exception('Length of iv must be 16 bytes for AES but got ${iv.length} bytes');
    if(data.length % 16 != 0) throw Exception('Length of data must be a multiple of 16 bytes for AES');

    final CBCBlockCipher cbc = CBCBlockCipher(AESEngine())..init(true, ParametersWithIV(KeyParameter(key.bytes), iv.bytes));
    final Uint8List cipher = Uint8List(data.length);

    int offset = 0;
    while (offset < data.length) {
      offset += cbc.processBlock(data, offset, cipher, offset);
    }

    return cipher;
  }

  /// Plain data is decrypted using a 256 bit key.
  @override
  Uint8List decrypt({required Uint8List cipher, required Key key, required IV iv}) {
    if(key.length != 32) throw Exception('Expected key length for AES-256 is 32 bytes but got ${key.length} bytes');
    if(iv.length != 16) throw Exception('Length of iv must be 16 bytes for AES but got ${iv.length} bytes');
    if(cipher.length % 16 != 0) throw Exception('Length of cipher must be a multiple of 16 bytes for AES');

    final CBCBlockCipher cbc = CBCBlockCipher(AESEngine())..init(false, ParametersWithIV(KeyParameter(key.bytes), iv.bytes));
    final Uint8List data = Uint8List(cipher.length);

    int offset = 0;
    while (offset < cipher.length) {
      offset += cbc.processBlock(cipher, offset, data, offset);
    }

    return data;
  }
}