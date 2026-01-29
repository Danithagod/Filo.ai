import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/chat/tool_result.dart';
import '../../../providers/navigation_provider.dart';

/// Widget to display file operation results (rename, move, delete)
class FileOpToolResult extends ConsumerWidget {
  final ToolResult result;
  final ThemeData theme;

  const FileOpToolResult({
    super.key,
    required this.result,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    String? path;
    String? newPath;
    String? message;

    try {
      final json = jsonDecode(result.result);
      if (json is Map) {
        path = json['from'] ?? json['path'] ?? json['file'];
        newPath = json['to'] ?? json['newPath'];
        message = json['message'];
      }
    } catch (_) {
      // Fallback
    }

    if (path == null && message == null) {
      // Fallback to text
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          result.result,
          style: textTheme.bodySmall,
        ),
      );
    }

    final isDelete =
        result.tool.contains('delete') || result.tool.contains('trash');
    final isRename =
        result.tool.contains('rename') || result.tool.contains('move');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isDelete ? colorScheme.error : colorScheme.primary)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDelete ? Icons.delete_outline : Icons.edit_note,
                  size: 16,
                  color: isDelete ? colorScheme.error : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isDelete
                    ? 'Deleted'
                    : (isRename ? 'Renamed/Moved' : 'Processed'),
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDelete ? colorScheme.error : colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (path != null)
            _buildPathRow(
              context,
              ref,
              'Source',
              path,
              strikethrough: isDelete,
            ),
          if (newPath != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Icon(
                Icons.arrow_downward_rounded,
                size: 14,
                color: colorScheme.outline,
              ),
            ),
            _buildPathRow(context, ref, 'Destination', newPath),
          ],
        ],
      ),
    );
  }

  Widget _buildPathRow(
    BuildContext context,
    WidgetRef ref,
    String label,
    String path, {
    bool strikethrough = false,
  }) {
    final colorScheme = theme.colorScheme;
    final fileName = path.split(RegExp(r'[\\/]')).last;

    return InkWell(
      onTap: strikethrough
          ? null
          : () {
              ref
                  .read(navigationProvider.notifier)
                  .navigateToFilesWithTarget(path);
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: Text(
                fileName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  decoration: strikethrough ? TextDecoration.lineThrough : null,
                  color: colorScheme.onSurface,
                  fontWeight: strikethrough
                      ? FontWeight.normal
                      : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
