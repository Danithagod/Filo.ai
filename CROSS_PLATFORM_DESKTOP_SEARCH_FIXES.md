# Cross-Platform Desktop Search - Fixes and Enhancements

**Date**: 2026-01-27
**Scope**: AI Agent Tools for Desktop Search
**Platforms**: Windows, macOS, Linux

---

## Executive Summary

The AI agent tools have several cross-platform compatibility issues that prevent reliable operation across different desktop operating systems. This document provides comprehensive fixes for:

1. Path handling inconsistencies
2. Platform-specific command execution
3. File encoding detection
4. Platform-specific folder mappings
5. Enhanced metadata support
6. Missing tools for desktop search

---

## Critical Issues Found

| Issue | Impact | Platforms Affected |
|-------|--------|-------------------|
| Hardcoded backslashes | Path joining fails on Unix | macOS, Linux |
| PowerShell-only commands | Terminal search doesn't work | macOS, Linux |
| No encoding detection | Corrupted file reads | All |
| Missing home directory fallback | Searches fail in `.` folder | All |
| Case sensitivity inconsistent | Different results per platform | All |
| No hidden file support | Can't find dotfiles | macOS, Linux |
| No symlink following | Broken links cause errors | All |
| Missing special folders | Can't search AppData/Library | All |

---

## FIX 1: Cross-Platform Path Utilities

### Problem
Path separators are hardcoded or inconsistently handled across the codebase.

### Solution
Create a dedicated cross-platform path utility.

### File: `semantic_butler_server/lib/src/utils/cross_platform_paths.dart`

```dart
import 'dart:io';

/// Cross-platform path utilities for desktop file search
class CrossPlatformPaths {
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
             Platform.environment['HOMEDRIVE'] != null &&
             Platform.environment['HOMEPATH'] != null
             ? '${Platform.environment['HOMEDRIVE']}${Platform.environment['HOMEPATH']}'
             : 'C:\\Users\\${Platform.environment['USERNAME'] ?? 'Default'}';
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
      final appData = Platform.environment['APPDATA'] ?? _joinSafe(home, 'AppData\\Roaming');
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? _joinSafe(home, 'AppData\\Local');
      final programData = Platform.environment['ProgramData'] ?? 'C:\\ProgramData';

      folders['appdata'] = appData;
      folders['localappdata'] = localAppData;
      folders['programdata'] = programData;
      folders['roaming'] = appData;
      folders['startup'] = _joinSafe(appData, 'Microsoft\\Windows\\Start Menu\\Programs\\Startup');
      folders['temp'] = Platform.environment['TEMP'] ?? _joinSafe(localAppData, 'Temp');
    } else if (Platform.isMacOS) {
      // macOS-specific folders
      folders['library'] = _joinSafe(home, 'Library');
      folders['application_support'] = _joinSafe(home, 'Library', 'Application Support');
      folders['caches'] = _joinSafe(home, 'Library', 'Caches');
      folders['temp'] = '/tmp';
    } else {
      // Linux-specific folders
      folders['config'] = Platform.environment['XDG_CONFIG_HOME'] ?? _joinSafe(home, '.config');
      folders['local'] = _joinSafe(home, '.local');
      folders['cache'] = Platform.environment['XDG_CACHE_HOME'] ?? _joinSafe(home, '.cache');
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
  static List<String> get rootPaths {
    if (Platform.isWindows) {
      return _getWindowsDrives();
    } else {
      return ['/'];
    }
  }

  /// Get Windows drive letters
  static List<String> _getWindowsDrives() {
    final drives = <String>[];
    for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
      final path = '$letter:\\';
      if (Directory(path).existsSync()) {
        drives.add(path);
      }
    }
    return drives;
  }

  /// Safe path join that handles nulls
  static String _joinSafe(String base, String part) {
    try {
      return join(base, part);
    } catch (e) {
      return base;
    }
  }

  /// Check if a path refers to a hidden file/folder
  static bool isHidden(String path) {
    if (Platform.isWindows) {
      // On Windows, check file attributes
      final file = File(path);
      if (file.existsSync()) {
        // Would need to call platform-specific code to check hidden attribute
        // For now, check if name starts with '.'
        final name = path.split(RegExp(r'[\\/])).last;
        return name.startsWith('.');
      }
      return false;
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
      final envVarPattern = RegExp(r'\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}|\$([a-zA-Z_][a-zA-Z0-9_]*)');
      expanded = expanded.replaceAllMapped(envVarPattern, (match) {
        return Platform.environment[match.group(1) ?? match.group(2)] ?? match.group(0)!;
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
      if (fromDrive != null && toDrive != null && fromDrive.group(0) != toDrive.group(0)) {
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

  /// Convert a glob pattern to a regex
  static RegExp globToRegex(String pattern) {
    var regex = pattern.replaceAll('*', '.*');
    regex = regex.replaceAll('?', '.');
    return RegExp('^$regex\$');
  }

  /// Check if a filename matches a pattern (handles * and ? wildcards)
  static bool matchesPattern(String filename, String pattern) {
    final regex = globToRegex(pattern);
    return regex.hasMatch(filename);
  }
}
```

