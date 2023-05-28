import 'package:encrypt/encrypt.dart';
import 'package:passwordmanager/engine/encryption.dart';

final class AESEncryption implements Encryption {

  @override
  String encrypt({required String plainText, required String password}) {
    password = _inflatePassword(password);
    Encrypter crypt = Encrypter(AES(Key.fromUtf8(password)));
    Encrypted encrypted = crypt.encrypt(plainText, iv: IV.fromLength(16));
    return encrypted.base64;
  }

  @override
  String decrypt({required String encryptedText, required String password}) {
    password = _inflatePassword(password);
    Encrypter crypt = Encrypter(AES(Key.fromUtf8(password)));
    String decrypted = crypt.decrypt64(encryptedText, iv: IV.fromLength(16));
    return decrypted;
  }

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