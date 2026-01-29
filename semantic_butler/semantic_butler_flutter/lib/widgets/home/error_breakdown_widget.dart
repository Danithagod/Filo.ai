import 'package:flutter/material.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';

/// Widget to display categorized error breakdown with visual chips
class ErrorBreakdownWidget extends StatelessWidget {
  /// List of error category counts to display
  final List<ErrorCategoryCount> categories;

  const ErrorBreakdownWidget({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Error Breakdown',
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: categories
              .map((cat) => _CategoryChip(category: cat))
              .toList(),
        ),
      ],
    );
  }
}

/// Individual error category chip with icon and count
class _CategoryChip extends StatelessWidget {
  final ErrorCategoryCount category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (icon, color) = _getCategoryVisuals(category.category, colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            _formatCategoryName(category.category),
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${category.count}',
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get icon and color for each error category
  (IconData, Color) _getCategoryVisuals(String category, ColorScheme cs) {
    switch (category) {
      case 'APITimeout':
        return (Icons.timer_off_outlined, cs.error);
      case 'CorruptFile':
        return (Icons.broken_image_outlined, cs.error);
      case 'PermissionDenied':
        return (Icons.lock_outline, cs.secondary);
      case 'NetworkError':
        return (Icons.wifi_off_outlined, cs.secondary);
      case 'UnsupportedFormat':
        return (Icons.help_outline, cs.secondary.withValues(alpha: 0.8));
      case 'InsufficientDiskSpace':
        return (Icons.sd_storage_outlined, cs.error);
      default:
        return (Icons.error_outline, cs.onSurfaceVariant);
    }
  }

  /// Format category name for display (e.g., "APITimeout" -> "API Timeout")
  String _formatCategoryName(String category) {
    return category.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
  }
}

/// Summary widget showing total errors with quick breakdown
class ErrorSummaryBadge extends StatelessWidget {
  final int failedFiles;
  final VoidCallback? onTap;

  const ErrorSummaryBadge({
    super.key,
    required this.failedFiles,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (failedFiles == 0) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 6),
            Text(
              '$failedFiles failed',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
