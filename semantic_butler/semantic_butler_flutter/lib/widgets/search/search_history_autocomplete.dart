import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../../main.dart';

/// Provider for search history
final searchHistoryProvider = FutureProvider.autoDispose<List<SearchHistory>>((ref) async {
  final client = ref.read(clientProvider);
  try {
    return await client.butler.getSearchHistory(limit: 20);
  } catch (e) {
    return [];
  }
});

/// Search bar with autocomplete from search history
class SearchBarWithHistory extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final Function(String)? onAISearch;
  final String hintText;
  final bool isSearching;

  const SearchBarWithHistory({
    super.key,
    required this.controller,
    required this.onSearch,
    this.onAISearch,
    this.hintText = 'Search your files...',
    this.isSearching = false,
  });

  @override
  ConsumerState<SearchBarWithHistory> createState() => _SearchBarWithHistoryState();
}

class _SearchBarWithHistoryState extends ConsumerState<SearchBarWithHistory> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && widget.controller.text.isEmpty) {
      _showOverlay();
    } else if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onTextChange() {
    if (_focusNode.hasFocus) {
      if (widget.controller.text.isEmpty) {
        _showOverlay();
      } else {
        _updateOverlay();
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: _buildSuggestionsList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final historyAsync = ref.watch(searchHistoryProvider);
    final currentText = widget.controller.text.toLowerCase();
    final colorScheme = Theme.of(context).colorScheme;

    return historyAsync.when(
      data: (history) {
        // Filter history based on current input
        final filtered = currentText.isEmpty
            ? history
            : history.where((h) => 
                h.query.toLowerCase().contains(currentText)
              ).toList();

        if (filtered.isEmpty) {
          return const SizedBox.shrink();
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              return ListTile(
                dense: true,
                leading: Icon(
                  Icons.history,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  item.query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${item.resultCount} results • ${_formatDate(item.searchedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: item.searchType != null
                    ? Chip(
                        label: Text(
                          item.searchType!,
                          style: const TextStyle(fontSize: 10),
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      )
                    : null,
                onTap: () {
                  widget.controller.text = item.query;
                  widget.controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: item.query.length),
                  );
                  _removeOverlay();
                  widget.onSearch(item.query);
                },
              );
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _layerLink,
      child: SearchBar(
        controller: widget.controller,
        focusNode: _focusNode,
        hintText: widget.hintText,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        leading: widget.isSearching
            ? SizedBox(
                width: 24,
                height: 24,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
              )
            : Tooltip(
                message: 'Focus search (Ctrl+K / Cmd+K)',
                child: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
        trailing: [
          if (widget.controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                widget.controller.clear();
                widget.onSearch('');
              },
            ),
          if (widget.onAISearch != null)
            IconButton(
              icon: Icon(
                Icons.auto_awesome,
                color: colorScheme.primary,
                size: 20,
              ),
              tooltip: 'AI Search',
              onPressed: widget.isSearching
                  ? null
                  : () {
                      _removeOverlay();
                      widget.onAISearch!(widget.controller.text);
                    },
            ),
          FilledButton(
            onPressed: widget.isSearching
                ? null
                : () {
                    _removeOverlay();
                    widget.onSearch(widget.controller.text);
                  },
            child: const Text('Search'),
          ),
          const SizedBox(width: 8),
        ],
        onSubmitted: (value) {
          _removeOverlay();
          widget.onSearch(value);
        },
        onTap: () {
          if (widget.controller.text.isEmpty) {
            _showOverlay();
          }
        },
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
      ),
    );
  }
}
