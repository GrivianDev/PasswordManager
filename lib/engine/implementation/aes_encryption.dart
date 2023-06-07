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
    password = _inflatePassword(password);
    Encrypter crypt = Encrypter(AES(Key.fromUtf8(password)));
    Encrypted encrypted = crypt.encrypt(plainText, iv: IV.fromLength(16));
    return encrypted.base64;
  }

  /// Ciphertext is decrypted using a 256 bit key generated from the password.
  /// Ciphertext needs to be provided in base64 encoding.
  /// Uses [_inflatePassword] to generate the full 256 bit key.
  @override
  String decrypt({required String encryptedText, required String password}) {
    password = _inflatePassword(password);
    Encrypter crypt = Encrypter(AES(Key.fromUtf8(password)));
    String decrypted = crypt.decrypt64(encryptedText, iv: IV.fromLength(16));
    return decrypted;
  }

  /// AES 256 bit requires a 256 bit key (in this implementation an utf8 string of length 32 [32*8=256]). However,
  /// users should not be forced to always have a password containing exactly 32 characters. This method appends the
  /// hashcode of the password as string until the length of 32 is reached. Appending the hash is safer because of its relative unpredictablility
  /// than concatenating the password "hello" to the key "hellohellohellohellohellohellohe". Otherwise "hello" and "hellohello" for example would generate the same key.
  String _inflatePassword(String password) {
    String hash = password.hashCode.toString();
    int missing = 32 - password.length;
    while(hash.length < missing) {
      hash += hash;
    }
    if(missing > 0) {
      password += hash.substring(0, missing);
    }
    return password;
  }
}