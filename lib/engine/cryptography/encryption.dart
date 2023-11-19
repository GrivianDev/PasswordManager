import 'dart:typed_data';
import 'package:passwordmanager/engine/cryptography/datatypes.dart';

/// This interface provides the [encrypt] and [decrypt] method to allow
/// encryption and decryption for text through a given password.
abstract class Encryption {

  Uint8List encrypt({required Uint8List data, required Key key, required IV iv});

  Uint8List decrypt({required Uint8List cipher, required Key key, required IV iv});

  int get blockLength;

  int get keyLength;
}