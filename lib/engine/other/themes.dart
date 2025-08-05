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
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(Color.fromRGBO(46, 50, 51, 1)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0.0,
      backgroundColor: Color.fromRGBO(46, 50, 51, 1),
      iconTheme: IconThemeData(
        color: Colors.white,
        size: 25.0,
      ),
      titleTextStyle: TextStyle(
        fontSize: 25.0,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.blue,
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Color.fromRGBO(77, 83, 84, 1),
      titleTextStyle: TextStyle(
        fontSize: 25.0,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        overflow: TextOverflow.clip,
      ),
      contentTextStyle: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        overflow: TextOverflow.clip,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        iconSize: WidgetStatePropertyAll<double?>(20.0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        iconSize: WidgetStatePropertyAll<double?>(20.0),
        foregroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
        backgroundColor: const WidgetStatePropertyAll<Color>(Colors.blue),
        iconColor: const WidgetStatePropertyAll<Color>(Colors.white),
        overlayColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.blue.shade600;
          }
          return Colors.blue.shade400;
        }),
        textStyle: WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            overflow: TextOverflow.clip,
          ),
        ),
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      ),
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(
        iconSize: WidgetStatePropertyAll<double?>(20.0),
        textStyle: WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            overflow: TextOverflow.clip,
          ),
        ),
        foregroundColor: WidgetStatePropertyAll<Color>(Colors.blue),
        iconColor: WidgetStatePropertyAll<Color>(Colors.blue),
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
      surface: Color.fromRGBO(77, 83, 84, 1),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: const BorderSide(width: 2, color: Colors.grey),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: const BorderSide(width: 2, color: Colors.red),
      ),
      errorStyle: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w800,
        color: Colors.redAccent,
        overflow: TextOverflow.clip,
      ),
    ),
    switchTheme: const SwitchThemeData(
      thumbColor: WidgetStatePropertyAll<Color>(Colors.blue),
      trackColor: WidgetStatePropertyAll<Color>(Colors.blueGrey),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    checkboxTheme: const CheckboxThemeData(
      fillColor: WidgetStatePropertyAll<Color>(Colors.blue),
      checkColor: WidgetStatePropertyAll<Color>(Colors.white),
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
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(Color.fromRGBO(225, 225, 225, 1)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0.0,
      backgroundColor: Color.fromRGBO(225, 225, 225, 1),
      iconTheme: IconThemeData(
        color: Colors.black,
        size: 25.0,
      ),
      titleTextStyle: TextStyle(
        fontSize: 25.0,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Color.fromRGBO(20, 75, 200, 1),
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 25.0,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        overflow: TextOverflow.clip,
      ),
      contentTextStyle: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        overflow: TextOverflow.clip,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        iconSize: WidgetStatePropertyAll<double?>(20.0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        iconSize: WidgetStatePropertyAll<double?>(20.0),
        foregroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
        backgroundColor: const WidgetStatePropertyAll<Color>(Color.fromRGBO(20, 75, 200, 1)),
        iconColor: const WidgetStatePropertyAll<Color>(Colors.white),
        overlayColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return Color.fromRGBO(0, 55, 180, 1);
          }
          return Color.fromRGBO(40, 95, 220, 1);
        }),
        textStyle: WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            overflow: TextOverflow.clip,
          ),
        ),
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      ),
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(
        iconSize: WidgetStatePropertyAll<double?>(20.0),
        textStyle: WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            overflow: TextOverflow.clip,
          ),
        ),
        foregroundColor: WidgetStatePropertyAll<Color>(Color.fromRGBO(20, 75, 200, 1)),
        iconColor: WidgetStatePropertyAll<Color>(Color.fromRGBO(20, 75, 200, 1)),
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
      surface: Colors.white,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: BorderSide(width: 2, color: Colors.grey.shade900),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: const BorderSide(width: 2, color: Colors.red),
      ),
      errorStyle: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w800,
        color: Colors.redAccent,
        overflow: TextOverflow.clip,
      ),
    ),
    switchTheme: const SwitchThemeData(
      thumbColor: WidgetStatePropertyAll<Color>(Color.fromRGBO(20, 75, 200, 1)),
      trackColor: WidgetStatePropertyAll<Color>(Colors.black),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color.fromRGBO(20, 75, 200, 1),
    ),
    iconTheme: const IconThemeData(
      color: Colors.black,
    ),
    checkboxTheme: const CheckboxThemeData(
      fillColor: WidgetStatePropertyAll<Color>(Color.fromRGBO(20, 75, 200, 1)),
      checkColor: WidgetStatePropertyAll<Color>(Colors.white),
    ),
  );
}
