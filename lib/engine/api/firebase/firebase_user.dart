class FirebaseUser {
  final String email;

  /// Long-lived refresh token for obtaining new ID tokens.
  final String refreshToken;

  /// Globally unique firebase user id (`localId` in API responses).
  final String userId;

  /// Short-lived JWT-Token used for authenticating actual api requests.
  final String idToken;

  FirebaseUser(this.email, this.refreshToken, this.userId, this.idToken);
}