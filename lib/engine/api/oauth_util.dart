import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/digests/sha256.dart';

String generateCodeVerifier([int byteLength = 32]) {
  final Random random = Random.secure();
  final Uint8List verifier = Uint8List.fromList(List.generate(byteLength, (_) => random.nextInt(0xFF)));
  return base64UrlEncode(verifier).replaceAll('=', '');
}

String generateCodeChallenge(String verifier) {
  final Uint8List bytes = utf8.encode(verifier);
  final Uint8List digest = SHA256Digest().process(bytes);
  return base64UrlEncode(digest).replaceAll('=', '');
}
