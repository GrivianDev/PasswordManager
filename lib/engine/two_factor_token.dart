import 'dart:typed_data';
import 'dart:math';
import 'package:base32/base32.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/macs/hmac.dart';

class TOTPSecret {
  static const String defaultAlgorithm = 'SHA-1';
  static const int defaultPeriod = 30;
  static const int defaultDigit = 6;
  static const List<String> allowedAlgorithms = ['SHA-1', 'SHA-256', 'SHA-512'];

  String issuer;
  String accountName;
  String secret; // base32 encoded
  String algorithm;
  int period;
  int digits;

  TOTPSecret(
      {required this.issuer,
      required this.accountName,
      required this.secret,
      this.algorithm = TOTPSecret.defaultAlgorithm,
      this.period = TOTPSecret.defaultPeriod,
      this.digits = TOTPSecret.defaultDigit}) {
    if (!TOTPSecret.allowedAlgorithms.contains(algorithm)) {
      throw ArgumentError(
          'Unsupported algorithm: $algorithm. Must be one of: ${TOTPSecret.allowedAlgorithms.join(', ')}.');
    }
    if (period < 0 || digits < 0) {
      throw ArgumentError('Unsupported negative values for period or digit.');
    }
  }

  factory TOTPSecret.fromUri(String uriString) {
    final uri = Uri.parse(uriString);

    if (uri.scheme != 'otpauth' || uri.host != 'totp') {
      throw const FormatException(
          'Invalid URI: must start with otpauth://totp/');
    }

    // Extract label: expected to be issuer:accountName
    final label = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
    final decodedLabel = Uri.decodeComponent(label);
    final parts = decodedLabel.split(':');

    if (parts.length != 2) {
      throw const FormatException(
          'Invalid label format: expected issuer:accountName');
    }

    final issuerFromLabel = parts[0];
    final accountName = parts[1];

    final query = uri.queryParameters;
    final secret = query['secret'];
    if (secret == null) {
      throw const FormatException('Missing "secret" in URI query');
    }

    /// Helper to map api specific string to flutter like equivalent
    String mapAlgorithm(String? alg) {
      switch (alg?.toUpperCase()) {
        case 'SHA256':
        case 'SHA-256':
          return 'SHA-256';
        case 'SHA512':
        case 'SHA-512':
          return 'SHA-512';
        default:
          return TOTPSecret.defaultAlgorithm;
      }
    }

    return TOTPSecret(
        issuer: query['issuer'] ?? issuerFromLabel,
        accountName: accountName,
        secret: secret,
        algorithm: mapAlgorithm(query['algorithm']),
        period: int.tryParse(
                query['period'] ?? TOTPSecret.defaultPeriod.toString()) ??
            TOTPSecret.defaultPeriod,
        digits: int.tryParse(
                query['digits'] ?? TOTPSecret.defaultDigit.toString()) ??
            TOTPSecret.defaultDigit);
  }

  factory TOTPSecret.fromJson(Map<String, dynamic> json) {
    return TOTPSecret(
        issuer: json['issuer'] as String,
        accountName: json['accountName'] as String,
        secret: json['secret'] as String,
        algorithm: json['algorithm'] as String? ?? TOTPSecret.defaultAlgorithm,
        period: json['period'] as int? ?? TOTPSecret.defaultPeriod,
        digits: json['digits'] as int? ?? TOTPSecret.defaultDigit);
  }

  String generateTOTPCode({DateTime? timestamp}) {
    final DateTime now = timestamp ?? DateTime.now().toUtc();
    final int secondsSinceEpoch = now.millisecondsSinceEpoch ~/ 1000;
    final int counter = secondsSinceEpoch ~/ period;

    final Uint8List decodedSecret = base32.decode(secret);
    final ByteData timeBytes = ByteData(8)..setInt64(0, counter, Endian.big);

    final HMac hmac = HMac(Digest(algorithm), 64)
      ..init(KeyParameter(decodedSecret));
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

  String getAuthUrl() {
    final String encodedIssuer = Uri.encodeComponent(issuer);
    final String encodedAccount = Uri.encodeComponent(accountName);

    // APIs expect SHA1, SHA256 or SHA512 instead of the flutter like SHA-1, ...
    final String normalizedAlgorithm =
        algorithm.toUpperCase().replaceAll('-', '');

    final uri = Uri(
      scheme: 'otpauth',
      host: 'totp',
      path: '$encodedIssuer:$encodedAccount',
      queryParameters: {
        'secret': secret,
        'issuer': issuer,
        'algorithm': normalizedAlgorithm,
        'digits': digits.toString(),
        'period': period.toString(),
      },
    );

    return uri.toString();
  }

  /// Returns a format that is human readable.
  @override
  String toString() {
    return 'TOTPSecret(issuer=$issuer, accountName=$accountName, secret=$secret, algorithm=$algorithm, period=$period, digits=$digits)';
  }
}
