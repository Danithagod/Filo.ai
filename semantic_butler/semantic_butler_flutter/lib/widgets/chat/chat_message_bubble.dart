import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/message_role.dart';
import '../../utils/thought_parser.dart';
import 'agent_thought_expander.dart';
import 'tool_result_badge.dart';
// No import needed here if unused, but let's see. Wait, if it defines MessageActionsToolbar, it IS used.
// The analyzer says it's unused because I haven't renamed the usage yet.
import 'message_actions_menu.dart';
import '../markdown/markdown_body.dart';
import '../../utils/background_processor.dart';

/// Chat message bubble widget with message actions
class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final int index;
  final Function(ChatMessage)? onDelete;
  final Function(ChatMessage)? onEdit;
  final Function(ChatMessage)? onRegenerate;
  final Function(ChatMessage)? onReply;
  final Function(ChatMessage, Map<String, dynamic>)? onRemoveAttachment;
  final Function(ChatMessage)? onShare;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.index,
    this.onDelete,
    this.onEdit,
    this.onRegenerate,
    this.onReply,
    this.onRemoveAttachment,
    this.onShare,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _isHovering = false;
  bool? _isStructured;
  bool _contentExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkPatterns();
  }

  @override
  void didUpdateWidget(ChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.content != widget.message.content) {
      _checkPatterns();
    }
  }

  Future<void> _checkPatterns() async {
    final content = widget.message.content;
    if (content.isEmpty) return;

    final isStructured = await BackgroundProcessor().containsStructuredPatterns(
      content,
    );
    if (mounted) {
      setState(() {
        _isStructured = isStructured;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = widget.message.role == MessageRole.user;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final bubbleMaxWidth = _getMaxWidth(context, availableWidth);

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Assistant avatar (Left)
                if (!isUser) ...[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: SvgPicture.asset(
                        'assets/filo_logo.svg',
                        colorFilter: ColorFilter.mode(
                          colorScheme.onSecondaryContainer,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Message Bubble
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: bubbleMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        // Reply to indicator
                        if (widget.message.replyToId != null)
                          _ReplyIndicator(replyToId: widget.message.replyToId!),

                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? colorScheme.primaryContainer
                                    : (widget.message.error != null
                                          ? colorScheme.errorContainer
                                          : (theme.brightness == Brightness.dark
                                                ? colorScheme.surfaceContainer
                                                : colorScheme
                                                      .surfaceContainerHigh)),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                                  bottomRight: Radius.circular(isUser ? 4 : 20),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Content
                                  _buildContent(context, isUser, colorScheme),

                                  // Attachments
                                  if (widget.message.attachments != null &&
                                      widget.message.attachments!.isNotEmpty)
                                    _buildAttachments(context),

                                  // Tools/Status Badge
                                  if ((widget.message.isStreaming &&
                                          widget.message.statusMessage !=
                                              null) ||
                                      (widget.message.toolResults != null &&
                                          widget
                                              .message
                                              .toolResults!
                                              .isNotEmpty))
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: widget.message.content.isNotEmpty
                                            ? 8
                                            : 0,
                                      ),
                                      child: ToolResultBadge(
                                        results:
                                            widget.message.toolResults ?? [],
                                        isStreaming: widget.message.isStreaming,
                                        statusMessage:
                                            widget.message.statusMessage,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Action Buttons (Moved higher to avoid overlapping text)
                            if (!widget.message.isStreaming)
                              Positioned(
                                top: -24,
                                right: isUser ? 4 : null,
                                left: isUser ? null : 4,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _isHovering ? 1.0 : 0.0,
                                  child: _buildActionButtons(context, isUser),
                                ),
                              ),
                          ],
                        ),

                        // Timestamp & Status (Outside bubble)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 4,
                            left: 4,
                            right: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.message.timestamp != null)
                                Text(
                                  _formatTime(widget.message.timestamp!),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(
                                          alpha: 0.5,
                                        ),
                                    fontSize: 10,
                                  ),
                                ),
                              if (widget.message.isEdited) ...[
                                const SizedBox(width: 4),
                                Text(
                                  'edited',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(
                                          alpha: 0.5,
                                        ),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // User Avatar (Right)
                if (isUser) ...[
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.primary,
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isUser,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);

    if (widget.message.error != null) {
      return Text(
        widget.message.error!.userMessage,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onErrorContainer,
          fontSize: 13.5,
        ),
      );
    }

    // Parse thoughts and status from content
    final parseResult = ThoughtParser.parse(widget.message.content);
    final content = parseResult.cleanContent;
    final thoughts = parseResult.thoughts;
    final statuses = parseResult.statuses;

    final textColor = isUser
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: textColor,
      height: 1.5,
      fontSize: 13.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser && (thoughts.isNotEmpty || widget.message.isStreaming))
          AgentThoughtExpander(
            thoughts: thoughts,
            isStreaming: widget.message.isStreaming,
          ),

        if (statuses.isNotEmpty) _buildStatuses(context, statuses),

        if (content.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: statuses.isNotEmpty ? 8 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: _contentExpanded || content.length < 800
                        ? double.infinity
                        : 200,
                  ),
                  child: ClipRect(
                    child: isUser || _isStructured == false
                        ? SelectableText(
                            content,
                            style: textStyle,
                          )
                        : MarkdownBodyWidget(
                            content: content,
                            textColor: textColor,
                            baseTextStyle: textStyle,
                          ),
                  ),
                ),
                if (content.length >= 800)
                  InkWell(
                    onTap: () =>
                        setState(() => _contentExpanded = !_contentExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _contentExpanded ? 'Show less' : 'Read more',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            _contentExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatuses(BuildContext context, List<MessageStatus> statuses) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: statuses.map((status) {
          IconData icon;
          Color color;
          switch (status.type) {
            case 'success':
              icon = Icons.check_circle_outline;
              color = colorScheme.tertiary;
              break;
            case 'warning':
              icon = Icons.warning_amber_outlined;
              color = colorScheme.secondary;
              break;
            case 'error':
              icon = Icons.error_outline;
              color = colorScheme.error;
              break;
            default:
              icon = Icons.info_outline;
              color = colorScheme.outline;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    status.text,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttachments(BuildContext context) {
    final attachments = widget.message.attachments!;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: attachments.map((att) {
          return Chip(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            avatar: const Icon(Icons.attach_file, size: 14),
            label: Text(
              att['name'] ?? 'File',
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isUser) {
    return MessageActionsToolbar(
      role: widget.message.role,
      timestamp: widget.message.timestamp ?? DateTime.now(),
      content: widget.message.content,
      isStreaming: widget.message.isStreaming,
      onCopy: () => _copyMessage(context),
      onEdit: () => widget.onEdit?.call(widget.message),
      onDelete: () => _deleteMessage(context),
      onRegenerate: () => widget.onRegenerate?.call(widget.message),
      onReply: () => widget.onReply?.call(widget.message),
      onShare: () => widget.onShare?.call(widget.message),
    );
  }

  double _getMaxWidth(BuildContext context, double availableWidth) {
    final content = widget.message.content;
    // We need to account for the avatar (28px) plus gaps (~16px) = ~44px
    final trueAvailable = availableWidth - 44;

    if (content.contains('```')) {
      return trueAvailable * 0.95; // Code blocks
    } else if (content.contains('|') && content.contains('---')) {
      return trueAvailable * 0.92; // Tables
    } else if (content.contains('\n- ') ||
        content.contains('\n* ') ||
        content.contains('\n1. ')) {
      return trueAvailable * 0.85; // Lists
    }

    return trueAvailable * 0.75; // Default text
  }

  Future<void> _copyMessage(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.message.content));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copied to clipboard'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteMessage(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This message will be marked as deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      widget.onDelete?.call(widget.message);
    }
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ReplyIndicator extends StatelessWidget {
  final String replyToId;

  const _ReplyIndicator({required this.replyToId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Replying to a message',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
