import 'package:flutter/services.dart';

class Base32InputFormatter extends TextInputFormatter {
  static final _base32CharRegex = RegExp(r'[A-Z2-7]'); // No '=' padding by default

  static String formatBase32(String input) {
    final raw = input.toUpperCase().replaceAll(' ', '');

    final filtered = raw
        .split('')
        .where((c) => _base32CharRegex.hasMatch(c))
        .join();

    final buffer = StringBuffer();
    for (int i = 0; i < filtered.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(filtered[i]);
    }

    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final formatted = formatBase32(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}