import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/tagged_file.dart';

/// Compact overlay widget for @-mention file tagging
/// Shows drives first, then navigable file/folder browser
class FileTagOverlay extends ConsumerStatefulWidget {
  final String query;
  final Function(TaggedFile) onFileSelected;
  final VoidCallback onDismiss;
  final Offset position;

  const FileTagOverlay({
    super.key,
    required this.query,
    required this.onFileSelected,
    required this.onDismiss,
    required this.position,
  });

  @override
  ConsumerState<FileTagOverlay> createState() => _FileTagOverlayState();
}

class _FileTagOverlayState extends ConsumerState<FileTagOverlay> {
  List<_BrowseItem> _items = [];
  List<_BrowseItem> _filteredItems = [];
  bool _isLoading = true;
  String? _currentPath; // null = show drives
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  /// FocusNode for keyboard handling - stored as instance variable for proper disposal
  late final FocusNode _keyboardFocusNode;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode();
    _loadDrives();
  }

  @override
  void didUpdateWidget(FileTagOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _filterItems();
    }
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDrives() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(clientProvider);
      final drives = await apiClient.fileSystem.getDrives();
      setState(() {
        _items = drives
            .map(
              (d) => _BrowseItem(
                name: d.name,
                path: d.path,
                isDirectory: true,
                isDrive: true,
              ),
            )
            .toList();
        _currentPath = null;
        _selectedIndex = 0;
        _isLoading = false;
      });
      _filterItems();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDirectory(String path) async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(clientProvider);
      final entries = await apiClient.fileSystem.listDirectory(path);
      setState(() {
        _items = entries
            .map(
              (e) => _BrowseItem(
                name: e.name,
                path: e.path,
                isDirectory: e.isDirectory,
              ),
            )
            .toList();
        _currentPath = path;
        _selectedIndex = 0;
        _isLoading = false;
      });
      _filterItems();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterItems() {
    final query = widget.query.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _items;
      } else {
        _filteredItems = _items.where((item) {
          return item.name.toLowerCase().contains(query);
        }).toList();
      }
      _selectedIndex = _selectedIndex.clamp(0, _filteredItems.length - 1);
    });
  }

  void _navigateUp() {
    if (_currentPath == null) return;

    // Check if we're at a drive root
    final parent = _getParentPath(_currentPath!);
    if (parent == null || parent == _currentPath) {
      _loadDrives();
    } else {
      _loadDirectory(parent);
    }
  }

  String? _getParentPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final lastSlash = normalized.lastIndexOf('/');
    if (lastSlash <= 0) return null;
    if (lastSlash <= 2 && normalized.contains(':')) return null; // Drive root
    return path.substring(0, lastSlash);
  }

  void _selectItem(_BrowseItem item, {bool forceSelect = false}) {
    if (item.isDirectory && !forceSelect) {
      // Single tap on directory navigates into it
      _loadDirectory(item.path);
    } else {
      // Select the item (file or folder with forceSelect)
      widget.onFileSelected(
        TaggedFile(
          path: item.path,
          name: item.name,
          isDirectory: item.isDirectory,
        ),
      );
    }
  }

  void _selectCurrentAsFolder() {
    // Allow selecting current directory as a folder
    if (_currentPath != null) {
      final name = _currentPath!.split(RegExp(r'[\\/]')).last;
      widget.onFileSelected(
        TaggedFile(
          path: _currentPath!,
          name: name.isEmpty ? _currentPath! : name,
          isDirectory: true,
        ),
      );
    }
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Request focus when navigation keys are pressed
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      _keyboardFocusNode.requestFocus();
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1).clamp(
          0,
          _filteredItems.length - 1,
        );
      });
      _scrollToSelected();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1).clamp(
          0,
          _filteredItems.length - 1,
        );
      });
      _scrollToSelected();
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_filteredItems.isNotEmpty && _selectedIndex < _filteredItems.length) {
        _selectItem(_filteredItems[_selectedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss();
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _navigateUp();
    }

    return KeyEventResult.handled;
  }

  void _scrollToSelected() {
    if (_scrollController.hasClients && _filteredItems.isNotEmpty) {
      const itemHeight = 40.0;
      final targetOffset = _selectedIndex * itemHeight;
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FocusScope(
      skipTraversal: true,
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: () {
            // Only request focus when user explicitly clicks on overlay
            FocusScope.of(context).requestFocus(_keyboardFocusNode);
          },
          child: Material(
            elevation: 12,
            color: colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Container(
              width: 420, // Slightly wider for better readability
              constraints: const BoxConstraints(
                maxHeight: 400, // Increased max height
                maxWidth: 420,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with path/breadcrumb
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_currentPath != null)
                          IconButton(
                            icon: const Icon(Icons.arrow_back, size: 18),
                            onPressed: _navigateUp,
                            tooltip: 'Back',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                        const SizedBox(width: 4),
                        Icon(
                          _currentPath == null
                              ? Icons.storage
                              : Icons.folder_open,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentPath ?? 'Select Drive',
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_currentPath != null)
                          TextButton.icon(
                            onPressed: _selectCurrentAsFolder,
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Select'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : _filteredItems.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                widget.query.isEmpty ? 'Empty' : 'No matches',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              final isSelected = index == _selectedIndex;

                              return InkWell(
                                onTap: () => _selectItem(item),
                                onLongPress: item.isDirectory
                                    ? () => _selectItem(item, forceSelect: true)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  color: isSelected
                                      ? colorScheme.primaryContainer.withValues(
                                          alpha: 0.5,
                                        )
                                      : null,
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.isDrive
                                            ? Icons.storage_rounded
                                            : item.isDirectory
                                            ? Icons.folder_rounded
                                            : Icons.insert_drive_file_outlined,
                                        size: 20,
                                        color: item.isDrive || item.isDirectory
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : null,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (item.isDirectory)
                                        Icon(
                                          Icons.chevron_right,
                                          size: 18,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Footer hint
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      '↑↓ Navigate • Enter Select • Hold to select folder',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
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
}

/// Internal browse item model
class _BrowseItem {
  final String name;
  final String path;
  final bool isDirectory;
  final bool isDrive;

  _BrowseItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.isDrive = false,
  });
}
