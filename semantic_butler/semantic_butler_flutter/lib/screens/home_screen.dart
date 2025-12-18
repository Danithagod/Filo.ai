import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../main.dart';
import '../utils/app_logger.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/stats_card.dart';
import '../widgets/recent_searches.dart';
import 'search_results_screen.dart';
import 'settings_screen.dart';

/// Home screen with Material 3 navigation rail
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Material 3 Navigation Rail
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: FloatingActionButton(
                  elevation: 0,
                  onPressed: () => _showQuickSearch(context),
                  child: const Icon(Icons.search),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: Text('Index'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),

            // Divider
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: colorScheme.outlineVariant,
            ),

            // Content area
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const SearchDashboard();
      case 1:
        return const IndexingScreen();
      case 2:
        return const SettingsScreen();
      default:
        return const SearchDashboard();
    }
  }

  void _showQuickSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _SemanticSearchDelegate(),
    );
  }
}

/// Search dashboard - main view with Material 3 styling
class SearchDashboard extends StatefulWidget {
  const SearchDashboard({super.key});

  @override
  State<SearchDashboard> createState() => _SearchDashboardState();
}

class _SearchDashboardState extends State<SearchDashboard> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(query: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header
          Text(
            'Semantic Butler',
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search your files using natural language',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 32),

          // Search bar with Material 3 styling
          SearchBarWidget(
            controller: _searchController,
            onSearch: _performSearch,
            hintText: 'Ask anything about your files...',
          ),

          const SizedBox(height: 32),

          // Stats section header
          Text(
            'Overview',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Stats cards - Material 3 style
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Documents',
                  value: '0',
                  icon: Icons.description_outlined,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Indexed',
                  value: '0',
                  icon: Icons.check_circle_outline,
                  color: colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Searches',
                  value: '0',
                  icon: Icons.search,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Recent searches section
          Text(
            'Recent',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          RecentSearches(
            onSearchTap: _performSearch,
          ),
        ],
      ),
    );
  }
}

/// Indexing screen with Material 3 styling and real-time progress
class IndexingScreen extends StatefulWidget {
  const IndexingScreen({super.key});

  @override
  State<IndexingScreen> createState() => _IndexingScreenState();
}

class _IndexingScreenState extends State<IndexingScreen> {
  bool _isIndexing = false;
  int _totalDocuments = 0;
  int _indexedDocuments = 0;
  int _pendingDocuments = 0;
  int _failedDocuments = 0;
  String? _currentFolder;

  @override
  void initState() {
    super.initState();
    _loadIndexingStatus();
  }

  Future<void> _loadIndexingStatus() async {
    AppLogger.debug('Loading indexing status...', tag: 'Indexing');
    try {
      final status = await client.butler.getIndexingStatus();
      AppLogger.info(
        'Status: ${status.indexedDocuments}/${status.totalDocuments} indexed, ${status.activeJobs} active jobs',
        tag: 'Indexing',
      );
      if (mounted) {
        setState(() {
          _totalDocuments = status.totalDocuments;
          _indexedDocuments = status.indexedDocuments;
          _pendingDocuments = status.pendingDocuments;
          _failedDocuments = status.failedDocuments;
          _isIndexing = status.activeJobs > 0;
        });

        // If indexing is active, poll for updates
        if (_isIndexing) {
          _pollIndexingStatus();
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load indexing status',
        tag: 'Indexing',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _pollIndexingStatus() async {
    while (_isIndexing && mounted) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final status = await client.butler.getIndexingStatus();
        if (mounted) {
          setState(() {
            _totalDocuments = status.totalDocuments;
            _indexedDocuments = status.indexedDocuments;
            _pendingDocuments = status.pendingDocuments;
            _failedDocuments = status.failedDocuments;
            _isIndexing = status.activeJobs > 0;
          });
        }
      } catch (e) {
        // Continue polling even on error
      }
    }
  }

  Future<void> _pickFolder() async {
    AppLogger.info('Opening folder picker...', tag: 'Indexing');
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null && mounted) {
        AppLogger.info('Selected folder: $selectedDirectory', tag: 'Indexing');
        setState(() {
          _isIndexing = true;
          _currentFolder = selectedDirectory;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting to index: $selectedDirectory'),
            duration: const Duration(seconds: 2),
          ),
        );

        // Call the server to start indexing
        AppLogger.info('Calling startIndexing API...', tag: 'Indexing');
        await client.butler.startIndexing(selectedDirectory);
        AppLogger.info('startIndexing API call completed', tag: 'Indexing');

        // Start polling for status
        _pollIndexingStatus();
      } else {
        AppLogger.debug('Folder picker cancelled', tag: 'Indexing');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to start indexing',
        tag: 'Indexing',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _isIndexing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  double get _progress {
    if (_totalDocuments == 0) return 0;
    return _indexedDocuments / _totalDocuments;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Index Files',
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add folders to index for semantic search',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Add folder button - Material 3 filled button
          FilledButton.icon(
            onPressed: _isIndexing ? null : _pickFolder,
            icon: _isIndexing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded),
            label: Text(_isIndexing ? 'Indexing...' : 'Add Folder'),
          ),

          const SizedBox(height: 24),

          // Progress section - show when indexing or has indexed documents
          if (_isIndexing || _totalDocuments > 0) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isIndexing
                                ? colorScheme.primaryContainer
                                : colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isIndexing ? Icons.sync : Icons.check_circle,
                            color: _isIndexing
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onTertiaryContainer,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isIndexing
                                    ? 'Indexing in progress...'
                                    : 'Indexing complete',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_currentFolder != null)
                                Text(
                                  _currentFolder!,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        // Percentage
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _isIndexing && _totalDocuments == 0
                            ? null
                            : _progress,
                        minHeight: 8,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Total',
                          value: _totalDocuments.toString(),
                          icon: Icons.description_outlined,
                          color: colorScheme.primary,
                        ),
                        _StatItem(
                          label: 'Indexed',
                          value: _indexedDocuments.toString(),
                          icon: Icons.check_circle_outline,
                          color: colorScheme.tertiary,
                        ),
                        _StatItem(
                          label: 'Pending',
                          value: _pendingDocuments.toString(),
                          icon: Icons.pending_outlined,
                          color: colorScheme.secondary,
                        ),
                        if (_failedDocuments > 0)
                          _StatItem(
                            label: 'Failed',
                            value: _failedDocuments.toString(),
                            icon: Icons.error_outline,
                            color: colorScheme.error,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Empty state card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.folder_open_outlined,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No folders indexed yet',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add a folder to start indexing your documents for semantic search.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small stat item for the progress card
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Custom search delegate for Material 3 search
class _SemanticSearchDelegate extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('Enter a search query'));
    }

    // Navigate to search results
    WidgetsBinding.instance.addPostFrameCallback((_) {
      close(context, query);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(query: query),
        ),
      );
    });

    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = [
      'Find all Flutter documentation',
      'What are my recent notes about?',
      'Search for API implementations',
      'Find project configuration files',
    ];

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}
