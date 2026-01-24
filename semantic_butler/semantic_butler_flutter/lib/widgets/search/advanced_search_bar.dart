import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../../main.dart'; // For clientProvider

class AdvancedSearchBar extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final Function(String)? onAISearch;
  final List<Widget>? trailing;
  final String hintText;

  const AdvancedSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.onAISearch,
    this.trailing,
    this.hintText = 'Search recent files, tags, or content...',
  });

  @override
  ConsumerState<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends ConsumerState<AdvancedSearchBar> {
  final SearchController _searchController = SearchController();
  Timer? _debounceTimer;
  List<SearchSuggestion> _suggestions = [];
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    // Sync external controller with internal SearchController
    widget.controller.addListener(_onExternalControllerChanged);
    _searchController.addListener(_onInternalControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onExternalControllerChanged);
    _searchController.removeListener(_onInternalControllerChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onExternalControllerChanged() {
    if (widget.controller.text != _searchController.text) {
      _searchController.text = widget.controller.text;
    }
  }

  void _onInternalControllerChanged() {
    if (widget.controller.text != _searchController.text) {
      widget.controller.text = _searchController.text;
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }

    setState(() => _isLoadingSuggestions = true);

    try {
      final apiClient = ref.read(clientProvider);
      final suggestions = await apiClient.butler.getSearchSuggestions(
        query,
        limit: 10,
      );
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSuggestions = false);
      // Fail silently for suggestions
    }
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SearchAnchor(
      searchController: _searchController,
      viewHintText: widget.hintText,
      headerHintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
          controller: controller,
          elevation: const WidgetStatePropertyAll<double>(0),
          backgroundColor: WidgetStatePropertyAll<Color>(
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.8),
          ),
          overlayColor: WidgetStatePropertyAll<Color>(
            colorScheme.onSurface.withValues(alpha: 0.05),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
          ),
          hintStyle: WidgetStatePropertyAll<TextStyle>(
            textTheme.bodyLarge!.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
          ),
          onTap: () {
            controller.openView();
          },
          onChanged: _onQueryChanged,
          leading: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          trailing: [
            if (widget.trailing != null) ...widget.trailing!,
            if (widget.onAISearch != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: IconButton(
                  icon: Icon(
                    Icons.auto_awesome,
                    color: colorScheme.primary.withValues(alpha: 0.8),
                    size: 22,
                  ),
                  tooltip: 'AI Search',
                  onPressed: () {
                    widget.onAISearch?.call(controller.text);
                  },
                ),
              ),
          ],
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        if (_isLoadingSuggestions) {
          return [
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ];
        }

        if (_suggestions.isEmpty && controller.text.isNotEmpty) {
          return [
            ListTile(
              title: Text('Search for "${controller.text}"'),
              leading: const Icon(Icons.search),
              onTap: () {
                controller.closeView(controller.text);
                widget.onSearch(controller.text);
              },
            ),
          ];
        }

        return _suggestions.map((suggestion) {
          IconData icon;
          switch (suggestion.type) {
            case 'tag':
              icon = Icons.label_outline;
              break;
            case 'history':
              icon = Icons.history;
              break;
            case 'file':
              icon = Icons.insert_drive_file_outlined;
              break;
            case 'preset':
              icon = Icons.bookmark_border;
              break;
            default:
              icon = Icons.search;
          }

          return ListTile(
            leading: Icon(icon, color: colorScheme.onSurfaceVariant),
            title: Text(suggestion.text),
            subtitle: suggestion.metadata != null
                ? Text(suggestion.metadata!)
                : null,
            trailing: const Icon(Icons.north_west, size: 16),
            onTap: () {
              controller.closeView(suggestion.text);
              widget.onSearch(suggestion.text);
            },
          );
        });
      },
      viewOnSubmitted: (query) {
        _searchController.closeView(query);
        widget.onSearch(query);
      },
    );
  }
}
