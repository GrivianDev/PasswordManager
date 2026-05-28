import 'dart:typed_data';

import 'package:ethercrypt/engine/cryptography/datatypes.dart';
import 'package:ethercrypt/engine/cryptography/encryption.dart';
import 'package:ethercrypt/engine/cryptography/padding_mode.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';

/// An implementation of the AES 256 bit CBC encryption algorithm.
/// Overrides the [encrypt] and [decrypt] method of the [Encryption] interface.
final class AES256CBC implements Encryption {
  final PaddingMode padding;

  AES256CBC({this.padding = PaddingMode.none});

  Uint8List _applyPadding(Uint8List data, int blockLength) {
    switch (padding) {
      case PaddingMode.none:
        if (data.length % blockLength != 0) {
          throw Exception('Length of data must be a multiple of $blockLength bytes for AES-256 when no padding is used');
        }

        return data;

      case PaddingMode.pkcs7:
        final int pad = blockLength - (data.length % blockLength);
        final Uint8List padded = Uint8List(data.length + pad)..setAll(0, data);

        for (int i = data.length; i < padded.length; i++) {
          padded[i] = pad;
        }

        return padded;
    }
  }

  Uint8List _removePadding(Uint8List data, int blockLength) {
    switch (padding) {
      case PaddingMode.none:
        return data;

      case PaddingMode.pkcs7:
        if (data.isEmpty || data.length % blockLength != 0) {
          throw Exception('Invalid PKCS7 padded data');
        }

        final int pad = data.last;

        if (pad < 1 || pad > blockLength) {
          throw Exception('Invalid PKCS7 padding');
        }

        for (int i = data.length - pad; i < data.length; i++) {
          if (data[i] != pad) {
            throw Exception('Invalid PKCS7 padding');
          }
        }

        return Uint8List.sublistView(data, 0, data.length - pad);
    }
  }

  /// Plain data is encrypted using a 256 bit key. Requires an iv of length 16 and key of length 32.
  /// Additionally, the datas length must be a multiple of 16 if no padding is used.
  @override
  Uint8List encrypt({required Uint8List data, required Uint8List key, required IV iv}) {
    if (key.length != keyLength) throw Exception('Expected key length for AES-256 is 32 bytes but got ${key.length} bytes');
    if (iv.length != blockLength) throw Exception('Length of iv must be 16 bytes for AES but got ${iv.length} bytes');

    final Uint8List padded = _applyPadding(data, blockLength);
    final CBCBlockCipher cbc = CBCBlockCipher(AESEngine())..init(true, ParametersWithIV(KeyParameter(key), iv.bytes));
    final Uint8List cipher = Uint8List(padded.length);

    int offset = 0;
    while (offset < padded.length) {
      offset += cbc.processBlock(padded, offset, cipher, offset);
    }

    return cipher;
  }

  /// Plain data is decrypted using a 256 bit key. Requires an iv of length 16 and key of length 32.
  /// Additionally, the cipher length must inheritely be a multiple of 16.
  @override
  Uint8List decrypt({required Uint8List cipher, required Uint8List key, required IV iv}) {
    if (key.length != keyLength) throw Exception('Expected key length for AES-256 is 32 bytes but got ${key.length} bytes');
    if (iv.length != blockLength) throw Exception('Length of iv must be 16 bytes for AES but got ${iv.length} bytes');
    if (cipher.length % blockLength != 0) throw Exception('Length of cipher must be a multiple of 16 bytes for AES');

    final CBCBlockCipher cbc = CBCBlockCipher(AESEngine())..init(false, ParametersWithIV(KeyParameter(key), iv.bytes));
    final Uint8List padded = Uint8List(cipher.length);

    int offset = 0;
    while (offset < cipher.length) {
      offset += cbc.processBlock(cipher, offset, padded, offset);
    }

    return _removePadding(padded, blockLength);
  }

  @override
  int get blockLength => 16;

  @override
  int get keyLength => 32;
}
