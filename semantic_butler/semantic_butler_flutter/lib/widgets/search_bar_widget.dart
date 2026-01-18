import 'dart:async';
import 'package:flutter/material.dart';

/// Material 3 styled search bar widget with debounce support
class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final Function(String)? onAISearch;
  final Function(String)? onDebounceSearch;
  final String hintText;
  final bool isSearching;
  final Duration debounceDuration;
  final int minQueryLength;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearch,
    this.onAISearch,
    this.onDebounceSearch,
    this.hintText = 'Search...',
    this.isSearching = false,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.minQueryLength = 2,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Listen to controller changes to update trailing icons (Issue 4.3)
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onChanged(String value) {
    if (widget.onDebounceSearch == null) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (mounted) {
        // Enforce minimum query length (Issue 4.2)
        // Always allow empty string to reset results
        if (value.isEmpty || value.length >= widget.minQueryLength) {
          widget.onDebounceSearch!(value);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SearchBar(
      controller: widget.controller,
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
              if (!mounted) return;
              widget.controller.clear();
              _debounceTimer?.cancel();
              widget.onSearch('');
              widget.onDebounceSearch?.call('');
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
                : () => widget.onAISearch!(widget.controller.text),
          ),
        FilledButton(
          onPressed: widget.isSearching
              ? null
              : () => widget.onSearch(widget.controller.text),
          child: const Text('Search'),
        ),
        const SizedBox(width: 8),
      ],
      onChanged: _onChanged,
      onSubmitted: widget.onSearch,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      autoFocus: false,
    );
  }
}
