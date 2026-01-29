import 'dart:io';

/// Path validation utility for security
/// 
/// Prevents access to dangerous system directories and validates
/// search paths to protect sensitive system files.
class PathValidator {
  /// Dangerous paths that should never be searched
  static final List<String> _dangerousPaths = [
    // Linux/Unix system directories
    '/etc', '/sys', '/proc', '/dev', '/boot', '/root',
    '/var/log', '/var/run', '/var/lib',
    
    // macOS system directories
    '/System', '/Library/System', '/private/etc',
    '/private/var', '/cores',
    
    // Windows system directories
    r'C:\Windows\System32', r'C:\Windows\SysWOW64',
    r'C:\Windows\WinSxS', r'C:\ProgramData\Microsoft',
    r'C:\$Recycle.Bin', r'C:\System Volume Information',
  ];

  /// Allowed base paths for searching
  static final List<String> _allowedPaths = [
    // Linux/Unix user directories
    '/home', '/mnt', '/media',
    
    // macOS user directories
    '/Users', '/Volumes',
    
    // Windows user directories and drives
    r'C:\Users', r'D:\', r'E:\', r'F:\', r'G:\',
  ];

  /// Check if a path is safe to search
  static bool isPathSafe(String path) {
    if (path.isEmpty) return false;
    
    final normalized = _normalizePath(path);
    
    // Check against dangerous paths
    for (final dangerous in _dangerousPaths) {
      final normalizedDangerous = _normalizePath(dangerous);
      if (normalized.startsWith(normalizedDangerous)) {
        return false;
      }
    }
    
    // Check if in allowed paths
    for (final allowed in _allowedPaths) {
      final normalizedAllowed = _normalizePath(allowed);
      if (normalized.startsWith(normalizedAllowed)) {
        return true;
      }
    }
    
    // Deny by default for security
    return false;
  }

  /// Validate and sanitize a search path
  static String? validateSearchPath(String path) {
    if (!isPathSafe(path)) {
      return null;
    }
    
    // Check if path exists
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) {
        return null;
      }
    } catch (e) {
      return null;
    }
    
    return path;
  }

  /// Normalize path for comparison
  static String _normalizePath(String path) {
    return path
        .toLowerCase()
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+$'), ''); // Remove trailing slashes
  }

  /// Check if path contains path traversal attempts
  static bool hasPathTraversal(String path) {
    return path.contains('..') || 
           path.contains('~') ||
           path.contains('0');
  }

  /// Get list of allowed base paths for current platform
  static List<String> getAllowedBasePaths() {
    if (Platform.isWindows) {
      return _allowedPaths.where((p) => p.contains(':')).toList();
    } else if (Platform.isMacOS) {
      return ['/Users', '/Volumes'];
    } else {
      return ['/home', '/mnt', '/media'];
    }
  }
}
