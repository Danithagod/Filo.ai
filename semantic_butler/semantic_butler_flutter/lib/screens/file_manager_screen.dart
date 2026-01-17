import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../utils/app_logger.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import 'package:path/path.dart' as p;

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
  bool _isGridView = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Filtered entries based on search
  List<FileSystemEntry> get _filteredEntries {
    if (_searchController.text.isEmpty) {
      return _entries;
    }
    return _entries
        .where(
          (e) => e.name.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadDrives();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDrives() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final drives = await client.fileSystem.getDrives();
      setState(() {
        _drives = drives;
        if (drives.isNotEmpty && _currentPath.isEmpty) {
          _currentPath = drives.first.path;
          _loadDirectory(_currentPath);
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load drives: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _currentPath = path;
      _error = null;
    });

    try {
      final entries = await client.fileSystem.listDirectory(path);
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load directory: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Floating Sidebar
        Container(
          width: 260,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildSidebar(
            Theme.of(context).colorScheme,
            Theme.of(context).textTheme,
          ),
        ),

        // Main Explorer
        Expanded(
          child: Column(
            children: [
              // Toolbar
              _buildToolbar(
                Theme.of(context).colorScheme,
                Theme.of(context).textTheme,
              ),

              const Divider(height: 1),

              // File List/Grid
              Expanded(
                child: _buildMainContent(
                  Theme.of(context).colorScheme,
                  Theme.of(context).textTheme,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              Icon(Icons.storage, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Drives',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _drives.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final drive = _drives[index];
              final isSelected = _currentPath.startsWith(drive.path);

              return Material(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _loadDirectory(drive.path),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.dns, // Drive icon
                          size: 20,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            drive.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: colorScheme.onPrimaryContainer,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText:
                      'Search in ${_currentPath.split(Platform.pathSeparator).last}...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                keyboardType: TextInputType.text,
                enableInteractiveSelection: true,
                autocorrect: false,
                enableSuggestions: true,
                textInputAction: TextInputAction.search,
              ),
            ),
          ] else ...[
            IconButton.filledTonal(
              icon: const Icon(Icons.arrow_back),
              onPressed: _navigateBack,
              tooltip: 'Back',
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadDirectory(_currentPath),
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 16),

            // Breadcrumbs
            Expanded(
              child: _buildBreadcrumbs(colorScheme, textTheme),
            ),

            const SizedBox(width: 16),

            // View Toggle
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.list),
                  isSelected: !_isGridView,
                  onPressed: () => setState(() => _isGridView = false),
                  tooltip: 'List View',
                  color: !_isGridView ? colorScheme.primary : null,
                ),
                IconButton(
                  icon: const Icon(Icons.grid_view),
                  isSelected: _isGridView,
                  onPressed: () => setState(() => _isGridView = true),
                  tooltip: 'Grid View',
                  color: _isGridView ? colorScheme.primary : null,
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Search Tool
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
              tooltip: 'Search Local',
              isSelected: _isSearching,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(ColorScheme colorScheme, TextTheme textTheme) {
    final List<String> parts = p
        .split(_currentPath)
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0)
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              InkWell(
                onTap: () {
                  final targetPath = p.joinAll(parts.take(i + 1));
                  final finalPath =
                      Platform.isWindows && !targetPath.contains('\\')
                      ? '$targetPath\\'
                      : targetPath;
                  _loadDirectory(finalPath);
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    parts[i],
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: i == parts.length - 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: i == parts.length - 1
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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

    final displayEntries = _filteredEntries;

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
                    return _FileGridItem(
                      entry: entry,
                      onTap: () {
                        if (entry.isDirectory) {
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
                    return _FileListItem(
                      entry: entry,
                      onTap: () {
                        if (entry.isDirectory) {
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

  void _openChatWithContext(FileSystemEntry entry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting AI chat about: ${entry.name}')),
    );
  }

  Future<void> _summarizeFile(FileSystemEntry entry) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Summarizing ${entry.name}...')),
    );
  }

  Future<void> _toggleIndex(FileSystemEntry entry) async {
    try {
      if (entry.isIndexed) {
        await client.butler.removeFromIndex(path: entry.path);
      } else {
        await client.butler.startIndexing(entry.path);
      }
      _loadDirectory(_currentPath);
    } catch (e) {
      AppLogger.error('Failed to toggle index: $e');
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
      try {
        await client.fileSystem.rename(entry.path, result, entry.isDirectory);
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

  Future<void> _confirmDelete(FileSystemEntry entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${entry.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await client.fileSystem.delete(entry.path);
        _loadDirectory(_currentPath);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }
}

class _FileListItem extends StatefulWidget {
  final FileSystemEntry entry;
  final VoidCallback onTap;
  final VoidCallback onContextMenu;

  const _FileListItem({
    required this.entry,
    required this.onTap,
    required this.onContextMenu,
  });

  @override
  State<_FileListItem> createState() => _FileListItemState();
}

class _FileListItemState extends State<_FileListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onSecondaryTap: widget.onContextMenu,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _isHovered
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? colorScheme.outlineVariant.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.entry.isDirectory
                            ? [
                                colorScheme.primaryContainer,
                                colorScheme.primaryContainer.withValues(
                                  alpha: 0.7,
                                ),
                              ]
                            : [
                                colorScheme.surfaceContainerHigh,
                                colorScheme.surfaceContainerHighest,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: colorScheme.shadow.withValues(
                                  alpha: 0.05,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      widget.entry.isDirectory
                          ? Icons.folder_rounded
                          : _getIconForFile(widget.entry.name),
                      color: widget.entry.isDirectory
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entry.name,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              widget.entry.isDirectory
                                  ? 'Folder'
                                  : _formatSize(widget.entry.size),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.3),
                                  fontSize: 8,
                                ),
                              ),
                            ),
                            Text(
                              _formatDate(widget.entry.modifiedAt),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions / Info Badge
                  if (widget.entry.isIndexed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Indexed',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    onPressed: widget.onContextMenu,
                    tooltip: 'Options',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForFile(String filename) {
    final ext = p.extension(filename).toLowerCase();
    switch (ext) {
      case '.pdf':
        return Icons.picture_as_pdf_rounded;
      case '.doc':
      case '.docx':
      case '.txt':
        return Icons.description_rounded;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Icons.image_rounded;
      case '.mp4':
      case '.mov':
      case '.avi':
        return Icons.video_library_rounded;
      case '.mp3':
      case '.wav':
        return Icons.audiotrack_rounded;
      case '.zip':
      case '.rar':
      case '.7z':
        return Icons.archive_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _FileGridItem extends StatefulWidget {
  final FileSystemEntry entry;
  final VoidCallback onTap;
  final VoidCallback onContextMenu;

  const _FileGridItem({
    required this.entry,
    required this.onTap,
    required this.onContextMenu,
  });

  @override
  State<_FileGridItem> createState() => _FileGridItemState();
}

class _FileGridItemState extends State<_FileGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onSecondaryTap: widget.onContextMenu,
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Card(
            elevation: _isHovered ? 4 : 1,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: _isHovered
                    ? colorScheme.primary.withValues(alpha: 0.3)
                    : colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: _isHovered ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icon Area
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.entry.isDirectory
                                ? colorScheme.primaryContainer.withValues(
                                    alpha: 0.3,
                                  )
                                : colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                          ),
                          child: Center(
                            child: Icon(
                              widget.entry.isDirectory
                                  ? Icons.folder_rounded
                                  : _getIconForFile(widget.entry.name),
                              size: 56,
                              color: widget.entry.isDirectory
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.8,
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // Info Area
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              widget.entry.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.entry.isDirectory
                                  ? 'Folder'
                                  : _formatSize(widget.entry.size),
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Indexed Badge
                  if (widget.entry.isIndexed)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.bolt_rounded,
                          size: 12,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),

                  // Context Menu Button (visible on hover)
                  if (_isHovered)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        onPressed: widget.onContextMenu,
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForFile(String filename) {
    final ext = p.extension(filename).toLowerCase();
    switch (ext) {
      case '.pdf':
        return Icons.picture_as_pdf_rounded;
      case '.doc':
      case '.docx':
      case '.txt':
        return Icons.description_rounded;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Icons.image_rounded;
      case '.mp4':
      case '.mov':
      case '.avi':
        return Icons.video_library_rounded;
      case '.mp3':
      case '.wav':
        return Icons.audiotrack_rounded;
      case '.zip':
      case '.rar':
      case '.7z':
        return Icons.archive_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
