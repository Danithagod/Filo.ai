import 'package:flutter/material.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';
import '../utils/app_logger.dart';
import 'loading_skeletons.dart';

/// Recent searches list widget with Material 3 styling
/// Includes delete individual items, clear all, and load more functionality
class RecentSearches extends StatefulWidget {
  final Function(String) onSearchTap;

  const RecentSearches({
    super.key,
    required this.onSearchTap,
  });

  @override
  State<RecentSearches> createState() => _RecentSearchesState();
}

class _RecentSearchesState extends State<RecentSearches> {
  List<SearchHistory> _searches = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _loadError;
  int _currentLimit = 10;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _loadError = null;
        _currentLimit = _pageSize;
      });
    }

    AppLogger.debug(
      'Loading search history (limit: $_currentLimit, loadMore: $loadMore)',
      tag: 'RecentSearches',
    );

    try {
      final history = await client.butler.getSearchHistory(
        limit: _pageSize, // Always fetch page size
        offset: loadMore
            ? _currentLimit - _pageSize
            : 0, // Offset based on current position
      );
      AppLogger.debug(
        'Loaded ${history.length} search history items',
        tag: 'RecentSearches',
      );

      if (!mounted) return;

      setState(() {
        _searches = history.where((h) => h.query.isNotEmpty).toList();
        _hasMore = history.length >= _currentLimit;
        _isLoading = false;
        _isLoadingMore = false;
        _loadError = null;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load search history',
        tag: 'RecentSearches',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        if (!loadMore) {
          _searches = [];
        }
        _isLoading = false;
        _isLoadingMore = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _currentLimit += _pageSize;
    await _loadSearchHistory(loadMore: true);
  }

  Future<void> _deleteItem(SearchHistory item) async {
    final index = _searches.indexWhere((s) => s.id == item.id);
    if (index == -1) return;

    setState(() {
      _searches.removeAt(index);
    });

    // Call backend to delete the item
    try {
      await client.butler.deleteSearchHistoryItem(item.id!);
      AppLogger.info(
        'Deleted search item: ${item.query}',
        tag: 'RecentSearches',
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to delete search item: $e',
        tag: 'RecentSearches',
      );
      // Re-add to local state if backend delete failed
      setState(() {
        _searches.insert(index, item);
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${item.query}"'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _clearAllHistory() async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.delete_forever, color: colorScheme.error, size: 48),
        title: const Text('Clear All History?'),
        content: const Text(
          'This will permanently delete all your search history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Keep backup for restoration
    final backup = List<SearchHistory>.from(_searches);

    setState(() {
      _searches = [];
    });

    try {
      final deletedCount = await client.butler.clearSearchHistory();
      AppLogger.info(
        'Cleared $deletedCount search history items',
        tag: 'RecentSearches',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleared ${backup.length} search history items'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error(
        'Failed to clear search history: $e',
        tag: 'RecentSearches',
      );
      if (mounted) {
        setState(() {
          _searches = backup;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clear failed: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${time.month}/${time.day}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const RecentSearchesSkeleton(itemCount: 3);
    }

    // Show error state with retry button
    if (_loadError != null && _searches.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load search history',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _loadSearchHistory,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_searches.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(
                Icons.history,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Text(
                'No recent searches',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with actions
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Recent Searches',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_searches.length}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: _loadSearchHistory,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Refresh history',
                  ),
                  if (_searches.isNotEmpty)
                    TextButton(
                      onPressed: _clearAllHistory,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Clear All'),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Search history list
        ..._searches.map(
          (search) => _SearchHistoryTile(
            item: search,
            time: _formatTime(search.searchedAt),
            onTap: () => widget.onSearchTap(search.query),
            onDelete: () => _deleteItem(search),
          ),
        ),

        // Load more button
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton.icon(
                      onPressed: _loadMore,
                      icon: const Icon(Icons.expand_more, size: 18),
                      label: const Text('Show More'),
                    ),
            ),
          ),
      ],
    );
  }
}

class _SearchHistoryTile extends StatefulWidget {
  final SearchHistory item;
  final String time;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SearchHistoryTile({
    required this.item,
    required this.time,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_SearchHistoryTile> createState() => _SearchHistoryTileState();
}

class _SearchHistoryTileState extends State<_SearchHistoryTile> {
  bool _isHovered = false;

  IconData _getSearchIcon() {
    switch (widget.item.searchType) {
      case 'local':
        return Icons.folder_open;
      case 'semantic':
        return Icons.auto_awesome;
      default:
        return Icons.search;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getSearchIcon(),
              color: colorScheme.onSecondaryContainer,
              size: 20,
            ),
          ),
          title: Text(
            widget.item.query,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              if (widget.item.searchType != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.item.searchType == 'local'
                        ? colorScheme.tertiaryContainer
                        : colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.item.searchType == 'local'
                            ? Icons.folder
                            : Icons.psychology,
                        size: 14,
                        color: widget.item.searchType == 'local'
                            ? colorScheme.onTertiaryContainer
                            : colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.item.searchType!.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: widget.item.searchType == 'local'
                              ? colorScheme.onTertiaryContainer
                              : colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '${widget.item.resultCount} results',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.time,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          trailing: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isHovered ? 1.0 : 0.0,
            child: IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: colorScheme.error,
              ),
              onPressed: widget.onDelete,
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
            ),
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
