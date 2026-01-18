import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../utils/app_logger.dart';
import '../utils/tool_name_mapper.dart';
import '../utils/file_content_loader.dart';
import '../models/tagged_file.dart';
import '../models/chat/message_role.dart';
import '../models/chat/tool_result.dart';
import '../models/chat/chat_message.dart';
import '../mixins/file_tagging_mixin.dart';
import '../widgets/chat/chat_message_bubble.dart';
import '../widgets/chat/chat_input_area.dart';
import '../widgets/chat/chat_app_bar.dart';
import '../widgets/chat/typing_indicator.dart';
import '../providers/navigation_provider.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';

/// Chat screen for natural language file organization
/// Uses the AgentEndpoint for conversational AI interactions
/// Built with Material 3 design principles
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with FileTaggingMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final FocusNode _inputFocusNode = FocusNode();

  /// Flag to prevent concurrent message sends (race condition fix)
  bool _isSending = false;

  // Pagination state
  static const int _messagesPerPage = 50;
  int _displayedMessageCount = _messagesPerPage;
  bool _isLoadingMore = false;

  // Implement FileTaggingMixin requirements
  @override
  TextEditingController get tagTextController => _messageController;

  @override
  FocusNode get tagFocusNode => _inputFocusNode;

  @override
  void initState() {
    super.initState();

    // Initialize file tagging
    initFileTagging();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

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

    // Check for navigation context after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForNavigationContext();
    });
  }

  /// Check if there's navigation context to handle (e.g., from file manager)
  void _checkForNavigationContext() {
    final navState = ref.read(navigationProvider);
    if (navState.chatContext != null) {
      final context = navState.chatContext!;

      // Add the file as a tagged file
      addTaggedFile(context.filePath, context.fileName);

      // Pre-fill the message if provided
      if (context.initialMessage != null) {
        _messageController.text = context.initialMessage!;
      }

      // Clear the context so it's not re-processed
      ref.read(navigationProvider.notifier).clearChatContext();

      // Focus the input
      _inputFocusNode.requestFocus();
    }
  }

  /// Adds a file to the list of tagged files for context
  void addTaggedFile(String path, String name) {
    final file = TaggedFile(path: path, name: name);
    if (!taggedFiles.any((f) => f.path == path)) {
      setState(() {
        taggedFiles.add(file);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    disposeFileTagging();
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  /// Handle scroll events for pagination
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Check if user scrolled to top (to load older messages)
    final position = _scrollController.position;
    if (position.pixels <= position.minScrollExtent + 100) {
      _loadMoreMessages();
    }
  }

  /// Load more messages when scrolling to top
  void _loadMoreMessages() {
    if (_isLoadingMore || _displayedMessageCount >= _messages.length) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
      _displayedMessageCount = (_displayedMessageCount + _messagesPerPage)
          .clamp(0, _messages.length);
      _isLoadingMore = false;
    });
  }

  /// Get the messages to display (most recent N messages)
  List<ChatMessage> get _displayedMessages {
    // Ensure we always show at least the page size or all messages if fewer
    final effectiveCount = _displayedMessageCount.clamp(
      0,
      _messages.length,
    );

    if (_messages.length <= effectiveCount) {
      return _messages;
    }
    // Show the most recent messages
    return _messages.sublist(_messages.length - effectiveCount);
  }

  /// Check if there are more messages to load
  bool get _hasMoreMessages {
    final effectiveCount = _displayedMessageCount.clamp(
      0,
      _messages.length,
    );
    return effectiveCount < _messages.length;
  }

  /// Build load more indicator widget
  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: TextButton.icon(
          onPressed: _isLoadingMore ? null : _loadMoreMessages,
          icon: _isLoadingMore
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.expand_more),
          label: Text(
            _isLoadingMore
                ? 'Loading...'
                : 'Load ${(_messages.length - _displayedMessageCount).clamp(0, _messagesPerPage)} older messages',
          ),
        ),
      ),
    );
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
    final taggedFilesSnapshot = List<TaggedFile>.from(taggedFiles);

    // Clear input and tags
    _messageController.clear();
    clearTaggedFiles();

    // Build context from tagged files
    final fileContext = await FileContentLoader.buildFileContext(
      taggedFilesSnapshot,
    );

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
              final friendlyName = ToolNameMapper.getFriendlyToolName(toolName);
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
                // Reset pagination
                _displayedMessageCount = _messagesPerPage;
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: ChatAppBar(
        isLoading: _isLoading,
        messageCount: _messages.length,
        onClearConversation: _clearConversation,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount:
                  _displayedMessages.length +
                  (_isLoading ? 1 : 0) +
                  (_hasMoreMessages ? 1 : 0),
              itemBuilder: (context, index) {
                // Load more indicator at top
                if (_hasMoreMessages && index == 0) {
                  return _buildLoadMoreIndicator();
                }

                // Adjust index if load more indicator is present
                final messageIndex = _hasMoreMessages ? index - 1 : index;

                // Typing indicator at bottom
                if (messageIndex == _displayedMessages.length && _isLoading) {
                  return const TypingIndicator();
                }

                return ChatMessageBubble(
                  message: _displayedMessages[messageIndex],
                  index: messageIndex,
                );
              },
            ),
          ),

          // Input area with elevated container
          ChatInputArea(
            controller: _messageController,
            focusNode: _inputFocusNode,
            isLoading: _isLoading,
            taggedFiles: taggedFiles,
            onSend: _sendMessage,
            onRemoveTag: removeTaggedFile,
          ),
        ],
      ),
    );
  }
}
