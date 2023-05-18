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
      primary: Colors.blue,
      background: Color.fromRGBO(77, 83, 84, 1),
    ),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.blue,
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

    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: const BorderSide(width: 2, color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: const BorderSide(width: 2, color: Colors.blue),
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.all(Colors.blue),
      trackColor: MaterialStateProperty.all(Colors.blueGrey),
    ),

    iconTheme: const IconThemeData(
      color: Colors.white
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    primaryColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color.fromRGBO(2, 10, 161, 1),
      background: Colors.grey,
    ),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color.fromRGBO(2, 10, 161, 1),
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

    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: BorderSide(width: 2, color: Colors.grey.shade900),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: const BorderSide(width: 2, color: Color.fromRGBO(2, 10, 161, 1)),
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.all(Colors.grey),
      trackColor: MaterialStateProperty.all(Colors.black),
    ),

    iconTheme: const IconThemeData(
        color: Colors.black,
    ),
  );
}
