import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';
import '../models/search_result_models.dart';
import '../utils/rate_limiter.dart';

enum SearchMode { semantic, hybrid, ai }

class SearchState {
  final String query;
  final List<UnifiedSearchResult> results;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String? loadMoreError;
  final SearchMode mode;
  final SearchFilters? filters;
  final List<AISearchProgress> progressHistory;
  final List<SearchFacet> facets;
  final String? suggestedQuery;
  final String? nextCursor;
  final int searchToken;

  SearchState({
    required this.query,
    this.results = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.loadMoreError,
    this.mode = SearchMode.hybrid,
    this.filters,
    this.progressHistory = const [],
    this.facets = const [],
    this.suggestedQuery,
    this.nextCursor,
    this.searchToken = 0,
  });

  SearchState copyWith({
    String? query,
    List<UnifiedSearchResult>? results,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? loadMoreError,
    SearchMode? mode,
    SearchFilters? filters,
    List<AISearchProgress>? progressHistory,
    List<SearchFacet>? facets,
    String? suggestedQuery,
    String? nextCursor,
    int? searchToken,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      loadMoreError: loadMoreError ?? this.loadMoreError,
      mode: mode ?? this.mode,
      filters: filters ?? this.filters,
      progressHistory: progressHistory ?? this.progressHistory,
      facets: facets ?? this.facets,
      suggestedQuery: suggestedQuery ?? this.suggestedQuery,
      nextCursor: nextCursor ?? this.nextCursor,
      searchToken: searchToken ?? this.searchToken,
    );
  }
}

class SearchController extends Notifier<SearchState> {
  StreamSubscription<AISearchProgress>? _aiSearchSubscription;
  Timer? _paginationDebounce;
  bool _isLoadMorePending = false;

  @override
  SearchState build() {
    ref.onDispose(() {
      _aiSearchSubscription?.cancel();
      _paginationDebounce?.cancel();
    });

    return SearchState(query: '');
  }

  void init(String query, SearchMode mode, SearchFilters? filters) {
    if (state.query == query && state.mode == mode && state.filters == filters) {
      return;
    }

    state = state.copyWith(
      query: query,
      mode: mode,
      filters: filters ?? state.filters,
    );
    if (query.isNotEmpty) {
      performSearch();
    }
  }

  Future<void> performSearch({
    SearchMode? mode,
    String? query,
    SearchFilters? filters,
  }) async {
    final newQuery = query ?? state.query;
    final newMode = mode ?? state.mode;
    final newFilters = filters ?? state.filters;

    if (newQuery.trim().isEmpty) {
      state = state.copyWith(
        query: newQuery,
        error: 'Please enter a search query',
        isLoading: false,
      );
      return;
    }

    if (newQuery.length > 500) {
      state = state.copyWith(
        query: newQuery,
        error: 'Search query is too long',
        isLoading: false,
      );
      return;
    }

    await _aiSearchSubscription?.cancel();
    _aiSearchSubscription = null;

    final currentToken = state.searchToken + 1;

    final searchEndpoint = newMode.name;
    if (!rateLimiter.checkAndRecord(searchEndpoint, maxPerMinute: 30)) {
      final waitSeconds = rateLimiter.getSecondsUntilAvailable(searchEndpoint);
      state = state.copyWith(
        query: newQuery,
        mode: newMode,
        filters: newFilters,
        error: 'Too many search requests. Please wait $waitSeconds seconds.',
        isLoading: false,
        searchToken: currentToken,
      );
      return;
    }

    state = state.copyWith(
      query: newQuery,
      mode: newMode,
      filters: newFilters,
      isLoading: true,
      error: null,
      loadMoreError: null,
      results: [],
      nextCursor: null,
      hasMore: true,
      progressHistory: [],
      suggestedQuery: null,
      facets: [],
      searchToken: currentToken,
    );

    _fetchFacets();

    if (newMode == SearchMode.ai) {
      await _performAISearch(currentToken);
    } else {
      await _performTraditionalSearch(currentToken);
    }
  }

