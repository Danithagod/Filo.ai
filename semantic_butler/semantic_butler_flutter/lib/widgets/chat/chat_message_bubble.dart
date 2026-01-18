import 'package:flutter/material.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/message_role.dart';
import '../../utils/xml_response_parser.dart';
import 'tool_result_badge.dart';
import 'structured_response_widget.dart';

/// Chat message bubble widget
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final int index;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.role == MessageRole.user;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: Offset.zero,
      curve: Curves.easeOutCubic,
      child: Padding(
        padding: EdgeInsets.only(
          top: index == 0 ? 0 : 8,
          bottom: 4,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Assistant avatar
            if (!isUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.smart_toy_outlined,
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Message bubble
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? colorScheme.primary
                      : message.isError
                      ? colorScheme.errorContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message content - use structured parser for assistant
                    if (message.content.isNotEmpty)
                      isUser
                          ? SelectableText(
                              message.content,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimary,
                                height: 1.4,
                              ),
                            )
                          : StructuredResponseWidget(
                              response: XmlResponseParser.parse(
                                message.content,
                              ),
                              textColor: message.isError
                                  ? colorScheme.onErrorContainer
                                  : colorScheme.onSurface,
                            ),

                    // Unified Tool/Status Badge
                    if ((message.isStreaming &&
                            message.statusMessage != null) ||
                        (message.toolResults != null &&
                            message.toolResults!.isNotEmpty))
                      Padding(
                        padding: EdgeInsets.only(
                          top: message.content.isNotEmpty ? 12 : 0,
                          bottom: 4,
                        ),
                        child: ToolResultBadge(
                          results: message.toolResults ?? [],
                          isStreaming: message.isStreaming,
                          statusMessage: message.statusMessage,
                        ),
                      ),

                    // Metadata row
                    if (message.toolsUsed != null && message.toolsUsed! > 0 ||
                        message.timestamp != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tools used badge
                            if (message.toolsUsed != null &&
                                message.toolsUsed! > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? colorScheme.onPrimary.withValues(
                                          alpha: 0.2,
                                        )
                                      : colorScheme.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.psychology_outlined,
                                      size: 12,
                                      color: isUser
                                          ? colorScheme.onPrimary.withValues(
                                              alpha: 0.8,
                                            )
                                          : colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${message.toolsUsed} action${message.toolsUsed == 1 ? '' : 's'}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: isUser
                                                ? colorScheme.onPrimary
                                                      .withValues(alpha: 0.8)
                                                : colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            // Timestamp
                            if (message.timestamp != null)
                              Text(
                                _formatTime(message.timestamp!),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isUser
                                      ? colorScheme.onPrimary.withValues(
                                          alpha: 0.6,
                                        )
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // User avatar
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(
                  Icons.person_outline,
                  size: 18,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ],
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
}
