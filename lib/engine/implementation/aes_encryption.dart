import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:passwordmanager/engine/encryption.dart';

/// An implementation of the AES 256 bit encryption algorithm.
/// Overrides the [encrypt] and [decrypt] method of the [Encryption] interface.
final class AESEncryption implements Encryption {

  /// Plaintext is encrypted using a 256 bit key generated from the password.
  /// Ciphertext is returned in base64 encoding.
  /// Uses [_inflatePassword] to generate the full 256 bit key.
  @override
  String encrypt({required String plainText, required String password}) {
    Uint8List hash = AESEncryption.sha256Hash(utf8.encode(password));
    Encrypter crypt = Encrypter(AES(Key(hash)));
    Encrypted encrypted = crypt.encrypt(plainText, iv: IV.fromLength(16));
    return encrypted.base64;
  }

  /// Ciphertext is decrypted using a 256 bit key generated from the password.
  /// Ciphertext needs to be provided in base64 encoding.
  /// Uses [_inflatePassword] to generate the full 256 bit key.
  @override
  String decrypt({required String encryptedText, required String password}) {
    Uint8List hash = AESEncryption.sha256Hash(utf8.encode(password));
    Encrypter crypt = Encrypter(AES(Key(hash)));
    String decrypted = crypt.decrypt64(encryptedText, iv: IV.fromLength(16));
    return decrypted;
  }

  /// AES 256 bit requires a 256 bit key. This method hashes a given byte list
  /// with the sha-256 hash algorithm. The result is a list of bytes that always consists of 256 bit.
  static Uint8List sha256Hash(List<int> bytes) {
    return Uint8List.fromList(sha256.convert(bytes).bytes);
  }

  /// Returns the hash bytes after applying sha-256 twice.
  static Uint8List sha256DoubledHash(List<int> bytes) {
    return Uint8List.fromList(sha256.convert(sha256.convert(bytes).bytes).bytes);
  }
}