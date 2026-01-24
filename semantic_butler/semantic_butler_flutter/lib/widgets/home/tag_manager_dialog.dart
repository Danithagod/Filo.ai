import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../../main.dart';
import '../../utils/app_logger.dart';

/// Dialog for managing tags with merge, rename, and hierarchy features
class TagManagerDialog extends ConsumerStatefulWidget {
  const TagManagerDialog({super.key});

  @override
  ConsumerState<TagManagerDialog> createState() => _TagManagerDialogState();
}

class _TagManagerDialogState extends ConsumerState<TagManagerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TagTaxonomy> _allTags = [];
  Map<String, List<TagTaxonomy>> _tagsByCategory = {};
  bool _isLoading = true;
  String _selectedCategory = 'all';

  // Selection state for merge operation
  final Set<String> _selectedTags = {};
  bool _isMergeMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTags();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(clientProvider);
      // Load all tags
      final tags = await apiClient.butler.getTopTags(limit: 500);

      // Group by category
      final byCategory = <String, List<TagTaxonomy>>{};
      for (final tag in tags) {
        byCategory.putIfAbsent(tag.category, () => []).add(tag);
      }

      setState(() {
        _allTags = tags;
        _tagsByCategory = byCategory;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load tags: $e', tag: 'TagManager');
      setState(() => _isLoading = false);
    }
  }

  List<TagTaxonomy> get _displayedTags {
    if (_selectedCategory == 'all') {
      return _allTags;
    }
    return _tagsByCategory[_selectedCategory] ?? [];
  }

  void _toggleMergeMode() {
    setState(() {
      _isMergeMode = !_isMergeMode;
      if (!_isMergeMode) {
        _selectedTags.clear();
      }
    });
  }

  void _toggleTagSelection(String tagValue) {
    setState(() {
      if (_selectedTags.contains(tagValue)) {
        _selectedTags.remove(tagValue);
      } else {
        _selectedTags.add(tagValue);
      }
    });
  }

  Future<void> _showMergeDialog() async {
    if (_selectedTags.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least 2 tags to merge'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final targetController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.merge),
        title: const Text('Merge Tags'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Merging ${_selectedTags.length} tags:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _selectedTags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Target tag name',
                hintText: 'Enter the new tag name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All files with the selected tags will be updated to use the target tag.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (targetController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Merge'),
          ),
        ],
      ),
    );

    if (confirmed == true && targetController.text.trim().isNotEmpty) {
      await _performMerge(targetController.text.trim());
    }
  }

  Future<void> _performMerge(String targetTag) async {
    try {
      final apiClient = ref.read(clientProvider);
      final sourceTags = _selectedTags.toList();
      final filesUpdated = await apiClient.butler.mergeTags(
        sourceTags: sourceTags,
        targetTag: targetTag,
        category: _selectedCategory != 'all' ? _selectedCategory : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Merged $filesUpdated files successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Reload tags
        setState(() {
          _selectedTags.clear();
          _isMergeMode = false;
        });
        await _loadTags();
      }
    } catch (e) {
      AppLogger.error('Failed to merge tags: $e', tag: 'TagManager');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to merge tags: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showRenameDialog(TagTaxonomy tag) async {
    final controller = TextEditingController(text: tag.tagValue);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.edit),
        title: const Text('Rename Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New tag name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty &&
                  controller.text.trim() != tag.tagValue) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      await _performRename(tag, controller.text.trim());
    }
  }

  Future<void> _performRename(TagTaxonomy tag, String newName) async {
    try {
      final apiClient = ref.read(clientProvider);
      final filesUpdated = await apiClient.butler.renameTag(
        oldTag: tag.tagValue,
        newTag: newName,
        category: tag.category,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Renamed tag in $filesUpdated files'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadTags();
      }
    } catch (e) {
      AppLogger.error('Failed to rename tag: $e', tag: 'TagManager');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rename tag: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showRelatedTags(TagTaxonomy tag) async {
    final apiClient = ref.read(clientProvider);
    final relatedTags = await apiClient.butler.getRelatedTags(
      tagValue: tag.tagValue,
      limit: 20,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.hub),
        title: Text('Tags related to "${tag.tagValue}"'),
        content: relatedTags.isEmpty
            ? const Text('No related tags found')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: relatedTags.length,
                  itemBuilder: (context, index) {
                    final related = relatedTags[index];
                    final count = related['cooccurrenceCount'] as int;
                    final tagValue = related['tagValue'] as String;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('$count'),
                      ),
                      title: Text(tagValue),
                      subtitle: Text(
                        'Appears together $count time(s)',
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 700,
        height: 600,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.label_outline),
                  const SizedBox(width: 12),
                  const Text(
                    'Tag Manager',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_isMergeMode)
                    FilledButton.icon(
                      onPressed: _selectedTags.length >= 2
                          ? _showMergeDialog
                          : null,
                      icon: const Icon(Icons.merge, size: 18),
                      label: Text('Merge (${_selectedTags.length})'),
                    ),
                  if (_isMergeMode) const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _toggleMergeMode,
                    icon: Icon(
                      _isMergeMode ? Icons.close : Icons.merge,
                      size: 18,
                    ),
                    label: Text(_isMergeMode ? 'Cancel' : 'Merge Mode'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Category filter tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              onTap: (index) {
                setState(() {
                  _selectedCategory = [
                    'all',
                    'topic',
                    'entity',
                    'keyword',
                  ][index];
                });
              },
              tabs: const [
                Tab(text: 'All Tags'),
                Tab(text: 'Topics'),
                Tab(text: 'Entities'),
                Tab(text: 'Keywords'),
              ],
            ),
            const Divider(height: 1),

            // Tags list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _displayedTags.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.label_off_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tags found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      key: PageStorageKey<String>('tag_manager_list_$_selectedCategory'),
                      padding: const EdgeInsets.all(16),
                      itemCount: _displayedTags.length,
                      itemBuilder: (context, index) {
                        final tag = _displayedTags[index];
                        final isSelected = _selectedTags.contains(tag.tagValue);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: _isMergeMode
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (_) =>
                                        _toggleTagSelection(tag.tagValue),
                                  )
                                : CircleAvatar(
                                    child: Text('${tag.frequency}'),
                                  ),
                            title: Text(
                              tag.tagValue,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${tag.category} • Used ${tag.frequency} time(s)',
                            ),
                            trailing: _isMergeMode
                                ? null
                                : PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      switch (value) {
                                        case 'rename':
                                          await _showRenameDialog(tag);
                                          break;
                                        case 'related':
                                          await _showRelatedTags(tag);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'rename',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Rename'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'related',
                                        child: Row(
                                          children: [
                                            Icon(Icons.hub, size: 18),
                                            SizedBox(width: 8),
                                            Text('Related Tags'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                            onTap: _isMergeMode
                                ? () => _toggleTagSelection(tag.tagValue)
                                : null,
                            selected: isSelected,
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
