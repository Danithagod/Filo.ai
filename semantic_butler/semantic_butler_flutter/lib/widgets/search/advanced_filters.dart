import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';

class AdvancedFilters extends StatelessWidget {
  final Function(SearchFilters) onFiltersChanged;
  final SearchFilters? initialFilters;

  const AdvancedFilters({
    super.key,
    required this.onFiltersChanged,
    this.initialFilters,
  });

  @override
  Widget build(BuildContext context) {
    final filters = initialFilters ?? SearchFilters();
    return LayoutBuilder(
      builder: (context, constraints) {
        final activeFilterCount = _calculateActiveFilterCount(filters);
        final colorScheme = Theme.of(context).colorScheme;

        // Use MediaQuery for a more global screen-width check
        final screenWidth = MediaQuery.of(context).size.width;
        final hideText = screenWidth < 720;

        return InkWell(
          onTap: () => _showFilterDialog(context, filters),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: hideText ? 10 : 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: activeFilterCount > 0
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: activeFilterCount > 0
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune,
                  size: 16,
                  color: activeFilterCount > 0
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                if (!hideText) ...[
                  const SizedBox(width: 8),
                  Text(
                    'All Filters',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: activeFilterCount > 0
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (activeFilterCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeFilterCount',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context, SearchFilters initialFilters) {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        initialFilters: initialFilters,
        onApply: onFiltersChanged,
      ),
    );
  }

  int _calculateActiveFilterCount(SearchFilters filters) {
    int count = 0;
    if (filters.dateFrom != null) count++;
    if (filters.fileTypes != null && filters.fileTypes!.isNotEmpty) count++;
    if (filters.tags != null && filters.tags!.isNotEmpty) count++;
    return count;
  }
}

class _FilterDialog extends StatefulWidget {
  final SearchFilters initialFilters;
  final Function(SearchFilters) onApply;

  const _FilterDialog({
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late SearchFilters _filters;
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _minSizeController = TextEditingController();
  final TextEditingController _maxSizeController = TextEditingController();

  final List<String> _fileTypes = [
    'pdf',
    'doc',
    'image',
    'code',
    'audio',
    'video',
  ];

  @override
  void initState() {
    super.initState();
    // Clone filters
    _filters = SearchFilters(
      dateFrom: widget.initialFilters.dateFrom,
      dateTo: widget.initialFilters.dateTo,
      fileTypes: widget.initialFilters.fileTypes?.toList(),
      tags: widget.initialFilters.tags?.toList(),
      minSize: widget.initialFilters.minSize,
      maxSize: widget.initialFilters.maxSize,
    );

    if (_filters.tags != null) {
      _tagsController.text = _filters.tags!.join(', ');
    }
    if (_filters.minSize != null) {
      _minSizeController.text = (_filters.minSize! / (1024 * 1024))
          .toStringAsFixed(1);
    }
    if (_filters.maxSize != null) {
      _maxSizeController.text = (_filters.maxSize! / (1024 * 1024))
          .toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _tagsController.dispose();
    _minSizeController.dispose();
    _maxSizeController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _filters = SearchFilters();
      _tagsController.clear();
      _minSizeController.clear();
      _maxSizeController.clear();
    });
  }

  void _apply() {
    // Parse tags
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    _filters.tags = tags.isEmpty ? null : tags;

    // Parse sizes (MB to bytes)
    final minMb = double.tryParse(_minSizeController.text);
    _filters.minSize = minMb != null ? (minMb * 1024 * 1024).toInt() : null;

    final maxMb = double.tryParse(_maxSizeController.text);
    _filters.maxSize = maxMb != null ? (maxMb * 1024 * 1024).toInt() : null;

    widget.onApply(_filters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat.yMMMd();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.tune, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Search Filters'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range
              _buildSectionHeader(context, 'Date Modified'),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialDateRange:
                        _filters.dateFrom != null && _filters.dateTo != null
                        ? DateTimeRange(
                            start: _filters.dateFrom!,
                            end: _filters.dateTo!,
                          )
                        : null,
                  );
                  if (picked != null) {
                    setState(() {
                      _filters.dateFrom = picked.start;
                      _filters.dateTo = picked.end;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _filters.dateFrom != null && _filters.dateTo != null
                              ? '${dateFormat.format(_filters.dateFrom!)} - ${dateFormat.format(_filters.dateTo!)}'
                              : 'Any time',
                          style: textTheme.bodyLarge,
                        ),
                      ),
                      if (_filters.dateFrom != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _filters.dateFrom = null;
                              _filters.dateTo = null;
                            });
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // File Types
              _buildSectionHeader(context, 'File Types'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _fileTypes.map((type) {
                  final isSelected =
                      _filters.fileTypes?.contains(type) ?? false;
                  return FilterChip(
                    label: Text(type.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        final current = _filters.fileTypes?.toList() ?? [];
                        if (selected) {
                          current.add(type);
                        } else {
                          current.remove(type);
                        }
                        _filters.fileTypes = current.isEmpty ? null : current;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Tags
              _buildSectionHeader(context, 'Tags'),
              const SizedBox(height: 12),
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  hintText: 'e.g. work, urgent, invoice',
                  prefixIcon: const Icon(Icons.label_outline, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  isDense: true,
                ),
                style: textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              // Size Range
              _buildSectionHeader(context, 'File Size (MB)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minSizeController,
                      decoration: InputDecoration(
                        labelText: 'Min size',
                        suffixText: 'MB',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('-', style: textTheme.bodyLarge),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _maxSizeController,
                      decoration: InputDecoration(
                        labelText: 'Max size',
                        suffixText: 'MB',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _reset,
          child: const Text('Reset All'),
        ),
        FilledButton(
          onPressed: _apply,
          child: const Text('Apply Filters'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
