import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';
import '../widgets/search_result_card.dart';
import '../widgets/search_result_preview.dart';
import '../widgets/loading_skeletons.dart';
import '../widgets/app_background.dart';
import '../utils/rate_limiter.dart';

/// Search mode for different search strategies
enum SearchMode {
  semantic,
  hybrid,
  ai,
}

/// Search results screen with infinite scroll pagination
class SearchResultsScreen extends ConsumerStatefulWidget {
  final String query;
  final SearchMode initialMode;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.initialMode = SearchMode.hybrid,
    this.initialFilters,
  });

  final SearchFilters? initialFilters;

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  final List<dynamic> _results = [];
  final Set<String> _resultPaths = {}; // Track unique paths for deduplication
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _loadMoreError; // Error state for pagination failures
  SearchMode _searchMode = SearchMode.hybrid; // Default to hybrid search
  SearchFilters? _filters;
  int? _selectedIndex; // Currently selected result for preview

  // AI Search specific state
  final List<String> _aiSearchProgress = [];
  StreamSubscription<AISearchProgress>? _aiSearchSubscription;

  static const int _pageSize = 20;
  int _currentOffset = 0;

  final ScrollController _scrollController = ScrollController();

  /// Search cancellation token - incremented on each new search to cancel stale results
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _searchMode = widget.initialMode;
    _filters = widget.initialFilters;
    _scrollController.addListener(_onScroll);
    _performSearch();
  }

  @override
  void dispose() {
    _aiSearchSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _performSearch() async {
    // Cancel any existing AI search subscription
    await _aiSearchSubscription?.cancel();
    _aiSearchSubscription = null;

    // Increment token to cancel any in-flight searches
    final currentToken = ++_searchToken;

    // Client-side rate limiting for better UX
    final searchEndpoint = _searchMode.name;
    if (!rateLimiter.checkAndRecord(searchEndpoint, maxPerMinute: 30)) {
      final waitSeconds = rateLimiter.getSecondsUntilAvailable(searchEndpoint);
      setState(() {
        _error = 'Too many search requests. Please wait $waitSeconds seconds.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _loadMoreError = null;
      _results.clear();
      _resultPaths.clear();
      _currentOffset = 0;
      _hasMore = true;
      _aiSearchProgress.clear();
      _selectedIndex = null;
    });

    // Use different search methods based on mode
    if (_searchMode == SearchMode.ai) {
      await _performAISearch(currentToken);
    } else {
      await _performTraditionalSearch(currentToken);
    }
  }

  /// Perform AI-powered search with streaming progress
  Future<void> _performAISearch(int currentToken) async {
    try {
      final stream = client.butler.aiSearch(
        widget.query,
        strategy: 'hybrid',
        maxResults: _pageSize,
      );

      _aiSearchSubscription = stream.listen(
        (progress) {
          // Check if this search was cancelled
          if (!mounted || currentToken != _searchToken) return;

          setState(() {
            // Add progress message
            if (progress.message != null && progress.message!.isNotEmpty) {
              _aiSearchProgress.add(progress.message!);
              // Keep only last 5 messages
              if (_aiSearchProgress.length > 5) {
                _aiSearchProgress.removeAt(0);
              }
            }

            // Update results when available
            if (progress.results != null && progress.results!.isNotEmpty) {
              _results.clear();
              _results.addAll(progress.results!);
            }

            // Mark as complete
            if (progress.type == 'complete') {
              _isLoading = false;
              _hasMore = false;
              _currentOffset = _results.length;
            }

            // Handle errors
            if (progress.type == 'error') {
              _error = progress.error ?? progress.message ?? 'Search failed';
              _isLoading = false;
            }
          });
        },
        onError: (e) {
          if (!mounted || currentToken != _searchToken) return;
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        },
        onDone: () {
          if (!mounted || currentToken != _searchToken) return;
          if (_isLoading) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (!mounted || currentToken != _searchToken) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Perform traditional semantic or hybrid search
  Future<void> _performTraditionalSearch(int currentToken) async {
    try {
      final results = _searchMode == SearchMode.hybrid
          ? await client.butler.hybridSearch(
              widget.query,
              limit: _pageSize,
              threshold: 0.3,
              offset: 0,
            )
          : await client.butler.semanticSearch(
              widget.query,
              limit: _pageSize,
              threshold: 0.3,
              offset: 0,
              filters: _filters,
            );

      // Check if this search was cancelled (user switched modes)
      if (!mounted || currentToken != _searchToken) return;

      setState(() {
        // Filter out duplicates
        for (final result in results) {
          // Dynamic access to path since we have mixed types
          final String p = (result as dynamic).path ?? '';
          if (p.isNotEmpty && !_resultPaths.contains(p)) {
            _resultPaths.add(p);
            _results.add(result);
          }
        }

        _isLoading = false;
        _hasMore = results.length >= _pageSize;
        _currentOffset = results
            .length; // This might drift if we dedup, but offset is for backend
      });
    } catch (e) {
      // Only handle error if this search wasn't cancelled
      if (!mounted || currentToken != _searchToken) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    // AI search doesn't support pagination - results are streamed all at once
    if (_searchMode == SearchMode.ai) return;

    if (_isLoadingMore || !_hasMore) return;

    // Client-side rate limiting for pagination
    final searchEndpoint = _searchMode.name;
    if (!rateLimiter.checkAndRecord(searchEndpoint, maxPerMinute: 30)) {
      final waitSeconds = rateLimiter.getSecondsUntilAvailable(searchEndpoint);
      setState(() {
        _loadMoreError = 'Rate limited. Please wait $waitSeconds seconds.';
      });
      return;
    }

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      final results = _searchMode == SearchMode.hybrid
          ? await client.butler.hybridSearch(
              widget.query,
              limit: _pageSize,
              threshold: 0.3,
              offset: _currentOffset,
            )
          : await client.butler.semanticSearch(
              widget.query,
              limit: _pageSize,
              threshold: 0.3,
              offset: _currentOffset,
            );
      if (!mounted) return;
      setState(() {
        // Filter out duplicates
        for (final result in results) {
          final String p = (result as dynamic).path ?? '';
          if (p.isNotEmpty && !_resultPaths.contains(p)) {
            _resultPaths.add(p);
            _results.add(result);
          }
        }
        _hasMore = results.length >= _pageSize;
        _currentOffset += results.length;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadMoreError = e.toString();
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results for "${widget.query}"'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SegmentedButton<SearchMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: SearchMode.semantic,
                  label: Text('Semantic'),
                  icon: Icon(Icons.search, size: 18),
                ),
                ButtonSegment(
                  value: SearchMode.hybrid,
                  label: Text('Hybrid'),
                  icon: Icon(Icons.blur_on, size: 18),
                ),
                ButtonSegment(
                  value: SearchMode.ai,
                  label: Text('AI'),
                  icon: Icon(Icons.auto_awesome, size: 18),
                ),
              ],
              selected: {_searchMode},
              onSelectionChanged: (Set<SearchMode> selected) {
                setState(() {
                  _searchMode = selected.first;
                });
                _performSearch();
              },
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _searchMode == SearchMode.ai
                ? 'AI Search in progress...'
                : 'Searching...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          // Show AI search progress messages
          if (_searchMode == SearchMode.ai && _aiSearchProgress.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withAlpha(128),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _aiSearchProgress
                    .map(
                      (msg) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                msg,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Expanded(
            child: SingleChildScrollView(
              child: SearchResultsSkeletonList(itemCount: 5),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Search Failed',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search query or index more documents.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results List
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_results.length}${_hasMore ? '+' : ''} results found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _results.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading indicator or error at bottom
                    if (index >= _results.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: _loadMoreError != null
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Failed to load more results',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FilledButton.tonal(
                                      onPressed: () {
                                        setState(() => _loadMoreError = null);
                                        _loadMore();
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                )
                              : _isLoadingMore
                              ? const CircularProgressIndicator()
                              : TextButton(
                                  onPressed: _loadMore,
                                  child: const Text('Load more'),
                                ),
                        ),
                      );
                    }

                    final result = _results[index];

                    // Handle both SearchResult and AISearchResult types
                    final String title;
                    final String path;
                    final String preview;
                    final double score;
                    final List<String> tags;

                    if (result is AISearchResult) {
                      title = result.fileName;
                      path = result.path;
                      preview =
                          result.contentPreview ?? result.matchReason ?? '';
                      score = result.relevanceScore ?? 0.5;
                      tags = result.tags ?? [];
                    } else {
                      // SearchResult type
                      title = result.fileName ?? 'Unknown';
                      path = result.path ?? '';
                      preview = result.contentPreview ?? '';
                      score = result.relevanceScore ?? 0.0;
                      tags =
                          (result.tags as List<dynamic>?)
                              ?.whereType<String>()
                              .toList() ??
                          [];
                    }

                    return SearchResultCard(
                      title: title,
                      path: path,
                      preview: preview,
                      relevanceScore: score,
                      tags: tags,
                      isSelected: _selectedIndex == index,
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Preview Pane
        if (_selectedIndex != null && _selectedIndex! < _results.length) ...[
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: _buildPreview(_results[_selectedIndex!]),
          ),
        ],
      ],
    );
  }

  Widget _buildPreview(dynamic result) {
    final String title;
    final String path;
    final double score;
    final List<String> tags;

    if (result is AISearchResult) {
      title = result.fileName;
      path = result.path;
      score = result.relevanceScore ?? 0.5;
      tags = result.tags ?? [];
    } else {
      title = result.fileName ?? 'Unknown';
      path = result.path ?? '';
      score = result.relevanceScore ?? 0.0;
      tags =
          (result.tags as List<dynamic>?)?.whereType<String>().toList() ?? [];
    }

    return SearchResultPreview(
      key: ValueKey(path), // Ensure it rebuilds for new files
      title: title,
      path: path,
      relevanceScore: score,
      tags: tags,
    );
  }
}
