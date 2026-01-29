import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/chat/message_role.dart';

class MessageActionsToolbar extends StatelessWidget {
  final MessageRole role;
  final DateTime? timestamp;
  final String content;
  final bool isStreaming;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRegenerate;
  final VoidCallback onReply;
  final VoidCallback onShare;

  const MessageActionsToolbar({
    super.key,
    required this.role,
    this.timestamp,
    required this.content,
    this.isStreaming = false,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    required this.onRegenerate,
    required this.onReply,
    required this.onShare,
  });

  /// Check if message can be regenerated (only for assistant messages that aren't streaming)
  bool get canRegenerate {
    return role == MessageRole.assistant && !isStreaming;
  }

  /// Check if message can be edited (only for user messages)
  bool get canEdit {
    return role == MessageRole.user && !isStreaming;
  }

  /// Check if message can be deleted
  bool get canDelete {
    return role == MessageRole.user && !isStreaming;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(
            icon: Icons.copy,
            onTap: onCopy,
            tooltip: 'Copy',
          ),
          if (canRegenerate)
            _ActionButton(
              icon: Icons.refresh,
              onTap: onRegenerate,
              tooltip: 'Regenerate',
            ),
          _ActionButton(
            icon: Icons.reply,
            onTap: onReply,
            tooltip: 'Reply',
          ),
          // More Menu
          MessageActionsMenu(
            role: role,
            timestamp: timestamp,
            content: content,
            isStreaming: isStreaming,
            onAction: (action) {
              switch (action) {
                case MessageAction.copy:
                  onCopy();
                  break;
                case MessageAction.edit:
                  onEdit();
                  break;
                case MessageAction.delete:
                  onDelete();
                  break;
                case MessageAction.regenerate:
                  onRegenerate();
                  break;
                case MessageAction.reply:
                  onReply();
                  break;
                case MessageAction.share:
                  onShare();
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }
}

enum MessageAction { copy, edit, delete, regenerate, reply, share }

class MessageActionsMenu extends StatelessWidget {
  final MessageRole role;
  final DateTime? timestamp;
  final String content;
  final bool isStreaming;
  final Function(MessageAction) onAction;

  const MessageActionsMenu({
    super.key,
    required this.role,
    this.timestamp,
    required this.content,
    this.isStreaming = false,
    required this.onAction,
  });

  bool get canEdit => role == MessageRole.user && !isStreaming;
  bool get canRegenerate => role == MessageRole.assistant && !isStreaming;
  bool get canDelete => role == MessageRole.user && !isStreaming;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<MessageAction>(
      icon: const Icon(Icons.more_horiz, size: 16),
      padding: EdgeInsets.zero,
      tooltip: 'More actions',
      onSelected: onAction,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: MessageAction.copy,
          child: ListTile(
            leading: Icon(Icons.copy, size: 20),
            title: Text('Copy text'),
            dense: true,
          ),
        ),
        if (canEdit)
          const PopupMenuItem(
            value: MessageAction.edit,
            child: ListTile(
              leading: Icon(Icons.edit, size: 20),
              title: Text('Edit message'),
              dense: true,
            ),
          ),
        if (canRegenerate)
          const PopupMenuItem(
            value: MessageAction.regenerate,
            child: ListTile(
              leading: Icon(Icons.refresh, size: 20),
              title: Text('Regenerate response'),
              dense: true,
            ),
          ),
        const PopupMenuItem(
          value: MessageAction.reply,
          child: ListTile(
            leading: Icon(Icons.reply, size: 20),
            title: Text('Reply'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: MessageAction.share,
          child: ListTile(
            leading: Icon(Icons.share, size: 20),
            title: Text('Share'),
            dense: true,
          ),
        ),
        if (canDelete) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: MessageAction.delete,
            child: ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: colorScheme.error,
                size: 20,
              ),
              title: Text('Delete', style: TextStyle(color: colorScheme.error)),
              dense: true,
            ),
          ),
        ],
      ],
    );
  }
}

/// Copy text to clipboard with feedback
Future<void> copyToClipboard(
  BuildContext context,
  String text, {
  String? message,
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Copied to clipboard'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
