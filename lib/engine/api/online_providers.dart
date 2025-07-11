enum OnlineProvidertype {
  firestore,
}

class LoginResult {
  final OnlineProvidertype type;
  final bool loggedIn;

  LoginResult(this.type, {required this.loggedIn});
}