import 'package:flutter/material.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';

import '../../main.dart';
import '../../utils/app_logger.dart';
import '../../screens/search_results_screen.dart';

/// Panel for managing and executing saved search presets
class SavedSearchPresetsPanel extends StatefulWidget {
  const SavedSearchPresetsPanel({super.key});

  @override
  State<SavedSearchPresetsPanel> createState() =>
      _SavedSearchPresetsPanelState();
}

class _SavedSearchPresetsPanelState extends State<SavedSearchPresetsPanel> {
  List<SavedSearchPreset> _presets = [];
  bool _isLoading = true;
  String? _error;

  // Note: Previous implementation had category filtering, but new endpoint
  // currently returns all presets. Filtering can be done client-side if needed
  // or added back to endpoint later.
  String? _selectedCategory;

  /// Flag to prevent concurrent preset operations
  bool _isOperating = false;

  /// Tracker for the last load request
  int _lastLoadRequestId = 0;

  final List<String> _categories = [
    'Documents',
    'Images',
    'Videos',
    'Code',
    'Recent',
    'Archive',
    'Work',
    'Personal',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    if (!mounted) return;
    final requestId = ++_lastLoadRequestId;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Endpoint currently doesn't support filtering by category in the signature generated
      // We'll fetch all and filter client side if needed, or update backend later.
      // Using generic getSavedPresets()
      final presets = await client.butler.getSavedPresets();

      if (!mounted || requestId != _lastLoadRequestId) return;

      // Filter client-side if category is selected
      final filtered = _selectedCategory != null
          ? presets.where((p) => p.category == _selectedCategory).toList()
          : presets;

      setState(() {
        _presets = filtered;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load presets: $e', tag: 'SearchPresets');
      if (!mounted || requestId != _lastLoadRequestId) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _showSavePresetDialog({String? initialQuery}) async {
    final nameController = TextEditingController();
    final queryController = TextEditingController(text: initialQuery ?? '');
    String? selectedCategory;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(Icons.bookmark_add_outlined),
          title: const Text('Save Search Preset'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Preset name',
                    hintText: 'e.g., Work Documents',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: queryController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Search query',
                    hintText: 'Enter your search query',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a preset name')),
                  );
                  return;
                }
                if (queryController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a query')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true &&
        nameController.text.trim().isNotEmpty &&
        queryController.text.trim().isNotEmpty) {
      await _savePreset(
        name: nameController.text.trim(),
        query: queryController.text.trim(),
        category: selectedCategory,
      );
    }
  }

  Future<void> _savePreset({
    required String name,
    required String query,
    String? category,
  }) async {
    try {
      final preset = SavedSearchPreset(
        name: name,
        query: query,
        category: category,
        usageCount: 0,
        createdAt: DateTime.now(),
      );

      await client.butler.savePreset(preset);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preset "$name" saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadPresets();
      }
    } catch (e) {
      AppLogger.error('Failed to save preset: $e', tag: 'SearchPresets');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preset: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _executePreset(SavedSearchPreset preset) async {
    if (_isOperating) return;
    _isOperating = true;

    try {
      final query = preset.query;
      if (query.trim().isEmpty) {
        throw Exception('Preset query is missing or empty');
      }

      final trimmedQuery = query.trim();

      // Navigate to search results
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchResultsScreen(query: trimmedQuery),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to execute preset: $e', tag: 'SearchPresets');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to execute preset: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isOperating = false;
    }
  }

  Future<void> _deletePreset(int presetId) async {
    if (_isOperating) return;
    _isOperating = true;

    try {
      await client.butler.deletePreset(presetId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preset deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadPresets();
      }
    } catch (e) {
      AppLogger.error('Failed to delete preset: $e', tag: 'SearchPresets');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete preset: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isOperating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.bookmark_outline,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Saved Searches',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _showSavePresetDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = null;
                      });
                      _loadPresets();
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : null;
                          });
                          _loadPresets();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Presets list
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: colorScheme.error,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load presets',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _loadPresets,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _presets.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 64,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No saved searches',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Save frequently used searches for quick access',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _presets.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final preset = _presets[index];
                        final name = preset.name;
                        final query = preset.query;
                        final category = preset.category;
                        final usageCount = preset.usageCount;

                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                              child: Text('$usageCount'),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  query,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (category != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Chip(
                                      label: Text(category),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _executePreset(preset),
                                  icon: const Icon(Icons.play_arrow),
                                  tooltip: 'Execute search',
                                ),
                                IconButton(
                                  onPressed: () {
                                    final presetId = preset.id;
                                    if (presetId != null) {
                                      _deletePreset(presetId);
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Delete preset',
                                ),
                              ],
                            ),
                            isThreeLine: category != null,
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
