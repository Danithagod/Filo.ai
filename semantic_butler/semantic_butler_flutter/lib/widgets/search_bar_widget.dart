import 'package:flutter/material.dart';

/// Material 3 styled search bar widget
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearch,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SearchBar(
      controller: controller,
      hintText: hintText,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
      leading: Icon(
        Icons.search,
        color: colorScheme.onSurfaceVariant,
      ),
      trailing: [
        if (controller.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              controller.clear();
            },
          ),
        FilledButton(
          onPressed: () => onSearch(controller.text),
          child: const Text('Search'),
        ),
        const SizedBox(width: 8),
      ],
      onSubmitted: onSearch,
    );
  }
}
