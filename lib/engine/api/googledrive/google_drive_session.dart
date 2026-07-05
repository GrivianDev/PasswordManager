class GoogleDriveSession {
  /// Short-lived token used for authenticating actual api requests.
  final String accessToken;

  /// Expiration time of the access token.
  final DateTime expiresAt;

  /// Long-lived refresh token. (Note that these are also sometimes time limited according to google specs)
  final String refreshToken;

  const GoogleDriveSession({
    required this.accessToken,
    required this.expiresAt,
    required this.refreshToken,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'refreshToken': refreshToken,
      };

  static GoogleDriveSession? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final accessToken = json['accessToken'];
    final expiresAtString = json['expiresAt'];
    final refreshToken = json['refreshToken'];

    if (accessToken is! String || refreshToken is! String || expiresAtString is! String) {
      return null;
    }

    final DateTime? expiresAt = DateTime.tryParse(expiresAtString);
    if (expiresAt == null) {
      return null;
    }

    return GoogleDriveSession(
      accessToken: accessToken,
      expiresAt: expiresAt,
      refreshToken: refreshToken,
    );
  }
}
