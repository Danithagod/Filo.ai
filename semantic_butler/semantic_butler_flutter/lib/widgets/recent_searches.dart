import 'package:flutter/material.dart';
import '../main.dart';

/// Recent searches list widget with Material 3 styling
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
  List<Map<String, dynamic>> _searches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final history = await client.butler.getSearchHistory(limit: 10);
      setState(() {
        _searches = history
            .map(
              (h) => {
                'query': h.query,
                'time': _formatTime(h.searchedAt),
                'results': h.resultCount,
              },
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searches = [];
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
      children: _searches
          .map(
            (search) => _SearchHistoryTile(
              query: search['query'] as String,
              time: search['time'] as String,
              resultCount: search['results'] as int,
              onTap: () => widget.onSearchTap(search['query'] as String),
            ),
          )
          .toList(),
    );
  }
}

class _SearchHistoryTile extends StatelessWidget {
  final String query;
  final String time;
  final int resultCount;
  final VoidCallback onTap;

  const _SearchHistoryTile({
    required this.query,
    required this.time,
    required this.resultCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.history,
            color: colorScheme.onSecondaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          query,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$resultCount results • $time',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}
