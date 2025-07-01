import 'dart:typed_data';
import 'package:passwordmanager/engine/cryptography/service.dart';

/// Datatype for containing the bytes for a key used in cryptography. May additionally hold the salt used for generating said key.
/// Intern generation method for keys uses PBKDF2 as key derivation function with 4096 iterations.
/// The algorithm for the generation is SHA-256.
class Key {
  final Uint8List bytes;
  final Uint8List? salt;

  const Key(this.bytes, [this.salt]);

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