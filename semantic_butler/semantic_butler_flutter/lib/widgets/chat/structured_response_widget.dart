import 'package:flutter/material.dart';
import '../../utils/xml_response_parser.dart';

/// Widget to display a `<thinking>` block as a collapsible section
class ThinkingBlockWidget extends StatelessWidget {
  final ThinkingBlock block;

  const ThinkingBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Icon(
            Icons.psychology_outlined,
            size: 18,
            color: colorScheme.primary.withValues(alpha: 0.7),
          ),
          title: Text(
            'Thinking...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            Text(
              block.content,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display a `<result>` block as a file/folder tree
class ResultBlockWidget extends StatelessWidget {
  final ResultBlock block;

  const ResultBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with path
          if (block.path != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    block.type == 'folder'
                        ? Icons.folder_rounded
                        : Icons.search_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      block.path!,
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Items list
          if (block.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: block.items
                    .map((item) => _buildItemRow(context, item))
                    .toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'No items found',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, ResultItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFolder = item.type == 'folder';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Icon(
            isFolder ? Icons.folder_outlined : _getFileIcon(item.name),
            size: 18,
            color: isFolder ? colorScheme.tertiary : colorScheme.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (item.size != null)
            Text(
              item.size!,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'py':
        return Icons.code;
      case 'dart':
        return Icons.flutter_dash;
      case 'js':
      case 'ts':
        return Icons.javascript;
      case 'json':
        return Icons.data_object;
      case 'md':
        return Icons.description;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}

/// Widget to display a `<status>` block as a colored chip
class StatusBlockWidget extends StatelessWidget {
  final StatusBlock block;

  const StatusBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: block.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: block.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            block.icon,
            size: 16,
            color: block.color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              block.content,
              style: TextStyle(
                fontSize: 13,
                color: block.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display a `<message>` block as plain text
class MessageBlockWidget extends StatelessWidget {
  final MessageBlock block;
  final Color? textColor;

  const MessageBlockWidget({
    super.key,
    required this.block,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      block.content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: textColor ?? Theme.of(context).colorScheme.onSurface,
        height: 1.5,
      ),
    );
  }
}

/// Main widget to render a complete parsed agent response
class StructuredResponseWidget extends StatelessWidget {
  final ParsedAgentResponse response;
  final Color? textColor;

  const StructuredResponseWidget({
    super.key,
    required this.response,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!response.hasStructuredContent) {
      // Fallback to plain text
      return SelectableText(
        response.rawContent,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: textColor,
          height: 1.4,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thinking blocks (collapsible)
        for (final block in response.thinkingBlocks)
          ThinkingBlockWidget(block: block),

        // Status blocks
        for (final block in response.statusBlocks)
          StatusBlockWidget(block: block),

        // Result blocks (file trees)
        for (final block in response.resultBlocks)
          ResultBlockWidget(block: block),

        // Message blocks (plain text)
        for (final block in response.messageBlocks)
          Padding(
            padding: EdgeInsets.only(
              top:
                  response.thinkingBlocks.isNotEmpty ||
                      response.resultBlocks.isNotEmpty
                  ? 8
                  : 0,
            ),
            child: MessageBlockWidget(block: block, textColor: textColor),
          ),
      ],
    );
  }
}
