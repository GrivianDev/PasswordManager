import 'dart:typed_data';
import 'package:passwordmanager/engine/cryptography/datatypes.dart';

/// This interface provides the [encrypt] and [decrypt] method to allow
/// symetric encryption and decryption for bytes through a given key and iv.
abstract class Encryption {

  /// Encrypts the given data according to the underlying implementation with the provided key.
  /// In most cases you should also provide a valid initialization vector.
  Uint8List encrypt({required Uint8List data, required Key key, required IV iv});

  /// Decrypts the given cipher according to the underlying implementation with the provided key.
  /// In most cases you should also provide a valid initialization vector.
  Uint8List decrypt({required Uint8List cipher, required Key key, required IV iv});

  int get blockLength;

  int get keyLength;
}