import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';
import '../utils/app_logger.dart';

/// State for search history
class SearchHistoryState {
  final List<SearchHistory> searches;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const SearchHistoryState({
    this.searches = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  SearchHistoryState copyWith({
    List<SearchHistory>? searches,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return SearchHistoryState(
      searches: searches ?? this.searches,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for search history state
class SearchHistoryNotifier extends Notifier<SearchHistoryState> {
  static const int _pageSize = 10;
  int _currentLimit = _pageSize;

  @override
  SearchHistoryState build() {
    // Auto-load history on initialization
    Future.microtask(() => loadHistory());
    return SearchHistoryState();
  }

  /// Load search history from server
  Future<void> loadHistory({bool loadMore = false}) async {
    if (loadMore) {
      if (state.isLoadingMore || !state.hasMore) return;
      state = state.copyWith(isLoadingMore: true);
    } else {
      state = SearchHistoryState(isLoading: true);
      _currentLimit = _pageSize;
    }

    final offset = loadMore ? _currentLimit - _pageSize : 0;

    AppLogger.debug(
      'Loading search history (limit: $_pageSize, offset: $offset, loadMore: $loadMore)',
      tag: 'SearchHistoryProvider',
    );

    try {
      final apiClient = ref.read(clientProvider);
      final history = await apiClient.butler.getSearchHistory(
        limit: _pageSize,
        offset: offset,
      );

      AppLogger.debug(
        'Loaded ${history.length} search history items',
        tag: 'SearchHistoryProvider',
      );

      final searches = history.where((h) => h.query.isNotEmpty).toList();
      final hasMore = history.length >= _pageSize;

      state = state.copyWith(
        searches: loadMore ? [...state.searches, ...searches] : searches,
        isLoading: false,
        isLoadingMore: false,
        hasMore: hasMore,
        clearError: true,
      );

      if (loadMore) _currentLimit += _pageSize;
    } catch (e) {
      AppLogger.error('Failed to load search history: $e', tag: 'SearchHistoryProvider');
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Delete a single search history item
  Future<void> deleteItem(SearchHistory item) async {
    final index = state.searches.indexWhere((s) => s.id == item.id);
    if (index == -1) return;

    // Optimistic update
    final backup = List<SearchHistory>.from(state.searches);
    final updated = List<SearchHistory>.from(state.searches)..removeAt(index);
    state = state.copyWith(searches: updated);

    try {
      final apiClient = ref.read(clientProvider);
      await apiClient.butler.deleteSearchHistoryItem(item.id!);
      AppLogger.info(
        'Deleted search item: ${item.query}',
        tag: 'SearchHistoryProvider',
      );
    } catch (e) {
      AppLogger.warning('Failed to delete search item: $e', tag: 'SearchHistoryProvider');
      // Revert on error
      state = state.copyWith(searches: backup);
      rethrow;
    }
  }

  /// Clear all search history
  Future<void> clearAll() async {
    final backup = List<SearchHistory>.from(state.searches);

    // Optimistic update
    state = state.copyWith(searches: const []);

    try {
      final apiClient = ref.read(clientProvider);
      final deletedCount = await apiClient.butler.clearSearchHistory();
      AppLogger.info(
        'Cleared $deletedCount search history items',
        tag: 'SearchHistoryProvider',
      );
    } catch (e) {
      AppLogger.error('Failed to clear search history: $e', tag: 'SearchHistoryProvider');
      // Revert on error
      state = state.copyWith(searches: backup);
      rethrow;
    }
  }

  /// Refresh the entire history list
  Future<void> refresh() async {
    _currentLimit = _pageSize;
    await loadHistory();
  }
}

/// Provider for search history state
final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, SearchHistoryState>(
      SearchHistoryNotifier.new,
    );
