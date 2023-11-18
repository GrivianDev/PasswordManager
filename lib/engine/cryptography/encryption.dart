import 'dart:typed_data';
import 'package:passwordmanager/engine/cryptography/datatypes.dart';
import 'package:passwordmanager/engine/cryptography/implementation/aes_encryption.dart';

/// This interface provides the [encrypt] and [decrypt] method to allow
/// encryption and decryption for text through a given password.
abstract class Encryption {

  Uint8List encrypt({required Uint8List data, required Key key, required IV iv});

  Uint8List decrypt({required Uint8List cipher, required Key key, required IV iv});
}

/// EncryptionProvider just provides one static getter to get the currently used encryption method
/// across all of the widget tree.
final class EncryptionProvider {

  /// Returns an implemented interface.
  /// Change the returned encryption model to another implementation
  /// for quick and easy changing the algorithm.
  static Encryption get encryption => AES256();
}