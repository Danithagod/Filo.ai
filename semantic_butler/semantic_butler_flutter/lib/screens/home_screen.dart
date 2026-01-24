import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';
import '../utils/app_logger.dart';
import '../widgets/search/advanced_search_bar.dart';
import '../widgets/search/advanced_filters.dart';

import '../widgets/recent_searches.dart';
import '../widgets/app_background.dart';
import 'search_results_screen.dart';
import 'settings_screen.dart';
import 'chat_screen.dart';
import 'file_manager_screen.dart';
import 'organization_screen.dart';
import '../widgets/home/stats_card.dart';
import '../widgets/home/fade_in_animation.dart';
import '../widgets/home/compact_index_card.dart';
import '../widgets/home/tag_manager_dialog.dart';
import '../widgets/home/ai_cost_dashboard.dart';
import '../widgets/home/index_health_dashboard.dart';
import '../providers/indexing_status_provider.dart';
import '../providers/navigation_provider.dart';

/// Home screen with Material 3 navigation rail
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final navState = ref.watch(navigationProvider);

    return Scaffold(
      body: Row(
        children: [
          // Material 3 Navigation Rail
          NavigationRail(
            selectedIndex: navState.selectedIndex,
            onDestinationSelected: (index) {
              ref.read(navigationProvider.notifier).navigateTo(index);
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
                icon: Tooltip(
                  message: 'Home (Ctrl+1 / Cmd+1)',
                  child: Icon(Icons.home_outlined),
                ),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Tooltip(
                  message: 'Index (Ctrl+2 / Cmd+2)',
                  child: Icon(Icons.folder_outlined),
                ),
                selectedIcon: Icon(Icons.folder),
                label: Text('Index'),
              ),
              NavigationRailDestination(
                icon: Tooltip(
                  message: 'Chat (Ctrl+3 / Cmd+3)',
                  child: Icon(Icons.chat_bubble_outline),
                ),
                selectedIcon: Icon(Icons.chat_bubble),
                label: Text('Chat'),
              ),
              NavigationRailDestination(
                icon: Tooltip(
                  message: 'Files (Ctrl+4 / Cmd+4)',
                  child: Icon(Icons.folder_shared_outlined),
                ),
                selectedIcon: Icon(Icons.folder_shared),
                label: Text('Files'),
              ),
              NavigationRailDestination(
                icon: Tooltip(
                  message: 'Organization (Ctrl+5 / Cmd+5)',
                  child: Icon(Icons.auto_fix_high_outlined),
                ),
                selectedIcon: Icon(Icons.auto_fix_high),
                label: Text('Organization'),
              ),
              NavigationRailDestination(
                icon: Tooltip(
                  message: 'Settings (Ctrl+6 / Cmd+6)',
                  child: Icon(Icons.settings_outlined),
                ),
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
    );
  }

  // PageStorage bucket for preserving scroll positions across tab switches
  final PageStorageBucket _bucket = PageStorageBucket();

  Widget _buildContent() {
    final navState = ref.watch(navigationProvider);

    // Using PageStorage + conditional building for better memory usage
    // Only the visible screen is built, with selective state preservation
    return PageStorage(
      bucket: _bucket,
      child: _buildScreen(navState.selectedIndex),
    );
  }

  Widget _buildScreen(int index) {
    // Build only the visible screen
    // Screens not in _keepAliveScreens will be rebuilt when navigated to
    switch (index) {
      case 0:
        return const SearchDashboard(key: PageStorageKey('search_dashboard'));
      case 1:
        return const IndexingScreen(key: PageStorageKey('indexing_screen'));
      case 2:
        return const ChatScreen(key: PageStorageKey('chat_screen'));
      case 3:
        return const FileManagerScreen(key: PageStorageKey('file_manager'));
      case 4:
        return const OrganizationScreen(
          key: PageStorageKey('organization_screen'),
        );
      case 5:
        return const SettingsScreen(key: PageStorageKey('settings_screen'));
      default:
        return const SearchDashboard(key: PageStorageKey('search_dashboard'));
    }
  }

  void _showQuickSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _SemanticSearchDelegate(ref),
    );
  }
}

