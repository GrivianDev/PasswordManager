import 'dart:typed_data';
import 'dart:math';
import 'package:base32/base32.dart';
import 'package:base32/encodings.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/macs/hmac.dart';

/// Holds data and logic for a Time-based One-Time Password (TOTP) secret,
/// including parameters for generation and serialization.
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

  static String _normalizeLooseBase32ToRFC4648(String base32secret) {
    final String s = base32secret.toUpperCase().replaceAll(' ', '').trim();
    final int padLen = (8 - (s.length % 8)) % 8;
    return s.padRight(s.length + padLen, '=');
  }

  /// Creates a new [TOTPSecret] instance with the given parameters.
  ///
  /// - **[issuer]**: The service or application providing the TOTP (e.g. "Google").
  /// - **[accountName]**: The user account associated with the TOTP (e.g. "alice@example.com").
  /// - **[secret]**: The shared secret in **Base32 encoding** (loosely RFC 4648 compliant).
  ///   - Input is normalized to uppercase and trimmed of whitespaces.
  ///   - Padding with '=' is added internally, but TOTP URIs and QR codes commonly omit it.
  /// - **[algorithm]**: The HMAC algorithm to use (`SHA-1`, `SHA-256`, `SHA-512`).
  ///   Any unsupported value throws an [ArgumentError].
  /// - **[period]**: The time step in seconds (commonly 30). Must be non-negative.
  /// - **[digits]**: The number of output digits (commonly 6 or 8). Must be non-negative.
  ///
  /// Throws:
  /// - [ArgumentError] if the algorithm is not one of the allowed values.
  /// - [ArgumentError] if the secret is not a valid RFC 4648 Base32 string after normalization to uppercase.
  /// - [ArgumentError] if [period] or [digits] are negative.
  TOTPSecret(
      {required this.issuer,
      required this.accountName,
      required String secret,
      this.algorithm = TOTPSecret.defaultAlgorithm,
      this.period = TOTPSecret.defaultPeriod,
      this.digits = TOTPSecret.defaultDigit})
      : secret = _normalizeLooseBase32ToRFC4648(secret) {
    if (!TOTPSecret.allowedAlgorithms.contains(algorithm)) {
      throw ArgumentError('Unsupported algorithm: $algorithm. Must be one of: ${TOTPSecret.allowedAlgorithms.join(', ')}.');
    }
    if (!base32.isValid(this.secret, encoding: Encoding.standardRFC4648)) {
      throw ArgumentError('Invalid base32 secret for StandardRFC4648: "${this.secret}"');
    }
    if (period < 0 || digits < 0) {
      throw ArgumentError('Unsupported negative values for period or digit.');
    }
  }

  /// Creates a TOTP secret from a valid `otpauth://totp/` URI string.
  factory TOTPSecret.fromUri(String uriString) {
    final Uri uri = Uri.parse(uriString);

    if (uri.scheme != 'otpauth' || uri.host != 'totp') {
      throw const FormatException('Invalid URI: must start with otpauth://totp/');
    }

    // Extract label: expected to be issuer:accountName
    final String label = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
    final String decodedLabel = Uri.decodeComponent(label);
    final List<String> parts = decodedLabel.split(':');

    if (parts.length != 2) {
      throw const FormatException('Invalid label format: expected issuer:accountName');
    }

    final String issuerFromLabel = parts[0];
    final String accountName = parts[1];

    final Map<String, String> query = uri.queryParameters;
    final String? rawSecret = query['secret'];
    if (rawSecret == null) {
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
        secret: rawSecret,
        algorithm: mapAlgorithm(query['algorithm']),
        period: int.tryParse(query['period'] ?? TOTPSecret.defaultPeriod.toString()) ?? TOTPSecret.defaultPeriod,
        digits: int.tryParse(query['digits'] ?? TOTPSecret.defaultDigit.toString()) ?? TOTPSecret.defaultDigit);
  }

  /// Creates a TOTP secret from a JSON-compatible map.
  factory TOTPSecret.fromJson(Map<String, dynamic> json) {
    return TOTPSecret(
        issuer: json['issuer'] as String,
        accountName: json['accountName'] as String,
        secret: json['secret'] as String,
        algorithm: json['algorithm'] as String? ?? TOTPSecret.defaultAlgorithm,
        period: json['period'] as int? ?? TOTPSecret.defaultPeriod,
        digits: json['digits'] as int? ?? TOTPSecret.defaultDigit);
  }

  String get unpaddedSecret => secret.replaceAll('=', '');

  /// Generates a TOTP code for the given timestamp or for the current UTC time.
  String generateTOTPCode({DateTime? timestamp}) {
    final DateTime now = timestamp ?? DateTime.now().toUtc();
    final int secondsSinceEpoch = now.millisecondsSinceEpoch ~/ 1000;
    final int counter = secondsSinceEpoch ~/ period;

    final Uint8List decodedSecret = base32.decode(secret, encoding: Encoding.standardRFC4648);
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

  /// Converts the TOTP secret to a JSON-compatible map.
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

  /// Generates the `otpauth://totp/` URI for this TOTP secret.
  String getAuthUrl() {
    final String encodedIssuer = Uri.encodeComponent(issuer);
    final String encodedAccount = Uri.encodeComponent(accountName);

    // APIs expect SHA1, SHA256 or SHA512 instead of the flutter like SHA-1, ...
    final String normalizedAlgorithm = algorithm.toUpperCase().replaceAll('-', '');

    final uri = Uri(
      scheme: 'otpauth',
      host: 'totp',
      path: '$encodedIssuer:$encodedAccount',
      queryParameters: {
        'secret': unpaddedSecret,
        'issuer': issuer,
        'algorithm': normalizedAlgorithm,
        'digits': digits.toString(),
        'period': period.toString(),
      },
    );

    return uri.toString();
  }

  /// Returns a human-readable string representation of the TOTP secret.
  @override
  String toString() {
    return 'TOTPSecret(issuer=$issuer, accountName=$accountName, secret=$secret, algorithm=$algorithm, period=$period, digits=$digits)';
  }
}
