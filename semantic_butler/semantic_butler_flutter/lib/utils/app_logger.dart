import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralized logging service for the app
class AppLogger {
  static const String _name = 'SemanticButler';

  /// Log a debug message (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      developer.log('$prefix$message', name: _name, level: 500);
      debugPrint('🐛 $_name | $prefix$message');
    }
  }

  /// Log an info message
  static void info(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    developer.log('$prefix$message', name: _name, level: 800);
    if (kDebugMode) {
      debugPrint('ℹ️ $_name | $prefix$message');
    }
  }

  /// Log a warning message
  static void warning(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    developer.log('$prefix$message', name: _name, level: 900);
    if (kDebugMode) {
      debugPrint('⚠️ $_name | $prefix$message');
    }
  }

  /// Log an error message with optional exception and stack trace
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final prefix = tag != null ? '[$tag] ' : '';
    developer.log(
      '$prefix$message',
      name: _name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    if (kDebugMode) {
      debugPrint('❌ $_name | $prefix$message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   StackTrace: $stackTrace');
      }
    }
  }

  /// Log a network request
  static void network(
    String method,
    String url, {
    int? statusCode,
    String? body,
  }) {
    if (kDebugMode) {
      final status = statusCode != null ? ' [$statusCode]' : '';
      debugPrint('🌐 $_name | $method $url$status');
      if (body != null && body.length < 500) {
        debugPrint('   Body: $body');
      }
    }
  }

  /// Log app lifecycle events
  static void lifecycle(String event) {
    if (kDebugMode) {
      debugPrint('🔄 $_name | Lifecycle: $event');
    }
  }
}
