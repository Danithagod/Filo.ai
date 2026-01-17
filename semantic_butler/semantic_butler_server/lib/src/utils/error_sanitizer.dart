/// Utility class for sanitizing error messages before sending to clients
/// Prevents information disclosure vulnerabilities
class ErrorSanitizer {
  /// Patterns that indicate sensitive information
  static final List<RegExp> _sensitivePatterns = [
    // Windows paths
    RegExp(r'[A-Za-z]:\\[^\s"]+', caseSensitive: false),
    // Unix paths (absolute)
    RegExp(r'/(?:home|root|var|etc|usr|tmp|opt)/[^\s"]+'),
    // Stack traces
    RegExp(r'at\s+\S+\s*\([^)]+:\d+:\d+\)'),
    // File line numbers (common in stack traces)
    RegExp(r'\([^)]+\.dart:\d+:\d+\)'),
    // Package paths
    RegExp(r'package:[^\s"]+'),
    // Internal error codes/IDs that might leak implementation details
    RegExp(r'Error\s*#?\d{4,}'),
    // IP addresses (internal)
    RegExp(r'\b(?:192\.168\.|10\.|172\.(?:1[6-9]|2[0-9]|3[01])\.)\d+\.\d+\b'),
    // API keys or tokens (common patterns)
    RegExp(
      r'(?:api[_-]?key|token|secret|password|auth)[=:]\s*[^\s"]+',
      caseSensitive: false,
    ),
    // Environment variable references
    RegExp(r'\$\{?[A-Z_][A-Z0-9_]*\}?'),
  ];

  /// Sensitive key names to remove from error details
  static const Set<String> _sensitiveKeys = {
    'raw_arguments',
    'stack_trace',
    'stackTrace',
    'internal_path',
    'server_path',
    'file_path',
    'api_key',
    'apiKey',
    'token',
    'secret',
    'password',
    'auth',
    'credentials',
  };

  /// Sanitize an error message by removing sensitive information
  /// Returns a user-friendly error message safe for client display
  static String sanitizeMessage(String message) {
    String sanitized = message;

    // Replace sensitive patterns with generic placeholders
    for (final pattern in _sensitivePatterns) {
      sanitized = sanitized.replaceAll(pattern, '[redacted]');
    }

    // Remove any remaining path-like patterns
    sanitized = _sanitizePaths(sanitized);

    // Limit message length to prevent information leakage through verbose errors
    if (sanitized.length > 500) {
      sanitized = '${sanitized.substring(0, 500)}...';
    }

    return sanitized.trim();
  }

  /// Sanitize a Map of error details, removing sensitive keys
  static Map<String, dynamic> sanitizeErrorDetails(
    Map<String, dynamic> details,
  ) {
    final sanitized = <String, dynamic>{};

    for (final entry in details.entries) {
      // Skip sensitive keys entirely
      if (_sensitiveKeys.contains(entry.key.toLowerCase())) {
        continue;
      }

      // Recursively sanitize nested maps
      if (entry.value is Map<String, dynamic>) {
        sanitized[entry.key] = sanitizeErrorDetails(
          entry.value as Map<String, dynamic>,
        );
      } else if (entry.value is String) {
        sanitized[entry.key] = sanitizeMessage(entry.value as String);
      } else if (entry.value is List) {
        sanitized[entry.key] = _sanitizeList(entry.value as List);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }

    return sanitized;
  }

  /// Sanitize a list of values
  static List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) {
        return sanitizeMessage(item);
      } else if (item is Map<String, dynamic>) {
        return sanitizeErrorDetails(item);
      } else if (item is List) {
        return _sanitizeList(item);
      }
      return item;
    }).toList();
  }

  /// Remove file system paths from a message
  static String _sanitizePaths(String message) {
    // Match common path patterns that might have been missed
    final pathPatterns = <RegExp>[
      // Windows drive letters followed by paths
      RegExp(
        r'[A-Z]:\\(?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>|\r\n]*',
        caseSensitive: false,
      ),
      // Unix-style absolute paths
      RegExp(r'/(?:[^/\s]+/)*[^/\s]+'),
    ];

    String result = message;
    for (final pattern in pathPatterns) {
      result = result.replaceAllMapped(pattern, (match) {
        final path = match.group(0) ?? '';
        // Only redact if it looks like a real path (has separators)
        if (path.contains('\\') || path.split('/').length > 2) {
          // Keep just the filename for context
          final parts = path.split(RegExp(r'[/\\]'));
          final filename = parts.isNotEmpty ? parts.last : 'file';
          return '[path]/$filename';
        }
        return path;
      });
    }

    return result;
  }

  /// Create a sanitized error response suitable for API responses
  static Map<String, dynamic> createSafeErrorResponse({
    required String message,
    String? errorType,
    Map<String, dynamic>? details,
  }) {
    final response = <String, dynamic>{
      'error': sanitizeMessage(message),
    };

    if (errorType != null) {
      response['type'] = errorType;
    }

    if (details != null) {
      response['details'] = sanitizeErrorDetails(details);
    }

    return response;
  }

  /// Wrap an exception for safe client display
  static String sanitizeException(Object exception) {
    final message = exception.toString();

    // Common exception prefixes to clean up
    final prefixes = [
      'Exception: ',
      'FormatException: ',
      'StateError: ',
      'ArgumentError: ',
      'FileSystemException: ',
      'SocketException: ',
    ];

    String cleaned = message;
    for (final prefix in prefixes) {
      if (cleaned.startsWith(prefix)) {
        cleaned = cleaned.substring(prefix.length);
        break;
      }
    }

    return sanitizeMessage(cleaned);
  }
}
