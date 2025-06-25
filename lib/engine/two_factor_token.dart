import 'dart:typed_data';
import 'dart:math';
import 'package:base32/base32.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/macs/hmac.dart';

class TOTPSecret {
  String issuer;
  String accountName;
  String secret; // base32 encoded
  String algorithm;
  int period;
  int digits;

  TOTPSecret({
    required this.issuer,
    required this.accountName,
    required this.secret,
    this.algorithm = 'SHA-1',
    this.period = 30,
    this.digits = 6
  });

  factory TOTPSecret.fromJson(Map<String, dynamic> json) {
    return TOTPSecret(
      issuer: json['issuer'] as String,
      accountName: json['accountName'] as String,
      secret: json['secret'] as String,
      algorithm: json['algorithm'] as String? ?? 'SHA-1',
      period: json['period'] as int? ?? 30,
      digits: json['digits'] as int? ?? 6);
  }

  String generateTOTPCode({DateTime? timestamp}) {
    final DateTime now = timestamp ?? DateTime.now().toUtc();
    final int secondsSinceEpoch = now.millisecondsSinceEpoch ~/ 1000;
    final int counter = secondsSinceEpoch ~/ period;

    final Uint8List decodedSecret = base32.decode(secret);
    final ByteData timeBytes = ByteData(8)..setInt64(0, counter, Endian.big);

    final HMac hmac = HMac(Digest(algorithm), 64)..init(KeyParameter(decodedSecret));
    final Uint8List hash = hmac.process(timeBytes.buffer.asUint8List());

    final int offset = hash.last & 0xf;
    final int binary = ((hash[offset] & 0x7f) << 24) |
    ((hash[offset + 1] & 0xff) << 16) |
    ((hash[offset + 2] & 0xff) << 8) |
    (hash[offset + 3] & 0xff);

    final int otp = binary % pow(10, digits).toInt();
    return otp.toString().padLeft(digits, '0');
  }

  Map<String, dynamic> toJson() {
    return {
      'issuer': issuer,
      'accountName': accountName,
      'secret': secret,
      'algorithm': algorithm,
      'period': period,
      'digits': digits
    };
  }

  /// Returns a format that is human readable.
  @override
  String toString() {
    return 'TOTPSecret(issuer=$issuer, accountName=$accountName, secret=$secret, algorithm=$algorithm, period=$period, digits=$digits)';
  }
}
