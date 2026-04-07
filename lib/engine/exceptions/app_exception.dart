import 'package:flutter/foundation.dart';

class AppException implements Exception {
  final String message;
  final String? debugContext;
  final Object? cause;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  AppException(this.message, {this.debugContext, this.cause, this.stackTrace, DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now() {
    _logIfDebug();
  }

  factory AppException.unknown({Object? cause, StackTrace? stackTrace}) {
    return AppException(
      'An unknown error occured.',
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  void _logIfDebug() {
    if (!kDebugMode) return;

    final String time = timestamp.toIso8601String();
    final String prefix = debugContext != null ? '$debugContext Failed' : 'Error occurred';

    debugPrint('$time - $prefix: $message');
    if (cause != null) debugPrint('Cause: $cause');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }

  @override
  String toString() => 'Error: $message';
}
