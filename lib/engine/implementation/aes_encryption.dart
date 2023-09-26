import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:passwordmanager/engine/encryption.dart';
import 'package:passwordmanager/engine/implementation/hashing.dart';

/// An implementation of the AES 256 bit encryption algorithm.
/// Overrides the [encrypt] and [decrypt] method of the [Encryption] interface.
final class AESEncryption implements Encryption {

  /// Plaintext is encrypted using a 256 bit key generated from the utf8 encoded password.
  /// Ciphertext is returned in base64 encoding.
  /// Uses the [Hashing.sha256Hash] method to generate the full 256 bit key.
  @override
  String encrypt({required String plainText, required String password}) {
    Uint8List hash = Hashing.sha256Hash(utf8.encode(password));
    Encrypter crypt = Encrypter(AES(Key(hash), mode: AESMode.sic, padding: null));
    Encrypted encrypted = crypt.encrypt(plainText, iv: IV.allZerosOfLength(16));
    return encrypted.base64;
  }

  /// Ciphertext is decrypted using a 256 bit key generated from the utf8 encoded password.
  /// Ciphertext needs to be provided in base64 encoding.
  /// Uses the [Hashing.sha256Hash] method to generate the full 256 bit key.
  @override
  String decrypt({required String encryptedText, required String password}) {
    Uint8List hash = Hashing.sha256Hash(utf8.encode(password));
    Encrypter crypt = Encrypter(AES(Key(hash), mode: AESMode.sic, padding: null));
    String decrypted = crypt.decrypt64(encryptedText, iv: IV.allZerosOfLength(16));
    return decrypted;
  }
}