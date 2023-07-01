import 'package:flutter/material.dart';

/// Class that provides the themedata used in this project.
/// The data can be accessed through the static getters [darkTheme] and [lightTheme].
class AppThemeData {
  static final ThemeData darkTheme = ThemeData(
    primaryColor: const Color.fromRGBO(46, 50, 51, 1),
    highlightColor: Colors.white,
    scaffoldBackgroundColor: const Color.fromRGBO(46, 50, 51, 1),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(46, 50, 51, 1),
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
      titleTextStyle: TextStyle(
        fontSize: 25.0,
        color: Colors.white,
      ),
    ),

    drawerTheme: const DrawerThemeData(
      backgroundColor: Color.fromRGBO(77, 83, 84, 1),
    ),

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
      bodyMedium: TextStyle(
        fontSize: 20.0,
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

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
    ),

    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    primaryColor: Colors.grey,
    highlightColor: Colors.grey,
    scaffoldBackgroundColor: Colors.grey,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.grey,
      iconTheme: IconThemeData(
        color: Colors.black,
      ),
      titleTextStyle: TextStyle(
        fontSize: 25.0,
        color: Colors.black87,
      ),
    ),

    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
    ),

    colorScheme: const ColorScheme.light(
      primary: Color.fromRGBO(2, 10, 161, 1),
      background: Colors.white,
    ),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color.fromRGBO(2, 10, 161, 1),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 25.0,
        color: Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: 20.0,
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

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color.fromRGBO(2, 10, 161, 1),
    ),

    iconTheme: const IconThemeData(
        color: Colors.black,
    ),
  );
}