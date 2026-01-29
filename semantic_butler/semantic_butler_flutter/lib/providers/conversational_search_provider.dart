import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Models for conversational search
class SearchTurn {
  final String query;
  final DateTime timestamp;
  final int resultCount;
  final String? strategy;
  final List<String>? refinements;

  SearchTurn({
    required this.query,
    required this.timestamp,
    required this.resultCount,
    this.strategy,
    this.refinements,
  });

  SearchTurn copyWith({
    String? query,
    DateTime? timestamp,
    int? resultCount,
    String? strategy,
    List<String>? refinements,
  }) {
    return SearchTurn(
      query: query ?? this.query,
      timestamp: timestamp ?? this.timestamp,
      resultCount: resultCount ?? this.resultCount,
      strategy: strategy ?? this.strategy,
      refinements: refinements ?? this.refinements,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
      'resultCount': resultCount,
      'strategy': strategy,
      'refinements': refinements,
    };
  }

  factory SearchTurn.fromJson(Map<String, dynamic> json) {
    return SearchTurn(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      resultCount: json['resultCount'] as int,
      strategy: json['strategy'] as String?,
      refinements: (json['refinements'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}

class ConversationalSearchState {
  final List<SearchTurn> history;
  final String sessionId;
  final bool isLoading;
  final String? error;

  ConversationalSearchState({
    this.history = const [],
    required this.sessionId,
    this.isLoading = false,
    this.error,
  });

  ConversationalSearchState copyWith({
    List<SearchTurn>? history,
    String? sessionId,
    bool? isLoading,
    String? error,
  }) {
    return ConversationalSearchState(
      history: history ?? this.history,
      sessionId: sessionId ?? this.sessionId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get formatted context for AI
  String get contextForAI {
    if (history.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('<!-- SEARCH CONTEXT -->');

    for (int i = 0; i < history.length; i++) {
      final turn = history[i];
      buffer.writeln(
        '[${i + 1}] "${turn.query}" → ${turn.resultCount} results',
      );
      if (turn.strategy != null) {
        buffer.writeln('    Strategy: ${turn.strategy}');
      }
    }

    buffer.writeln('<!-- END CONTEXT -->');
    return buffer.toString();
  }

  /// Get previous queries as suggestions
  List<String> get previousQueries {
    return history.map((t) => t.query).toList();
  }

  /// Check if current query might be a refinement
  bool isRefinement(String currentQuery) {
    if (history.isEmpty) return false;

    final lowerQuery = currentQuery.toLowerCase();
    final refinementIndicators = [
      'more',
      'less',
      'only',
      'except',
      'but',
      'also',
      'narrow',
      'widen',
      'refine',
      'filter',
      'exclude',
      'another',
      'different',
      'other',
      'alternative',
      'first',
      'second',
      'third',
      'last',
      'previous',
      'like the',
      'similar to',
      'same as',
    ];

    return refinementIndicators.any(
      (indicator) => lowerQuery.contains(indicator),
    );
  }

  /// Generate follow-up suggestions based on history
  List<String> generateFollowUpSuggestions() {
    if (history.isEmpty) return [];

    final lastQuery = history.last.query.toLowerCase();
    final suggestions = <String>[];

    // Context-aware suggestions
    if (lastQuery.contains('pdf') || lastQuery.contains('document')) {
      suggestions.addAll([
        'Only show files larger than 1MB',
        'Show results from last week',
        'Narrow to specific folder',
      ]);
    }

    if (lastQuery.contains('image') ||
        lastQuery.contains('photo') ||
        lastQuery.contains('jpg')) {
      suggestions.addAll([
        'Show only from last month',
        'Larger than 2MB',
        'In Downloads folder',
      ]);
    }

    // Generic suggestions
    suggestions.addAll([
      'Show more results',
      'Refine with date filter',
      'Different file type',
    ]);

    return suggestions.toSet().take(5).toList();
  }
}

/// Provider for conversational search state
class ConversationalSearchNotifier extends Notifier<ConversationalSearchState> {
  @override
  ConversationalSearchState build() {
    return ConversationalSearchState(
      sessionId: _generateSessionId(),
    );
  }

  static String _generateSessionId() {
    return 'sess_${DateTime.now().millisecondsSinceEpoch}_${Object().hashCode}';
  }

  /// Add a search turn to history
  void addTurn({
    required String query,
    required int resultCount,
    String? strategy,
    List<String>? refinements,
  }) {
    final turn = SearchTurn(
      query: query,
      timestamp: DateTime.now(),
      resultCount: resultCount,
      strategy: strategy,
      refinements: refinements,
    );

    final newHistory = [...state.history, turn];

    // Keep only last 10 turns
    if (newHistory.length > 10) {
      state = state.copyWith(
        history: newHistory.sublist(newHistory.length - 10),
      );
    } else {
      state = state.copyWith(history: newHistory);
    }
  }

  /// Clear history
  void clearHistory() {
    state = state.copyWith(history: []);
  }

  /// Build a refined query based on context
  String? buildRefinedQuery(String userSuggestion) {
    if (state.history.isEmpty) return null;

    final lastQuery = state.history.last.query;
    final suggestion = userSuggestion.toLowerCase();

    // Parse the suggestion and combine with last query
    if (suggestion.contains('larger than') ||
        suggestion.contains('bigger than')) {
      return '$lastQuery ${suggestion.replaceAll('show', '').trim()}';
    }

    if (suggestion.contains('from last') ||
        suggestion.contains('this week') ||
        suggestion.contains('this month')) {
      return '$lastQuery ${suggestion.trim()}';
    }

    if (suggestion.contains('folder')) {
      return '$lastQuery ${suggestion.trim()}';
    }

    return '$lastQuery ${suggestion.trim()}';
  }

  /// Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Set error
  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  /// Start new session
  void newSession() {
    state = ConversationalSearchState(
      sessionId: _generateSessionId(),
    );
  }
}

/// Provider instance
final conversationalSearchProvider =
    NotifierProvider<ConversationalSearchNotifier, ConversationalSearchState>(
      () {
        return ConversationalSearchNotifier();
      },
    );

/// Convenience provider to access session ID
final searchSessionIdProvider = Provider<String>((ref) {
  return ref.watch(conversationalSearchProvider).sessionId;
});

/// Convenience provider for follow-up suggestions
final followUpSuggestionsProvider = Provider<List<String>>((ref) {
  final state = ref.watch(conversationalSearchProvider);
  return state.generateFollowUpSuggestions();
});
