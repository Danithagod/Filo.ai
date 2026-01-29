import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../models/search_result_models.dart';
import '../providers/search_controller.dart' as sc;
import '../widgets/search_result_card.dart';
import '../widgets/search_result_preview.dart';
import '../widgets/loading_skeletons.dart';
import '../widgets/app_background.dart';
import '../widgets/search/ai_search_progress_view.dart';
import '../widgets/search/bulk_actions_bar.dart';

/// Search results screen driven by SearchController
class SearchResultsScreen extends ConsumerStatefulWidget {
  final String query;
  final sc.SearchMode initialMode;
  final SearchFilters? initialFilters;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.initialMode = sc.SearchMode.hybrid,
    this.initialFilters,
  });

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchBarController;
  int? _selectedIndex;
  final Set<String> _selectedPaths = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchBarController = TextEditingController(text: widget.query);
    _scrollController.addListener(_onScroll);

    // Initialize search controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(sc.searchControllerProvider.notifier)
          .init(
            widget.query,
            widget.initialMode,
            widget.initialFilters,
          );
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchBarController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(sc.searchControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(sc.searchControllerProvider);
    final searchNotifier = ref.read(sc.searchControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(searchNotifier),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to previous screen',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Semantics(
              label: 'Search mode selector',
              child: SegmentedButton<sc.SearchMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: sc.SearchMode.semantic,
                    label: Text('Semantic'),
                    icon: Icon(Icons.search, size: 18),
                  ),
                  ButtonSegment(
                    value: sc.SearchMode.hybrid,
                    label: Text('Hybrid'),
                    icon: Icon(Icons.blur_on, size: 18),
                  ),
                  ButtonSegment(
                    value: sc.SearchMode.ai,
                    label: Text('AI'),
                    icon: Icon(Icons.auto_awesome, size: 18),
                  ),
                ],
                selected: {searchState.mode},
                onSelectionChanged: (Set<sc.SearchMode> selected) {
                  searchNotifier.updateMode(selected.first);
                },
              ),
            ),
          ),
          Tooltip(
            message:
                'Search Logic: Use AND, OR, NOT and "quotes" for complex queries.',
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildContent(searchState, searchNotifier),
        ),
      ),
    );
  }

  Widget _buildSearchBar(sc.SearchController searchNotifier) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      constraints: const BoxConstraints(maxWidth: 600),
      child: TextField(
        controller: _searchBarController,
        decoration: InputDecoration(
          hintText: 'Refine search...',
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () => _searchBarController.clear(),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            searchNotifier.updateQuery(value);
          }
        },
      ),
    );
  }

  Widget _buildContent(sc.SearchState state, sc.SearchController notifier) {
    if (state.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.mode == sc.SearchMode.ai
                ? 'AI Search in progress...'
                : 'Searching...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (state.mode == sc.SearchMode.ai &&
              state.progressHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            AISearchProgressView(
              history: state.progressHistory,
              isComplete: !state.isLoading && state.error == null,
              error: state.error,
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

    if (state.error != null) {
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
              state.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => notifier.performSearch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.suggestedQuery != null) ...[
              _buildDidYouMean(state.suggestedQuery!, notifier),
              const SizedBox(height: 32),
            ],
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
        if (state.facets.isNotEmpty) ...[
          SizedBox(
            width: 200,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: state.facets
                    .map((facet) => _buildFacet(facet, state, notifier))
                    .toList(),
              ),
            ),
          ),
          const VerticalDivider(width: 32),
        ],
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.suggestedQuery != null) ...[
                _buildDidYouMean(state.suggestedQuery!, notifier),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Text(
                    '${state.results.length}${state.hasMore ? '+' : ''} results found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedPaths.isEmpty)
                    TextButton.icon(
                      onPressed: () => setState(() {
                        for (final r in state.results) {
                          _selectedPaths.add(r.path);
                        }
                      }),
                      icon: const Icon(Icons.select_all, size: 18),
                      label: const Text('Select All'),
                    ),
                ],
              ),
              if (_selectedPaths.isNotEmpty) ...[
                const SizedBox(height: 8),
                BulkActionsBar(
                  selectedCount: _selectedPaths.length,
                  totalCount: state.results.length,
                  onSelectAll: () => setState(() {
                    for (final r in state.results) {
                      _selectedPaths.add(r.path);
                    }
                  }),
                  onDeselectAll: () => setState(() => _selectedPaths.clear()),
                  onTag: () => _showBulkTagDialog(),
                  onExport: () => _exportSelectedPaths(),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: state.results.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.results.length) {
                      return _buildLoadMoreFooter(state, notifier);
                    }

                    final result = state.results[index];
                    return SearchResultCard(
                      title: result.fileName,
                      path: result.path,
                      preview: result.contentPreview,
                      relevanceScore: result.relevanceScore,
                      tags: result.tags,
                      isSelected: _selectedIndex == index,
                      onTap: () => setState(() => _selectedIndex = index),
                      highlightQuery: state.query,
                      showCheckbox: _selectedPaths.isNotEmpty,
                      isChecked: _selectedPaths.contains(result.path),
                      onCheckChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedPaths.add(result.path);
                          } else {
                            _selectedPaths.remove(result.path);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (_selectedIndex != null &&
            _selectedIndex! < state.results.length) ...[
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: _buildPreviewPane(state.results[_selectedIndex!]),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadMoreFooter(
    sc.SearchState state,
    sc.SearchController notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: state.loadMoreError != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load more results',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () => notifier.loadMore(),
                    child: const Text('Retry'),
                  ),
                ],
              )
            : state.isLoadingMore
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: () => notifier.loadMore(),
                child: const Text('Load more'),
              ),
      ),
    );
  }

  Widget _buildPreviewPane(UnifiedSearchResult result) {
    return SearchResultPreview(
      key: ValueKey(result.path),
      title: result.fileName,
      path: result.path,
      relevanceScore: result.relevanceScore,
      tags: result.tags,
    );
  }

  Widget _buildDidYouMean(String suggestion, sc.SearchController notifier) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Did you mean: '),
          GestureDetector(
            onTap: () {
              _searchBarController.text = suggestion;
              notifier.updateQuery(suggestion);
            },
            child: Text(
              suggestion,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Text('?'),
        ],
      ),
    );
  }

  Widget _buildFacet(
    SearchFacet facet,
    sc.SearchState state,
    sc.SearchController notifier,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    String title;
    switch (facet.facetType) {
      case 'fileType':
        title = 'File Types';
        break;
      case 'tag':
        title = 'Tags';
        break;
      default:
        title = facet.facetType;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        ...facet.entries.map((entry) {
          final isSelected =
              state.filters?.fileTypes?.contains(entry.value) == true ||
              state.filters?.tags?.contains(entry.value) == true;

          return InkWell(
            onTap: () {
              final filters = state.filters ?? SearchFilters();
              if (facet.facetType == 'fileType') {
                final list = filters.fileTypes?.toList() ?? [];
                if (list.contains(entry.value)) {
                  list.remove(entry.value);
                } else {
                  list.add(entry.value);
                }
                filters.fileTypes = list.isNotEmpty ? list : null;
              } else if (facet.facetType == 'tag') {
                final list = filters.tags?.toList() ?? [];
                if (list.contains(entry.value)) {
                  list.remove(entry.value);
                } else {
                  list.add(entry.value);
                }
                filters.tags = list.isNotEmpty ? list : null;
              }
              notifier.updateFilters(filters);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.label,
                      style: textTheme.bodySmall?.copyWith(
                        color: isSelected ? colorScheme.primary : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.count}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const Divider(),
      ],
    );
  }

  void _showBulkTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tags'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter tags (comma-separated)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tags would be applied to ${_selectedPaths.length} files'),
                ),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _exportSelectedPaths() {
    final paths = _selectedPaths.join('\n');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedPaths.length} file paths copied'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Selected Files'),
                content: SizedBox(
                  width: 400,
                  height: 300,
                  child: SingleChildScrollView(
                    child: SelectableText(paths),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
