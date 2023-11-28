import 'package:flutter/material.dart';

/// Class that provides the themedata used in this project.
/// The data can be accessed through the static getters [darkTheme] and [lightTheme].
class AppThemeData {
  static final ThemeData darkTheme = ThemeData(
    primaryColor: const Color.fromRGBO(46, 50, 51, 1),
    highlightColor: Colors.white,
    scaffoldBackgroundColor: const Color.fromRGBO(46, 50, 51, 1),
    cardColor: const Color.fromRGBO(77, 83, 84, 1),
    dividerTheme: const DividerThemeData(
      color: Colors.grey,
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Color.fromRGBO(77, 83, 84, 1),
      selectedTileColor: Color.fromRGBO(77, 83, 84, 1),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0.0,
      backgroundColor: Color.fromRGBO(46, 50, 51, 1),
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
      titleTextStyle: TextStyle(
        fontSize: 25.0,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
        iconColor: MaterialStateProperty.all<Color>(Colors.white),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        textStyle: MaterialStateProperty.all<TextStyle>(
          const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
        iconColor: MaterialStateProperty.all<Color>(Colors.blue),
      ),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      backgroundColor: Color.fromRGBO(46, 50, 51, 1),
      collapsedBackgroundColor: Color.fromRGBO(77, 83, 84, 1),
      textColor: Colors.blue,
      childrenPadding: EdgeInsets.all(10.0),
      iconColor: Colors.blue,
      collapsedIconColor: Colors.white,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color.fromRGBO(77, 83, 84, 1),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Colors.blue,
      surfaceTint: Colors.transparent,
      background: Color.fromRGBO(77, 83, 84, 1),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.blue,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 25.0,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        overflow: TextOverflow.clip,
      ),
      bodyMedium: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        overflow: TextOverflow.clip,
      ),
      bodySmall: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        overflow: TextOverflow.clip,
      ),
      displayLarge: TextStyle(
        fontSize: 25.0,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        overflow: TextOverflow.ellipsis,
      ),
      displayMedium: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        overflow: TextOverflow.ellipsis,
      ),
      displaySmall: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.all(15),
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
      thumbColor: MaterialStateProperty.all<Color>(Colors.blue),
      trackColor: MaterialStateProperty.all<Color>(Colors.blueGrey),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.all<Color>(Colors.blue),
      checkColor: MaterialStateProperty.all<Color>(Colors.white),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    primaryColor: const Color.fromRGBO(225, 225, 225, 1),
    highlightColor: const Color.fromRGBO(225, 225, 225, 1),
    scaffoldBackgroundColor: const Color.fromRGBO(225, 225, 225, 1),
    cardColor: Colors.white,
    dividerTheme: const DividerThemeData(
      color: Colors.grey,
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.white,
      selectedTileColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0.0,
      backgroundColor: Color.fromRGBO(225, 225, 225, 1),
      iconTheme: IconThemeData(
        color: Colors.black,
      ),
      titleTextStyle: TextStyle(
        fontSize: 25.0,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(const Color.fromRGBO(20, 75, 200, 1)),
        iconColor: MaterialStateProperty.all<Color>(Colors.white),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        textStyle: MaterialStateProperty.all<TextStyle>(
          const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        foregroundColor: MaterialStateProperty.all<Color>(const Color.fromRGBO(20, 75, 200, 1)),
        iconColor: MaterialStateProperty.all<Color>(const Color.fromRGBO(20, 75, 200, 1)),
      ),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      backgroundColor: Color.fromRGBO(225, 225, 225, 1),
      collapsedBackgroundColor: Colors.white,
      textColor: Color.fromRGBO(20, 75, 200, 1),
      childrenPadding: EdgeInsets.all(10.0),
      iconColor: Color.fromRGBO(20, 75, 200, 1),
      collapsedIconColor: Colors.black,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
    ),
    colorScheme: const ColorScheme.light(
      primary: Color.fromRGBO(20, 75, 200, 1),
      surfaceTint: Colors.transparent,
      background: Colors.white,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color.fromRGBO(20, 75, 200, 1),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 25.0,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        overflow: TextOverflow.clip,
      ),
      bodyMedium: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        overflow: TextOverflow.clip,
      ),
      bodySmall: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        overflow: TextOverflow.clip,
      ),
      displayLarge: TextStyle(
        fontSize: 25.0,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        overflow: TextOverflow.ellipsis,
      ),
      displayMedium: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        overflow: TextOverflow.ellipsis,
      ),
      displaySmall: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.all(15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: BorderSide(width: 2, color: Colors.grey.shade900),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: const BorderSide(width: 2, color: Color.fromRGBO(20, 75, 200, 1)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.all<Color>(const Color.fromRGBO(20, 75, 200, 1)),
      trackColor: MaterialStateProperty.all<Color>(Colors.black),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color.fromRGBO(20, 75, 200, 1),
    ),
    iconTheme: const IconThemeData(
      color: Colors.black,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.all<Color>(const Color.fromRGBO(20, 75, 200, 1)),
      checkColor: MaterialStateProperty.all<Color>(Colors.white),
    ),
  );
}