  Future<void> _performAISearch(int token) async {
    runZonedGuarded(
      () async {
        try {
          final apiClient = ref.read(clientProvider);
          final stream = apiClient.butler.aiSearch(
            state.query,
            strategy: 'hybrid',
            maxResults: 20,
            filters: state.filters,
          );

          _aiSearchSubscription = stream.listen(
            (progress) {
              if (token != state.searchToken) return;

              final List<AISearchProgress> newHistory = List.from(
                state.progressHistory,
              );
              if ((progress.message != null && progress.message!.isNotEmpty) ||
                  (progress.results != null && progress.results!.isNotEmpty) ||
                  progress.type == 'thinking' ||
                  progress.type == 'searching') {
                newHistory.add(progress);
                if (newHistory.length > 20) newHistory.removeAt(0);
              }

              List<UnifiedSearchResult> newResults = state.results;
              if (progress.results != null && progress.results!.isNotEmpty) {
                final Set<String> paths = {};
                newResults = progress.results!
                    .map((r) {
                      return UnifiedSearchResult.fromAISearchResult(r);
                    })
                    .where((r) => paths.add(r.path))
                    .toList();
              }

              String? suggestedQuery = state.suggestedQuery;
              bool isLoading = state.isLoading;
              bool hasMore = state.hasMore;

              if (progress.type == 'complete') {
                isLoading = false;
                hasMore = false;
                if (progress.results != null && progress.results!.isNotEmpty) {
                  suggestedQuery = progress.results!.first.suggestedQuery;
                }
              }

              if (progress.type == 'error') {
                final errorMsg =
                    progress.error ?? progress.message ?? 'Search failed';
                if (_canFallback(errorMsg)) {
                  _triggerFallback(token, errorMsg);
                  return;
                } else {
                  state = state.copyWith(
                    error: errorMsg,
                    isLoading: false,
                    progressHistory: newHistory,
                  );
                  return;
                }
              }

              state = state.copyWith(
                progressHistory: newHistory,
                results: newResults,
                isLoading: isLoading,
                hasMore: hasMore,
                suggestedQuery: suggestedQuery,
              );
            },
            onError: (e) {
              if (token != state.searchToken) return;
              if (_canFallback(e)) {
                _triggerFallback(token, e.toString());
              } else {
                _handleError(e);
              }
            },
            onDone: () {
              if (token != state.searchToken) return;
              if (state.isLoading) {
                state = state.copyWith(isLoading: false);
              }
            },
          );
        } catch (e) {
          if (token != state.searchToken) return;
          if (_canFallback(e)) {
            _triggerFallback(token, e.toString());
          } else {
            _handleError(e);
          }
        }
      },
      (error, stack) {
        final msg = error.toString();
        if (!msg.contains('Cannot add event after closing') &&
            !msg.contains(
              'Message posted when web socket connection is closed',
            )) {
          debugPrint(
            'Uncaught error in AI search controller zone: $error\n$stack',
          );
          if (token == state.searchToken) {
            _handleError(error);
          }
        }
      },
    );
  }

  Future<void> _performTraditionalSearch(int token) async {
    try {
      final apiClient = ref.read(clientProvider);

      if (state.mode == SearchMode.semantic) {
        final stream = apiClient.butler.semanticSearchStream(
          state.query,
          limit: 20,
          threshold: 0.3,
          offset: 0,
          filters: state.filters,
        );

        final Set<String> paths = {};
        final List<UnifiedSearchResult> newResults = [];
        String? suggested;

        await for (final result in stream) {
          if (token != state.searchToken) break;

          if (result.id == -1) {
            suggested = result.suggestedQuery;
            continue;
          }

          if (result.path.isNotEmpty && paths.add(result.path)) {
            newResults.add(UnifiedSearchResult.fromSearchResult(result));
            state = state.copyWith(
              results: List.from(newResults),
              isLoading: false,
              suggestedQuery: suggested ?? result.suggestedQuery,
            );
          }
        }

        if (token == state.searchToken && newResults.isNotEmpty) {
          final last = (newResults.last as TraditionalSearchResultWrapper).raw;
          state = state.copyWith(
            hasMore: last.nextCursor != null,
            nextCursor: last.nextCursor,
          );
        }
      } else {
        final results = await apiClient.butler.hybridSearch(
          state.query,
          limit: 20,
          threshold: 0.3,
          offset: 0,
          semanticWeight: state.filters?.semanticWeight,
          keywordWeight: state.filters?.keywordWeight,
          filters: state.filters,
        );

        if (token != state.searchToken) return;

        final Set<String> paths = {};
        final List<UnifiedSearchResult> newResults = results
            .where((r) => paths.add(r.path))
            .map((r) => UnifiedSearchResult.fromSearchResult(r))
            .toList();

        state = state.copyWith(
          results: newResults,
          isLoading: false,
          hasMore: results.isNotEmpty && results.last.nextCursor != null,
          nextCursor: results.isNotEmpty ? results.last.nextCursor : null,
          suggestedQuery: results.isNotEmpty
              ? results.first.suggestedQuery
              : null,
        );
      }
    } catch (e) {
      if (token == state.searchToken) {
        _handleError(e);
      }
    }
  }

