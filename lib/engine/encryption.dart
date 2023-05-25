import 'package:passwordmanager/engine/implementation/aes_encryption.dart';

abstract class Encryption {

  String encrypt({required String plainText, required String password});

  String decrypt({required String encryptedText, required String password});
}

final class EncryptionProvider {
  static Encryption get encryption => AESEncryption();
}