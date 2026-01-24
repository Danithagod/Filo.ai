import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

/// Utility for syntax highlighting code blocks
class AppSyntaxHighlighter {
  static const _defaultLanguage = 'plaintext';

  /// List of supported language aliases
  static const Set<String> supportedLanguages = {
    'dart',
    'python',
    'py',
    'javascript',
    'js',
    'typescript',
    'ts',
    'java',
    'cpp',
    'c++',
    'c',
    'json',
    'yaml',
    'yml',
    'xml',
    'html',
    'htm',
    'css',
    'scss',
    'bash',
    'sh',
    'shell',
    'sql',
    'markdown',
    'md',
    'go',
    'golang',
    'rust',
    'swift',
    'kotlin',
    'plaintext',
    'text',
  };

  /// Normalize language name to supported key
  static String normalizeLanguage(String? language) {
    if (language == null || language.isEmpty) return _defaultLanguage;
    final normalized = language.toLowerCase().trim();
    return supportedLanguages.contains(normalized)
        ? normalized
        : _defaultLanguage;
  }

  /// Check if a language is supported
  static bool isSupported(String language) {
    return supportedLanguages.contains(language.toLowerCase());
  }

  /// Parse code and return a tree of nodes (internal for custom rendering if needed)
  static List<Node>? parse(String code, String language) {
    final normalizedLang = normalizeLanguage(language);
    try {
      final result = highlight.parse(code, language: normalizedLang);
      return result.nodes;
    } catch (e) {
      return null;
    }
  }

  /// Get display name for language
  static String getDisplayName(String language) {
    final normalized = normalizeLanguage(language);
    final displayNames = {
      'dart': 'Dart',
      'python': 'Python',
      'py': 'Python',
      'javascript': 'JavaScript',
      'js': 'JavaScript',
      'typescript': 'TypeScript',
      'ts': 'TypeScript',
      'java': 'Java',
      'cpp': 'C++',
      'c++': 'C++',
      'c': 'C',
      'json': 'JSON',
      'yaml': 'YAML',
      'yml': 'YAML',
      'xml': 'XML',
      'html': 'HTML',
      'css': 'CSS',
      'bash': 'Bash',
      'sh': 'Shell',
      'sql': 'SQL',
      'markdown': 'Markdown',
      'md': 'Markdown',
      'go': 'Go',
      'golang': 'Go',
      'rust': 'Rust',
      'swift': 'Swift',
      'kotlin': 'Kotlin',
      'plaintext': 'Plain Text',
      'text': 'Text',
    };
    return displayNames[normalized] ?? normalized.toUpperCase();
  }

  /// Get color for syntax element type
  static Color getColorForType(String? type, BuildContext context) {
    if (type == null) return Theme.of(context).colorScheme.onSurface;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colors based on common IDE themes
    switch (type) {
      case 'keyword':
      case 'built_in':
      case 'selector-tag':
        return isDark ? const Color(0xFFC586C0) : const Color(0xFFAF00DB);
      case 'string':
      case 'string_literal':
      case 'attr':
        return isDark ? const Color(0xFFCE9178) : const Color(0xFFA31515);
      case 'comment':
      case 'quote':
        return isDark ? const Color(0xFF6A9955) : const Color(0xFF008000);
      case 'number':
      case 'literal':
      case 'boolean':
        return isDark ? const Color(0xFFB5CEA8) : const Color(0xFF098658);
      case 'function':
      case 'title':
      case 'params':
        return isDark ? const Color(0xFFDCDCAA) : const Color(0xFF795E26);
      case 'class':
      case 'type':
      case 'meta':
        return isDark ? const Color(0xFF4EC9B0) : const Color(0xFF267F99);
      case 'variable':
      case 'template-variable':
      case 'name':
        return isDark ? const Color(0xFF9CDCFE) : const Color(0xFF001080);
      case 'operator':
      case 'punctuation':
        return isDark ? const Color(0xFFD4D4D4) : const Color(0xFF000000);
      case 'tag':
        return isDark ? const Color(0xFF569CD6) : const Color(0xFF800000);
      case 'attribute':
        return isDark ? const Color(0xFF9CDCFE) : const Color(0xFFFF0000);
      case 'value':
        return isDark ? const Color(0xFFCE9178) : const Color(0xFFA31515);
      default:
        return theme.colorScheme.onSurface;
    }
  }
}
