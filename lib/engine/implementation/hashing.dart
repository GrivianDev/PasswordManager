import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Helper class for generating hash values based on input bytes.
/// Currently implements sha-256 hashing.
final class Hashing {

  /// This method hashes a given byte list
  /// with the sha-256 hash algorithm. The result is a list of bytes that always consists of 256 bit.
  static Uint8List sha256Hash(List<int> bytes) {
    return Uint8List.fromList(sha256.convert(bytes).bytes);
  }

  /// Returns the hash bytes after applying sha-256 twice.
  static Uint8List sha256DoubledHash(List<int> bytes) {
    return Uint8List.fromList(sha256.convert(sha256.convert(bytes).bytes).bytes);
  }

  /// Creates a hex string representation of bytes.
  static String asString(Uint8List bytes) => bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
}