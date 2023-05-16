import 'package:encrypt/encrypt.dart';

class Encryption {
  static String encrypt(String plainText, String password) {
    password = _inflatePassword(password);
    Encrypter crypt = Encrypter(AES(Key.fromUtf8(password)));
    Encrypted encrypted = crypt.encrypt(plainText, iv: IV.fromLength(16));
    return encrypted.base64;
  }

  static String decrypt(String encryptedText, String password) {
    password = _inflatePassword(password);
    Encrypter crypt = Encrypter(AES(Key.fromUtf8(password)));
    String decrypted = crypt.decrypt64(encryptedText, iv: IV.fromLength(16));
    return decrypted;
  }

  static String _inflatePassword(String password) {
    String hash = password.hashCode.toString();
    int missing = 32 - password.length;
    while(hash.length < missing) {
      hash += hash;
    }
    if(missing > 0) {
      password += hash.substring(0, missing);
    }
    print('Password: $password | length: ${password.length}');
    return password;
  }
}