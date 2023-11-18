import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/digests/sha256.dart';

import 'datatypes.dart';

final class CryptograhicService {
  static Uint8List expand(Uint8List data, int blocksize) {
    if(data.isEmpty) {
      return randomBytes(blocksize);
    } else {
      final int diff = (blocksize - (data.length % blocksize)) % blocksize;
      final Uint8List filler = randomBytes(diff);
      return Uint8List.fromList([...data, ...filler]);
    }
  }

  static Uint8List randomBytes(final int length) {
    final Random random = Random.secure();
    return Uint8List.fromList(List.generate(length, (index) => random.nextInt(0xff)));
  }

  static Key createAES256Key({required String password}) => Key.createSecure(password, 32);

  static Key recreateAES256Key({required String password, required Uint8List salt}) {
    return Key.recreate(password, salt, 32);
  }

  static Uint8List verificationCodeFrom(Key key, Uint8List data) {
    final HMac hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(key.bytes));
    final Uint8List verificationCode = hmac.process(data);
    return verificationCode;
  }

  static Uint8List sha256(Uint8List data) {
    return SHA256Digest().process(data);
  }
}