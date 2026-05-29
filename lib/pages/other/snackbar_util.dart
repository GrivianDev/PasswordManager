import 'package:flutter/material.dart';

final class SnackBarUtils {
  static SnackBar message(
    String text, {
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    return SnackBar(
      duration: duration,
      backgroundColor: backgroundColor,
      content: Wrap(
        spacing: 5,
        children: [
          if (icon != null) Icon(icon, size: 15, color: Colors.white),
          Text(text),
        ],
      ),
    );
  }
}
