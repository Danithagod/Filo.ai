import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../main.dart';
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

/// Indexing screen with Material 3 styling
class IndexingScreen extends StatelessWidget {
  const IndexingScreen({super.key});

  Future<void> _pickFolder(BuildContext context) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null && context.mounted) {
        // Start indexing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting to index: $selectedDirectory'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {},
            ),
          ),
        );

        // Call the server to start indexing
        await client.butler.startIndexing(selectedDirectory);
      }
    } catch (e) {
      if (context.mounted) {
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

    return Padding(
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
            onPressed: () => _pickFolder(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Folder'),
          ),

          const SizedBox(height: 24),

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
