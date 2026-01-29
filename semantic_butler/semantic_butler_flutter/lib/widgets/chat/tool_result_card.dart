import 'package:flutter/material.dart';
import '../../models/chat/tool_result.dart';
import 'tool_results/generic_tool_result.dart';
import 'tool_results/search_tool_result.dart';
import 'tool_results/file_op_tool_result.dart';
import '../common/custom_expansion_tile.dart';

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
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.success
              ? colorScheme.outlineVariant.withValues(alpha: 0.5)
              : colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: CustomExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          _buildResultContent(result, theme),
        ],
      ),
    );
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

  Widget _buildResultContent(ToolResult result, ThemeData theme) {
    if (!result.success) {
      return GenericToolResult(
        tool: result.tool,
        result: result.result,
        success: false,
      );
    }

    final tool = result.tool;

    if (tool == 'search_files' ||
        tool == 'grep_search' ||
        tool == 'find_files' ||
        tool == 'searchTags' ||
        tool == 'find_related') {
      return SearchToolResult(result: result, theme: theme);
    }

    if (tool.contains('rename') ||
        tool.contains('move') ||
        tool.contains('delete') ||
        tool.contains('copy')) {
      return FileOpToolResult(result: result, theme: theme);
    }

    return GenericToolResult(
      tool: result.tool,
      result: result.result,
      success: result.success,
    );
  }
}
