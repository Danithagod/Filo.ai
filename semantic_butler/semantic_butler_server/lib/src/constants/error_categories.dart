/// Error categories for indexing failures
class ErrorCategory {
  /// API timeout during embedding generation
  static const String apiTimeout = 'APITimeout';

  /// Corrupt or unreadable file
  static const String corruptFile = 'CorruptFile';

  /// Permission denied accessing file
  static const String permissionDenied = 'PermissionDenied';

  /// Network error during API call
  static const String networkError = 'NetworkError';

  /// Unsupported file format
  static const String unsupportedFormat = 'UnsupportedFormat';

  /// Insufficient disk space
  static const String insufficientDiskSpace = 'InsufficientDiskSpace';

  /// Unknown error
  static const String unknown = 'Unknown';
}
