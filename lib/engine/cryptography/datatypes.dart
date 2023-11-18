import 'dart:convert';
import 'dart:typed_data';
import 'package:passwordmanager/engine/cryptography/service.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';

class Key {
  final Uint8List bytes;
  final Uint8List? salt;

  const Key(this.bytes, this.salt);

  static Uint8List _generateKey(String passphrase, Uint8List salt, int length) {
    const int iterations = 4096;

    final Pbkdf2Parameters params = Pbkdf2Parameters(salt, iterations, length);
    final PBKDF2KeyDerivator pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(params);

    final Uint8List key = pbkdf2.process(utf8.encode(passphrase));
    return key;
  }

  factory Key.createSecure(String passphrase, int length) {
    final Uint8List salt = CryptograhicService.randomBytes(length);

    final Uint8List key = _generateKey(passphrase, salt, length);
    return Key(key, salt);
  }

  factory Key.recreate(String passphrase, Uint8List salt, int length) {
    final Uint8List key = _generateKey(passphrase, salt, length);
    return Key(key, salt);
  }

  int get length => bytes.length;
}

class IV {
  final Uint8List bytes;

  const IV(this.bytes);

  factory IV.allZero(int length) => IV(Uint8List.fromList(List.filled(length, 0)));

  factory IV.fromLength(int length) => IV(CryptograhicService.randomBytes(length));

  int get length => bytes.length;
}