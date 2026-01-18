import 'package:flutter/material.dart';

/// Parsed response from the agent with structured XML blocks
class ParsedAgentResponse {
  final List<ThinkingBlock> thinkingBlocks;
  final List<ResultBlock> resultBlocks;
  final List<MessageBlock> messageBlocks;
  final List<StatusBlock> statusBlocks;
  final String rawContent;

  ParsedAgentResponse({
    required this.thinkingBlocks,
    required this.resultBlocks,
    required this.messageBlocks,
    required this.statusBlocks,
    required this.rawContent,
  });

  /// Check if the response has any structured content
  bool get hasStructuredContent =>
      thinkingBlocks.isNotEmpty ||
      resultBlocks.isNotEmpty ||
      messageBlocks.isNotEmpty ||
      statusBlocks.isNotEmpty;

  /// Get plain text content (strips all XML tags)
  String get plainText {
    if (!hasStructuredContent) return rawContent;

    final parts = <String>[];
    for (final msg in messageBlocks) {
      parts.add(msg.content);
    }
    return parts.join('\n\n');
  }
}

/// A `<thinking>` block containing reasoning
class ThinkingBlock {
  final String content;
  ThinkingBlock(this.content);
}

/// A `<result>` block containing file/folder listings
class ResultBlock {
  final String type; // 'folder', 'file', 'search'
  final String? path;
  final List<ResultItem> items;

  ResultBlock({
    required this.type,
    this.path,
    required this.items,
  });
}

/// An item within a `<result>` block
class ResultItem {
  final String type; // 'file' or 'folder'
  final String name;
  final String? size;
  final String? description;

  ResultItem({
    required this.type,
    required this.name,
    this.size,
    this.description,
  });
}

/// A `<message>` block containing conversational text
class MessageBlock {
  final String content;
  MessageBlock(this.content);
}

/// A `<status>` block containing action outcomes
class StatusBlock {
  final String type; // 'success', 'error', 'warning'
  final String content;

  StatusBlock({
    required this.type,
    required this.content,
  });

  Color get color {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (type) {
      case 'success':
        return Icons.check_circle_outline;
      case 'error':
        return Icons.error_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      default:
        return Icons.info_outline;
    }
  }
}

/// Parser for agent responses with XML tags
class XmlResponseParser {
  /// Parse agent response content into structured blocks
  static ParsedAgentResponse parse(String content) {
    final thinkingBlocks = <ThinkingBlock>[];
    final resultBlocks = <ResultBlock>[];
    final messageBlocks = <MessageBlock>[];
    final statusBlocks = <StatusBlock>[];

    // Extract <thinking> blocks
    final thinkingRegex = RegExp(
      r'<thinking>(.*?)</thinking>',
      multiLine: true,
      dotAll: true,
    );
    for (final match in thinkingRegex.allMatches(content)) {
      final innerContent = match.group(1)?.trim() ?? '';
      if (innerContent.isNotEmpty) {
        thinkingBlocks.add(ThinkingBlock(innerContent));
      }
    }

    // Extract <result> blocks
    final resultRegex = RegExp(
      r'<result\s+type="([^"]*)"(?:\s+path="([^"]*)")?\s*>(.*?)</result>',
      multiLine: true,
      dotAll: true,
    );
    for (final match in resultRegex.allMatches(content)) {
      final type = match.group(1) ?? 'unknown';
      final path = match.group(2);
      final innerContent = match.group(3) ?? '';

      // Parse <item> elements within results
      final items = <ResultItem>[];
      final itemRegex = RegExp(
        r'<item\s+type="([^"]*)"(?:\s+name="([^"]*)")?(?:\s+size="([^"]*)")?(?:\s+description="([^"]*)")?\s*/?>',
        multiLine: true,
      );
      for (final itemMatch in itemRegex.allMatches(innerContent)) {
        items.add(
          ResultItem(
            type: itemMatch.group(1) ?? 'file',
            name: itemMatch.group(2) ?? 'Unknown',
            size: itemMatch.group(3),
            description: itemMatch.group(4),
          ),
        );
      }

      resultBlocks.add(
        ResultBlock(
          type: type,
          path: path,
          items: items,
        ),
      );
    }

    // Extract <message> blocks
    final messageRegex = RegExp(
      r'<message>(.*?)</message>',
      multiLine: true,
      dotAll: true,
    );
    for (final match in messageRegex.allMatches(content)) {
      final innerContent = match.group(1)?.trim() ?? '';
      if (innerContent.isNotEmpty) {
        messageBlocks.add(MessageBlock(innerContent));
      }
    }

    // Extract <status> blocks
    final statusRegex = RegExp(
      r'<status\s+type="([^"]*)">(.*?)</status>',
      multiLine: true,
      dotAll: true,
    );
    for (final match in statusRegex.allMatches(content)) {
      final type = match.group(1) ?? 'info';
      final innerContent = match.group(2)?.trim() ?? '';
      if (innerContent.isNotEmpty) {
        statusBlocks.add(
          StatusBlock(
            type: type,
            content: innerContent,
          ),
        );
      }
    }

    // If no structured content found, treat entire content as a message
    if (thinkingBlocks.isEmpty &&
        resultBlocks.isEmpty &&
        messageBlocks.isEmpty &&
        statusBlocks.isEmpty) {
      // Clean up any markdown formatting from unstructured responses
      final cleanContent = _stripMarkdown(content);
      if (cleanContent.isNotEmpty) {
        messageBlocks.add(MessageBlock(cleanContent));
      }
    }

    return ParsedAgentResponse(
      thinkingBlocks: thinkingBlocks,
      resultBlocks: resultBlocks,
      messageBlocks: messageBlocks,
      statusBlocks: statusBlocks,
      rawContent: content,
    );
  }

  /// Strip common markdown formatting
  static String _stripMarkdown(String content) {
    return content
        // Remove bold
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        // Remove italic
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        // Remove headers
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        // Remove code blocks
        .replaceAll(RegExp(r'```[^`]*```'), '')
        // Remove inline code
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        // Clean up extra whitespace
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
