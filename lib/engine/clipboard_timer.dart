import 'dart:async';
import 'package:flutter/services.dart';

/// Small class used to clear the clipboard after a certain time using an intern timer.
final class ClipboardTimer {
  static Timer? _timer;

  /// Copys given string to the clipboard but removes the content after the given duration.
  /// Timer is cancelled if method is called while previous timer did not run out.
  static Future<void> timed({required String text, required Duration duration}) async {
    if(_timer != null && _timer!.isActive) _timer!.cancel();
    await Clipboard.setData(ClipboardData(text: text));
    _timer = Timer(duration, () => Clipboard.setData(const ClipboardData(text: '')));
  }
}
