import 'dart:convert';
import 'dart:typed_data';
import 'package:passwordmanager/engine/cryptography/service.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';

/// Datatype for containing the bytes for a key used in cryptography. May additionally hold the salt used for generating said key.
/// Intern generation method for keys uses PBKDF2 as key derivation function with 4096 iterations.
/// The algorithm for the generation is SHA-256.
class Key {
  final Uint8List bytes;
  final Uint8List? salt;

  const Key(this.bytes, [this.salt]);

  static Uint8List _generateKey(String passphrase, Uint8List salt, int length) {
    const int iterations = 4096;

    final Pbkdf2Parameters params = Pbkdf2Parameters(salt, iterations, length);
    final PBKDF2KeyDerivator pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(params);

    final Uint8List key = pbkdf2.process(utf8.encode(passphrase));
    return key;
  }

  /// Creates a secure key of provided length based on the input passphrase. Might take a moment for generation.
  factory Key.createSecure(String passphrase, int length) {
    final Uint8List salt = CryptographicService.randomBytes(length);

    final Uint8List key = _generateKey(passphrase, salt, length);
    return Key(key, salt);
  }

  /// Recreate a key with the additional salt value. Might take a moment for generation.
  factory Key.recreate(String passphrase, Uint8List salt, int length) {
    final Uint8List key = _generateKey(passphrase, salt, length);
    return Key(key, salt);
  }

  int get length => bytes.length;
}

/// An initialisation vector
class IV {
  final Uint8List bytes;

  const IV(this.bytes);

  /// An iv with only zeros. NOT CRYPTOGRAPHYCLY SECURE!
  factory IV.allZero(int length) => IV(Uint8List.fromList(List.filled(length, 0)));

  /// A randomly generated iv,
  factory IV.fromLength(int length) => IV(CryptographicService.randomBytes(length));

  int get length => bytes.length;
}