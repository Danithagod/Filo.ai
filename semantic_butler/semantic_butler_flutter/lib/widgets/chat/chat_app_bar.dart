import 'package:flutter/material.dart';

/// App bar for chat screen showing agent status and actions
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoading;
  final int messageCount;
  final VoidCallback onClearConversation;

  const ChatAppBar({
    super.key,
    required this.isLoading,
    required this.messageCount,
    required this.onClearConversation,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              color: colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semantic Butler',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                isLoading ? 'Thinking...' : 'Ready to help',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isLoading
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (messageCount > 1)
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear conversation',
            onPressed: onClearConversation,
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}
