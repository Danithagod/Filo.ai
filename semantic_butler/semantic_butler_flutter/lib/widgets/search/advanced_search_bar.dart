import 'dart:async';
import 'package:flutter/material.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../../main.dart'; // For client access

class AdvancedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final Function(String)? onAISearch;
  final String hintText;

  const AdvancedSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.onAISearch,
    this.hintText = 'Search recent files, tags, or content...',
  });

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar> {
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
      final suggestions = await client.butler.getSearchSuggestions(
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

    return SearchAnchor(
      searchController: _searchController,
      viewHintText: widget.hintText,
      headerHintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
          controller: controller,
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 16.0),
          ),
          onTap: () {
            controller.openView();
          },
          onChanged: _onQueryChanged,
          leading: const Icon(Icons.search),
          trailing: [
            if (widget.onAISearch != null)
              Tooltip(
                message: 'AI Search',
                child: IconButton(
                  icon: Icon(Icons.auto_awesome, color: colorScheme.primary),
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
