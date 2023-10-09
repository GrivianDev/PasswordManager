import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/persistance.dart';

/// Class providing two methods: [SafetyAnalyser.rateSafety], [SafetyAnalyser.generateSavePassword].
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
  double rateSafety({required String password}) {
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

    final double sum = occuranceRating + variety;

    return lengthRating * (sum / 2.0);
  }

  /// Generates a random password consisting of [20-32] characters.
  String generateSavePassword(BuildContext context) {
    final Settings settings = context.read<Settings>();
    String chars = (settings.useLettersEnabled || settings.useNumbersEnabled || settings.useSpecialCharsEnabled) ? '' : alphabet + uAlphabet;
    if(settings.useLettersEnabled) chars += alphabet + uAlphabet;
    if(settings.useNumbersEnabled) chars += numbers;
    if(settings.useSpecialCharsEnabled) chars += specialChars;
    final Random rand = Random.secure();
    return String.fromCharCodes(Iterable<int>.generate(rand.nextInt(12) + 20, (_) => chars.codeUnitAt(rand.nextInt(chars.length))));
  }
}

/// Small class that acts as a kind of security guard for important actions.
/// Implements an increasing cooldown for important actions that failed too often.
final class Guardian {
  static const int _cooldown = 15;
  static const int _maxTries = 3;
  static int _cooldownMultiplier = 0;
  static int _remainingTries = _maxTries;
  static Timer? _timer;

  /// Call this method at the beginning of the important action and catch the possible Exception.
  static Future<void> failIfAccessDenied(Future<void> Function() func) async {
    if(_remainingTries <= 0) {
      throw Exception("Too many failed attempts. Try again in a few seconds.");
    }
    await func();
  }

  /// Call this method if the important action fails in a security relevant case. Provide an optional message that is thrown as Exception.
  /// Too many calls will start a timer that will cause a call to [failIfAccessDenied] to throw an Exception.
  static void callAccessFailed(String? message) {
    if(--_remainingTries <= 0) {
      _cooldownMultiplier++;
      _timer = Timer(Duration(seconds: _cooldownMultiplier * _cooldown), () => _remainingTries = _maxTries);
    }
    if(message != null) throw Exception(message);
  }
}