import 'dart:typed_data';
import 'package:pointycastle/api.dart';
import 'package:passwordmanager/engine/cryptography/datatypes.dart';
import 'package:passwordmanager/engine/cryptography/encryption.dart';
import 'package:pointycastle/block/modes/sic.dart';

class LegacyAES256Decrypter implements Encryption {
  @override
  Uint8List encrypt({required Uint8List data, required Key key, required IV iv}) {
    throw UnsupportedError('Do not encrypt via this method');
  }

  @override
  Uint8List decrypt({required Uint8List cipher, required Key key, required IV iv}) {
    if(key.length != 32) throw Exception('Expected key length for AES-256 is 32 bytes but got ${key.length} bytes');
    if(iv.length != 16) throw Exception('Length of iv must be 16 bytes for AES but got ${iv.length} bytes');
    if(cipher.length % 16 != 0) throw Exception('Length of cipher must be a multiple of 16 bytes for AES');

    final SICBlockCipher sic = SICBlockCipher(16, StreamCipher('AES/SIC'))..init(false, ParametersWithIV(KeyParameter(key.bytes), iv.bytes));
    final Uint8List data = Uint8List(cipher.length);

    int offset = 0;
    while (offset < cipher.length) {
      offset += sic.processBlock(cipher, offset, data, offset);
    }

    return data;
  }}