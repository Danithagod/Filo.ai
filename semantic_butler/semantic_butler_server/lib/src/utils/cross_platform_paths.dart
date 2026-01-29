import 'dart:io';

/// Cross-platform path utilities for desktop file search
class CrossPlatformPaths {
  CrossPlatformPaths._(); // Prevent instantiation

  /// Get the appropriate path separator for the current platform
  static String get separator => Platform.isWindows ? '\\' : '/';

  /// Join path parts with the correct separator
  static String join(String base, String part) {
    final cleanedBase = base.replaceAll(RegExp(r'[\\/]+$'), '');
    final cleanedPart = part.replaceAll(RegExp(r'^[\\/]+'), '');
    return '$cleanedBase$separator$cleanedPart';
  }

  /// Join multiple path parts
  static String joinAll(List<String> parts) {
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0];
    return parts.reduce((a, b) => join(a, b));
  }

  /// Normalize a path for the current platform
  static String normalize(String path) {
    if (Platform.isWindows) {
      // Convert forward slashes to backslashes on Windows
      // But preserve UNC paths (\\server\share)
      if (path.startsWith('\\\\') || path.startsWith('//')) {
        return path.replaceAll('/', '\\');
      }
      // Preserve drive letters
      final driveMatch = RegExp(r'^[a-zA-Z]:').firstMatch(path);
      if (driveMatch != null) {
        final drive = driveMatch.group(0)!;
        final rest = path.substring(drive.length).replaceAll('/', '\\');
        return '$drive$rest';
      }
      return path.replaceAll('/', '\\');
    } else {
      // Convert backslashes to forward slashes on Unix
      return path.replaceAll('\\', '/');
    }
  }

  /// Get the user's home directory
  static String get homeDirectory {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ??
          (Platform.environment['HOMEDRIVE'] != null &&
                  Platform.environment['HOMEPATH'] != null
              ? '${Platform.environment['HOMEDRIVE']}${Platform.environment['HOMEPATH']}'
              : 'C:\\Users\\${Platform.environment['USERNAME'] ?? 'Default'}');
    } else {
      return Platform.environment['HOME'] ?? '/';
    }
  }

  /// Get platform-specific special folders
  static Map<String, String> get specialFolders {
    final home = homeDirectory;
    final folders = <String, String>{};

    // Common folders across all platforms
    folders['desktop'] = _joinSafe(home, 'Desktop');
    folders['documents'] = _joinSafe(home, 'Documents');
    folders['downloads'] = _joinSafe(home, 'Downloads');
    folders['pictures'] = _joinSafe(home, 'Pictures');
    folders['videos'] = _joinSafe(home, 'Videos');
    folders['music'] = _joinSafe(home, 'Music');

    if (Platform.isWindows) {
      // Windows-specific folders
      final appData =
          Platform.environment['APPDATA'] ??
          _joinSafe(home, r'AppData\Roaming');
      final localAppData =
          Platform.environment['LOCALAPPDATA'] ??
          _joinSafe(home, r'AppData\Local');
      final programData =
          Platform.environment['ProgramData'] ?? r'C:\ProgramData';

      folders['appdata'] = appData;
      folders['localappdata'] = localAppData;
      folders['programdata'] = programData;
      folders['roaming'] = appData;
      folders['startup'] = _joinSafe(
        appData,
        r'Microsoft\Windows\Start Menu\Programs\Startup',
      );
      folders['temp'] =
          Platform.environment['TEMP'] ?? _joinSafe(localAppData, 'Temp');
    } else if (Platform.isMacOS) {
      // macOS-specific folders
      folders['library'] = _joinSafe(home, 'Library');
      folders['application_support'] = _joinSafe(
        home,
        'Library',
        'Application Support',
      );
      folders['caches'] = _joinSafe(home, 'Library', 'Caches');
      folders['temp'] = '/tmp';
    } else {
      // Linux-specific folders
      folders['config'] =
          Platform.environment['XDG_CONFIG_HOME'] ?? _joinSafe(home, '.config');
      folders['local'] = _joinSafe(home, '.local');
      folders['cache'] =
          Platform.environment['XDG_CACHE_HOME'] ?? _joinSafe(home, '.cache');
      folders['temp'] = '/tmp';
    }

    return folders;
  }

  /// Get a specific special folder by name
  static String? getSpecialFolder(String name) {
    final lowerName = name.toLowerCase();
    final folders = specialFolders;

    // Direct match
    if (folders.containsKey(lowerName)) {
      return folders[lowerName];
    }

    // Fuzzy match for common aliases
    final aliases = {
      'docs': 'documents',
      'pics': 'pictures',
      'movies': 'videos',
      'apps': 'application_support',
    };

    final key = aliases[lowerName] ?? lowerName;
    return folders[key];
  }

  /// Check if a path is absolute
  static bool isAbsolute(String path) {
    if (Platform.isWindows) {
      // Windows: C:\, \\server\share, or / (for Unix-style paths on Windows)
      return RegExp(r'^[a-zA-Z]:\\|\\\\|^[a-zA-Z]:/|^//').hasMatch(path);
    } else {
      // Unix: starts with /
      return path.startsWith('/');
    }
  }

  /// Get the root path for the platform
  static String get rootPath {
    if (Platform.isWindows) {
      // Return first available drive or C:\
      return 'C:\\';
    } else {
      return '/';
    }
  }

  /// Get all available root paths (drives on Windows, just / on Unix)
  /// Async version to allow for shell commands
  static Future<List<String>> getRootPaths() async {
    if (Platform.isWindows) {
      return await _getWindowsDrivesAsync();
    } else {
      return ['/'];
    }
  }

  /// Get all available root paths (synchronous, best effort/fallback)
  /// CAUTION: On Windows, this may not list all drives to avoid blocking
  static List<String> get rootPaths {
    if (Platform.isWindows) {
      // Safe synchronous fallback - usually C: is enough for validations
      // Use getRootPaths() for full drive listing
      return ['C:\\'];
    } else {
      return ['/'];
    }
  }

  /// Get Windows drive letters using PowerShell for safety
  static Future<List<String>> _getWindowsDrivesAsync() async {
    try {
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          'Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root',
        ],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split(RegExp(r'\r\n|\r|\n'));
        final drives = lines
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty && l.endsWith(':\\'))
            .toList();

        if (drives.isNotEmpty) return drives;
      }
    } catch (_) {
      // Fallback if PowerShell fails
    }

    // Fallback: Check common drives safely (Skip A/B to avoid floppy noise)
    final drives = <String>[];
    for (final letter in 'CDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
      final path = '$letter:\\';
      try {
        if (await Directory(path).exists()) {
          drives.add(path);
        }
      } catch (_) {}
    }
    return drives.isEmpty ? ['C:\\'] : drives;
  }

  /// Safe path join that handles nulls and errors
  static String _joinSafe(String base, String part, [String? part2]) {
    try {
      if (part2 != null) {
        return join(join(base, part), part2);
      }
      return join(base, part);
    } catch (_) {
      return base;
    }
  }

  /// Check if a path refers to a hidden file/folder
  static bool isHidden(String path) {
    if (Platform.isWindows) {
      // On Windows, check if name starts with '.'
      final name = path.split(RegExp(r'[\\/]')).last;
      return name.startsWith('.');
    } else {
      // On Unix, hidden files start with '.'
      final parts = path.split('/');
      for (final part in parts) {
        if (part.startsWith('.') && part != '.' && part != '..') {
          return true;
        }
      }
      return false;
    }
  }

  /// Resolve a path that may contain ~ or environment variables
  static String expand(String path) {
    var expanded = path;

    // Expand ~ to home directory
    if (expanded.startsWith('~')) {
      expanded = homeDirectory + expanded.substring(1);
    }

    // Expand environment variables on Windows
    if (Platform.isWindows) {
      final envVarPattern = RegExp(r'%([^%]+)%');
      expanded = expanded.replaceAllMapped(envVarPattern, (match) {
        return Platform.environment[match.group(1)] ?? match.group(0)!;
      });

      // Also handle $VAR style for consistency
      final dollarVarPattern = RegExp(r'\$([a-zA-Z_][a-zA-Z0-9_]*)');
      expanded = expanded.replaceAllMapped(dollarVarPattern, (match) {
        return Platform.environment[match.group(1)] ?? match.group(0)!;
      });
    } else {
      // Expand $VAR or ${VAR} style environment variables
      final envVarPattern = RegExp(
        r'\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}|\$([a-zA-Z_][a-zA-Z0-9_]*)',
      );
      expanded = expanded.replaceAllMapped(envVarPattern, (match) {
        return Platform.environment[match.group(1) ?? match.group(2)] ??
            match.group(0)!;
      });
    }

    return expanded;
  }

  /// Check if a path is within another path
  static bool isWithin(String child, String parent) {
    final normalizedChild = normalize(child);
    final normalizedParent = normalize(parent);
    return normalizedChild.startsWith(normalizedParent + separator) ||
        normalizedChild == normalizedParent;
  }

  /// Get the relative path from one path to another
  static String relative(String from, String to) {
    final normalizedFrom = normalize(from);
    final normalizedTo = normalize(to);

    if (Platform.isWindows) {
      // Different drives on Windows - no relative path possible
      final fromDrive = RegExp(r'^[a-zA-Z]:').firstMatch(normalizedFrom);
      final toDrive = RegExp(r'^[a-zA-Z]:').firstMatch(normalizedTo);
      if (fromDrive != null &&
          toDrive != null &&
          fromDrive.group(0) != toDrive.group(0)) {
        return normalizedTo;
      }
    }

    // Simple implementation - for full functionality, consider using the path package
    if (normalizedTo.startsWith(normalizedFrom)) {
      final suffix = normalizedTo.substring(normalizedFrom.length);
      return suffix.replaceAll(RegExp(r'^[\\/]+'), '');
    }

    return normalizedTo;
  }

  // ==========================================================================
  // CASE SENSITIVITY
  // ==========================================================================

  /// Compare two paths considering platform case sensitivity
  ///
  /// On Windows: case-insensitive comparison
  /// On Unix: case-sensitive comparison
  static bool pathsEqual(String path1, String path2) {
    final normalized1 = normalize(path1);
    final normalized2 = normalize(path2);

    if (Platform.isWindows) {
      return normalized1.toLowerCase() == normalized2.toLowerCase();
    }
    return normalized1 == normalized2;
  }

  /// Check if a path starts with a prefix (case-aware)
  static bool pathStartsWith(String path, String prefix) {
    final normalizedPath = normalize(path);
    final normalizedPrefix = normalize(prefix);

    if (Platform.isWindows) {
      return normalizedPath.toLowerCase().startsWith(
        normalizedPrefix.toLowerCase(),
      );
    }
    return normalizedPath.startsWith(normalizedPrefix);
  }

  /// Check if a path contains a substring (case-aware)
  static bool pathContains(String path, String substring) {
    final normalizedPath = normalize(path);
    final normalizedSubstring = normalize(substring);

    if (Platform.isWindows) {
      return normalizedPath.toLowerCase().contains(
        normalizedSubstring.toLowerCase(),
      );
    }
    return normalizedPath.contains(normalizedSubstring);
  }

  /// Convert a glob pattern to a regex
  static RegExp globToRegex(String pattern, {bool caseSensitive = true}) {
    var regex = pattern.replaceAll('*', '.*');
    regex = regex.replaceAll('?', '.');
    return RegExp('^$regex\$', caseSensitive: caseSensitive);
  }

  /// Check if a filename matches a pattern (handles * and ? wildcards)
  ///
  /// On Windows: matching is case-insensitive
  /// On Unix: matching is case-sensitive
  static bool matchesPattern(String filename, String pattern) {
    final regex = globToRegex(pattern, caseSensitive: !Platform.isWindows);
    return regex.hasMatch(filename);
  }

  /// Check if a filename matches a pattern with explicit case sensitivity
  static bool matchesPatternCaseSensitive(
    String filename,
    String pattern, {
    bool caseSensitive = true,
  }) {
    final regex = globToRegex(pattern, caseSensitive: caseSensitive);
    return regex.hasMatch(filename);
  }

  // ==========================================================================
  // PATH VALIDATION / SECURITY
  // ==========================================================================

  /// Get the list of allowed search root directories
  /// These are safe directories that users can search within
  static List<String> get allowedSearchRoots {
    final home = homeDirectory;
    final allowed = <String>[
      home,
      ...specialFolders.values,
    ];

    // On Windows, also allow drive roots that exist
    if (Platform.isWindows) {
      for (final letter in 'CDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
        allowed.add('$letter:\\');
        allowed.add('$letter:/');
      }
    } else {
      // On Unix, allow common safe directories
      allowed.addAll([
        '/home',
        '/Users',
        '/tmp',
        '/var/tmp',
      ]);
    }

    return allowed;
  }

  /// Directories that should never be searched (security/performance)
  static List<String> get forbiddenPaths {
    if (Platform.isWindows) {
      return [
        r'C:\Windows',
        r'C:\Program Files',
        r'C:\Program Files (x86)',
        r'C:\$Recycle.Bin',
        r'C:\System Volume Information',
        r'C:\Recovery',
        r'C:\PerfLogs',
      ];
    } else if (Platform.isMacOS) {
      return [
        '/System',
        '/Library',
        '/private/var',
        '/usr',
        '/bin',
        '/sbin',
        '/etc',
        '/dev',
        '/proc',
        '/.Spotlight-V100',
        '/.fseventsd',
      ];
    } else {
      return [
        '/bin',
        '/sbin',
        '/usr',
        '/etc',
        '/dev',
        '/proc',
        '/sys',
        '/boot',
        '/root',
        '/var/log',
        '/var/run',
      ];
    }
  }

  /// Validate that a path is safe to search
  /// Returns true if the path is within allowed directories and not forbidden
  static bool isPathSafeToSearch(String path) {
    final normalizedPath = normalize(path);

    // Check if path is in forbidden list
    for (final forbidden in forbiddenPaths) {
      if (pathStartsWith(normalizedPath, forbidden)) {
        return false;
      }
    }

    // Check for path traversal attempts
    if (normalizedPath.contains('..')) {
      // Resolve the path and check again
      try {
        final resolved = Directory(normalizedPath).absolute.path;
        for (final forbidden in forbiddenPaths) {
          if (pathStartsWith(resolved, forbidden)) {
            return false;
          }
        }
      } catch (_) {
        return false;
      }
    }

    return true;
  }

  /// Validate and sanitize a user-provided path for search
  /// Returns the sanitized path or null if invalid/unsafe
  static String? validateSearchPath(String path) {
    if (path.isEmpty) return null;

    // Expand environment variables and ~
    final expanded = expand(path);
    final normalized = normalize(expanded);

    // Check if path is safe
    if (!isPathSafeToSearch(normalized)) {
      return null;
    }

    return normalized;
  }

  /// Platform detection helpers
  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;
  static bool get isUnix => !Platform.isWindows;

  /// Get platform name for logging/messages
  static String get platformName {
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }
}
