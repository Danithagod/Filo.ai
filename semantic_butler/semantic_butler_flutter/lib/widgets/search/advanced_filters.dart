import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart'; // For SearchFilters model

class AdvancedFilters extends StatefulWidget {
  final Function(SearchFilters) onFiltersChanged;
  final SearchFilters? initialFilters;

  const AdvancedFilters({
    super.key,
    required this.onFiltersChanged,
    this.initialFilters,
  });

  @override
  State<AdvancedFilters> createState() => _AdvancedFiltersState();
}

class _AdvancedFiltersState extends State<AdvancedFilters> {
  late SearchFilters _filters;
  bool _isExpanded = false;

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
    _filters = widget.initialFilters ?? SearchFilters();
  }

  void _updateFilters() {
    widget.onFiltersChanged(_filters);
  }

  void _clearFilters() {
    setState(() {
      _filters = SearchFilters();
    });
    _updateFilters();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final dateFormat = DateFormat.yMMMd();

    final activeFilterCount = _calculateActiveFilterCount();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) =>
            setState(() => _isExpanded = expanded),
        shape: const Border(), // Remove default borders
        collapsedShape: const Border(),
        leading: Icon(Icons.filter_list, color: colorScheme.primary),
        title: Text('Advanced Filters'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (activeFilterCount > 0)
              Badge(
                label: Text('$activeFilterCount'),
                backgroundColor: colorScheme.primary,
                textColor: colorScheme.onPrimary,
              ),
            const SizedBox(width: 8),
            Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // Date Range
          _buildSectionHeader(context, 'Date Modified'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _filters.dateFrom != null && _filters.dateTo != null
                        ? '${dateFormat.format(_filters.dateFrom!)} - ${dateFormat.format(_filters.dateTo!)}'
                        : 'Select Date Range',
                  ),
                  onPressed: () async {
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
                      _updateFilters();
                    }
                  },
                ),
              ),
              if (_filters.dateFrom != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _filters.dateFrom = null;
                      _filters.dateTo = null;
                    });
                    _updateFilters();
                  },
                ),
            ],
          ),

          const SizedBox(height: 16),

          // File Types
          _buildSectionHeader(context, 'File Types'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _fileTypes.map((type) {
              final isSelected = _filters.fileTypes?.contains(type) ?? false;
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
                  _updateFilters();
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Size (Basic implementation for now)

          // Clear Button
          const Divider(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: activeFilterCount > 0 ? _clearFilters : null,
              child: const Text('Clear All Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  int _calculateActiveFilterCount() {
    int count = 0;
    if (_filters.dateFrom != null) count++;
    if (_filters.fileTypes != null && _filters.fileTypes!.isNotEmpty) count++;
    if (_filters.tags != null && _filters.tags!.isNotEmpty) count++;
    return count;
  }
}
