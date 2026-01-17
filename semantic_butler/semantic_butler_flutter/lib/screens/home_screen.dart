import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';
import '../utils/app_logger.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/recent_searches.dart';
import '../widgets/app_background.dart';
import 'search_results_screen.dart';
import 'settings_screen.dart';
import 'chat_screen.dart';
import 'file_manager_screen.dart';
import '../providers/watched_folders_provider.dart';

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
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: Text('Chat'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_shared_outlined),
                  selectedIcon: Icon(Icons.folder_shared),
                  label: Text('Files'),
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
              child: AppBackground(
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Using IndexedStack to preserve state when switching tabs
    return IndexedStack(
      index: _selectedIndex,
      children: [
        SearchDashboard(),
        IndexingScreen(),
        ChatScreen(),
        FileManagerScreen(),
        SettingsScreen(),
      ],
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header with modern look
              const _FadeInUp(
                delay: Duration(milliseconds: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Semantic Butler',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Search your files using natural language',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Enhanced Search bar
              _FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SearchBarWidget(
                    controller: _searchController,
                    onSearch: _performSearch,
                    hintText: 'Ask anything about your files...',
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Stats section
              _FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Overview',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Divider(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _ModernStatsCard(
                            title: 'Documents',
                            value: '1,248',
                            icon: Icons.description_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _ModernStatsCard(
                            title: 'Indexed',
                            value: '85%',
                            icon: Icons.offline_bolt_rounded,
                            color: colorScheme.tertiary,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _ModernStatsCard(
                            title: 'Activity',
                            value: 'High',
                            icon: Icons.trending_up_rounded,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Recent searches section
              _FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Recent activity',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Divider(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    RecentSearches(
                      onSearchTap: _performSearch,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ModernStatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeInUp({required this.child, this.delay = Duration.zero});

  @override
  State<_FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<_FadeInUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _offsetAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCirc,
          ),
        );

    _opacityAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
          ),
        );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: widget.child,
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
  List<IndexingJob> _recentJobs = [];

  /// Timer for polling indexing status - cancellable to prevent memory leaks
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadIndexingStatus();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  /// Stop the polling timer
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
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
          _recentJobs = status.recentJobs ?? [];
          _isIndexing = status.activeJobs > 0;
        });

        // If indexing is active, start polling for updates
        if (_isIndexing) {
          _startPolling();
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

  /// Start polling for indexing status updates using a cancellable Timer
  void _startPolling() {
    // Cancel any existing timer first
    _stopPolling();

    // Use Timer.periodic for cancellable polling
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      // Safety check: stop polling if widget is disposed
      if (!mounted) {
        _stopPolling();
        return;
      }

      try {
        final status = await client.butler.getIndexingStatus();
        if (mounted) {
          setState(() {
            _totalDocuments = status.totalDocuments;
            _indexedDocuments = status.indexedDocuments;
            _pendingDocuments = status.pendingDocuments;
            _failedDocuments = status.failedDocuments;
            _recentJobs = status.recentJobs ?? [];
            _isIndexing = status.activeJobs > 0;
          });

          // Stop polling if indexing completed
          if (!_isIndexing) {
            _stopPolling();
          }
        }
      } catch (e) {
        // Continue polling even on error, but log it
        AppLogger.warning('Polling error: $e', tag: 'Indexing');
      }
    });
  }

  Future<void> _pickFolder() async {
    AppLogger.info('Opening folder picker...', tag: 'Indexing');
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null && mounted) {
        AppLogger.info('Selected folder: $selectedDirectory', tag: 'Indexing');
        setState(() {
          _isIndexing = true;
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
        _startPolling();
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

          // Summary Stats Row (Compact)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatCard(
                  label: 'TOTAL',
                  value: _totalDocuments.toString(),
                  icon: Icons.description_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'INDEXED',
                  value: _indexedDocuments.toString(),
                  icon: Icons.check_circle_outline,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'PENDING',
                  value: _pendingDocuments.toString(),
                  icon: Icons.pending_outlined,
                  color: colorScheme.secondary,
                ),
                if (_failedDocuments > 0) ...[
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'FAILED',
                    value: _failedDocuments.toString(),
                    icon: Icons.error_outline,
                    color: colorScheme.error,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Add Folder Action
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isIndexing ? null : _pickFolder,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: _isIndexing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.create_new_folder_outlined),
              label: Text(
                _isIndexing ? 'Indexing in Progress...' : 'Index New Folder',
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Recent Jobs Section
          Text(
            'Indexed Folders',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (_recentJobs.isEmpty)
            _buildEmptyState(colorScheme, textTheme)
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _recentJobs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final job = _recentJobs[index];
                return _IndexingJobCard(job: job);
              },
            ),

          // Bottom spacer
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No folders indexed yet',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 300,
            child: Text(
              'Add a folder to start indexing your documents for semantic search',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Styled stat card for indexing progress
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
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

class _IndexingJobCard extends ConsumerStatefulWidget {
  final IndexingJob job;

  const _IndexingJobCard({required this.job});

  @override
  ConsumerState<_IndexingJobCard> createState() => _IndexingJobCardState();
}

class _IndexingJobCardState extends ConsumerState<_IndexingJobCard> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final job = widget.job;

    final watchedFolders = ref.watch(watchedFoldersProvider);
    final isSmartIndexing = watchedFolders.any(
      (f) => f.path == job.folderPath && f.isEnabled,
    );

    final isRunning = job.status == 'running';
    final isFailed = job.status == 'failed';

    // Calculate progress
    double progress = 0.0;
    if (job.totalFiles > 0) {
      progress =
          (job.processedFiles + job.failedFiles + job.skippedFiles) /
          job.totalFiles;
      if (progress > 1.0) progress = 1.0;
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isRunning
                        ? colorScheme.primaryContainer
                        : isFailed
                        ? colorScheme.errorContainer
                        : colorScheme.tertiaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRunning
                        ? Icons.sync
                        : isFailed
                        ? Icons.error_outline
                        : Icons.check,
                    size: 20,
                    color: isRunning
                        ? colorScheme.onPrimaryContainer
                        : isFailed
                        ? colorScheme.onErrorContainer
                        : colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.folderPath.split(Platform.pathSeparator).last,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        job.folderPath,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    job.status.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (isRunning || progress > 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${job.processedFiles}/${job.totalFiles} files',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                borderRadius: BorderRadius.circular(4),
              ),
            ],

            if (isFailed && job.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                job.errorMessage!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Smart Indexing Toggle
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isSmartIndexing
                      ? Icons.visibility_rounded
                      : Icons.visibility_outlined,
                  size: 18,
                  color: isSmartIndexing
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSmartIndexing ? 'Smart Indexing On' : 'Smart Indexing',
                    style: textTheme.bodyMedium?.copyWith(
                      color: isSmartIndexing
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isSmartIndexing ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                _isToggling
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Switch.adaptive(
                        value: isSmartIndexing,
                        onChanged: (value) =>
                            _toggleSmartIndexing(job.folderPath),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSmartIndexing(String folderPath) async {
    setState(() => _isToggling = true);
    try {
      await ref.read(watchedFoldersProvider.notifier).toggle(folderPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle smart indexing: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }
}