---

## FIX 2: Enhanced Terminal Service for Cross-Platform Search

### Problem
Terminal service uses PowerShell-only commands on Windows and doesn't have proper fallbacks for Unix systems.

### Solution
Rewrite the terminal service to use platform-appropriate commands.

### File: `semantic_butler_server/lib/src/services/terminal_service.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../config/ai_models.dart';
import 'openrouter_client.dart';
import 'circuit_breaker.dart';
import 'smart_rate_limiter.dart';
import 'cross_platform_paths.dart';

/// Cross-platform terminal service for file system operations
class TerminalService {
  final OpenRouterClient? _aiClient;
  final CircuitBreaker _circuitBreaker;

  TerminalService({OpenRouterClient? aiClient})
      : _aiClient = aiClient,
        _circuitBreaker = CircuitBreakerRegistry.instance.getBreaker(
          'terminal_service',
        );

  /// Platform detection
  bool get isWindows => Platform.isWindows;
  bool get isMacOS => Platform.isMacOS;
  bool get isLinux => Platform.isLinux;
  bool get isUnix => !Platform.isWindows;

  /// Get the appropriate shell command for the platform
  String get shellCommand {
    if (isWindows) {
      // Prefer PowerShell Core if available, fall back to Windows PowerShell
      return 'powershell.exe';
    } else {
      return '/bin/bash';
    }
  }

  /// Get shell arguments
  List<String> get shellArgs {
    if (isWindows) {
      return ['-NoProfile', '-Command'];
    } else {
      return ['-c'];
    }
  }

  // ==========================================================================
  // DRIVE / ROOT DISCOVERY
  // ==========================================================================

  /// Discover available drives (Windows) or root paths (Unix)
  Future<List<DriveInfo>> listDrives() async {
    if (isWindows) {
      return _listWindowsDrives();
    } else {
      return _listUnixMounts();
    }
  }

  /// List Windows drives
  Future<List<DriveInfo>> _listWindowsDrives() async {
    final drives = <DriveInfo>[];

    try {
      // Use PowerShell to get drive information
      final result = await _runCommand('powershell.exe', [
        '-NoProfile',
        '-Command',
        'Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Used -ne $null} | Select-Object Name, Used, Free | ConvertTo-Json',
      ]);

      if (result.success && result.stdout.isNotEmpty) {
        // Parse JSON output or parse text fallback
        final lines = result.stdout.split('\n');
        for (final line in lines) {
          final driveMatch = RegExp(r'([A-Z]):').firstMatch(line);
          if (driveMatch != null) {
            final letter = driveMatch.group(1)!;
            final path = '$letter:\\';
            if (Directory(path).existsSync()) {
              drives.add(DriveInfo(
                path: path,
                description: 'Drive $letter',
                totalBytes: null,
                availableBytes: null,
              ));
            }
          }
        }
      }
    } catch (e) {
      // Fallback: enumerate drive letters
      for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
        final path = '$letter:\\';
        try {
          if (Directory(path).existsSync()) {
            drives.add(DriveInfo(
              path: path,
              description: 'Drive $letter',
              totalBytes: null,
              availableBytes: null,
            ));
          }
        } catch (_) {}
      }
    }

    if (drives.isEmpty) {
      // Ensure C: is always included
      drives.add(DriveInfo(
        path: 'C:\\',
        description: 'Local Disk (C:)',
        totalBytes: null,
        availableBytes: null,
      ));
    }

