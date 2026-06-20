import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(String message) {
    if (kDebugMode) {
      _print('DEBUG', message);
    }
  }

  static void i(String message) {
    _print('INFO', message);
  }

  static void w(String message) {
    _print('WARNING', message);
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _print('ERROR', message);
    if (error != null) {
      _print('ERROR_DETAIL', error.toString());
    }
    if (stackTrace != null && kDebugMode) {
      _print('STACKTRACE', stackTrace.toString());
    }
  }

  static void _print(String level, String message) {
    final time = DateTime.now().toIso8601String();
    // Safety check to avoid accidental leak of key material in general
    if (message.contains('diary_encryption_key') || message.contains('key') && message.length > 40) {
      debugPrint('[$time] [$level] [REDACTED SENSITIVE DATA]');
    } else {
      debugPrint('[$time] [$level] $message');
    }
  }
}