  Future<void> loadMore() async {
    if (state.mode == SearchMode.ai) return;
    if (state.isLoadingMore || !state.hasMore) return;
    if (_isLoadMorePending) return;

    _paginationDebounce?.cancel();
    _isLoadMorePending = true;
    _paginationDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        await _executeLoadMore();
      } finally {
        _isLoadMorePending = false;
      }
    });
  }

  Future<void> _executeLoadMore() async {
    final searchEndpoint = state.mode.name;
    if (!rateLimiter.checkAndRecord(searchEndpoint, maxPerMinute: 30)) {
      final waitSeconds = rateLimiter.getSecondsUntilAvailable(searchEndpoint);
      state = state.copyWith(
        loadMoreError: 'Rate limited. Please wait $waitSeconds seconds.',
      );
      return;
    }

    state = state.copyWith(isLoadingMore: true, loadMoreError: null);

    try {
      final apiClient = ref.read(clientProvider);
      final filtersWithCursor =
          state.filters?.copyWith(cursor: state.nextCursor) ??
          SearchFilters(cursor: state.nextCursor);

      final List<SearchResult> results = state.mode == SearchMode.hybrid
          ? await apiClient.butler.hybridSearch(
              state.query,
              limit: 20,
              threshold: 0.3,
              offset: 0,
              semanticWeight: state.filters?.semanticWeight,
              keywordWeight: state.filters?.keywordWeight,
              filters: filtersWithCursor,
            )
          : await apiClient.butler.semanticSearch(
              state.query,
              limit: 20,
              threshold: 0.3,
              offset: 0,
              filters: filtersWithCursor,
            );

      final Set<String> existingPaths = state.results
          .map((r) => r.path)
          .toSet();
      final List<UnifiedSearchResult> newResults = List.from(state.results);

      for (final r in results) {
        if (existingPaths.add(r.path)) {
          newResults.add(UnifiedSearchResult.fromSearchResult(r));
        }
      }

      state = state.copyWith(
        results: newResults,
        hasMore: results.isNotEmpty && results.last.nextCursor != null,
        nextCursor: results.isNotEmpty ? results.last.nextCursor : null,
        isLoadingMore: false,
      );
    } catch (e) {
      _handleError(e, isLoadMore: true);
    }
  }

  bool _canFallback(dynamic error) {
    // Check for specific exception types first
    if (error is StateError) return false;

    final msg = error.toString().toLowerCase();

    // Don't fallback on cancellation
    if (msg.contains('operation cancelled') || msg.contains('canceled')) {
      return false;
    }

    // Don't fallback on authentication/authorization errors
    // Check for HTTP status codes and common auth error messages
    final authPatterns = [
      '401', '403', '404',
      'unauthorized', 'forbidden', 'not found',
      'invalid credentials', 'access denied',
      'authentication failed', 'permission denied',
      'invalid api key', 'expired token',
    ];

    for (final pattern in authPatterns) {
      if (msg.contains(pattern)) {
        return false;
      }
    }

    // Don't fallback on validation errors
    if (msg.contains('validation') || msg.contains('invalid input')) {
      return false;
    }

    return true;
  }

  void _triggerFallback(int token, String originalError) {
    if (token != state.searchToken) return;

    _aiSearchSubscription?.cancel();
    _aiSearchSubscription = null;

    state = state.copyWith(
      mode: SearchMode.hybrid,
      isLoading: true,
      error: null,
      progressHistory: [],
    );

    _performTraditionalSearch(token);
  }

  void _handleError(dynamic e, {bool isLoadMore = false}) {
    String msg = e.toString();
    if (msg.startsWith('Exception: ')) msg = msg.substring(11);

    if (msg.contains('CircuitBreakerOpenException') ||
        msg.contains('Circuit breaker')) {
      msg = 'System is protecting itself from overload. Please wait a moment.';
    } else if (msg.contains('429') || msg.contains('Rate limit')) {
      msg = 'Too many requests. Please wait before searching again.';
    } else if (msg.contains('Connection refused') ||
        msg.contains('SocketException')) {
      msg = 'Cannot connect to server. Check your connection.';
    } else if (msg.contains('timed out')) {
      msg = 'Search timed out. Try a simpler query.';
    }

    if (isLoadMore) {
      state = state.copyWith(loadMoreError: msg, isLoadingMore: false);
    } else {
      state = state.copyWith(error: msg, isLoading: false);
    }
  }

  Future<void> _fetchFacets() async {
    try {
      final apiClient = ref.read(clientProvider);
      final facets = await apiClient.butler.getSearchFacets(
        state.query,
        filters: state.filters,
      );
      state = state.copyWith(facets: facets);
    } catch (e) {
      debugPrint('Error fetching facets: $e');
    }
  }

  void updateFilters(SearchFilters filters) {
    performSearch(filters: filters);
  }

  void updateMode(SearchMode mode) {
    performSearch(mode: mode);
  }

  void updateQuery(String query) {
    performSearch(query: query);
  }
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(() {
      return SearchController();
    });
