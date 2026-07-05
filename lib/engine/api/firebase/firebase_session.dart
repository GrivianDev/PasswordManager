class FirebaseSession {
  /// Globally unique firebase user id.
  final String userId;

  /// Short-lived JWT-Token used for authenticating actual api requests.
  final String idToken;

  /// Expiration time of the ID token.
  final DateTime expiresAt;

  /// Long-lived refresh token for obtaining new ID tokens.
  final String refreshToken;

  const FirebaseSession({
    required this.userId,
    required this.idToken,
    required this.expiresAt,
    required this.refreshToken,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'idToken': idToken,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'refreshToken': refreshToken,
      };

  static FirebaseSession? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final userId = json['userId'];
    final idToken = json['idToken'];
    final refreshToken = json['refreshToken'];
    final expiresAtString = json['expiresAt'];

    if (userId is! String || idToken is! String || refreshToken is! String || expiresAtString is! String) {
      return null;
    }

    final DateTime? expiresAt = DateTime.tryParse(expiresAtString);
    if (expiresAt == null) {
      return null;
    }

    return FirebaseSession(
      userId: userId,
      idToken: idToken,
      expiresAt: expiresAt,
      refreshToken: refreshToken,
    );
  }
}
