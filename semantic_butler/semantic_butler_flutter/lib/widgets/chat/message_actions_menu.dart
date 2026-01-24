import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/chat/message_role.dart';
import '../../utils/chat_constants.dart';

/// Available actions that can be performed on a chat message
enum MessageAction {
  copy,
  edit,
  delete,
  regenerate,
  reply,
  share,
}

/// Callbacks for message actions
typedef MessageActionCallback = void Function(MessageAction);

/// Popup menu with actions for a chat message
class MessageActionsMenu extends StatelessWidget {
  final MessageRole role;
  final DateTime timestamp;
  final String content;
  final bool isStreaming;
  final MessageActionCallback onAction;

  const MessageActionsMenu({
    super.key,
    required this.role,
    required this.timestamp,
    required this.content,
    this.isStreaming = false,
    required this.onAction,
  });

  /// Check if user message can be edited (within 5 minutes)
  bool get canEdit {
    if (role != MessageRole.user || isStreaming) return false;
    return DateTime.now().difference(timestamp) <
        ChatConstants.editWindowDuration;
  }

  /// Check if assistant response can be regenerated
  bool get canRegenerate {
    return role == MessageRole.assistant && !isStreaming;
  }

  /// Check if message can be deleted
  bool get canDelete {
    return role == MessageRole.user && !isStreaming;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MessageAction>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: _getIconColor(context),
      ),
      tooltip: 'Message actions',
      onSelected: onAction,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      itemBuilder: (context) => [
        // Copy (always available)
        _buildMenuItem(
          context,
          MessageAction.copy,
          Icons.copy,
          'Copy',
        ),
        // Reply (always available)
        _buildMenuItem(
          context,
          MessageAction.reply,
          Icons.reply,
          'Reply',
        ),
        // Share/Export (always available)
        _buildMenuItem(
          context,
          MessageAction.share,
          Icons.share,
          'Share',
        ),
        const PopupMenuDivider(),
        // Edit (user messages only, within 5 min)
        if (canEdit)
          _buildMenuItem(
            context,
            MessageAction.edit,
            Icons.edit,
            'Edit',
          ),
        // Delete (user messages only)
        if (canDelete)
          _buildMenuItem(
            context,
            MessageAction.delete,
            Icons.delete,
            'Delete',
          ),
        // Regenerate (assistant messages only)
        if (canRegenerate)
          _buildMenuItem(
            context,
            MessageAction.regenerate,
            Icons.refresh,
            'Regenerate',
          ),
      ],
    );
  }

  PopupMenuItem<MessageAction> _buildMenuItem(
    BuildContext context,
    MessageAction action,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<MessageAction>(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  Color _getIconColor(BuildContext context) {
    final isUser = role == MessageRole.user;
    final colorScheme = Theme.of(context).colorScheme;
    return isUser
        ? colorScheme.onPrimary.withValues(alpha: 0.7)
        : colorScheme.onSurfaceVariant;
  }
}

/// Inline action buttons shown on hover for quick access
class MessageActionButtons extends StatelessWidget {
  final MessageRole role;
  final DateTime timestamp;
  final String content;
  final bool isStreaming;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRegenerate;
  final VoidCallback onReply;
  final VoidCallback onShare;

  const MessageActionButtons({
    super.key,
    required this.role,
    required this.timestamp,
    required this.content,
    this.isStreaming = false,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    required this.onRegenerate,
    required this.onReply,
    required this.onShare,
  });

  /// Check if user message can be edited (within 5 minutes)
  bool get canEdit {
    if (role != MessageRole.user || isStreaming) return false;
    return DateTime.now().difference(timestamp) <
        ChatConstants.editWindowDuration;
  }

  /// Check if assistant response can be regenerated
  bool get canRegenerate {
    return role == MessageRole.assistant && !isStreaming;
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
            color: Colors.black.withValues(alpha: 0.1),
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