/// Search dashboard - main view with Material 3 styling
class SearchDashboard extends ConsumerStatefulWidget {
  const SearchDashboard({super.key});

  @override
  ConsumerState<SearchDashboard> createState() => _SearchDashboardState();
}

class _SearchDashboardState extends ConsumerState<SearchDashboard>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  SearchFilters _searchFilters = SearchFilters();
  DateTime? _lastRefreshTime;
  static const _refreshCooldown = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _scheduleRefreshIfNeeded();
    }
  }

  /// Check if current navigation state shows this dashboard
  bool get _isVisible {
    final navState = ref.read(navigationProvider);
    return navState.selectedIndex == 0;
  }

  /// Refresh dashboard data if enough time has passed
  void _scheduleRefreshIfNeeded() {
    if (!_isVisible) return;

    final now = DateTime.now();
    if (_lastRefreshTime == null ||
        now.difference(_lastRefreshTime!) > _refreshCooldown) {
      _refreshDashboard();
    }
  }

  /// Refresh all dashboard data
  Future<void> _refreshDashboard() async {
    _lastRefreshTime = DateTime.now();

    // Refresh indexing status
    ref.read(indexingStatusProvider.notifier).refresh();

    // Note: RecentSearches widget handles its own refresh internally
    // The key forces a rebuild which triggers a fresh load
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          query: query,
          initialMode: SearchMode.hybrid,
          initialFilters: _searchFilters,
        ),
      ),
    );
  }

  void _performAISearch(String query) {
    if (query.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          query: query,
          initialMode: SearchMode.ai,
          // AI Search doesn't support filters yet in this implementation
        ),
      ),
    );
  }

  void _showTagManager(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TagManagerDialog(),
    );
  }

  void _showCostDashboard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AICostDashboard(),
    );
  }

  void _showIndexHealth(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const IndexHealthDashboard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(indexingStatusProvider).value;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header with modern look
              const FadeInAnimation(
                delay: Duration(milliseconds: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.1,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Semantic Butler',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FadeInAnimation(
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
              FadeInAnimation(
                delay: const Duration(milliseconds: 300),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: AdvancedSearchBar(
                    controller: _searchController,
                    onSearch: _performSearch,
                    onAISearch: _performAISearch,
                    hintText: 'Search your files using natural language',
                    trailing: [
                      AdvancedFilters(
                        initialFilters: _searchFilters,
                        onFiltersChanged: (filters) {
                          setState(() {
                            _searchFilters = filters;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Stats section
              FadeInAnimation(
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
                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 300,
                            maxWidth: 800,
                          ),
                          child: StatsCard(
                            title: 'Documents',
                            numericValue: (status?.totalDocuments ?? 0)
                                .toDouble(),
                            icon: Icons.description_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 300,
                            maxWidth: 800,
                          ),
                          child: StatsCard(
                            title: 'Indexed',
                            numericValue:
                                status != null && status.totalDocuments > 0
                                ? (status.indexedDocuments /
                                      status.totalDocuments *
                                      100)
                                : 0,
                            suffix: '%',
                            progress:
                                status != null && status.totalDocuments > 0
                                ? (status.indexedDocuments /
                                      status.totalDocuments)
                                : 0,
                            icon: Icons.check_circle_rounded,
                            color: colorScheme.tertiary,
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 300,
                            maxWidth: 800,
                          ),
                          child: StatsCard(
                            title: 'Activity',
                            numericValue: (status?.activeJobs ?? 0).toDouble(),
                            suffix: status != null && status.activeJobs > 0
                                ? ' Active'
                                : ' Jobs',
                            isPulse: status != null && status.activeJobs > 0,
                            icon: Icons.trending_up_rounded,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Quick actions section
              FadeInAnimation(
                delay: const Duration(milliseconds: 450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Quick actions',
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
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showTagManager(context),
                          icon: const Icon(Icons.label_outline, size: 20),
                          label: const Text('Manage Tags'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showCostDashboard(context),
                          icon: const Icon(Icons.analytics_outlined, size: 20),
                          label: const Text('Cost Dashboard'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showIndexHealth(context),
                          icon: const Icon(Icons.health_and_safety, size: 20),
                          label: const Text('Index Health'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Recent searches section
              FadeInAnimation(
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

/// Indexing screen with Material 3 styling and real-time progress
class IndexingScreen extends ConsumerStatefulWidget {
  const IndexingScreen({super.key});

  @override
  ConsumerState<IndexingScreen> createState() => _IndexingScreenState();
}

class _IndexingScreenState extends ConsumerState<IndexingScreen> {
  bool _isStatusLoading = false;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    // Use provider for initial load
    Future.microtask(() => ref.read(indexingStatusProvider.notifier).refresh());
  }

  Future<void> _loadIndexingStatus() async {
    setState(() => _isStatusLoading = true);
    await ref.read(indexingStatusProvider.notifier).refresh();
    if (mounted) setState(() => _isStatusLoading = false);
  }

  Future<void> _pickFolder() async {
    AppLogger.info('Opening folder picker...', tag: 'Indexing');
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null && mounted) {
        AppLogger.info('Selected folder: $selectedDirectory', tag: 'Indexing');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting to index: $selectedDirectory'),
            duration: const Duration(seconds: 2),
          ),
        );

        // Call the server to start indexing
        AppLogger.info('Calling startIndexing API...', tag: 'Indexing');
        final apiClient = ref.read(clientProvider);
        await apiClient.butler.startIndexing(selectedDirectory);
        AppLogger.info('startIndexing API call completed', tag: 'Indexing');

        // Refresh global provider immediately
        ref.read(indexingStatusProvider.notifier).refresh();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(indexingStatusProvider).value;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final recentJobs = status?.recentJobs ?? [];
    final isIndexing = (status?.activeJobs ?? 0) > 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
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
              const SizedBox(height: 48),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    label: 'TOTAL DOCUMENTS',
                    numericValue: (status?.totalDocuments ?? 0).toDouble(),
                    icon: Icons.description_outlined,
                    color: colorScheme.primary,
                  ),
                  _StatCard(
                    label: 'INDEXED',
                    numericValue: (status?.indexedDocuments ?? 0).toDouble(),
                    icon: Icons.check_circle_outline,
                    color: colorScheme.tertiary,
                  ),
                  _StatCard(
                    label: 'PENDING',
                    numericValue: (status?.pendingDocuments ?? 0).toDouble(),
                    icon: Icons.pending_outlined,
                    color: colorScheme.secondary,
                  ),
                  if ((status?.failedDocuments ?? 0) > 0)
                    _StatCard(
                      label: 'FAILED',
                      numericValue: (status?.failedDocuments ?? 0).toDouble(),
                      icon: Icons.error_outline,
                      color: colorScheme.error,
                    ),
                ],
              ),

              const SizedBox(height: 32),

              // Add Folder Action
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 200),
                  child: FilledButton.icon(
                    onPressed: isIndexing ? null : _pickFolder,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                    ),
                    icon: (status?.activeJobs ?? 0) > 0
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.create_new_folder_outlined),
                    label: Text(
                      (status?.activeJobs ?? 0) > 0
                          ? 'Indexing in Progress...'
                          : 'Index New Folder',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Recent Jobs Section Header
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Indexed Folders',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${recentJobs.length}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // View Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.grid_view_rounded, size: 18),
                          onPressed: () => setState(() => _isGridView = true),
                          color: _isGridView
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          style: IconButton.styleFrom(
                            backgroundColor: _isGridView
                                ? colorScheme.primaryContainer.withValues(
                                    alpha: 0.6,
                                  )
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.view_list_rounded, size: 18),
                          onPressed: () => setState(() => _isGridView = false),
                          color: !_isGridView
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          style: IconButton.styleFrom(
                            backgroundColor: !_isGridView
                                ? colorScheme.primaryContainer.withValues(
                                    alpha: 0.6,
                                  )
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (recentJobs.isNotEmpty)
                    TextButton.icon(
                      onPressed:
                          ((status?.activeJobs ?? 0) > 0 || _isStatusLoading)
                          ? null
                          : _loadIndexingStatus,
                      icon: _isStatusLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                strokeCap: StrokeCap.round,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(_isStatusLoading ? '' : 'Refresh'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isStatusLoading && recentJobs.isEmpty)
                if (_isGridView)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: 8,
                    itemBuilder: (context, index) => CompactIndexCard.skeleton(
                      isListView: false,
                    ),
                  )
                else
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: 8,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) => CompactIndexCard.skeleton(
                      isListView: true,
                    ),
                  )
              else if (recentJobs.isEmpty)
                _buildEmptyState(colorScheme, textTheme)
              else if (_isGridView)
                Stack(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 180,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: recentJobs.length,
                      itemBuilder: (context, index) {
                        final job = recentJobs[index];
                        return CompactIndexCard(
                          job: job,
                          onRefresh: _loadIndexingStatus,
                          isListView: false,
                        );
                      },
                    ),
                    if (_isStatusLoading)
                      Positioned.fill(
                        child: Container(
                          color: colorScheme.surface.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                )
              else
                Stack(
                  children: [
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: recentJobs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final job = recentJobs[index];
                        return CompactIndexCard(
                          job: job,
                          onRefresh: _loadIndexingStatus,
                          isListView: true,
                        );
                      },
                    ),
                    if (_isStatusLoading)
                      Positioned.fill(
                        child: Container(
                          color: colorScheme.surface.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),

              // Bottom spacer
              const SizedBox(height: 48),
            ],
          ),
        ),
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

/// Styled stat card for indexing progress with counter animation
class _StatCard extends StatelessWidget {
  final String label;
  final double numericValue;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.numericValue,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: numericValue),
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                value.toInt().toString(),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              );
            },
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

/// Custom search delegate for Material 3 search with dynamic suggestions
class _SemanticSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  _SemanticSearchDelegate(this.ref);

  // Cache for search history
  List<SearchHistory>? _searchHistoryCache;
  bool _isLoadingHistory = false;

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
      if (!context.mounted) return;
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<List<SearchHistory>>(
      future: _loadSearchHistory(),
      builder: (context, snapshot) {
        // Default suggestions for when we're loading or have no history
        final defaultSuggestions = [
          'Find all documentation',
          'Search for API implementations',
          'Find configuration files',
          'Recent notes and files',
        ];

        // Filter suggestions based on current query
        final historyItems = snapshot.data ?? [];
        final historySuggestions = historyItems
            .where(
              (h) =>
                  h.query.isNotEmpty &&
                  (query.isEmpty ||
                      h.query.toLowerCase().contains(query.toLowerCase())),
            )
            .take(5)
            .toList();

        final filteredDefaults = defaultSuggestions
            .where(
              (s) =>
                  query.isEmpty ||
                  s.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

        return ListView(
          children: [
            // Recent searches section
            if (historySuggestions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Recent Searches',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...historySuggestions.map(
                (history) => ListTile(
                  leading: Icon(Icons.history, color: colorScheme.primary),
                  title: Text(history.query),
                  subtitle: Text(
                    '${history.resultCount} results',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.north_west,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    query = history.query;
                    showResults(context);
                  },
                ),
              ),
              const Divider(),
            ],

            // Suggested searches section
            if (filteredDefaults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Suggested Searches',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...filteredDefaults.map(
                (suggestion) => ListTile(
                  leading: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: Text(suggestion),
                  onTap: () {
                    query = suggestion;
                    showResults(context);
                  },
                ),
              ),
            ],

            // Show loading indicator if still loading
            if (snapshot.connectionState == ConnectionState.waiting &&
                historySuggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }

  /// Load search history from server with caching
  Future<List<SearchHistory>> _loadSearchHistory() async {
    // Return cached results if available
    if (_searchHistoryCache != null) {
      return _searchHistoryCache!;
    }

    // Prevent duplicate loading
    if (_isLoadingHistory) {
      return [];
    }

    _isLoadingHistory = true;
    try {
      final apiClient = ref.read(clientProvider);
      final history = await apiClient.butler.getSearchHistory(
        limit: 10,
        offset: 0,
      );
      _searchHistoryCache = history;
      return history;
    } catch (e) {
      AppLogger.warning('Failed to load search history: $e');
      return [];
    } finally {
      _isLoadingHistory = false;
    }
  }
}
