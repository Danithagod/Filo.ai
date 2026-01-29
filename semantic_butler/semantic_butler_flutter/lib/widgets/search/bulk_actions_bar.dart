import 'package:flutter/material.dart';

/// Bulk actions bar for search results
class BulkActionsBar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback? onDelete;
  final VoidCallback? onTag;
  final VoidCallback? onMove;
  final VoidCallback? onExport;

  const BulkActionsBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onDeselectAll,
    this.onDelete,
    this.onTag,
    this.onMove,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (selectedCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Selection info
          Icon(
            Icons.check_circle,
            size: 20,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            '$selectedCount of $totalCount selected',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),

          // Select/Deselect all
          TextButton.icon(
            onPressed: selectedCount == totalCount ? onDeselectAll : onSelectAll,
            icon: Icon(
              selectedCount == totalCount
                  ? Icons.deselect
                  : Icons.select_all,
              size: 18,
            ),
            label: Text(
              selectedCount == totalCount ? 'Deselect All' : 'Select All',
            ),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
          ),

          const Spacer(),

          // Action buttons
          if (onTag != null)
            _ActionButton(
              icon: Icons.label_outline,
              label: 'Tag',
              onPressed: onTag!,
              colorScheme: colorScheme,
            ),
          if (onMove != null) ...[
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.drive_file_move_outline,
              label: 'Move',
              onPressed: onMove!,
              colorScheme: colorScheme,
            ),
          ],
          if (onExport != null) ...[
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.file_download_outlined,
              label: 'Export',
              onPressed: onExport!,
              colorScheme: colorScheme,
            ),
          ],
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.delete_outline,
              label: 'Delete',
              onPressed: onDelete!,
              colorScheme: colorScheme,
              isDestructive: true,
            ),
          ],

          const SizedBox(width: 8),

          // Close button
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onDeselectAll,
            tooltip: 'Clear selection',
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.colorScheme,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        foregroundColor: isDestructive
            ? colorScheme.error
            : colorScheme.onPrimaryContainer,
        backgroundColor: isDestructive
            ? colorScheme.errorContainer
            : colorScheme.primaryContainer.withValues(alpha: 0.5),
      ),
    );
  }
}

/// Mixin to add bulk selection functionality to a StatefulWidget
mixin BulkSelectionMixin<T> {
  final Set<T> _selectedItems = {};

  Set<T> get selectedItems => _selectedItems;
  int get selectedCount => _selectedItems.length;
  bool get hasSelection => _selectedItems.isNotEmpty;

  bool isSelected(T item) => _selectedItems.contains(item);

  void toggleSelection(T item) {
    if (_selectedItems.contains(item)) {
      _selectedItems.remove(item);
    } else {
      _selectedItems.add(item);
    }
  }

  void selectAll(List<T> items) {
    _selectedItems.addAll(items);
  }

  void deselectAll() {
    _selectedItems.clear();
  }

  void selectItem(T item) {
    _selectedItems.add(item);
  }

  void deselectItem(T item) {
    _selectedItems.remove(item);
  }
}
