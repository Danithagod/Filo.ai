import 'package:flutter/material.dart';
import '../../models/chat/message_role.dart';

/// Quote bar shown when replying to a message
class MessageQuoteBar extends StatelessWidget {
  final String quotedContent;
  final MessageRole quotedRole;
  final VoidCallback onCancel;

  const MessageQuoteBar({
    super.key,
    required this.quotedContent,
    required this.quotedRole,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = quotedRole == MessageRole.user;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUser
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUser
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.secondary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote indicator line
          Container(
            width: 3,
            height: 48,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: isUser ? colorScheme.primary : colorScheme.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Quote content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? 'You' : 'Assistant',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isUser ? colorScheme.primary : colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _truncateQuote(quotedContent),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Cancel button
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
            tooltip: 'Cancel reply',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  String _truncateQuote(String content) {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }
}
