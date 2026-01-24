import 'package:flutter/material.dart';
import '../../models/chat/tool_result.dart';

/// Card displaying tool execution result
class ToolResultCard extends StatelessWidget {
  final ToolResult result;
  final bool isUser;

  const ToolResultCard({
    super.key,
    required this.result,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final friendlyDescription = _getFriendlyToolDescription(
      result.tool,
      success: result.success,
    );

    final itemColor = result.success
        ? (isUser ? colorScheme.onPrimary : colorScheme.primary)
        : colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: result.success
            ? (isUser
                  ? colorScheme.onPrimary.withValues(alpha: 0.05)
                  : colorScheme.surfaceContainerHigh)
            : colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.success
              ? (isUser
                    ? colorScheme.onPrimary.withValues(alpha: 0.1)
                    : colorScheme.outlineVariant.withValues(alpha: 0.5))
              : colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          clipBehavior: Clip.none,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: itemColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              result.success
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              size: 16,
              color: itemColor,
            ),
          ),
          title: Text(
            friendlyDescription,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: result.success
                  ? (isUser ? colorScheme.onPrimary : colorScheme.onSurface)
                  : colorScheme.error,
            ),
          ),
          trailing: Icon(
            Icons.unfold_more_rounded,
            size: 18,
            color: result.success
                ? (isUser
                      ? colorScheme.onPrimary.withValues(alpha: 0.5)
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5))
                : colorScheme.error.withValues(alpha: 0.5),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.terminal_rounded,
                        size: 12,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Technical Output (${result.tool})',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(result.timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    result.result,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _getFriendlyToolDescription(
    String toolName, {
    bool success = true,
  }) {
    if (!success) {
      switch (toolName) {
        case 'search_files':
          return 'Search failed';
        case 'rename_file':
        case 'rename_folder':
          return 'Rename failed';
        case 'move_file':
          return 'Move failed';
        case 'delete_file':
        case 'move_to_trash':
          return 'Delete failed';
        default:
          return 'Action failed';
      }
    }

    switch (toolName) {
      case 'search_files':
        return 'Semantic search completed';
      case 'grep_search':
        return 'Text search finished';
      case 'find_files':
        return 'Files located';
      case 'read_file_contents':
        return 'Content read';
      case 'get_drives':
        return 'Drives identified';
      case 'list_directory':
        return 'Folder contents listed';
      case 'create_folder':
        return 'New folder created';
      case 'rename_file':
      case 'rename_folder':
        return 'Renamed successfully';
      case 'move_file':
        return 'Moved successfully';
      case 'copy_file':
        return 'Copied successfully';
      case 'delete_file':
        return 'Permanently deleted';
      case 'move_to_trash':
        return 'Sent to trash';
      case 'summarize_document':
        return 'Summary generated';
      case 'get_document_details':
        return 'Metadata retrieved';
      case 'find_related':
        return 'Related items identified';
      case 'get_indexing_status':
        return 'Index status retrieved';
      case 'batch_operations':
        return 'Batch operations completed';
      default:
        return 'Action completed';
    }
  }
}
