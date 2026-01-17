import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../utils/app_logger.dart';
import '../models/tagged_file.dart';
import '../widgets/file_tag_overlay.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';

/// Chat screen for natural language file organization
/// Uses the AgentEndpoint for conversational AI interactions
/// Built with Material 3 design principles
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final FocusNode _inputFocusNode = FocusNode();

  /// Flag to prevent concurrent message sends (race condition fix)
  bool _isSending = false;

  // Animation controller for typing indicator
  late AnimationController _typingAnimationController;

  // @-mention file tagging
  final List<TaggedFile> _taggedFiles = [];
  bool _showTagOverlay = false;
  String _tagQuery = '';
  OverlayEntry? _tagOverlayEntry;

  @override
  void initState() {
    super.initState();

    // Setup typing animation
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Add welcome message
    _messages.add(
      ChatMessage(
        role: MessageRole.assistant,
        content:
            "Hello! I'm Semantic Butler, your intelligent file assistant.\n\n"
            "I can help you:\n"
            "• Search files using natural language\n"
            "• Organize files – rename, move, delete\n"
            "• Create folders & list contents\n"
            "• Find semantically related documents\n\n"
            "Type **@** to tag files for context!\n\n"
            "How can I assist you today?",
        timestamp: DateTime.now(),
      ),
    );

    // Listen for @-mentions in text
    _messageController.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final text = _messageController.text;
    final cursorPos = _messageController.selection.baseOffset;

    if (cursorPos <= 0) {
      _hideTagOverlay();
      return;
    }

    // Find @ before cursor
    final beforeCursor = text.substring(0, cursorPos);
    final lastAtIndex = beforeCursor.lastIndexOf('@');

    if (lastAtIndex >= 0) {
      // Check if there's a space between @ and cursor (meaning tag is complete)
      final afterAt = beforeCursor.substring(lastAtIndex + 1);
      if (!afterAt.contains(' ') && !afterAt.contains('\n')) {
        // Show overlay with query
        _tagQuery = afterAt;
        _showTagOverlayWidget();
        return;
      }
    }

    _hideTagOverlay();
  }

  void _showTagOverlayWidget() {
    if (_tagOverlayEntry != null) {
      // Update existing overlay
      _tagOverlayEntry!.markNeedsBuild();
      return;
    }

    // Get screen position for overlay - position above input field
    // Sidebar is ~260px wide, so position overlay to the right of it
    final position = Offset(280, 80);

    _tagOverlayEntry = OverlayEntry(
      builder: (context) => FileTagOverlay(
        query: _tagQuery,
        position: position,
        onFileSelected: _onFileTagged,
        onDismiss: _hideTagOverlay,
      ),
    );

    Overlay.of(context).insert(_tagOverlayEntry!);
    setState(() => _showTagOverlay = true);
  }

  void _hideTagOverlay() {
    _tagOverlayEntry?.remove();
    _tagOverlayEntry = null;
    if (_showTagOverlay) {
      setState(() => _showTagOverlay = false);
    }
  }

  void _onFileTagged(TaggedFile file) {
    // Add to tagged files list
    if (!_taggedFiles.contains(file)) {
      setState(() => _taggedFiles.add(file));
    }

    // Replace @query with @filename in text
    final text = _messageController.text;
    final cursorPos = _messageController.selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPos);
    final lastAtIndex = beforeCursor.lastIndexOf('@');

    if (lastAtIndex >= 0) {
      final newText =
          '${text.substring(0, lastAtIndex)}@${file.displayName} ${text.substring(cursorPos)}';
      _messageController.text = newText;
      _messageController.selection = TextSelection.collapsed(
        offset: lastAtIndex + file.displayName.length + 2,
      );
    }

    _hideTagOverlay();
    _inputFocusNode.requestFocus();
  }

  void _removeTaggedFile(TaggedFile file) {
    setState(() => _taggedFiles.remove(file));
  }

  @override
  void dispose() {
    _hideTagOverlay();
    _messageController.removeListener(_handleTextChange);
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Prevent concurrent sends (race condition fix)
    if (_isSending) {
      AppLogger.warning('Message send blocked - already sending');
      return;
    }
    _isSending = true;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Capture tagged files and clear them
    final taggedFilesSnapshot = List<TaggedFile>.from(_taggedFiles);

    // Clear input and tags
    _messageController.clear();
    setState(() => _taggedFiles.clear());

    // Build context from tagged files
    String fileContext = '';
    if (taggedFilesSnapshot.isNotEmpty) {
      final contextParts = <String>[];
      for (final file in taggedFilesSnapshot) {
        try {
          final content = await _loadFileContent(file.path);
          if (content != null && content.isNotEmpty) {
            contextParts.add(
              '--- ${file.displayName} (${file.path}) ---\n$content',
            );
          }
        } catch (e) {
          AppLogger.warning('Failed to load file ${file.path}: $e');
        }
      }
      if (contextParts.isNotEmpty) {
        fileContext =
            '[ATTACHED FILES]\n${contextParts.join('\n\n')}\n[END ATTACHED FILES]\n\n';
      }
    }

    // Combine file context with user message
    final fullMessage = fileContext.isEmpty ? message : '$fileContext$message';

    // Add user message (display original message, not with context)
    setState(() {
      _messages.add(
        ChatMessage(
          role: MessageRole.user,
          content: message,
          taggedFiles: taggedFilesSnapshot.isNotEmpty
              ? taggedFilesSnapshot.map((f) => f.displayName).toList()
              : null,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    // Scroll to bottom
    _scrollToBottom();

    try {
      // Convert messages to AgentMessage format for conversation history
      final history = _messages.take(_messages.length - 1).where((m) => !m.isError).map(
        (m) {
          String content = m.content;

          // If it's an assistant message with tool results, append them to content
          // so the model "remembers" its actions in the next turn
          if (m.role == MessageRole.assistant &&
              m.toolResults != null &&
              m.toolResults!.isNotEmpty) {
            final toolSummary = m.toolResults!
                .map(
                  (r) =>
                      '- ${r.tool}: ${r.success ? "Success" : "Failed"} (${r.result})',
                )
                .join('\n');
            content +=
                '\n\n[System Note: Your previous actions in this turn:]\n$toolSummary';
          }

          return AgentMessage(
            role: m.role == MessageRole.user ? 'user' : 'assistant',
            content: content,
          );
        },
      ).toList();

      // Add placeholder message for streaming response
      final streamingMessageIndex = _messages.length;
      setState(() {
        _messages.add(
          ChatMessage(
            role: MessageRole.assistant,
            content: '',
            isStreaming: true,
            timestamp: DateTime.now(),
          ),
        );
      });

      // Start streaming
      final contentBuffer = StringBuffer();
      int toolsUsed = 0;
      String? currentTool;

      await for (final event in client.agent.streamChat(
        fullMessage,
        conversationHistory: history.isEmpty ? null : history,
      )) {
        switch (event.type) {
          case 'thinking':
            // Update status
            setState(() {
              final currentMsg = _messages[streamingMessageIndex];
              _messages[streamingMessageIndex] = currentMsg.copyWith(
                content: contentBuffer.isNotEmpty
                    ? contentBuffer.toString()
                    : (event.content ?? 'Thinking...'),
                isStreaming: true,
                statusMessage: event.content,
              );
            });
            break;

          case 'text':
            // Append text token
            if (event.content != null) {
              contentBuffer.write(event.content);
              setState(() {
                final currentMsg = _messages[streamingMessageIndex];
                _messages[streamingMessageIndex] = currentMsg.copyWith(
                  content: contentBuffer.toString(),
                  isStreaming: true,
                  currentTool: currentTool,
                  toolsUsed: toolsUsed,
                );
              });
              _scrollToBottom();
            }
            break;

          case 'tool_start':
            // Show tool execution
            currentTool = event.tool;
            toolsUsed++;
            setState(() {
              final toolName = event.tool ?? 'unknown';
              final friendlyName = _getFriendlyToolName(toolName);
              final currentMsg = _messages[streamingMessageIndex];
              _messages[streamingMessageIndex] = currentMsg.copyWith(
                content: contentBuffer.toString(),
                isStreaming: true,
                statusMessage: '$friendlyName...',
                currentTool: toolName,
                toolsUsed: toolsUsed,
              );
            });
            break;

          case 'tool_result':
            // Tool completed
            final resultText =
                event.result ?? '{"success": false, "error": "No result"}';
            final toolName = event.tool ?? 'unknown';

            // Parse success status
            bool toolSuccess = true;
            try {
              final resultJson = jsonDecode(resultText);
              if (resultJson is Map) {
                toolSuccess =
                    resultJson['success'] ?? !resultJson.containsKey('error');
              }
            } catch (e) {
              toolSuccess = false;
            }

            setState(() {
              final currentMsg = _messages[streamingMessageIndex];
              final updatedResults = List<ToolResult>.from(
                currentMsg.toolResults ?? [],
              );
              updatedResults.add(
                ToolResult(
                  tool: toolName,
                  result: resultText,
                  success: toolSuccess,
                  timestamp: DateTime.now(),
                ),
              );

              _messages[streamingMessageIndex] = currentMsg.copyWith(
                currentTool: null,
                statusMessage: toolSuccess
                    ? 'Action completed'
                    : 'Action failed',
                toolsUsed: toolsUsed,
                toolResults: updatedResults,
              );
            });
            break;

          case 'complete':
            // Final message
            setState(() {
              final currentMsg = _messages[streamingMessageIndex];
              _messages[streamingMessageIndex] = currentMsg.copyWith(
                content: event.content ?? contentBuffer.toString(),
                isStreaming: false,
                statusMessage: null, // Clear status message
                toolsUsed: toolsUsed,
                timestamp: DateTime.now(),
              );
              _isLoading = false;
              _isSending = false; // Reset send lock
            });
            break;

          case 'error':
            // Error occurred
            setState(() {
              final currentMsg = _messages[streamingMessageIndex];
              _messages[streamingMessageIndex] = currentMsg.copyWith(
                content: contentBuffer.isNotEmpty
                    ? contentBuffer.toString()
                    : (event.content ?? 'An error occurred'),
                isError: true,
                isStreaming: false,
                statusMessage: 'Error',
                timestamp: DateTime.now(),
              );
              _isLoading = false;
              _isSending = false; // Reset send lock
            });
            break;
        }
      }

      // Ensure _isSending is reset if stream ends without complete/error event
      _isSending = false;
      _scrollToBottom();
    } catch (e) {
      AppLogger.error('Chat error: $e', tag: 'Chat');
      setState(() {
        _messages.add(
          ChatMessage(
            role: MessageRole.assistant,
            content: 'I encountered an error. Please try again.\n\nError: $e',
            isError: true,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
        _isSending = false; // Reset send lock on error
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Clear conversation?'),
        content: const Text(
          'This will remove all messages except the welcome message.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.removeRange(1, _messages.length);
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
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
                  _isLoading ? 'Thinking...' : 'Ready to help',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _isLoading
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear conversation',
              onPressed: _clearConversation,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index], index);
              },
            ),
          ),

          // Input area with elevated container
          _buildInputArea(colorScheme, theme),
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tagged files chips
              if (_taggedFiles.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _taggedFiles.map((file) {
                      return InputChip(
                        label: Text(file.displayName),
                        avatar: Icon(
                          file.isDirectory
                              ? Icons.folder_rounded
                              : Icons.insert_drive_file_outlined,
                          size: 16,
                        ),
                        onDeleted: () => _removeTaggedFile(file),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ),

              // Input row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Input field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _inputFocusNode,
                        decoration: InputDecoration(
                          hintText: _taggedFiles.isEmpty
                              ? 'Ask about your files... (@ to tag)'
                              : 'Ask about tagged files...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_isLoading,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        enableInteractiveSelection: true,
                        autocorrect: true,
                        enableSuggestions: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button with animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: IconButton.filled(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.arrow_upward_rounded),
                      tooltip: 'Send message',
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
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
                    // Message content
                    if (message.content.isNotEmpty)
                      SelectableText(
                        message.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isUser
                              ? colorScheme.onPrimary
                              : message.isError
                              ? colorScheme.onErrorContainer
                              : colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),

                    // Status message (e.g., "Thinking...", "Executing search_files...")
                    if (message.isStreaming && message.statusMessage != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: message.content.isNotEmpty ? 8 : 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.content.isEmpty) ...[
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: isUser
                                      ? colorScheme.onPrimary
                                      : colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Icon(
                              message.statusMessage!.contains('Executing')
                                  ? Icons.bolt_rounded
                                  : Icons.auto_awesome_rounded,
                              size: 14,
                              color: isUser
                                  ? colorScheme.onPrimary.withValues(alpha: 0.7)
                                  : colorScheme.primary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              message.statusMessage!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isUser
                                    ? colorScheme.onPrimary.withValues(
                                        alpha: 0.7,
                                      )
                                    : colorScheme.primary.withValues(
                                        alpha: 0.7,
                                      ),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Tool results
                    if (message.toolResults != null &&
                        message.toolResults!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(
                              height: 1,
                              color: isUser
                                  ? colorScheme.onPrimary.withValues(alpha: 0.2)
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.1,
                                    ),
                            ),
                            const SizedBox(height: 8),
                            ...message.toolResults!.map(
                              (res) => _buildToolResultBox(res, isUser),
                            ),
                          ],
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

  Widget _buildToolResultBox(ToolResult result, bool isUser) {
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
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          visualDensity: VisualDensity.compact,
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
                      Text(
                        'Technical Output (${result.tool})',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
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

  Widget _buildTypingIndicator() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final value =
                        ((_typingAnimationController.value + delay) % 1.0 * 2 -
                        1);
                    final offset = (value.abs() - 0.5).abs() * 6;
                    return Container(
                      margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                      child: Transform.translate(
                        offset: Offset(0, -offset),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Load file content for context
  Future<String?> _loadFileContent(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        // Limit content to avoid token overflow
        if (content.length > 10000) {
          return '${content.substring(0, 10000)}\n... [truncated, file too large]';
        }
        return content;
      }
    } catch (e) {
      AppLogger.warning('Failed to read file content: $e');
    }
    return null;
  }

  String _getFriendlyToolName(String toolName) {
    switch (toolName) {
      case 'search_files':
        return 'Searching documents';
      case 'grep_search':
        return 'Looking for specific text';
      case 'find_files':
        return 'Locating files';
      case 'read_file_contents':
        return 'Reading file';
      case 'get_drives':
        return 'Checking drives';
      case 'list_directory':
        return 'Scanning folder';
      case 'create_folder':
        return 'Creating folder';
      case 'rename_file':
      case 'rename_folder':
        return 'Renaming item';
      case 'move_file':
        return 'Moving item';
      case 'copy_file':
        return 'Copying item';
      case 'delete_file':
        return 'Eliminating item';
      case 'move_to_trash':
        return 'Moving to trash';
      case 'summarize_document':
        return 'Analyzing content';
      case 'get_document_details':
        return 'Getting info';
      case 'find_related':
        return 'Finding similar files';
      case 'get_indexing_status':
        return 'Checking index';
      case 'batch_operations':
        return 'Running multiple actions';
      default:
        return 'Working';
    }
  }

  String _getFriendlyToolDescription(String toolName, {bool success = true}) {
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

/// Message in the chat
enum MessageRole { user, assistant }

class ToolResult {
  final String tool;
  final String result;
  final bool success;
  final DateTime timestamp;

  ToolResult({
    required this.tool,
    required this.result,
    this.success = true,
    required this.timestamp,
  });
}

class ChatMessage {
  final MessageRole role;
  final String content;
  final int? toolsUsed;
  final bool isError;
  final bool isStreaming;
  final String? statusMessage;
  final String? currentTool;
  final List<ToolResult>? toolResults;
  final DateTime? timestamp;
  final List<String>? taggedFiles;

  ChatMessage({
    required this.role,
    required this.content,
    this.toolsUsed,
    this.isError = false,
    this.isStreaming = false,
    this.statusMessage,
    this.currentTool,
    this.toolResults,
    this.timestamp,
    this.taggedFiles,
  });

  ChatMessage copyWith({
    MessageRole? role,
    String? content,
    int? toolsUsed,
    bool? isError,
    bool? isStreaming,
    String? statusMessage,
    String? currentTool,
    List<ToolResult>? toolResults,
    DateTime? timestamp,
    List<String>? taggedFiles,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      toolsUsed: toolsUsed ?? this.toolsUsed,
      isError: isError ?? this.isError,
      isStreaming: isStreaming ?? this.isStreaming,
      statusMessage: statusMessage ?? this.statusMessage,
      currentTool: currentTool ?? this.currentTool,
      toolResults: toolResults ?? this.toolResults,
      timestamp: timestamp ?? this.timestamp,
      taggedFiles: taggedFiles ?? this.taggedFiles,
    );
  }
}
