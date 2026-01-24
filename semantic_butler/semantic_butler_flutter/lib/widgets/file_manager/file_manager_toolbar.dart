import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'breadcrumb_navigation.dart';

/// Toolbar widget for file manager with navigation and view controls
class FileManagerToolbar extends StatefulWidget {
  final bool isSearching;
  final bool isGridView;
  final String currentPath;
  final TextEditingController searchController;
  final VoidCallback onNavigateBack;
  final VoidCallback onRefresh;
  final VoidCallback onToggleSearch;
  final VoidCallback onExitSearch;
  final void Function(bool) onViewModeChanged;
  final void Function(String) onPathSelected;
  final VoidCallback? onRootTap;
  final ValueChanged<String>? onSearchChanged;
  final Duration debounceDuration;

  const FileManagerToolbar({
    super.key,
    required this.isSearching,
    required this.isGridView,
    required this.currentPath,
    required this.searchController,
    required this.onNavigateBack,
    required this.onRefresh,
    required this.onToggleSearch,
    required this.onExitSearch,
    required this.onViewModeChanged,
    required this.onPathSelected,
    this.onRootTap,
    this.onSearchChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<FileManagerToolbar> createState() => _FileManagerToolbarState();
}

class _FileManagerToolbarState extends State<FileManagerToolbar> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (mounted) {
        widget.onSearchChanged?.call(value);
      }
    });
  }

  /// Get a display-friendly path that shows context without being too long
  String _getDisplayPath(String path) {
    if (path.isEmpty) return 'Root';
    final parts = path.split(Platform.pathSeparator);
    if (parts.length <= 3) return path;
    // Show last 2 parts with ellipsis prefix for long paths
    return '...${Platform.pathSeparator}${parts.sublist(parts.length - 2).join(Platform.pathSeparator)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          if (widget.isSearching) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onExitSearch,
              tooltip: 'Exit Search',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape):
                      widget.onExitSearch,
                },
                child: TextField(
                  controller: widget.searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText:
                        'Search in: ${_getDisplayPath(widget.currentPath)}',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    suffixIcon: widget.searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              widget.searchController.clear();
                              widget.onSearchChanged?.call('');
                            },
                          )
                        : null,
                  ),
                  keyboardType: TextInputType.text,
                  enableInteractiveSelection: true,
                  autocorrect: false,
                  enableSuggestions: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onChanged,
                  onSubmitted: (value) {
                    // Handle Enter key - currently just keeps the filter applied
                  },
                ),
              ),
            ),
          ] else ...[
            IconButton.filledTonal(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onNavigateBack,
              tooltip: 'Back',
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: widget.onRefresh,
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 16),

            // Breadcrumbs
            Expanded(
              child: BreadcrumbNavigation(
                currentPath: widget.currentPath,
                onPathSelected: widget.onPathSelected,
                onRootTap: widget.onRootTap,
              ),
            ),

            const SizedBox(width: 16),

            // View Toggle
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.list),
                  isSelected: !widget.isGridView,
                  onPressed: () => widget.onViewModeChanged(false),
                  tooltip: 'List View',
                  color: !widget.isGridView ? colorScheme.primary : null,
                ),
                IconButton(
                  icon: const Icon(Icons.grid_view),
                  isSelected: widget.isGridView,
                  onPressed: () => widget.onViewModeChanged(true),
                  tooltip: 'Grid View',
                  color: widget.isGridView ? colorScheme.primary : null,
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Search Tool
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: widget.onToggleSearch,
              tooltip: 'Search Local',
              isSelected: widget.isSearching,
            ),
          ],
        ],
      ),
    );
  }
}
