/// Utility to parse and extract thinking blocks and other XML tags from message content
class ThoughtParser {
  static final RegExp _thinkingPattern = RegExp(
    r'<thinking>(.*?)</thinking>',
    dotAll: true,
  );

  static final RegExp _messagePattern = RegExp(
    r'<message>(.*?)</message>',
    dotAll: true,
  );

  static final RegExp _statusPattern = RegExp(
    r'<status(?:\s+type="([^"]*)")?>(.*?)</status>',
    dotAll: true,
  );

  static final RegExp _resultPattern = RegExp(
    r'<result.*?>.*?</result>',
    dotAll: true,
  );

  /// Parses content to separate thoughts, status, and message from final content
  static ThoughtParseResult parse(String content) {
    if (content.isEmpty) {
      return ThoughtParseResult(thoughts: [], statuses: [], cleanContent: '');
    }

    final thoughts = <String>[];
    final statuses = <MessageStatus>[];
    String cleanContent = '';

    // 1. Extract thoughts from <thinking> tags
    final thinkingMatches = _thinkingPattern.allMatches(content);
    for (final match in thinkingMatches) {
      if (match.group(1) != null) {
        final t = match.group(1)!.trim();
        if (t.isNotEmpty) thoughts.add(t);
      }
    }

    // 2. Extract status updates from <status> tags
    final statusMatches = _statusPattern.allMatches(content);
    for (final match in statusMatches) {
      final type = match.group(1) ?? 'info';
      final text = match.group(2)?.trim() ?? '';
      if (text.isNotEmpty) {
        statuses.add(MessageStatus(type: type, text: text));
      }
    }

    // 3. Find the primary message
    final messageMatch = _messagePattern.firstMatch(content);
    if (messageMatch != null && messageMatch.group(1) != null) {
      cleanContent = messageMatch.group(1)!.trim();
    }

    // 4. Capture "leaked" text outside of tags as thoughts
    // This handles agents that just start typing without tags or wrap only partial content
    String remaining = content
        .replaceAll(_thinkingPattern, '')
        .replaceAll(_messagePattern, '')
        .replaceAll(_statusPattern, '')
        .replaceAll(_resultPattern, '')
        .trim();

    // If we have remaining text that wasn't in a message tag, and it's not empty
    if (remaining.isNotEmpty) {
      if (cleanContent.isEmpty) {
        // If no <message> tag, the remaining text IS the message
        cleanContent = remaining;
      } else {
        // If we have a <message> tag, treat other text as thoughts
        // But only if it's not just a duplicate or something trivial
        if (!thoughts.contains(remaining) && remaining != cleanContent) {
          thoughts.add(remaining);
        }
      }
    }

    // 5. Handle unclosed tags during streaming (more robust)
    if (content.contains('<thinking>') && !content.contains('</thinking>')) {
      final lastThinkingStart = content.lastIndexOf('<thinking>');
      final unclosedThought = content.substring(lastThinkingStart + 11).trim();
      if (unclosedThought.isNotEmpty && !thoughts.contains(unclosedThought)) {
        thoughts.add(unclosedThought);
      }
    }

    if (content.contains('<message>') && !content.contains('</message>')) {
      final lastMessageStart = content.lastIndexOf('<message>');
      final unclosedMessage = content.substring(lastMessageStart + 9).trim();
      if (unclosedMessage.isNotEmpty) {
        cleanContent = unclosedMessage;
      }
    }

    // Final safety: strip any stray tags that might be incomplete or unknown
    cleanContent = _stripStrayTags(cleanContent);

    return ThoughtParseResult(
      thoughts: thoughts,
      statuses: statuses,
      cleanContent: cleanContent,
    );
  }

  static String _stripStrayTags(String text) {
    // Remove anything that looks like an XML tag but isn't part of standard markdown
    return text.replaceAll(RegExp(r'</?[a-zA-Z]+[^>]*>'), '').trim();
  }
}

class MessageStatus {
  final String type;
  final String text;

  const MessageStatus({required this.type, required this.text});
}

class ThoughtParseResult {
  final List<String> thoughts;
  final List<MessageStatus> statuses;
  final String cleanContent;

  const ThoughtParseResult({
    required this.thoughts,
    required this.statuses,
    required this.cleanContent,
  });

  bool get hasThoughts => thoughts.isNotEmpty;
  bool get hasStatuses => statuses.isNotEmpty;
}
