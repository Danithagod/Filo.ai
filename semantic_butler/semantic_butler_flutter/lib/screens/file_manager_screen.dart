import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../utils/app_logger.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import 'package:path/path.dart' as p;
import '../widgets/file_manager/file_list_item.dart';
import '../widgets/file_manager/file_grid_item.dart';
import '../widgets/file_manager/file_manager_sidebar.dart';
import '../widgets/file_manager/file_manager_toolbar.dart';
import '../widgets/file_manager/summary_dialog.dart';
import 'search_results_screen.dart';
import '../providers/directory_cache_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/local_indexing_provider.dart';

/// Full File Manager screen with breadcrumb navigation and drive listing
class FileManagerScreen extends ConsumerStatefulWidget {
  const FileManagerScreen({super.key});

  @override
  ConsumerState<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends ConsumerState<FileManagerScreen> {
  String _currentPath = '';
  List<FileSystemEntry> _entries = [];
  List<DriveInfo> _drives = [];
  bool _isLoading = false;
  String? _error;
  String? _drivesError; // Separate error state for drives loading
  bool _isGridView = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String? _highlightedPath;

  // ValueNotifier for reactive filtering without full rebuilds
  final ValueNotifier<List<FileSystemEntry>> _filteredEntriesNotifier =
      ValueNotifier<List<FileSystemEntry>>([]);

  @override
  void initState() {
    super.initState();
    _loadDrives();
    _searchController.addListener(_updateFilteredEntries);
  }

  @override
  void dispose() {
    _searchController.removeListener(_updateFilteredEntries);
    _searchController.dispose();
    _filteredEntriesNotifier.dispose();
    super.dispose();
  }

  /// Worker function for filtering entries in an isolate
  static List<FileSystemEntry> _filterEntriesIsolate(
    Map<String, dynamic> args,
  ) {
    final entries = args['entries'] as List<FileSystemEntry>;
    final query = args['query'] as String;

    return entries
        .where(
          (e) =>
              e.name.toLowerCase().contains(query) ||
              e.path.toLowerCase().contains(query),
        )
        .toList();
  }

  // To track active filtering tasks and ignore stale results
  int _searchTaskId = 0;

  /// Update filtered entries based on current search query
  Future<void> _updateFilteredEntries() async {
    if (!mounted) return;

    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      _filteredEntriesNotifier.value = _entries;
      return;
    }

    // For small lists, filter synchronously to avoid isolate overhead
    if (_entries.length < 500) {
      final filtered = _entries
          .where(
            (e) =>
                e.name.toLowerCase().contains(query) ||
                e.path.toLowerCase().contains(query),
          )
          .toList();
      _filteredEntriesNotifier.value = filtered;
      // Record local search history with actual count
      await _recordLocalSearch(query, filtered.length);
      return;
    }

    // For large lists, use background isolate
    final taskId = ++_searchTaskId;
    try {
      final filtered = await compute(_filterEntriesIsolate, {
        'entries': _entries,
        'query': query,
      });

      // Only update if this is still the most recent task
      if (!mounted || taskId != _searchTaskId) return;

      _filteredEntriesNotifier.value = filtered;
      // Record local search history with actual count
      await _recordLocalSearch(query, filtered.length);
    } catch (e) {
      // Fallback to sync on error
      AppLogger.warning('Isolate filtering failed: $e');
      if (!mounted || taskId != _searchTaskId) return;
      final filtered = _entries
          .where(
            (e) =>
                e.name.toLowerCase().contains(query) ||
                e.path.toLowerCase().contains(query),
          )
          .toList();
      _filteredEntriesNotifier.value = filtered;
      // Record local search history with actual count
      await _recordLocalSearch(query, filtered.length);
    }
  }

  /// Record local search to history
  Future<void> _recordLocalSearch(String query, int resultCount) async {
    try {
      final apiClient = ref.read(clientProvider);
      await apiClient.butler.recordLocalSearch(
        query.trim(),
        _currentPath,
        resultCount,
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to record local search: $e',
        tag: 'FileManagerScreen',
      );
      // Don't let this interrupt the user experience
    }
  }

