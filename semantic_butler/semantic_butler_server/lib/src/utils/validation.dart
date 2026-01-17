/// Input validation utilities for public endpoints
///
/// Provides security validation to prevent SQL injection, path traversal,
/// and other malicious input attacks.
class InputValidation {
  /// Maximum allowed query length
  static const int maxQueryLength = 1000;

  /// Maximum allowed path length
  static const int maxPathLength = 4096;

  /// SQL injection patterns to detect
  static final RegExp _sqlPatterns = RegExp(
    r"(--|;|/\*|\*/|xp_|sp_|exec|execute|insert|update|delete|drop|alter|create|truncate)",
    caseSensitive: false,
  );

  /// Validate search query input
  static void validateSearchQuery(String query) {
    if (query.length > maxQueryLength) {
      throw ValidationException(
        'Query exceeds maximum length of $maxQueryLength characters',
      );
    }
    if (_sqlPatterns.hasMatch(query)) {
      throw ValidationException('Query contains invalid characters');
    }
  }

  /// Validate file path for traversal attacks
  static void validateFilePath(String path) {
    if (path.isEmpty) {
      throw ValidationException('Path cannot be empty');
    }
    if (path.length > maxPathLength) {
      throw ValidationException(
        'Path exceeds maximum length of $maxPathLength characters',
      );
    }
    if (path.contains('../') || path.contains('..\\')) {
      throw ValidationException('Path traversal detected');
    }
    // Prevent null bytes
    if (path.contains('\x00')) {
      throw ValidationException('Null byte in path detected');
    }
  }

  /// Validate pagination limit
  static void validateLimit(int limit, {int max = 100}) {
    if (limit < 1 || limit > max) {
      throw ValidationException('Limit must be between 1 and $max');
    }
  }

  /// Validate threshold is in valid range
  static void validateThreshold(double threshold) {
    if (threshold < 0.0 || threshold > 1.0) {
      throw ValidationException('Threshold must be between 0.0 and 1.0');
    }
  }

  /// Validate positive integer ID
  static void validateId(int id) {
    if (id < 1) {
      throw ValidationException('ID must be a positive integer');
    }
  }

  /// Validate pattern for glob patterns (ignore patterns)
  static void validatePattern(String pattern) {
    if (pattern.isEmpty) {
      throw ValidationException('Pattern cannot be empty');
    }
    if (pattern.length > 500) {
      throw ValidationException('Pattern exceeds maximum length');
    }
    // Prevent potential ReDoS by limiting repetitions
    if (RegExp(r'(\*{3,}|\?{3,})').hasMatch(pattern)) {
      throw ValidationException('Pattern contains excessive wildcards');
    }
  }
}

/// Exception thrown when input validation fails
class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
