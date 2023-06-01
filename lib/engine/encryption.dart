import 'package:passwordmanager/engine/implementation/aes_encryption.dart';

/// This interface provides the [encrypt] and [decrypt] method to allow
/// encryption and decryption for text through a given password.
abstract class Encryption {

  String encrypt({required String plainText, required String password});

  String decrypt({required String encryptedText, required String password});
}

/// EncryptionProvider just provides one static getter to get the currently used encryption method
/// across all of the widget tree.
final class EncryptionProvider {

  /// Returns an implemented interface.
  /// Change the returned encryption model to another implementation
  /// for quick and easy changing the algorithm.
  static Encryption get encryption => AESEncryption();
}