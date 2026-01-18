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

  /// Build file context string from multiple tagged files
  static Future<String> buildFileContext(List<dynamic> taggedFiles) async {
    final contextParts = <String>[];

    for (final file in taggedFiles) {
      try {
        final path = file.path as String;
        final displayName = file.displayName as String;
        final content = await loadFileContent(path);

        if (content != null && content.isNotEmpty) {
          contextParts.add(
            '--- $displayName ($path) ---\n$content',
          );
        }
      } catch (e) {
        AppLogger.warning('Failed to load file ${file.path}: $e');
      }
    }

    if (contextParts.isEmpty) {
      return '';
    }

    return '[ATTACHED FILES]\n${contextParts.join('\n\n')}\n[END ATTACHED FILES]\n\n';
  }
}
