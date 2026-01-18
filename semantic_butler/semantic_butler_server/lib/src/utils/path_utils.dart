import 'dart:io';

/// Utility for platform-aware path operations
///
/// Handles Windows case-insensitivity and path separator differences
/// for consistent path comparison across platforms.
class PathUtils {
  PathUtils._(); // Prevent instantiation

  /// Normalize a path for consistent comparison
  ///
  /// On Windows: converts to lowercase and uses backslash
  /// On other platforms: returns path as-is
  static String normalize(String path) {
    if (Platform.isWindows) {
      return path.toLowerCase().replaceAll('/', r'\');
    }
    return path;
  }

  /// Compare two paths in a platform-aware manner
  ///
  /// On Windows: case-insensitive comparison
  /// On other platforms: case-sensitive comparison
  static bool equals(String a, String b) {
    return normalize(a) == normalize(b);
  }

  /// Check if a path starts with a prefix (platform-aware)
  static bool startsWith(String path, String prefix) {
    return normalize(path).startsWith(normalize(prefix));
  }
}
