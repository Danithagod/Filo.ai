import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../utils/app_logger.dart';
import '../utils/tool_name_mapper.dart';
import '../utils/file_content_loader.dart';
import '../utils/stream_debouncer.dart';
import '../models/tagged_file.dart';
import '../models/chat/message_role.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_error.dart';
import '../models/chat/tool_result.dart';
import '../providers/chat_history_provider.dart';
import '../mixins/file_tagging_mixin.dart';
import '../widgets/chat/chat_message_bubble.dart';
import '../widgets/chat/chat_input_area.dart';
import '../widgets/chat/chat_app_bar.dart';
import '../widgets/chat/error_message_bubble.dart';
import '../widgets/chat/file_drop_zone.dart';
import '../providers/navigation_provider.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../widgets/chat_history_sidebar.dart';
import 'package:intl/intl.dart';
import '../widgets/chat/welcome_carousel.dart';
import '../mixins/slash_command_mixin.dart';
import '../services/settings_service.dart';
import '../widgets/command_palette_overlay.dart';

/// Chat screen for natural language file organization
/// Uses the AgentEndpoint for conversational AI interactions
/// Built with Material 3 design principles
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with FileTaggingMixin, SlashCommandMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<File> _attachedFiles = [];
  bool _isLoading = false;
  final FocusNode _inputFocusNode = FocusNode();

  /// Flag to prevent concurrent message sends (race condition fix)
  bool _isSending = false;

  /// Stream debouncer for optimized streaming updates
  final StreamDebouncer _streamDebouncer = StreamDebouncer(
    delay: const Duration(milliseconds: 75),
  );

  /// Reply to content
  ChatMessage? _replyToMessage;

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

    // Initialize slash commands
    initSlashCommands();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

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
  final LayerLink tagLayerLink = LayerLink();

  @override
  void onCommandTriggered(SlashCommand command) {
    if (command.command == 'clear') {
      _clearConversation();
    } else if (command.command == 'search') {
      // Focus input for search query
      _inputFocusNode.requestFocus();
    } else if (command.command == 'organize') {
      // Pre-fill with organize template
      _messageController.text = 'Organize the folder ';
      _inputFocusNode.requestFocus();
      // Move cursor to end
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
    } else if (command.command == 'index') {
      // Pre-fill with index template
      _messageController.text = 'Index the folder ';
      _inputFocusNode.requestFocus();
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
    }
  }

  @override
  void onCommandSelected(SlashCommand command) {
    if (command.command == 'clear') {
      _clearConversation();
      return;
    }
    super.onCommandSelected(command);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _streamDebouncer.dispose();
    disposeFileTagging();
    disposeSlashCommands();
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

  /// Load more messages using provider
  void _loadMoreMessages() {
    ref.read(chatHistoryProvider.notifier).loadMoreMessages();
  }

  Widget _buildLoadMoreIndicator(ChatHistoryState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: TextButton.icon(
          onPressed: state.isLoadingMore ? null : _loadMoreMessages,
          icon: state.isLoadingMore
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.expand_more),
          label: Text(
            state.isLoadingMore ? 'Loading...' : 'Load older messages',
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(settingsProvider);
        return settings.when(
          data: (s) {
            if (s.hasSeenOnboarding) {
              return const SizedBox.shrink();
            }
            return WelcomeCarousel(
              onGetStarted: () {
                ref.read(settingsProvider.notifier).setOnboardingSeen(true);
                _inputFocusNode.requestFocus();
              },
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  void _handleFilesDropped(List<File> files) {
    setState(() {
      _attachedFiles.addAll(files);
    });
  }

  /// Remove an attached file
  void _removeAttachedFile(File file) {
    setState(() {
      _attachedFiles.remove(file);
    });
  }

  /// Handle reply to message
  void _handleReply(ChatMessage message) {
    setState(() {
      _replyToMessage = message;
    });
    _inputFocusNode.requestFocus();
  }

  /// Cancel reply
  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  /// Handle message action: Delete
  Future<void> _handleDeleteMessage(ChatMessage message) async {
    // This logic should probably move to the provider, but for now we update via provider
    final updatedMessage = message.copyWith(
      isDeleted: true,
      content: '[Message deleted]',
    );

    await ref.read(chatHistoryProvider.notifier).addMessage(updatedMessage);
  }

  /// Handle message action: Edit
  void _handleEditMessage(ChatMessage message) {
    if (!message.canEdit) return;

    // Populate input with original message content
    _messageController.text = message.content;
    _inputFocusNode.requestFocus();
  }

  /// Handle message action: Remove attachment
  Future<void> _handleRemoveAttachmentFromMessage(
    ChatMessage message,
    Map<String, dynamic> attachment,
  ) async {
    if (message.role != MessageRole.user) return;

    final updatedAttachments = List<Map<String, dynamic>>.from(
      message.attachments ?? [],
    )..removeWhere((a) => a['path'] == attachment['path']);

    final updatedMessage = message.copyWith(attachments: updatedAttachments);
    await ref.read(chatHistoryProvider.notifier).addMessage(updatedMessage);
  }

  /// Handle message action: Share
  void _handleShareMessage(ChatMessage message) {
    final content = message.content;
    final timestamp = message.timestamp != null
        ? DateFormat.yMMMd().add_jm().format(message.timestamp!)
        : 'Unknown time';
    final role = message.role == MessageRole.user ? 'User' : 'Assistant';

    final shareText = '--- Message from $role ($timestamp) ---\n\n$content';

    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied with metadata for sharing'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleRegenerateResponse(ChatMessage message) async {
    final messages =
        ref.read(chatHistoryProvider).value?.currentConversation?.messages ??
            [];
    final index = messages.indexOf(message);
    if (index == -1 || index == 0) return;

    final userMessage = messages[index - 1];
    if (userMessage.role == MessageRole.user) {
      await _resendMessage(userMessage);
    }
  }

  /// Resend a message (for retry or regenerate)
  Future<void> _resendMessage(ChatMessage message) async {
    final messageContent = message.content;

    // Reconstruct tagged files (this might be improved but works for now)
    final taggedFilesSnapshot = <TaggedFile>[];
    if (message.taggedFiles != null) {
      for (final fileName in message.taggedFiles!) {
        // Try to find the file in tagged files list
        final taggedFile = taggedFiles.firstWhere(
          (f) => f.displayName == fileName,
          orElse: () => TaggedFile(path: fileName, name: fileName),
        );
        taggedFilesSnapshot.add(taggedFile);
      }
    }

    // Clear input
    _messageController.clear();

    // Build file context
    final fileContext = await FileContentLoader.buildFileContext(
      taggedFilesSnapshot,
    );

    // Add user context
    final settings = ref.read(settingsProvider).value;
    final userName = settings?.userName;
    final userContext = (userName != null && userName.isNotEmpty)
        ? '[User Info] Name: $userName\n\n'
        : '';

    // Combine file context with user message
    final fullMessage = fileContext.isEmpty
        ? '$userContext$messageContent'
        : '$userContext$fileContext$messageContent';

    // Create user message
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      role: MessageRole.user,
      content: messageContent,
      taggedFiles: message.taggedFiles,
      timestamp: DateTime.now(),
    );

    // Final resend logic
    setState(() {
      _isLoading = true;
    });

    // Persist to history
    await ref.read(chatHistoryProvider.notifier).addMessage(userMessage);

    // Scroll to bottom
    _scrollToBottom();

    // Send to API
    await _streamResponse(fullMessage);
  }

  /// Stream response from API
  Future<void> _streamResponse(String fullMessage) async {
    try {
      final historyState = ref.read(chatHistoryProvider).value;
      final history = (historyState?.currentConversation?.messages ?? [])
          .where((m) => !m.hasError)
          .map((m) {
        String content = m.content;
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
      }).toList();

      // Show loading
      setState(() {
        _isLoading = true;
      });

      // Start streaming with debouncing
      final contentBuffer = StringBuffer();
      int toolsUsed = 0;
      String? currentTool;
      final List<ToolResult> toolResults = [];

      final apiClient = ref.read(clientProvider);
      await for (final event in apiClient.agent.streamChat(
        fullMessage,
        conversationHistory: history.isEmpty ? null : history,
      )) {
        switch (event.type) {
          case 'thinking':
            _updateStreamingMessage(
              ChatMessage(
                id: 'streaming',
                role: MessageRole.assistant,
                content: contentBuffer.toString(),
                statusMessage: event.content ?? 'Thinking...',
                toolsUsed: toolsUsed,
                isStreaming: true,
              ),
            );
            break;

          case 'text':
            if (event.content != null) {
              contentBuffer.write(event.content);
              _updateStreamingMessage(
                ChatMessage(
                  id: 'streaming',
                  role: MessageRole.assistant,
                  content: contentBuffer.toString(),
                  currentTool: currentTool,
                  toolsUsed: toolsUsed,
                  isStreaming: true,
                ),
                scroll: true,
              );
            }
            break;

          case 'tool_start':
            currentTool = event.tool;
            toolsUsed++;
            final toolName = event.tool ?? 'unknown';
            final friendlyName = ToolNameMapper.getFriendlyToolName(toolName);
            _updateStreamingMessage(
              ChatMessage(
                id: 'streaming',
                role: MessageRole.assistant,
                content: contentBuffer.toString(),
                statusMessage: '$friendlyName...',
                currentTool: toolName,
                toolsUsed: toolsUsed,
                isStreaming: true,
              ),
            );
            break;

          case 'tool_result':
            final resultText = event.result ?? '{"success": false}';

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

            final resultObj = ToolResult(
              tool: event.tool ?? 'unknown',
              result: resultText,
              success: toolSuccess,
              timestamp: DateTime.now(),
            );
            toolResults.add(resultObj);

            _updateStreamingMessage(
              ChatMessage(
                id: 'streaming',
                role: MessageRole.assistant,
                content: contentBuffer.toString(),
                currentTool: null,
                statusMessage:
                    toolSuccess ? 'Action completed' : 'Action failed',
                toolsUsed: toolsUsed,
                toolResults: List.of(toolResults),
                isStreaming: true,
              ),
            );
            break;

          case 'complete':
            final finalContent = contentBuffer.toString();
            final assistantMessage = ChatMessage(
              id: const Uuid().v4(),
              role: MessageRole.assistant,
              content: finalContent,
              toolsUsed: toolsUsed,
              toolResults: toolResults.isEmpty ? null : List.of(toolResults),
              timestamp: DateTime.now(),
            );

            await ref
                .read(chatHistoryProvider.notifier)
                .setStreamingMessage(null);
            await ref
                .read(chatHistoryProvider.notifier)
                .addMessage(assistantMessage);

            setState(() {
              _isLoading = false;
              _isSending = false;
            });
            _scrollToBottom(force: true);
            _scanForNavigation(finalContent);
            break;

          case 'error':
            final errorMessage = ChatMessage(
              id: const Uuid().v4(),
              role: MessageRole.assistant,
              content: contentBuffer.isNotEmpty
                  ? contentBuffer.toString()
                  : (event.content ?? 'An error occurred'),
              isError: true,
              timestamp: DateTime.now(),
            );

            await ref
                .read(chatHistoryProvider.notifier)
                .setStreamingMessage(null);
            await ref
                .read(chatHistoryProvider.notifier)
                .addMessage(errorMessage);

            setState(() {
              _isLoading = false;
              _isSending = false;
            });
        }
      }
    } catch (e) {
      AppLogger.error('Chat error: $e', tag: 'Chat');

      ChatError error;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        error = ChatError.network(e.toString());
      } else if (e.toString().contains('TimeoutException')) {
        error = ChatError.timeout();
      } else {
        error = ChatError.unknown(e.toString());
      }

      if (mounted) {
        final errorMsg = ChatMessage(
          id: const Uuid().v4(),
          role: MessageRole.assistant,
          content: '',
          error: error,
          timestamp: DateTime.now(),
        );
        await ref.read(chatHistoryProvider.notifier).addMessage(errorMsg);
        setState(() {
          _isLoading = false;
          _isSending = false;
        });
        _scrollToBottom(force: true);
      }
    } finally {
      if (mounted) {
        // Ensure sending flag is reset in all cases (error, complete, or abrupt stop)
        _isSending = false;
        // Also ensure loading state is cleared if it wasn't already
        if (_isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        _isSending = false;
      }
    }
  }

  void _updateStreamingMessage(ChatMessage message, {bool scroll = false}) {
    _streamDebouncer.debounce(message.content, () {
      if (mounted) {
        ref.read(chatHistoryProvider.notifier).setStreamingMessage(message);
        if (scroll) {
          _scrollToBottom();
        }
      }
    });
  }

  void _scanForNavigation(String content) {
    final regex = RegExp(r'\[NAVIGATE:\s*([^\]]+)\]');
    final match = regex.firstMatch(content);
    if (match != null) {
      final path = match.group(1)?.trim();
      if (path != null) {
        ref.read(navigationProvider.notifier).navigateToFilesWithTarget(path);
      }
    }
  }

  /// Send a new message
  Future<void> _sendMessage() async {
    final messageContent = _messageController.text.trim();
    if (messageContent.isEmpty &&
        _attachedFiles.isEmpty &&
        _replyToMessage == null) {
      return;
    }

    // Prevent concurrent sends
    if (_isSending) {
      AppLogger.warning('Message send blocked - already sending');
      return;
    }
    _isSending = true;

    // Capture state
    final taggedFilesSnapshot = List<TaggedFile>.from(taggedFiles);
    final attachedFilesSnapshot = List<File>.from(_attachedFiles);
    final replyToSnapshot = _replyToMessage;
    // We need these visible in catch block
    String displayContent = messageContent;

    try {
      // Haptic feedback
      HapticFeedback.lightImpact();

      // Clear input and state
      _messageController.clear();
      clearTaggedFiles();
      setState(() {
        _attachedFiles.clear();
        _replyToMessage = null;
      });

      // Build file context (tagged files + attached files)
      final mergedFiles = [
        ...taggedFilesSnapshot.map(
          (f) => {'path': f.path, 'displayName': f.displayName},
        ),
        ...attachedFilesSnapshot.map(
          (f) => {
            'path': f.path,
            'displayName': p.basename(f.path),
          },
        ),
      ];

      final fileContext = await FileContentLoader.buildFileContext(mergedFiles);

      // Add reply context if any
      final replyContext = replyToSnapshot != null
          ? '\n\n[Replying to: ${replyToSnapshot.content.substring(0, replyToSnapshot.content.length > 100 ? 100 : replyToSnapshot.content.length)}]\n'
          : '';

      // Add user context
      final settings = ref.read(settingsProvider).value;
      final userName = settings?.userName;
      final userContext = (userName != null && userName.isNotEmpty)
          ? '[User Info] Name: $userName\n\n'
          : '';

      // Combine all context
      String fullMessage;

      if (fileContext.isNotEmpty) {
        fullMessage = '$userContext$fileContext$messageContent$replyContext';
      } else {
        fullMessage = '$userContext$messageContent$replyContext';
      }

      // Add attachment info
      if (attachedFilesSnapshot.isNotEmpty) {
        fullMessage +=
            '\n\n[Attached: ${attachedFilesSnapshot.map((f) => f.path).join(', ')}]';
      }

      // Create user message with attachments
      final userMessage = ChatMessage(
        id: const Uuid().v4(),
        role: MessageRole.user,
        content: displayContent,
        taggedFiles: taggedFilesSnapshot.isNotEmpty
            ? taggedFilesSnapshot.map((f) => f.displayName).toList()
            : null,
        replyToId: replyToSnapshot?.id,
        attachments: attachedFilesSnapshot.isNotEmpty
            ? attachedFilesSnapshot.map((f) {
                final isDir = FileSystemEntity.isDirectorySync(f.path);
                int? size;
                if (!isDir) {
                  try {
                    size = f.lengthSync();
                  } catch (_) {}
                }
                return {
                  'path': f.path,
                  'name': p.basename(f.path),
                  'size': size,
                  'isDirectory': isDir,
                };
              }).toList()
            : null,
        timestamp: DateTime.now(),
      );

      // Final send logic: use provider
      setState(() {
        _isLoading = true;
      });

      // Save to history immediately
      await ref.read(chatHistoryProvider.notifier).addMessage(userMessage);

      // Scroll to bottom
      _scrollToBottom();

      // Stream response
      await _streamResponse(fullMessage);
    } catch (e) {
      AppLogger.error('Error sending message: $e', tag: 'Chat');

      // Attempt to restore state so user doesn't lose work
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSending = false;

          // Restore inputs
          _messageController.text = displayContent;
          taggedFiles.addAll(
            taggedFilesSnapshot,
          );
          _attachedFiles.addAll(attachedFilesSnapshot);
          _replyToMessage = replyToSnapshot;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        _isSending = false;
      }
    }
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final position = _scrollController.position;
        final threshold = 100.0;
        final isNearBottom =
            position.maxScrollExtent - position.pixels < threshold;

        if (force || isNearBottom) {
          _scrollController.animateTo(
            position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.refresh),
        title: const Text('Start new chat?'),
        content: const Text('This will start a fresh conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatHistoryProvider.notifier).createNewConversation();
            },
            child: const Text('New Chat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ChatHistoryState>>(chatHistoryProvider, (
      previous,
      next,
    ) {
      if (next.hasValue) {
        final prevId = previous?.value?.currentConversationId;
        final nextId = next.value!.currentConversationId;
        if (prevId != nextId) {
          _scrollToBottom();
        }
      }
    });

    final historyState = ref.watch(chatHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const ChatHistorySidebar(),
      appBar: ChatAppBar(
        isLoading: _isLoading,
        messageCount:
            historyState.value?.currentConversation?.messages.length ?? 0,
        onClearConversation: _clearConversation,
      ),
      body: Builder(
        builder: (context) => CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyH, control: true): () {
              Scaffold.of(context).openDrawer();
            },
            const SingleActivator(LogicalKeyboardKey.keyH, meta: true): () {
              Scaffold.of(context).openDrawer();
            },
          },
          child: historyState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : FileDropZone(
                  onFilesDropped: _handleFilesDropped,
                  child: Column(
                    children: [
                      // Messages list
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final state = ref.watch(chatHistoryProvider);
                            return state.when(
                              data: (state) {
                                final messages =
                                    state.currentConversation?.messages ?? [];
                                final hasMore = state.hasMoreMessages;

                                if (messages.isEmpty &&
                                    state.currentConversationId == null) {
                                  return _buildWelcome(context);
                                }

                                final streaming = state.streamingMessage;

                                return ListView.builder(
                                  key: const PageStorageKey('chat_list'),
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    24,
                                    16,
                                    16,
                                  ),
                                  itemCount: messages.length +
                                      (streaming != null ? 1 : 0) +
                                      (hasMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (hasMore && index == 0) {
                                      return _buildLoadMoreIndicator(state);
                                    }

                                    final messageIndex =
                                        hasMore ? index - 1 : index;

                                    if (streaming != null &&
                                        messageIndex == messages.length) {
                                      return ChatMessageBubble(
                                        key: ValueKey(
                                          'streaming_${streaming.id ?? 'stream'}',
                                        ),
                                        message: streaming,
                                        index: messageIndex,
                                      );
                                    }

                                    final message = messages[messageIndex];

                                    if (message.hasError &&
                                        message.error != null) {
                                      return ErrorMessageBubble(
                                        key: ValueKey(
                                          'error_${message.id ?? index}',
                                        ),
                                        error: message.error!,
                                        onRetry: () {
                                          if (message.id != null) {
                                            ref
                                                .read(
                                                  chatHistoryProvider.notifier,
                                                )
                                                .dismissMessage(message.id!);
                                          }
                                          if (messageIndex > 0) {
                                            _resendMessage(
                                              messages[messageIndex - 1],
                                            );
                                          }
                                        },
                                        onDismiss: () {
                                          if (message.id != null) {
                                            ref
                                                .read(
                                                  chatHistoryProvider.notifier,
                                                )
                                                .dismissMessage(message.id!);
                                          }
                                        },
                                      );
                                    }

                                    return ChatMessageBubble(
                                      key: ValueKey(
                                        message.id ??
                                            'msg_${message.timestamp?.millisecondsSinceEpoch}_$index',
                                      ),
                                      message: message,
                                      index: messageIndex,
                                      onDelete: _handleDeleteMessage,
                                      onEdit: _handleEditMessage,
                                      onRegenerate: _handleRegenerateResponse,
                                      onReply: _handleReply,
                                      onRemoveAttachment:
                                          _handleRemoveAttachmentFromMessage,
                                      onShare: _handleShareMessage,
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (err, stack) =>
                                  Center(child: Text('Error: $err')),
                            );
                          },
                        ),
                      ),

                      // Input area
                      ChatInputArea(
                        controller: _messageController,
                        focusNode: _inputFocusNode,
                        isLoading: _isSending,
                        taggedFiles: taggedFiles,
                        attachedFiles: _attachedFiles,
                        onSend: _sendMessage,
                        onRemoveTag: removeTaggedFile,
                        onRemoveAttachment: _removeAttachedFile,
                        onFilesDropped: _handleFilesDropped,
                        replyToMessage: _replyToMessage,
                        onCancelReply: _cancelReply,
                        layerLink: tagLayerLink,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