  Future<void> _loadDrives() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _drivesError = null;
    });

    try {
      final apiClient = ref.read(clientProvider);
      final drives = await apiClient.fileSystem.getDrives();
      if (!mounted) return;
      setState(() {
        _drives = drives;
        _drivesError = null;
        if (drives.isNotEmpty && _currentPath.isEmpty) {
          _currentPath = drives.first.path;
          _loadDirectory(_currentPath);
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      AppLogger.error('Failed to load drives: $e', tag: 'FileManager');
      if (!mounted) return;
      setState(() {
        _drivesError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _currentPath = path;
      _error = null;
      // Clear search when navigating to a new directory
      _searchController.clear();
      _isSearching = false;
    });

    try {
      // Use cache to avoid repeated API calls
      final entries = await ref.read(directoryCacheProvider).getDirectory(path);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
      // Update filtered entries after loading
      _updateFilteredEntries();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load directory: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDeepLink(String path) async {
    try {
      final isDir = await Directory(path).exists();
      final isFile = await File(path).exists();

      if (isDir) {
        setState(() {
          _highlightedPath = null;
        });
        _loadDirectory(path);
      } else if (isFile) {
        final parent = p.dirname(path);
        setState(() {
          _highlightedPath = path;
        });
        _loadDirectory(parent);
      } else {
        // Fallback for non-local paths or ambiguous cases
        // If it has an extension, assume it's a file
        if (p.extension(path).isNotEmpty) {
          final parent = p.dirname(path);
          setState(() {
            _highlightedPath = path;
          });
          _loadDirectory(parent);
        } else {
          _loadDirectory(path);
        }
      }
    } catch (e) {
      // On error, just try to load as directory
      _loadDirectory(path);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
  }

  void _navigateBack() {
    if (_currentPath.isEmpty) {
      return;
    }
    final parent = p.dirname(_currentPath);
    if (parent != _currentPath) {
      _loadDirectory(parent);
    }
  }

  /// Show drive selector dialog when clicking root icon
  void _showDriveSelector() {
    if (_drives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No drives available')),
      );
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Platform.isWindows ? Icons.computer : Icons.home_outlined,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(Platform.isWindows ? 'This PC' : 'Select Drive'),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final drive in _drives)
                ListTile(
                  leading: Icon(
                    Icons.dns,
                    color:
                        _currentPath.toLowerCase().startsWith(
                          drive.path.toLowerCase(),
                        )
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(drive.name),
                  subtitle: Text(drive.path),
                  selected: _currentPath.toLowerCase().startsWith(
                    drive.path.toLowerCase(),
                  ),
                  selectedTileColor: colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _loadDirectory(drive.path);
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen<NavigationState>(navigationProvider, (previous, next) {
      if (next.fileTargetPath != null &&
          next.fileTargetPath != previous?.fileTargetPath) {
        _handleDeepLink(next.fileTargetPath!);
        // Consumed the target
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(navigationProvider.notifier).clearFileTarget();
        });
      }
    });

    return Row(
      children: [
        // Floating Sidebar
        Container(
          width: 260,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: FileManagerSidebar(
            drives: _drives,
            currentPath: _currentPath,
            isLoading: _isLoading,
            errorMessage: _drivesError,
            onDriveSelected: _loadDirectory,
            onRetry: _loadDrives,
          ),
        ),

        // Main Explorer
        Expanded(
          child: Column(
            children: [
              // Toolbar
              FileManagerToolbar(
                isSearching: _isSearching,
                isGridView: _isGridView,
                currentPath: _currentPath,
                searchController: _searchController,
                onNavigateBack: _navigateBack,
                onRefresh: () => _loadDirectory(_currentPath),
                onToggleSearch: () => setState(() => _isSearching = true),
                onExitSearch: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                },
                onViewModeChanged: (isGrid) =>
                    setState(() => _isGridView = isGrid),
                onPathSelected: _loadDirectory,
                onRootTap: _showDriveSelector,
                onSearchChanged: (_) => _updateFilteredEntries(),
              ),

              const Divider(height: 1),

              // File List/Grid
              Expanded(
                child: _buildMainContent(colorScheme, textTheme),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoading && _entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning file system...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _loadDirectory(_currentPath),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Use ValueListenableBuilder to avoid full rebuilds on search
    return ValueListenableBuilder<List<FileSystemEntry>>(
      valueListenable: _filteredEntriesNotifier,
      builder: (context, displayEntries, _) {
        return _buildFileList(displayEntries, colorScheme, textTheme);
      },
    );
  }

  Widget _buildFileList(
    List<FileSystemEntry> displayEntries,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (displayEntries.isEmpty) {
      final isSearching = _searchController.text.isNotEmpty;
      return Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: 1.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSearching
                      ? Icons.search_off_rounded
                      : Icons.folder_open_rounded,
                  size: 80,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isSearching
                    ? 'No matching files found'
                    : 'This folder is empty',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSearching
                    ? 'Try adjusting your search terms'
                    : 'Drag and drop files here to add them to this folder',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (isSearching) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('Clear Search'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Stack(
        key: ValueKey(_isGridView),
        children: [
          _isGridView
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: displayEntries.length,
                  itemBuilder: (context, index) {
                    final entry = displayEntries[index];
                    return FileGridItem(
                      entry: entry,
                      isHighlighted: _highlightedPath == entry.path,
                      onTap: () {
                        if (entry.isDirectory) {
                          setState(() => _highlightedPath = null);
                          _loadDirectory(entry.path);
                          _searchController.clear();
                          _isSearching = false;
                        }
                      },
                      onContextMenu: () => _showContextMenu(context, entry),
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: displayEntries.length,
                  itemBuilder: (context, index) {
                    final entry = displayEntries[index];
                    return FileListItem(
                      entry: entry,
                      isHighlighted: _highlightedPath == entry.path,
                      onTap: () {
                        if (entry.isDirectory) {
                          setState(() => _highlightedPath = null);
                          _loadDirectory(entry.path);
                          _searchController.clear();
                          _isSearching = false;
                        }
                      },
                      onContextMenu: () => _showContextMenu(context, entry),
                    );
                  },
                ),
          if (_isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, FileSystemEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    entry.isDirectory ? Icons.folder : Icons.insert_drive_file,
                    color: entry.isDirectory
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // AI Actions Section
            if (!entry.isDirectory) ...[
              ListTile(
                leading: Icon(Icons.auto_awesome, color: colorScheme.tertiary),
                title: const Text('Ask Assistant'),
                onTap: () {
                  Navigator.pop(context);
                  _openChatWithContext(entry);
                },
              ),
              ListTile(
                leading: const Icon(Icons.summarize_outlined),
                title: const Text('Summarize'),
                onTap: () {
                  Navigator.pop(context);
                  _summarizeFile(entry);
                },
              ),
              ListTile(
                leading: const Icon(Icons.find_in_page_outlined),
                title: const Text('Search Similar'),
                onTap: () {
                  Navigator.pop(context);
                  _searchSimilar(entry);
                },
              ),
            ],

            // Indexing Action
            ListTile(
              leading: Icon(
                entry.isIndexed ? Icons.sync_disabled : Icons.sync,
                color: entry.isIndexed
                    ? colorScheme.error
                    : colorScheme.primary,
              ),
              title: Text(
                entry.isIndexed ? 'Remove from Index' : 'Add to Index',
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleIndex(entry);
              },
            ),

            const Divider(height: 1),

            // Standard Operations
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(entry);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text('Delete', style: TextStyle(color: colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _searchSimilar(FileSystemEntry entry) {
    // Navigate to Search with filename as initial query
    // This effectively performs a semantic search for files like this one
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          query: entry.name,
        ),
      ),
    );
  }

  void _openChatWithContext(FileSystemEntry entry) {
    // Navigate to Chat tab with file context
    ref
        .read(navigationProvider.notifier)
        .navigateToChatWithContext(
          ChatNavigationContext(
            filePath: entry.path,
            fileName: entry.name,
            initialMessage: 'Tell me about this file: ${entry.name}',
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening AI chat for: ${entry.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _summarizeFile(FileSystemEntry entry) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating summary...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Call the summarization endpoint
      final apiClient = ref.read(clientProvider);
      final summaryJson = await apiClient.butler.summarizeFile(entry.path);

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show summary dialog
      showDialog(
        context: context,
        builder: (dialogContext) => SummaryDialog(
          fileName: entry.name,
          summaryJson: summaryJson,
          onAskAssistant: () => _openChatWithContext(entry),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to summarize file: $e', tag: 'FileManager');

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to summarize: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _toggleIndex(FileSystemEntry entry) async {
    try {
      final apiClient = ref.read(clientProvider);
      if (entry.isIndexed) {
        await apiClient.butler.removeFromIndex(path: entry.path);
      } else {
        // HYBRID ARCHITECTURE: Client-side indexing
        if (entry.isDirectory) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Indexing folder in background...')),
          );
          // Run in background to avoid blocking UI
          // ignore: unused_result
          ref
              .read(localIndexingServiceProvider)
              .indexDirectory(entry.path)
              .then((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Indexing completed: ${entry.name}'),
                    ),
                  );
                  ref.read(directoryCacheProvider).invalidate(_currentPath);
                  _loadDirectory(_currentPath);
                }
              })
              .catchError((e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Indexing failed: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
                return null; // Return to void
              });
          return; // Return immediately, don't wait for refresh here
        } else {
          // Single file - can await comfortably
          await ref.read(localIndexingServiceProvider).indexFile(entry.path);
        }
      }
      // Invalidate cache to show updated index status
      ref.read(directoryCacheProvider).invalidate(_currentPath);
      _loadDirectory(_currentPath);
    } catch (e) {
      AppLogger.error('Failed to toggle index: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update indexing: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showRenameDialog(FileSystemEntry entry) async {
    final controller = TextEditingController(text: entry.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New name',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
          enableInteractiveSelection: true,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result != entry.name && mounted) {
      // Validate filename characters
      final invalidChars = RegExp(r'[<>:"/\\|?*]');
      if (invalidChars.hasMatch(result)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid filename: contains restricted characters (< > : " / \\ | ? *)',
            ),
          ),
        );
        return;
      }

      try {
        final apiClient = ref.read(clientProvider);
        await apiClient.fileSystem.rename(
          entry.path,
          result,
          entry.isDirectory,
        );
        // Invalidate cache after file operation
        ref.read(directoryCacheProvider).invalidate(_currentPath);
        _loadDirectory(_currentPath);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Rename failed: $e')));
        }
      }
    }
  }

  /// Get the app-specific trash directory path
  Future<String> _getTrashPath() async {
    if (Platform.isWindows) {
      // Use a hidden folder in user's AppData
      final appData = Platform.environment['APPDATA'] ?? '';
      return p.join(appData, 'SemanticButler', '.trash');
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      return p.join(home, '.Trash', 'SemanticButler');
    }
    // Linux and others
    final home = Platform.environment['HOME'] ?? '';
    return p.join(home, '.local', 'share', 'SemanticButler', 'trash');
  }

  /// Move file to trash with undo capability
  Future<void> _confirmDelete(FileSystemEntry entry) async {
    final colorScheme = Theme.of(context).colorScheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 48),
        title: const Text('Move to Trash?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    entry.isDirectory ? Icons.folder : Icons.insert_drive_file,
                    color: entry.isDirectory
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You can undo this action for a short time after deletion.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    try {
      // Get trash path and ensure it exists
      final trashPath = await _getTrashPath();
      final trashDir = Directory(trashPath);
      if (!await trashDir.exists()) {
        await trashDir.create(recursive: true);
      }

      // Generate unique trash filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final trashEntryName = '${timestamp}_${entry.name}';
      final trashEntryPath = p.join(trashPath, trashEntryName);
      final originalPath = entry.path;

      // Move file to trash using server API
      final apiClient = ref.read(clientProvider);
      await apiClient.fileSystem.move(entry.path, trashEntryPath);

      // Invalidate cache and refresh
      ref.read(directoryCacheProvider).invalidate(_currentPath);
      await _loadDirectory(_currentPath);

      if (!mounted) return;

      // Show undo SnackBar
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: colorScheme.onInverseSurface,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Deleted "${entry.name}"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: colorScheme.inversePrimary,
            onPressed: () async {
              try {
                // Restore from trash
                final apiClient = ref.read(clientProvider);
                await apiClient.fileSystem.move(trashEntryPath, originalPath);
                ref.read(directoryCacheProvider).invalidate(_currentPath);
                await _loadDirectory(_currentPath);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Restored "${entry.name}"'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                AppLogger.error(
                  'Failed to restore file: $e',
                  tag: 'FileManager',
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to restore: $e'),
                    backgroundColor: colorScheme.error,
                  ),
                );
              }
            },
          ),
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to delete file: $e', tag: 'FileManager');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }
}
