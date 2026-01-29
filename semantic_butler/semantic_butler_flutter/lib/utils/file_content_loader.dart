import 'dart:io';
import 'app_logger.dart';

/// Utility class for loading file content with size limits
class FileContentLoader {
  /// Maximum file content size to load (10KB)
  static const int maxContentLength = 10000;

  /// Load file content for context, with truncation for large files
  static Future<String?> loadFileContent(String path) async {
    try {
      final file = File(path);
      if (!(await file.exists())) return null;

      // Check for binary content by reading the first 1KB
      final bytes = await file.openRead(0, 1024).first;
      if (bytes.contains(0)) {
        return "[Binary file - preview not available]";
      }

      final content = await file.readAsString();
      // Limit content to avoid token overflow
      if (content.length > maxContentLength) {
        return '${content.substring(0, maxContentLength)}\n... [truncated, file too large]';
      }
      return content;
    } catch (e) {
      AppLogger.warning('Failed to read file content: $e');
      if (e is FileSystemException && e.message.contains('Non-UTF-8')) {
        return "[Binary file or invalid encoding - preview not available]";
      }
    }
    return null;
  }

  /// Load directory structure as a tree-like string
  static Future<String?> loadDirectoryStructure(String path) async {
    try {
      final dir = Directory(path);
      if (!(await dir.exists())) return null;

      final buffer = StringBuffer();
      buffer.writeln(
        'Directory Listing for: ${path.split(Platform.pathSeparator).last}',
      );

      // Safety limits
      int fileCount = 0;
      const int maxFiles = 100;
      const int maxDepth = 3;

      Future<void> listDir(Directory d, int depth, String prefix) async {
        if (depth > maxDepth || fileCount >= maxFiles) return;

        try {
          final entities = await d.list(followLinks: false).toList();

          // Sort explicitly: directories first (alphabetical), then files (alphabetical)
          entities.sort((a, b) {
            final aIsDir = a is Directory;
            final bIsDir = b is Directory;
            if (aIsDir && !bIsDir) return -1;
            if (!aIsDir && bIsDir) return 1;
            return a.path.compareTo(b.path);
          });

          for (final entity in entities) {
            if (fileCount >= maxFiles) {
              buffer.writeln('$prefix... [limit reached]');
              return;
            }

            final name = entity.path.split(Platform.pathSeparator).last;

            // Skip hidden files/dirs
            if (name.startsWith('.')) continue;

            if (entity is Directory) {
              buffer.writeln('$prefix[DIR] $name/');
              await listDir(entity, depth + 1, '$prefix  ');
            } else if (entity is File) {
              fileCount++;
              buffer.writeln('$prefix$name');
            }
          }
        } catch (e) {
          buffer.writeln('$prefix[Access Denied or Error: $e]');
        }
      }

      await listDir(dir, 0, '');
      return buffer.toString();
    } catch (e) {
      AppLogger.error('Failed to load directory structure: $e');
      return null;
    }
  }

  /// Build file context string from multiple tagged files
  static Future<String> buildFileContext(List<dynamic> taggedFiles) async {
    final contextParts = <String>[];

    for (final file in taggedFiles) {
      try {
        String? path;
        String? displayName;

        if (file is Map) {
          path = file['path']?.toString();
          displayName = file['displayName']?.toString();
        } else {
          try {
            path = (file as dynamic).path?.toString();
            displayName = (file as dynamic).displayName?.toString();
          } catch (_) {
            // Not a compatible object
          }
        }

        if (path == null) continue;
        displayName ??= path.split(Platform.pathSeparator).last;

        String? content;

        // Check if it's a directory
        if (await Directory(path).exists()) {
          content = await loadDirectoryStructure(path);
          if (content != null) {
            displayName = '[FOLDER] $displayName';
          }
        } else {
          content = await loadFileContent(path);
        }

        if (content != null && content.isNotEmpty) {
          contextParts.add(
            '--- $displayName ($path) ---\n$content',
          );
        }
      } catch (e) {
        AppLogger.warning('Failed to load file context: $e');
      }
    }

    if (contextParts.isEmpty) {
      return '';
    }

    return '[ATTACHED CONTEXT]\n${contextParts.join('\n\n')}\n[END ATTACHED CONTEXT]\n\n';
  }
}
