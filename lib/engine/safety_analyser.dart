import 'dart:math';

/// Class providing two static methods: [SafetyAnalyser.rateSafety], [SafetyAnalyser.generateSavePassword].
/// Used for determening if a password is considered save or generate strong passwords.
final class SafetyAnalyser {
  static const String alphabet = 'abcdefghijklmnopqrstuvwxyz';
  static const String uAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String numbers = '0123456789';
  static const String specialChars = '\'\$^°ß!"§%&/()=?,;.:-_#*+|<>~´`{[]}';

  /// Returns a rating between [0-1] based on these factors:
  /// * Does password contain different characters overall
  /// * Is recommended password length of 12 reached, if not how much is missing.
  /// * Were lowercase, uppercase, numbers and special characters used.
  static double rateSafety({required String password}) {
    if(password.isEmpty) return 0.0;

    // 1) Test if not always the same symbols have been used
    Map<int, int> occurances = Map.fromIterable(password.codeUnits);
    final double occuranceRating = occurances.length.toDouble() / password.length.toDouble();

    // 2) Test how near the password comes to min length of 12
    final double lengthRating =  (password.length.toDouble() / 12.0).clamp(0, 1);

    // 3) test if password contains letters, uppercase, numbers and special chars
    double variety = 0.0;
    for(int val in password.codeUnits) {
      if(alphabet.contains(String.fromCharCode(val))) {
        variety += 1;
        break;
      }
    }
    for(int val in password.codeUnits) {
      if(uAlphabet.contains(String.fromCharCode(val))) {
        variety += 1;
        break;
      }
    }
    for(int val in password.codeUnits) {
      if(numbers.contains(String.fromCharCode(val))) {
        variety += 1;
        break;
      }
    }
    for(int val in password.codeUnits) {
      if(specialChars.contains(String.fromCharCode(val))) {
        variety += 1;
        break;
      }
    }
    variety /= 4.0;

    final double sum = occuranceRating + lengthRating + variety;

    return sum / 3.0;
  }

  /// Generates a random password consisting of [20-32] characters.
  static String generateSavePassword() {
    const String chars = alphabet + uAlphabet + numbers + specialChars;
    final Random rand = Random.secure();
    return String.fromCharCodes(Iterable<int>.generate(rand.nextInt(12) + 20, (_) => chars.codeUnitAt(rand.nextInt(chars.length))));
  }
}