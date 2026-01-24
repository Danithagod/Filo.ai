import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Breadcrumb navigation widget for file path navigation
/// with root navigation, deep path collapsing, and accessibility
class BreadcrumbNavigation extends StatelessWidget {
  final String currentPath;
  final void Function(String) onPathSelected;
  final VoidCallback? onRootTap;

  /// Maximum segments to show before collapsing (first N + last M)
  static const int _maxVisibleSegments = 5;

  /// Segments to show at start when collapsed
  static const int _startSegments = 2;

  /// Segments to show at end when collapsed
  static const int _endSegments = 2;

  const BreadcrumbNavigation({
    super.key,
    required this.currentPath,
    required this.onPathSelected,
    this.onRootTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isUnc = currentPath.startsWith('\\\\');
    final List<String> parts = p
        .split(currentPath)
        .where((s) => s.isNotEmpty)
        .toList();

    // If it's a UNC path, the first part should be prepended with \\
    if (isUnc && parts.isNotEmpty && !parts[0].startsWith('\\\\')) {
      parts[0] = '\\\\${parts[0]}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Root/Computer icon
            _buildRootItem(context, colorScheme),

            // Breadcrumb segments
            ..._buildBreadcrumbs(context, parts, colorScheme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildRootItem(BuildContext context, ColorScheme colorScheme) {
    return Semantics(
      label: Platform.isWindows ? 'This PC' : 'Root',
      button: true,
      onTapHint: 'Navigate to root',
      child: Tooltip(
        message: Platform.isWindows ? 'This PC' : 'Root',
        child: InkWell(
          onTap: onRootTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Icon(
              Platform.isWindows ? Icons.computer : Icons.home_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBreadcrumbs(
    BuildContext context,
    List<String> parts,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (parts.isEmpty) return [];

    // No collapsing needed for short paths
    if (parts.length <= _maxVisibleSegments) {
      return _buildAllSegments(context, parts, colorScheme, textTheme);
    }

    // Collapse middle segments for deep paths
    return _buildCollapsedSegments(context, parts, colorScheme, textTheme);
  }

  List<Widget> _buildAllSegments(
    BuildContext context,
    List<String> parts,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final widgets = <Widget>[];

    for (var i = 0; i < parts.length; i++) {
      // Chevron separator
      widgets.add(
        Icon(
          Icons.chevron_right,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      );

      // Segment
      widgets.add(
        _buildSegment(
          context,
          parts[i],
          i,
          parts,
          colorScheme,
          textTheme,
          isLast: i == parts.length - 1,
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildCollapsedSegments(
    BuildContext context,
    List<String> parts,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final widgets = <Widget>[];

    // First N segments
    for (var i = 0; i < _startSegments; i++) {
      widgets.add(
        Icon(
          Icons.chevron_right,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      );
      widgets.add(
        _buildSegment(
          context,
          parts[i],
          i,
          parts,
          colorScheme,
          textTheme,
        ),
      );
    }

    // Ellipsis dropdown for collapsed segments
    widgets.add(
      Icon(
        Icons.chevron_right,
        size: 16,
        color: colorScheme.onSurfaceVariant,
      ),
    );
    widgets.add(
      _buildCollapsedDropdown(context, parts, colorScheme, textTheme),
    );

    // Last M segments
    final startOfEnd = parts.length - _endSegments;
    for (var i = startOfEnd; i < parts.length; i++) {
      widgets.add(
        Icon(
          Icons.chevron_right,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      );
      widgets.add(
        _buildSegment(
          context,
          parts[i],
          i,
          parts,
          colorScheme,
          textTheme,
          isLast: i == parts.length - 1,
        ),
      );
    }

    return widgets;
  }

  Widget _buildSegment(
    BuildContext context,
    String segment,
    int index,
    List<String> parts,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    bool isLast = false,
  }) {
    return Semantics(
      label: '$segment folder${isLast ? ', current location' : ''}',
      button: true,
      onTapHint: 'Navigate to $segment',
      child: InkWell(
        onTap: () {
          final targetPath = p.joinAll(parts.take(index + 1));
          final finalPath = Platform.isWindows && !targetPath.contains('\\')
              ? '$targetPath\\'
              : targetPath;
          onPathSelected(finalPath);
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            segment,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
              color: isLast ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedDropdown(
    BuildContext context,
    List<String> parts,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Get the collapsed middle segments
    final collapsedStart = _startSegments;
    final collapsedEnd = parts.length - _endSegments;
    final collapsedParts = parts.sublist(collapsedStart, collapsedEnd);

    // Build full path tooltip
    final fullPath = parts.join(Platform.pathSeparator);

    return Semantics(
      label: '${collapsedParts.length} hidden folders',
      button: true,
      onTapHint: 'Show hidden folders',
      child: PopupMenuButton<int>(
        tooltip: fullPath,
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        itemBuilder: (context) {
          return [
            for (var i = 0; i < collapsedParts.length; i++)
              PopupMenuItem<int>(
                value: collapsedStart + i,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(collapsedParts[i]),
                  ],
                ),
              ),
          ];
        },
        onSelected: (index) {
          final targetPath = p.joinAll(parts.take(index + 1));
          final finalPath = Platform.isWindows && !targetPath.contains('\\')
              ? '$targetPath\\'
              : targetPath;
          onPathSelected(finalPath);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.more_horiz,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${collapsedParts.length}',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
