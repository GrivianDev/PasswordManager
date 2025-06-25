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
