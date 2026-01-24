import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../providers/search_history_provider.dart';
import 'loading_skeletons.dart';

/// Recent searches list widget with Material 3 styling
/// Includes delete individual items, clear all, and load more functionality
class RecentSearches extends ConsumerWidget {
  final Function(String) onSearchTap;

  const RecentSearches({
    super.key,
    required this.onSearchTap,
  });

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
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final historyState = ref.watch(searchHistoryProvider);

    if (historyState.isLoading) {
      return const RecentSearchesSkeleton(itemCount: 3);
    }

    // Show error state with retry button
    if (historyState.error != null && historyState.searches.isEmpty) {
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
                historyState.error!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.read(searchHistoryProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (historyState.searches.isEmpty) {
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
                      '${historyState.searches.length}',
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
                    onPressed: () => ref.read(searchHistoryProvider.notifier).refresh(),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Refresh history',
                  ),
                  if (historyState.searches.isNotEmpty)
                    TextButton(
                      onPressed: () => _showClearAllDialog(context, ref),
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
        ...historyState.searches.map(
          (search) => _SearchHistoryTile(
            item: search,
            time: _formatTime(search.searchedAt),
            onTap: () => onSearchTap(search.query),
            onDelete: () => _deleteItem(context, ref, search),
          ),
        ),

        // Load more button
        if (historyState.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: historyState.isLoadingMore
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton.icon(
                      onPressed: () =>
                          ref.read(searchHistoryProvider.notifier).loadHistory(loadMore: true),
                      icon: const Icon(Icons.expand_more, size: 18),
                      label: const Text('Show More'),
                    ),
            ),
          ),
      ],
    );
  }

  Future<void> _showClearAllDialog(BuildContext context, WidgetRef ref) async {
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

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(searchHistoryProvider.notifier).clearAll();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Search history cleared'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Clear failed: $e'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref, SearchHistory item) async {
    try {
      await ref.read(searchHistoryProvider.notifier).deleteItem(item);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${item.query}"'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
