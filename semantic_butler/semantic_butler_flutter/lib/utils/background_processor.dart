import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Utility class for offloading heavy processing to background Isolates.
/// Keeps the main UI thread free for fluid animations and interactions.
class BackgroundProcessor {
  // Singleton instance
  static final BackgroundProcessor _instance = BackgroundProcessor._internal();
  factory BackgroundProcessor() => _instance;
  BackgroundProcessor._internal();

  /// Threshold for offloading to isolate (to avoid spawn overhead for small tasks)
  static const int _isolateThreshold = 1000;

  /// Decode JSON string in the background
  Future<dynamic> decodeJson(String source) async {
    if (source.length < _isolateThreshold) return jsonDecode(source);
    try {
      return await compute(_jsonDecodeWrapper, source);
    } catch (e) {
      return jsonDecode(source);
    }
  }

  /// Encode object to JSON string in the background
  Future<String> encodeJson(Object? object) async {
    // We can't easily check 'length' of object, but we can assume complex ones are large
    try {
      return await compute(_jsonEncodeWrapper, object);
    } catch (e) {
      return jsonEncode(object);
    }
  }

  /// Pre-process content for any structural patterns
  Future<bool> containsStructuredPatterns(String content) async {
    if (content.length < _isolateThreshold) {
      return _checkStructuredPatterns(content);
    }
    try {
      return await compute(_checkStructuredPatterns, content);
    } catch (e) {
      return _checkStructuredPatterns(content);
    }
  }

  /// Parse markdown blocks in the background
  Future<List<Map<String, dynamic>>> parseMarkdown(String content) async {
    if (content.length < _isolateThreshold) {
      return _markdownParseWrapper(content);
    }
    try {
      return await compute(_markdownParseWrapper, content);
    } catch (e) {
      return _markdownParseWrapper(content);
    }
  }
}

// Top-level wrapper functions for compute()
dynamic _jsonDecodeWrapper(String source) => jsonDecode(source);
String _jsonEncodeWrapper(Object? object) => jsonEncode(object);

bool _checkStructuredPatterns(String content) {
  return content.contains('```') ||
      content.contains('<') ||
      content.contains('**') ||
      content.contains('# ');
}

List<Map<String, dynamic>> _markdownParseWrapper(String content) {
  final codeBlockRegex = RegExp(
    r'```(\w*)\n([\s\S]*?)```',
    multiLine: true,
  );

  final blocks = <Map<String, dynamic>>[];
  int lastIndex = 0;

  for (final match in codeBlockRegex.allMatches(content)) {
    // Add text before code block
    if (match.start > lastIndex) {
      final text = content.substring(lastIndex, match.start);
      if (text.trim().isNotEmpty) {
        blocks.add({
          'type': 'text',
          'content': text,
        });
      }
    }

    // Add code block
    final language = match.group(1)?.trim() ?? '';
    final code = match.group(2) ?? '';
    blocks.add({
      'type': 'code',
      'content': code,
      'language': language.isEmpty ? 'plaintext' : language,
    });

    lastIndex = match.end;
  }

  // Add remaining text
  if (lastIndex < content.length) {
    final text = content.substring(lastIndex);
    if (text.trim().isNotEmpty) {
      blocks.add({
        'type': 'text',
        'content': text,
      });
    }
  }

  // If no code blocks found
  if (blocks.isEmpty && content.trim().isNotEmpty) {
    blocks.add({
      'type': 'text',
      'content': content,
    });
  }

  return blocks;
}
