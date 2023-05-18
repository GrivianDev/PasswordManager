import 'package:flutter/material.dart';
import '../engine/persistance.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode get themeMode => Settings.isLightMode() ? ThemeMode.light : ThemeMode.dark;

  Future<void> toggleTheme(bool isOn) async {
    await Settings.setLightMode(isOn);
    notifyListeners();
  }
}

class AppThemeData {
  static final ThemeData darkTheme = ThemeData(
    primaryColor: const Color.fromRGBO(46, 50, 51, 1),
    colorScheme: const ColorScheme.dark(
      background: Color.fromRGBO(77, 83, 84, 1),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 25.0,
        color: Colors.white,
      ),
      bodySmall: TextStyle(
        fontSize: 16.0,
        color: Colors.white,
      ),
    ),

    iconTheme: const IconThemeData(
      color: Colors.white
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    primaryColor: Colors.white,
    colorScheme: const ColorScheme.light(
      background: Colors.grey,
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 25.0,
        color: Colors.black87,
      ),
      bodySmall: TextStyle(
        fontSize: 16.0,
        color: Colors.black87,
      ),
    ),

    iconTheme: const IconThemeData(
        color: Colors.black,
    ),
  );
}