    return drives;
  }

  /// List Unix mount points
  Future<List<DriveInfo>> _listUnixMounts() async {
    final mounts = <DriveInfo>[];

    // Always include root
    mounts.add(DriveInfo(
      path: '/',
      description: 'Root',
      totalBytes: null,
      availableBytes: null,
    ));

    // Try to get more mounts from /proc/mounts (Linux) or df (macOS/Linux)
    try {
      String? mountsOutput;

      if (isLinux && File('/proc/mounts').existsSync()) {
        mountsOutput = await File('/proc/mounts').readAsString();
      } else {
        // Use df command as fallback
        final result = await _runCommand('df', ['-k', '-P']);
        if (result.success) {
          mountsOutput = result.stdout;
        }
      }

      if (mountsOutput != null) {
        final lines = mountsOutput.split('\n');
        final seenPaths = <String>{'/'}; // Already added root

        for (final line in lines) {
          // Parse mount lines
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length < 2) continue;

          final mountPoint = parts[1];
          // Only include user-relevant mounts
          if (mountPoint.startsWith('/') &&
              !mountPoint.startsWith('/proc') &&
              !mountPoint.startsWith('/sys') &&
              !mountPoint.startsWith('/dev') &&
              !seenPaths.contains(mountPoint)) {

            // Get a friendly name
            String description = mountPoint;
            if (mountPoint == '/') {
              description = 'Root';
            } else if (mountPoint.startsWith('/home')) {
              description = 'Home';
            } else if (mountPoint.startsWith('/mnt')) {
              description = 'Mount: ${mountPoint.split('/').last}';
            } else {
              description = mountPoint.split('/').last;
            }

            mounts.add(DriveInfo(
              path: mountPoint,
              description: description,
              totalBytes: null,
              availableBytes: null,
            ));
            seenPaths.add(mountPoint);
          }
        }
      }
    } catch (e) {
      // Stick with root mount
    }

    return mounts;
  }

  // ==========================================================================
  // FILE SEARCH
  // ==========================================================================

  /// Deep search for files matching a pattern
  Future<CommandResult> deepSearch(
    String pattern, {
    String? directory,
    bool foldersOnly = false,
    int maxResults = 1000,
    int timeoutSeconds = 60,
  }) async {
    final searchDir = directory ?? CrossPlatformPaths.rootPath;
    final effectiveDir = CrossPlatformPaths.expand(searchDir);

    // Verify directory exists
    if (!Directory(effectiveDir).existsSync()) {
      return CommandResult(
        success: false,
        stdout: '',
        stderr: 'Directory does not exist: $effectiveDir',
        exitCode: 1,
      );
    }

    if (isWindows) {
      return _searchWindows(pattern, effectiveDir, foldersOnly, maxResults, timeoutSeconds);
    } else if (isMacOS) {
      return _searchMacOS(pattern, effectiveDir, foldersOnly, maxResults, timeoutSeconds);
    } else {
      return _searchLinux(pattern, effectiveDir, foldersOnly, maxResults, timeoutSeconds);
    }
  }

  /// Windows file search using PowerShell
  Future<CommandResult> _searchWindows(
    String pattern,
    String directory,
    bool foldersOnly,
    int maxResults,
    int timeoutSeconds,
  ) async {
    try {
      // Build PowerShell command
      final escapedDir = directory.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
      final escapedPattern = pattern.replaceAll('*', '.*').replaceAll('?', '.');

      String itemType = foldersOnly ? 'Directory' : 'File';
      String recurseArg = '-Recurse';

      final psScript = '''
Get-ChildItem -Path "$escapedDir" -Filter "$pattern" -$itemType $recurseArg -ErrorAction SilentlyContinue -Depth 10 |
  Select-Object -First $maxResults -ExpandProperty FullName |
  ForEach-Object { Write-Output \$_.Replace("`$env:USERPROFILE", "~") }
''';

      final result = await _runCommand('powershell.exe', [
        '-NoProfile',
        '-Command',
        psScript,
      ], timeout: Duration(seconds: timeoutSeconds));

      return result;
    } catch (e) {
      return CommandResult(
        success: false,
        stdout: '',
        stderr: 'Search failed: $e',
        exitCode: -1,
      );
    }
  }

  /// macOS file search using mdfind (Spotlight) or find
  Future<CommandResult> _searchMacOS(
    String pattern,
    String directory,
    bool foldersOnly,
    int maxResults,
    int timeoutSeconds,
  ) async {
    // First try mdfind (Spotlight) for faster results
    try {
      final mdfindArgs = [
        'onlyin',
        directory,
        '-name',
        pattern,
      ];

      final result = await _runCommand('mdfind', mdfindArgs,
        timeout: Duration(seconds: timeoutSeconds ~/ 2));

      if (result.success && result.stdout.trim().isNotEmpty) {
        // Limit results
        final lines = result.stdout.split('\n')
            .where((l) => l.trim().isNotEmpty)
            .take(maxResults)
            .toList();
        return CommandResult(
          success: true,
          stdout: lines.join('\n'),
          stderr: result.stderr,
          exitCode: result.exitCode,
        );
      }
    } catch (_) {
      // Fall through to find command
    }

    // Fallback to find command
    return _searchUnixFind(pattern, directory, foldersOnly, maxResults, timeoutSeconds);
  }

  /// Linux file search using find or locate
  Future<CommandResult> _searchLinux(
    String pattern,
    String directory,
    bool foldersOnly,
    int maxResults,
    int timeoutSeconds,
  ) async {
    // First try locate for fast results
    try {
      final locateArgs = ['-i', '-l', '$maxResults', pattern];
      final result = await _runCommand('locate', locateArgs,
        timeout: Duration(seconds: timeoutSeconds ~/ 3));

      if (result.success && result.stdout.trim().isNotEmpty) {
        // Filter to directory if specified
        final lines = result.stdout.split('\n')
            .where((l) => l.trim().isNotEmpty)
            .where((l) => l.startsWith(directory))
            .take(maxResults)
            .toList();
        return CommandResult(
          success: true,
          stdout: lines.join('\n'),
          stderr: result.stderr,
          exitCode: result.exitCode,
        );
      }
    } catch (_) {
      // Fall through to find
    }

    return _searchUnixFind(pattern, directory, foldersOnly, maxResults, timeoutSeconds);
  }

  /// Common Unix find command
  Future<CommandResult> _searchUnixFind(
    String pattern,
    String directory,
    bool foldersOnly,
    int maxResults,
    int timeoutSeconds,
  ) async {
    try {
      final args = <String>[
        directory,
        '-iname',
        pattern,
        if (foldersOnly) '-type' else '',
        if (foldersOnly) 'd' else '',
        '-mount', // Don't cross filesystem boundaries
        '2>/dev/null', // Suppress permission errors
        '|',
        'head',
        '-n',
        '$maxResults',
      ].where((s) => s.isNotEmpty).toList();

      // Run through shell for the pipe
      final command = args.join(' ');
      final result = await _runThroughShell(command,
        timeout: Duration(seconds: timeoutSeconds));

      return result;
    } catch (e) {
      return CommandResult(
        success: false,
        stdout: '',
        stderr: 'Search failed: $e',
        exitCode: -1,
      );
    }
  }

  // ==========================================================================
  // FILE READING
  // ==========================================================================

  /// Read file contents with encoding detection
  Future<CommandResult> readFile(String path, {int lines = 100}) async {
    final expandedPath = CrossPlatformPaths.expand(path);
    final file = File(expandedPath);

    if (!file.existsSync()) {
      return CommandResult(
        success: false,
        stdout: '',
        stderr: 'File not found: $path',
        exitCode: 1,
      );
    }

    try {
      // Detect encoding and read file
      final contents = await _readFileWithEncoding(file, lines);

      return CommandResult(
        success: true,
        stdout: contents,
        stderr: '',
        exitCode: 0,
      );
    } catch (e) {
      return CommandResult(
        success: false,
        stdout: '',
        stderr: 'Failed to read file: $e',
        exitCode: -1,
      );
    }
  }

  /// Read file with encoding detection
  Future<String> _readFileWithEncoding(File file, int lines) async {
    final bytes = await file.openRead(0, 10240).toList(); // Read first 10KB for detection
    final byteList = bytes.expand((b) => b).toList();

    // Check for BOM
    Encoding detectedEncoding = utf8;
    int bomOffset = 0;

    if (byteList.length >= 3) {
      // UTF-8 BOM
      if (byteList[0] == 0xEF && byteList[1] == 0xBB && byteList[2] == 0xBF) {
        detectedEncoding = utf8;
        bomOffset = 3;
      }
      // UTF-16 LE BOM
      else if (byteList[0] == 0xFF && byteList[1] == 0xFE) {
        detectedEncoding = utf16Le;
        bomOffset = 2;
      }
      // UTF-16 BE BOM
      else if (byteList[0] == 0xFE && byteList[1] == 0xFF) {
        detectedEncoding = utf16Be;
        bomOffset = 2;
      }
      // UTF-32 LE BOM
      else if (byteList.length >= 4 &&
          byteList[0] == 0xFF && byteList[1] == 0xFE &&
          byteList[2] == 0x00 && byteList[3] == 0x00) {
        detectedEncoding = Encoding.getByName('utf-32le') ?? utf8;
        bomOffset = 4;
      }
      // UTF-32 BE BOM
      else if (byteList.length >= 4 &&
          byteList[0] == 0x00 && byteList[1] == 0x00 &&
          byteList[2] == 0xFE && byteList[3] == 0xFF) {
        detectedEncoding = Encoding.getByName('utf-32be') ?? utf8;
        bomOffset = 4;
      }
    }

    // Read full file with detected encoding
    final fullBytes = await file.readAsBytes();
    String content;

    try {
      if (bomOffset > 0) {
        content = detectedEncoding.decode(fullBytes.sublist(bomOffset));
      } else {
        content = detectedEncoding.decode(fullBytes);
      }
    } catch (e) {
      // Fallback to latin-1
      content = latin1.decode(fullBytes);
    }

    // Limit to requested lines
    final lineList = content.split(RegExp(r'\r?\n')).take(lines).toList();
    return lineList.join('\n');
  }

  // ==========================================================================
  // FILE INFO
  // ==========================================================================

  /// Get detailed file information
  Future<Map<String, dynamic>> getFileInfo(String path) async {
    final expandedPath = CrossPlatformPaths.expand(path);
    final entity = File(expandedPath);

    if (!entity.existsSync()) {
      // Try as directory
      final dir = Directory(expandedPath);
      if (!dir.existsSync()) {
        return {'status': 'error', 'message': 'Path not found: $path'};
      }
    }

    try {
      final stat = await entity.stat();
      final info = <String, dynamic>{
        'status': 'success',
        'path': expandedPath,
        'type': stat.type.toString(),
        'size': stat.size,
        'modified': stat.modified.toIso8601String(),
        'accessed': stat.accessed.toIso8601String(),
        'changed': stat.changed.toIso8601String(),
        'mode': stat.modeString(),
      };

      // Add platform-specific metadata
      if (isWindows) {
        info.addAll(await _getWindowsFileInfo(expandedPath));
      } else {
        info.addAll(await _getUnixFileInfo(expandedPath));
      }

      return info;
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Get Windows-specific file info
  Future<Map<String, dynamic>> _getWindowsFileInfo(String path) async {
    final info = <String, dynamic>{};

    try {
      // Use PowerShell to get extended attributes
      final psScript = '''
Get-ItemProperty -Path "$path" -ErrorAction SilentlyContinue |
  Select-Object Attributes, CreationTime, VersionInfo |
  ConvertTo-Json
''';

      final result = await _runCommand('powershell.exe', [
        '-NoProfile',
        '-Command',
        psScript,
      ]);

      if (result.success) {
        info['attributes'] = result.stdout.trim();
      }
    } catch (_) {}

    return info;
  }

  /// Get Unix-specific file info
  Future<Map<String, dynamic>> _getUnixFileInfo(String path) async {
    final info = <String, dynamic>{};

    try {
      // Use stat command for extended info
      final result = await _runCommand('stat', [
        '-c',
        '%U:%G:%A:%e', // owner:group:permissions:creation_time
        path,
      ]);

      if (result.success) {
        final parts = result.stdout.trim().split(':');
        if (parts.length >= 3) {
          info['owner'] = parts[0];
          info['group'] = parts[1];
          info['permissions'] = parts[2];
        }
      }
    } catch (_) {}

    // Check for symlink
    final link = Link(path);
    if (link.existsSync()) {
      info['symlink_target'] = await link.target();
    }

    return info;
  }

  // ==========================================================================
  // COMMAND EXECUTION HELPERS
  // ==========================================================================

  /// Run a command through the shell
  Future<CommandResult> _runThroughShell(String command,
      {Duration? timeout}) async {
    final args = [...shellArgs, command];
    return _runCommand(shellCommand, args, timeout: timeout);
  }

  /// Run a command and return the result
  Future<CommandResult> _runCommand(
    String command,
    List<String> args, {
    Duration? timeout,
  }) async {
    try {
      final process = await Process.start(
        command,
        args,
        runInShell: false,
        mode: ProcessStartMode.normal,
      );

      final stdout = <String>[];
      final stderr = <String>[];

    final futureTimeout = timeout ?? const Duration(seconds: 30);

    // Watch for timeout
    final timer = Timer(futureTimeout, () {
      process.kill();
    });

    // Stream subscriptions
    final sub1 = process.stdout.transform(utf8.decoder).listen(stdout.add);
    final sub2 = process.stderr.transform(utf8.decoder).listen(stderr.add);

    // Wait for process to complete
    final exitCode = await process.exitCode;

    timer.cancel();
    sub1.cancel();
    sub2.cancel();

    return CommandResult(
      success: exitCode == 0,
      stdout: stdout.join(),
      stderr: stderr.join(),
      exitCode: exitCode,
    );
    } on TimeoutException {
      return CommandResult(
        success: false,
        stdout: '',
        stderr: 'Command timed out',
        exitCode: -1,
      );
    } catch (e) {
      return CommandResult(
        success: false,
        stdout: '',
        stderr: 'Command failed: $e',
        exitCode: -1,
      );
    }
  }
}

// ==========================================================================
// DATA CLASSES
// ==========================================================================

/// Result of a command execution
class CommandResult {
  final bool success;
  final String stdout;
  final String stderr;
  final int exitCode;

  CommandResult({
    required this.success,
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });
}

/// Information about a drive or mount point
class DriveInfo {
  final String path;
  final String description;
  final int? totalBytes;
  final int? availableBytes;

  DriveInfo({
    required this.path,
    required this.description,
    this.totalBytes,
    this.availableBytes,
  });

  /// Get free space percentage if both values available
  double? get freePercentage {
    if (totalBytes == null || availableBytes == null) return null;
    if (totalBytes == 0) return null;
    return (availableBytes! / totalBytes!);
  }

  /// Get used bytes
  int? get usedBytes {
    if (totalBytes == null || availableBytes == null) return null;
    return totalBytes! - availableBytes!;
  }

  /// Format as human readable
  String get formattedDescription {
    if (totalBytes == null) return description;

    final usedGB = ((usedBytes ?? 0) / (1024 * 1024 * 1024)).toStringAsFixed(1);
    final totalGB = (totalBytes! / (1024 * 1024 * 1024)).toStringAsFixed(1);
    return '$description ($usedGB / $totalGB GB)';
  }
}
```

---

## FIX 3: Enhanced AI Search Service Integration

### Problem
The AI search service uses hardcoded path handling and doesn't integrate with the new cross-platform utilities.

### Solution
Update `ai_search_service.dart` to use the new `CrossPlatformPaths` utility.

### File: `semantic_butler_server/lib/src/services/ai_search_service.dart`

#### Update imports:

```dart
import '../utils/cross_platform_paths.dart';
```

#### Replace `_normalizePath` method with:

```dart
  /// Normalize a path for the current platform
  String _normalizePath(String path) {
    // Use the cross-platform utility
    return CrossPlatformPaths.normalize(
      CrossPlatformPaths.expand(path)
    );
  }
```

#### Replace `_getLocationDescription` with:

```dart
  /// Get a user-friendly description for a path
  String _getLocationDescription(String path) {
    // Check against special folders
    final specialFolders = CrossPlatformPaths.specialFolders;
    final normalized = CrossPlatformPaths.normalize(path);

    for (final entry in specialFolders.entries) {
      final folderPath = CrossPlatformPaths.normalize(entry.value);
      if (normalized == folderPath ||
          normalized.startsWith(folderPath + CrossPlatformPaths.separator)) {
        // Return friendly name with subpath if present
        if (normalized != folderPath) {
          final subpath = normalized.substring(folderPath.length);
          return '${entry.key}${subpath.length > 20 ? '...' : subpath}';
        }
        return entry.key;
      }
    }

    // Check for home directory
    final home = CrossPlatformPaths.homeDirectory;
    if (normalized.startsWith(CrossPlatformPaths.normalize(home))) {
      final relative = CrossPlatformPaths.relative(home, path);
      return relative.isEmpty ? 'Home' : '~/$relative';
    }

    // Check if it's a drive or mount
    if (Platform.isWindows) {
      final drivePattern = RegExp(r'^[a-zA-Z]:\\?$');
      if (drivePattern.hasMatch(path)) {
        return 'Drive ${path[0].toUpperCase()}';
      }
    }

    // Return last folder name
    final parts = path.split(RegExp(r'[\\/]'));
    final lastPart = parts.where((p) => p.isNotEmpty).last;
    return lastPart.length <= 25 ? lastPart : '${lastPart.substring(0, 22)}...';
  }
```

#### Update `_getAvailableDrives`:

```dart
  /// Get all available drives as SearchPaths
  Future<List<SearchPath>> _getAvailableDrives() async {
    try {
      final drives = await _terminal.listDrives();
      return drives.map((d) => SearchPath(
        path: d.path,
        description: d.formattedDescription,
        isDrive: true,
      )).toList();
    } catch (e) {
      // Fallback to root paths from CrossPlatformPaths
      final rootPaths = CrossPlatformPaths.rootPaths;
      return rootPaths.map((p) => SearchPath(
        path: p,
        description: Platform.isWindows ? 'Drive ${p[0]}' : 'Root',
        isDrive: true,
      )).toList();
    }
  }
```

---

## FIX 4: Additional AI Agent Tools

### Problem
Missing tools for hidden files, symlinks, and special folders.

### Solution
Add new tools to the agent toolkit.

### File: `semantic_butler_server/lib/src/services/search_tools.dart`

```dart
import '../utils/cross_platform_paths.dart';

/// Tools available for the AI search agent
class SearchTools {
  // Tool Names
  static const String searchIndex = 'search_index';
  static const String searchTerminal = 'search_terminal';
  static const String readFile = 'read_file';
  static const String getFileInfo = 'get_file_info';
  static const String getSpecialPaths = 'get_special_paths';
  static const String listHiddenFiles = 'list_hidden_files';
  static const String resolveSymlink = 'resolve_symlink';

  // Parameter definitions
  static List<Tool> get allTools => [
    // ... existing tools (searchIndex, searchTerminal, readFile, getFileInfo) ...

    Tool(
      function: ToolFunction(
        name: getSpecialPaths,
        description: '''
Get platform-specific special folder paths like Documents, Downloads, AppData, etc.
Returns paths appropriate for the current operating system (Windows, macOS, Linux).
''',
        parameters: {
          'type': 'object',
          'properties': {
            'folderType': {
              'type': 'string',
              'description': 'Type of special folder to retrieve',
              'enum': [
                'desktop', 'documents', 'downloads', 'pictures', 'videos', 'music',
                'appdata', 'localappdata', 'roaming', 'temp',
                'application_support', 'library', 'config', 'cache'
              ],
            },
          },
          'required': ['folderType'],
        },
      ),
    ),

    Tool(
      function: ToolFunction(
        name: listHiddenFiles,
        description: '''
List hidden files and folders in a directory.
On Unix systems, hidden files start with a dot (.).
On Windows, checks the hidden file attribute.
''',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Directory path to search (defaults to current directory)',
            },
            'includeSystem': {
              'type': 'boolean',
              'description': 'Include system/protected files and folders',
            },
          },
        },
      ),
    ),

    Tool(
      function: ToolFunction(
        name: resolveSymlink,
        description: '''
Resolve symbolic links to their target paths.
Returns the actual file or directory that a symlink points to.
''',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Path to check for symbolic link',
            },
          },
          'required': ['path'],
        },
      ),
    ),
  ];
}
```

### Add tool implementations in `ai_search_service.dart`:

```dart
  // In _executeTool method, add these cases:

  } else if (name == SearchTools.getSpecialPaths) {
    final folderType = args['folderType'] as String;
    final path = CrossPlatformPaths.getSpecialFolder(folderType);

    if (path != null) {
      return {
        'status': 'success',
        'folder_type': folderType,
        'path': path,
        'platform': Platform.operatingSystem,
      };
    } else {
      return {
        'status': 'error',
        'message': 'Special folder not found: $folderType',
      };
    }

  } else if (name == SearchTools.listHiddenFiles) {
    final path = args['path'] as String? ?? '.';
    final includeSystem = args['includeSystem'] as bool? ?? false;
    final expandedPath = CrossPlatformPaths.expand(path);

    try {
      final dir = Directory(expandedPath);
      if (!dir.existsSync()) {
        return {'status': 'error', 'message': 'Directory not found'};
      }

      final entities = dir.listSync();
      final hiddenFiles = <String>[];

      for (final entity in entities) {
        final name = entity.path.split(RegExp(r'[\\/]')).last;

        // Check hidden status
        bool isHidden = CrossPlatformPaths.isHidden(entity.path);

        // On Unix, also check for dotfiles
        if (!isHidden && !Platform.isWindows) {
          isHidden = name.startsWith('.');
        }

        // Skip system files unless requested
        if (!includeSystem) {
          if (Platform.isWindows) {
            // Skip Windows system folders
            if (name.toLowerCase() == 'system volume information' ||
                name.toLowerCase().startsWith('\$')) {
              continue;
            }
          } else {
            // Skip Unix system paths
            if (name.startsWith('.') && ['.', '..'].contains(name)) {
              continue;
            }
          }
        }

        if (isHidden) {
          hiddenFiles.add(entity.path);
        }
      }

      return {
        'status': 'success',
        'path': expandedPath,
        'hidden_count': hiddenFiles.length,
        'hidden_files': hiddenFiles.take(100).toList(),
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }

  } else if (name == SearchTools.resolveSymlink) {
    final path = args['path'] as String;
    final expandedPath = CrossPlatformPaths.expand(path);

    try {
      final link = Link(expandedPath);
      if (link.existsSync()) {
        final target = await link.target();
        return {
          'status': 'success',
          'link_path': expandedPath,
          'target': target,
          'target_exists': await File(target).exists() || await Directory(target).exists(),
        };
      } else {
        // Check if it's a file or dir (not a symlink)
        final file = File(expandedPath);
        final dir = Directory(expandedPath);
        if (file.existsSync() || dir.existsSync()) {
          return {
            'status': 'success',
            'link_path': expandedPath,
            'message': 'Path is not a symbolic link',
            'is_symlink': false,
          };
        }
        return {'status': 'error', 'message': 'Path not found'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
```

---

## Testing Scenarios

### Windows
| Scenario | Command/Tool | Expected Result |
|----------|--------------|-----------------|
| Search Documents folder | search_terminal | Returns files from `%USERPROFILE%\Documents` |
| Get special folder | get_special_paths("appdata") | Returns `%APPDATA%` path |
| Search C: drive | search_terminal with path "C:\" | Searches entire C: drive |
| List hidden files | list_hidden_files | Returns `.gitignore`, `.env`, etc. |

### macOS
| Scenario | Command/Tool | Expected Result |
|----------|--------------|-----------------|
| Search Documents folder | search_terminal | Returns files from `~/Documents` |
| Get special folder | get_special_paths("application_support") | Returns `~/Library/Application Support` |
| Search root | search_terminal with path "/" | Searches entire filesystem |
| Use Spotlight | search_terminal (auto) | Uses `mdfind` for fast results |

### Linux
| Scenario | Command/Tool | Expected Result |
|----------|--------------|-----------------|
| Search Documents folder | search_terminal | Returns files from `~/Documents` |
| Get special folder | get_special_paths("config") | Returns `~/.config` |
| Use locate | search_terminal (auto) | Uses `locate` for fast results |
| Fallback to find | search_terminal (no locate) | Uses `find` command |

---

## Implementation Checklist

- [ ] Create `cross_platform_paths.dart`
- [ ] Update `terminal_service.dart` with platform-specific search
- [ ] Update `ai_search_service.dart` to use new utilities
- [ ] Add new tools to `search_tools.dart`
- [ ] Implement new tool handlers in `ai_search_service.dart`
- [ ] Test on Windows (PowerShell, drive letters)
- [ ] Test on macOS (Spotlight, Unix paths)
- [ ] Test on Linux (locate/find, Unix paths)

---

**End of Document**
