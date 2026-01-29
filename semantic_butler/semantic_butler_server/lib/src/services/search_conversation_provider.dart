/// Provider for conversational search capabilities
class SearchConversationProvider {
  static final SearchConversationProvider instance =
      SearchConversationProvider._();

  SearchConversationProvider._();

  /// In-memory storage for active conversations
  /// Key: Session ID, Value: List of messages/queries
  final Map<String, List<SearchTurn>> _conversations = {};

  /// Add a turn to the conversation
  void addTurn(String sessionId, String query, dynamic resultStats) {
    if (!_conversations.containsKey(sessionId)) {
      _conversations[sessionId] = [];
    }

    _conversations[sessionId]!.add(
      SearchTurn(
        query: query,
        timestamp: DateTime.now(),
        resultStats: resultStats,
      ),
    );

    // Keep history limited to last 10 turns
    if (_conversations[sessionId]!.length > 10) {
      _conversations[sessionId]!.removeAt(0);
    }
  }

  /// Get simplified history context for AI
  String getContextForAI(String sessionId) {
    final history = _conversations[sessionId];
    if (history == null || history.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('Previous search context:');

    for (final turn in history) {
      buffer.writeln('- User asked: "${turn.query}"');
      // We could add result stats here if relevant
      // e.g. "- Found 5 results"
    }

    return buffer.toString();
  }

  /// Clear history
  void clearSession(String sessionId) {
    _conversations.remove(sessionId);
  }
}

class SearchTurn {
  final String query;
  final DateTime timestamp;
  final dynamic resultStats; // e.g. "Found 5 files"

  SearchTurn({
    required this.query,
    required this.timestamp,
    this.resultStats,
  });
}
