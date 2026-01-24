# Chat Improvements Implementation Plan

## Overview
This document outlines the implementation plan for enhancing the Semantic Butler chat screen with persistence, message actions, improved input experience, markdown support, streaming performance, error handling, and file operations.

---

## 1. Message Persistence

### Goals
- Save conversations to local storage
- Chat history sidebar to switch between conversations
- Auto-save after each message
- Support for conversation titles and metadata

### Files to Create
| File | Purpose |
|------|---------|
| `lib/models/chat/conversation.dart` | Conversation model with messages metadata |
| `lib/services/chat_storage_service.dart` | SharedPreferences-based storage for conversations |
| `lib/providers/chat_history_provider.dart` | Riverpod provider for chat state management |
| `lib/widgets/chat_history_sidebar.dart` | Sidebar widget showing conversation list |

### Files to Modify
| File | Changes |
|------|----------|
| `lib/screens/chat_screen.dart` | Integrate with ChatHistoryProvider |
| `lib/models/chat/chat_message.dart` | Add unique ID, edited flag, deleted flag |
| `pubspec.yaml` | Add `uuid` package for message IDs |

### Implementation Steps

#### Step 1.1: Create Conversation Model
```dart
// lib/models/chat/conversation.dart
class Conversation {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? pinnedIndex; // null if not pinned

  Conversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.pinnedIndex,
  });

  // JSON serialization methods
  factory Conversation.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();

  // Generate auto-title from first message
  static String generateTitle(String firstMessage);
}
```

#### Step 1.2: Create ChatStorageService
```dart
// lib/services/chat_storage_service.dart
class ChatStorageService {
  static const String _conversationsKey = 'chat_conversations';
  static const String _currentConversationKey = 'chat_current';

  // Save all conversations
  Future<void> saveConversations(List<Conversation> conversations);

  // Load all conversations
  Future<List<Conversation>> loadConversations();

  // Save/update single conversation
  Future<void> saveConversation(Conversation conversation);

  // Delete conversation
  Future<void> deleteConversation(String id);

  // Get current conversation ID
  Future<String?> getCurrentConversationId();

  // Set current conversation ID
  Future<void> setCurrentConversationId(String id);

  // Export conversation as markdown
  String exportToMarkdown(Conversation conversation);
}
```

#### Step 1.3: Create ChatHistoryProvider
```dart
// lib/providers/chat_history_provider.dart
class ChatHistoryState {
  final List<Conversation> conversations;
  final String? currentConversationId;
  final bool isLoading;
  final String? error;

  // Pinned conversations first, then sorted by date
  List<Conversation> get sortedConversations;
  Conversation? get currentConversation;
}

class ChatHistoryNotifier extends AsyncNotifier<ChatHistoryState> {
  // Load conversations from storage
  Future<void> loadConversations();

  // Create new conversation
  Future<void> createConversation();

  // Switch to existing conversation
  void selectConversation(String id);

  // Delete current conversation
  Future<void> deleteCurrentConversation();

  // Add message to current conversation (auto-saves)
  Future<void> addMessage(ChatMessage message);

  // Update message (for editing)
  Future<void> updateMessage(String messageId, ChatMessage updated);

  // Clear all messages in current conversation
  Future<void> clearCurrentConversation();

  // Pin/unpin conversation
  Future<void> togglePin(String id);
}
```

#### Step 1.4: Update ChatMessage Model
```dart
// Add to existing ChatMessage class
class ChatMessage {
  final String id; // NEW: Unique identifier
  final bool isEdited; // NEW: Track if user edited
  final bool isDeleted; // NEW: Soft delete
  final String? replyToId; // NEW: For quote/reply feature
  final DateTime? editedAt; // NEW: When edited

  // Add to copyWith method
  ChatMessage copyWith({
    String? id,
    bool? isEdited,
    bool? isDeleted,
    String? replyToId,
    DateTime? editedAt,
    // ... existing params
  });
}
```

#### Step 1.5: Create ChatHistorySidebar Widget
```dart
// lib/widgets/chat_history_sidebar.dart
class ChatHistorySidebar extends ConsumerWidget {
  // Show conversation list with:
  // - Pinned conversations section
  // - Recent conversations section
  // - New chat button
  // - Delete/edit actions per conversation
  // - Search/filter conversations
}
```

---

## 2. Message Actions

### Goals
- Copy button on all messages
- Edit/delete for user messages
- Regenerate response for assistant messages
- Quote/reply to specific messages

### Files to Create
| File | Purpose |
|------|---------|
| `lib/widgets/chat/message_actions_menu.dart` | Popup menu with message actions |
| `lib/widgets/chat/message_quote_bar.dart` | Quote preview when replying |

### Files to Modify
| File | Changes |
|------|----------|
| `lib/widgets/chat/chat_message_bubble.dart` | Add action buttons and menu |
| `lib/screens/chat_screen.dart` | Handle action callbacks |
| `lib/models/chat/chat_message.dart` | Add replyToId field |

### Implementation Steps

#### Step 2.1: Message Actions Menu
```dart
// lib/widgets/chat/message_actions_menu.dart
enum MessageAction {
  copy,
  edit,      // User messages only, within 5 minutes
  delete,    // User messages only
  regenerate,// Assistant messages only
  reply,     // Quote and reply
  share,     // Export single message
}

class MessageActionsMenu extends StatelessWidget {
  final MessageRole role;
  final DateTime timestamp;
  final String content;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRegenerate;
  final VoidCallback onReply;
  final VoidCallback onShare;

  // Show different options based on:
  // - Message role (user vs assistant)
  // - Message age (5 min edit window)
  // - Current state (streaming can't edit)
}
```

#### Step 2.2: Update ChatMessageBubble
```dart
// Add to chat_message_bubble.dart
class ChatMessageBubble extends StatelessWidget {
  // Add:
  // - Long-press gesture detector
  // - Hover detection for desktop
  // - Action button in corner (3 dots)
  // - Callback handlers for actions

  Widget _buildActionButtons() {
    return Row(
      children: [
        IconButton(icon: Icons.copy, onPressed: onCopy),
        if (isUser && canEdit) IconButton(icon: Icons.edit, onPressed: onEdit),
        if (isUser) IconButton(icon: Icons.delete, onPressed: onDelete),
        if (!isUser) IconButton(icon: Icons.refresh, onPressed: onRegenerate),
        IconButton(icon: Icons.reply, onPressed: onReply),
      ],
    );
  }
}
```

#### Step 2.3: Quote/Reply Feature
```dart
// lib/widgets/chat/message_quote_bar.dart
class MessageQuoteBar extends StatelessWidget {
  final String quotedContent;
  final MessageRole quotedRole;
  final VoidCallback onCancel;

  // Show bar above input with:
  // - Vertical line indicating quote
  // - Quoted text (truncated)
  // - X button to cancel
}
```

#### Step 2.4: Message Action Handlers in ChatScreen
```dart
// Add to chat_screen.dart
class _ChatScreenState {
  // Copy to clipboard with haptic feedback
  Future<void> _copyMessage(ChatMessage message) async {
    await Clipboard.setData(ClipboardData(text: message.content));
    // Show snackbar confirmation
  }

  // Edit user message
  void _editMessage(int index) {
    // Populate input with message content
    // Remove message from list
    // Update storage
  }

  // Delete message
  Future<void> _deleteMessage(int index) async {
    // Confirm with dialog
    // Soft delete (mark as deleted, don't remove)
    // Update storage
  }

  // Regenerate assistant response
  Future<void> _regenerateResponse(int index) async {
    // Remove assistant message
    // Get previous messages for context
    // Re-send to API with same history
  }

  // Reply to message
  void _replyToMessage(ChatMessage message) {
    // Set replyToId on next message
    // Show quote bar
  }
}
```

---

## 3. Better Input Experience

### Goals
- Multi-line with proper auto-grow
- Paste image/file support
- Quick action chips below input
- Voice input button (optional, platform-dependent)

### Files to Create
| File | Purpose |
|------|---------|
| `lib/widgets/chat/auto_grow_text_field.dart` | Text field that grows with content |
| `lib/widgets/chat/quick_action_chips.dart` | Common query shortcuts |
| `lib/widgets/chat/voice_input_button.dart` | Voice-to-text input |

### Files to Modify
| File | Changes |
|------|----------|
| `lib/widgets/chat/chat_input_area.dart` | Integrate new components |
| `lib/screens/chat_screen.dart` | Handle new input types |
| `pubspec.yaml` | Add `flutter_markdown` for rendering pasted content |

### Implementation Steps

#### Step 3.1: Auto-Grow Text Field
```dart
// lib/widgets/chat/auto_grow_text_field.dart
class AutoGrowTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  // ... styling params

  @override
  State<AutoGrowTextField> createState() => _AutoGrowTextFieldState();
}

class _AutoGrowTextFieldState extends State<AutoGrowTextField> {
  // Calculate line count from text
  // Update maxLines dynamically
  // Use TextField with decoration
}
```

#### Step 3.2: Quick Action Chips
```dart
// lib/widgets/chat/quick_action_chips.dart
class QuickActionChips extends StatelessWidget {
  final List<QuickAction> actions;
  final ValueChanged<String> onActionSelected;

  // Display as horizontal scrollable chips
  // Common actions:
  // "Find files named..."
  // "Search for..."
  // "Summarize..."
  // "What's in..."
}

class QuickAction {
  final String label;
  final String icon;
  final String template;
  final String placeholder;
}
```

#### Step 3.3: File Paste Support
```dart
// Add to chat_input_area.dart
class ChatInputArea extends StatefulWidget {
  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final List<File> _attachedFiles = [];

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      // Listen for Ctrl+V paste
      onKeyEvent: _handlePaste,
      child: Column(
        children: [
          // Attached files preview
          if (_attachedFiles.isNotEmpty) _buildAttachments(),
          // Input field
          AutoGrowTextField(...),
          // Quick actions
          QuickActionChips(...),
        ],
      ),
    );
  }

  void _handlePaste(KeyEvent event) {
    // Detect paste event
    // Check clipboard for image/file
    // Add to _attachedFiles
  }
}
```

#### Step 3.4: Voice Input Button
```dart
// lib/widgets/chat/voice_input_button.dart
class VoiceInputButton extends StatefulWidget {
  final ValueChanged<String> onTextReceived;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  bool _isListening = false;
  stt.SpeechToText? _speech;

  // Use speech_to_text package
  // Show animated waveform when listening
  // Handle platform permissions
}
```

---

## 4. Code Block & Markdown Support

### Goals
- Syntax highlighting for code blocks
- Copy button on code blocks
- Proper markdown tables, lists, headers
- Collapsible long code blocks

### Files to Create
| File | Purpose |
|------|---------|
| `lib/widgets/markdown/code_block_widget.dart` | Code block with syntax highlighting |
| `lib/widgets/markdown/markdown_body.dart` | Custom markdown renderer |
| `lib/utils/markdown_parser.dart` | Parse markdown with code detection |
| `lib/utils/syntax_highlighter.dart` | Highlight code by language |

### Files to Modify
| File | Changes |
|------|----------|
| `lib/utils/xml_response_parser.dart` | Remove `_stripMarkdown`, preserve markdown |
| `lib/widgets/chat/structured_response_widget.dart` | Use markdown renderer |
| `pubspec.yaml` | Add `flutter_markdown`, `highlight`, `flutter_highlight` |

### Implementation Steps

#### Step 4.1: Update Dependencies
```yaml
# pubspec.yaml additions:
dependencies:
  flutter_markdown: ^0.7.4
  highlight: ^0.7.0
  flutter_highlight: ^0.7.0
  markdown: ^7.2.2
  clipboard_watcher: ^0.0.4  # For copy button
```

#### Step 4.2: Create Syntax Highlighter
```dart
// lib/utils/syntax_highlighter.dart
class SyntaxHighlighter {
  static String highlight(String code, String language) {
    // Use highlight package
    // Map language aliases to supported languages
    // Return HTML with span tags for styling
  }

  static Color getHighlightColor(String type, BuildContext context) {
    // Return colors for: keyword, string, comment, number, etc.
  }

  static Set<String> get supportedLanguages => {
    'dart', 'python', 'javascript', 'typescript', 'java', 'cpp', 'c',
    'json', 'yaml', 'xml', 'html', 'css', 'bash', 'sql', 'markdown',
  };
}
```

#### Step 4.3: Create Code Block Widget
```dart
// lib/widgets/markdown/code_block_widget.dart
class CodeBlockWidget extends StatefulWidget {
  final String code;
  final String? language;
  final bool initiallyExpanded;

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _isExpanded = true;
  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header with language, copy button, collapse toggle
          _buildHeader(),
          // Code content
          _isExpanded
            ? _buildHighlightedCode()
            : _buildCollapsedPreview(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(widget.language ?? 'text'),
        Spacer(),
        IconButton(
          icon: Icon(_isCopied ? Icons.check : Icons.copy),
          onPressed: _copyToClipboard,
        ),
        IconButton(
          icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
        ),
      ],
    );
  }
}
```

#### Step 4.4: Update XML Parser
```dart
// lib/utils/xml_response_parser.dart
class XmlResponseParser {
  static ParsedAgentResponse parse(String content) {
    // EXISTING: Parse XML blocks

    // NEW: For unstructured content, parse markdown
    if (!hasStructuredContent) {
      final markdownBlocks = _parseMarkdownBlocks(content);
      return ParsedAgentResponse(
        // ... include markdown blocks
      );
    }
  }

  static List<MarkdownBlock> _parseMarkdownBlocks(String content) {
    // Detect code blocks (```)
    // Extract language and content
    // Return list of MarkdownBlock with type: text or code
  }
}

// Add new model
class MarkdownBlock {
  final String type; // 'text' or 'code'
  final String content;
  final String? language; // For code blocks
}
```

#### Step 4.5: Update StructuredResponseWidget
```dart
// lib/widgets/chat/structured_response_widget.dart
class StructuredResponseWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // EXISTING: Thinking, Result, Status blocks
        for (final block in response.thinkingBlocks)
          ThinkingBlockWidget(block: block),
        // ...

        // NEW: Render message blocks with markdown
        for (final block in response.messageBlocks)
          MarkdownBodyWidget(content: block.content),
      ],
    );
  }
}

// New widget
class MarkdownBodyWidget extends StatelessWidget {
  final String content;

  @override
  Widget build(BuildContext context) {
    // Parse for code blocks
    final blocks = MarkdownParser.parse(content);

    return Column(
      children: blocks.map((block) {
        if (block.type == 'code') {
          return CodeBlockWidget(
            code: block.content,
            language: block.language,
          );
        }
        return MarkdownBody(data: block.content);
      }),
    );
  }
}
```

---

## 5. Streaming Performance

### Goals
- Debounce text updates (batch 50-100ms)
- Only rebuild changed message bubbles
- Use ValueNotifier for streaming content

### Files to Create
| File | Purpose |
|------|---------|
| `lib/widgets/chat/streaming_message_bubble.dart` | Optimized streaming bubble |
| `lib/utils/stream_debouncer.dart` | Debounce utility |

### Files to Modify
| File | Changes |
|------|----------|
| `lib/screens/chat_screen.dart` | Use debounced streaming updates |
| `lib/models/chat/chat_message.dart` | Add ValueNotifier for content |

### Implementation Steps

#### Step 5.1: Create Stream Debouncer
```dart
// lib/utils/stream_debouncer.dart
class StreamDebouncer {
  final Duration delay;
  Timer? _timer;
  final StringBuffer _buffer = StringBuffer();
  VoidCallback? _callback;

  StreamDebouncer({required this.delay});

  void write(String text, VoidCallback callback) {
    _buffer.write(text);
    _callback = callback;

    _timer?.cancel();
    _timer = Timer(delay, _flush);
  }

  void _flush() {
    if (_callback != null && _buffer.isNotEmpty) {
      _callback!();
      _buffer.clear();
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
```

#### Step 5.2: Update ChatMessage for Streaming
```dart
// lib/models/chat/chat_message.dart
class ChatMessage {
  // For streaming messages, use ValueNotifier
  final ValueNotifier<String> contentNotifier;

  ChatMessage({
    required String content,
    // ...
  }) : contentNotifier = ValueNotifier(content);

  // Update content without rebuilding entire tree
  void updateContent(String newContent) {
    contentNotifier.value = newContent;
  }
}
```

#### Step 5.3: Create StreamingMessageBubble
```dart
// lib/widgets/chat/streaming_message_bubble.dart
class StreamingMessageBubble extends StatefulWidget {
  final ChatMessage message;

  @override
  State<StreamingMessageBubble> createState() => _StreamingMessageBubbleState();
}

class _StreamingMessageBubbleState extends State<StreamingMessageBubble> {
  @override
  void initState() {
    super.initState();
    // Listen only to this message's content changes
    widget.message.contentNotifier.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    widget.message.contentNotifier.removeListener(_onContentChanged);
    super.dispose();
  }

  void _onContentChanged() {
    // Only rebuild this bubble, not entire list
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.message.contentNotifier,
      builder: (context, content, child) {
        return ChatMessageBubble(
          message: widget.message.copyWith(content: content),
        );
      },
    );
  }
}
```

#### Step 5.4: Update ChatScreen Streaming
```dart
// lib/screens/chat_screen.dart
class _ChatScreenState extends ConsumerState<ChatScreen> {
  final StreamDebouncer _streamDebouncer = StreamDebouncer(
    delay: Duration(milliseconds: 75),
  );

  Future<void> _sendMessage() async {
    await for (final event in apiClient.agent.streamChat(...)) {
      switch (event.type) {
        case 'text':
          // Debounce text updates
          _streamDebouncer.write(event.content ?? '', () {
            setState(() {
              _messages[streamingMessageIndex] =
                  _messages[streamingMessageIndex].copyWith(
                content: contentBuffer.toString(),
              );
            });
          });
          break;

        case 'complete':
          _streamDebouncer.dispose(); // Flush remaining
          // ... handle completion
          break;
      }
    }
  }

  @override
  void dispose() {
    _streamDebouncer.dispose();
    super.dispose();
  }
}
```

---

## 6. Better Error Handling

### Goals
- Retry button on failed messages
- Re-send last message option
- Show specific error types (network, API, timeout)
- Graceful degradation

### Files to Create
| File | Purpose |
|------|---------|
| `lib/models/chat/chat_error.dart` | Typed error classes |
| `lib/widgets/chat/error_message_bubble.dart` | Specialized error UI |
| `lib/widgets/chat/retry_banner.dart` | Global retry banner |

### Files to Modify
| File | Changes |
|------|----------|
| `lib/screens/chat_screen.dart` | Enhanced error handling |
| `lib/models/chat/chat_message.dart` | Add errorType field |

### Implementation Steps

#### Step 6.1: Define Error Types
```dart
// lib/models/chat/chat_error.dart
enum ChatErrorType {
  network,
  timeout,
  apiRateLimit,
  apiAuth,
  apiServer,
  streamingLost,
  unknown,
}

class ChatError {
  final ChatErrorType type;
  final String message;
  final String? details;
  final bool isRetryable;
  final DateTime timestamp;

  const ChatError({
    required this.type,
    required this.message,
    this.details,
    this.isRetryable = true,
    required this.timestamp,
  });

  // Factory constructors for common errors
  factory ChatError.network(String details) {
    return ChatError(
      type: ChatErrorType.network,
      message: 'Network connection failed',
      details: details,
      isRetryable: true,
      timestamp: DateTime.now(),
    );
  }

  factory ChatError.timeout() {
    return ChatError(
      type: ChatErrorType.timeout,
      message: 'Request timed out',
      isRetryable: true,
      timestamp: DateTime.now(),
    );
  }

  // User-friendly messages
  String get userMessage {
    switch (type) {
      case ChatErrorType.network:
        return 'No internet connection. Please check your network.';
      case ChatErrorType.timeout:
        return 'The request took too long. Please try again.';
      case ChatErrorType.apiRateLimit:
        return 'Too many requests. Please wait a moment.';
      case ChatErrorType.apiAuth:
        return 'Authentication failed. Please check your API key.';
      case ChatErrorType.apiServer:
        return 'Server error. Please try again later.';
      default:
        return message;
    }
  }

  // Suggested actions
  List<String> get suggestedActions {
    switch (type) {
      case ChatErrorType.network:
        return ['Check connection', 'Retry'];
      case ChatErrorType.timeout:
        return ['Try again', 'Check server status'];
      default:
        return ['Retry'];
    }
  }
}
```

#### Step 6.2: Update ChatMessage
```dart
// lib/models/chat/chat_message.dart
class ChatMessage {
  final ChatError? error; // NEW: Typed error

  // Helper methods
  bool get hasError => error != null;
  bool get isRetryable => error?.isRetryable ?? false;
}
```

#### Step 6.3: Error Message Bubble
```dart
// lib/widgets/chat/error_message_bubble.dart
class ErrorMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = message.error!;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error icon and title
          Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              SizedBox(width: 8),
              Text('Error', style: theme.textTheme.titleSmall),
            ],
          ),
          SizedBox(height: 8),

          // User-friendly message
          Text(error.userMessage),

          // Details (expandable)
          if (error.details != null)
            ExpansionTile(
              title: Text('Details'),
              children: [
                Text(
                  error.details!,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),

          SizedBox(height: 12),

          // Action buttons
          Wrap(
            spacing: 8,
            children: [
              if (error.isRetryable)
                FilledButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                  onPressed: onRetry,
                ),
              // Other suggested actions
              ...error.suggestedActions.map((action) =>
                OutlinedButton(
                  child: Text(action),
                  onPressed: () => _handleAction(action),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

#### Step 6.4: Global Retry Banner
```dart
// lib/widgets/chat/retry_banner.dart
class RetryBanner extends StatefulWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(message),
      leading: Icon(Icons.warning_amber),
      actions: [
        TextButton(onPressed: onDismiss, child: Text('Dismiss')),
        FilledButton(onPressed: onRetry, child: Text('Retry')),
      ],
    );
  }
}
```

#### Step 6.5: Update ChatScreen Error Handling
```dart
// lib/screens/chat_screen.dart
class _ChatScreenState extends ConsumerState<ChatScreen> {
  ChatError? _lastError;

  Future<void> _sendMessage() async {
    try {
      final apiClient = ref.read(clientProvider);
      await for (final event in apiClient.agent.streamChat(...)) {
        // ... handle events
      }
    } on SocketException catch (e) {
      _lastError = ChatError.network(e.toString());
      _addErrorMessage(_lastError!);
    } on TimeoutException catch (_) {
      _lastError = ChatError.timeout();
      _addErrorMessage(_lastError!);
    } on ClientException catch (e) {
      // Parse error type from response
      _lastError = _parseClientError(e);
      _addErrorMessage(_lastError!);
    } catch (e) {
      _lastError = ChatError(
        type: ChatErrorType.unknown,
        message: 'An unexpected error occurred',
        details: e.toString(),
      );
      _addErrorMessage(_lastError!);
    }
  }

  void _addErrorMessage(ChatError error) {
    setState(() {
      _messages.add(
        ChatMessage(
          role: MessageRole.assistant,
          content: '',
          error: error,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _retryLastMessage() async {
    if (_lastError?.isRetryable != true) return;

    // Remove error message
    setState(() {
      if (_messages.isNotEmpty && _messages.last.hasError) {
        _messages.removeLast();
      }
    });

    // Re-send last user message
    final lastUserMsg = _messages.reversed.firstWhere(
      (m) => m.role == MessageRole.user && !m.hasError,
    );

    await _resendMessage(lastUserMsg);
  }
}
```

---

## 10. File Operations in Chat

### Goals
- Drag & drop files into chat
- Preview images inline
- Quick file actions from @-tagged files

### Files to Create
| File | Purpose |
|------|---------|
| `lib/widgets/chat/file_drop_zone.dart` | Drag & drop overlay |
| `lib/widgets/chat/image_preview.dart` | Inline image preview |
| `lib/widgets/chat/attached_file_chip.dart` | File attachment display |
| `lib/widgets/chat/tagged_file_actions.dart` | Quick actions on @-tagged files |

### Files to Modify
| File | Changes |
|------|----------|
| `lib/screens/chat_screen.dart` | Handle file drop and attachments |
| `lib/widgets/chat/chat_input_area.dart` | Add drag target wrapper |
| `lib/models/chat/chat_message.dart` | Add attachments list |

### Implementation Steps

#### Step 10.1: Update ChatMessage for Attachments
```dart
// lib/models/chat/chat_message.dart
class ChatMessage {
  final List<ChatAttachment>? attachments; // NEW

  // For file references from context
  final List<TaggedFile>? referencedFiles; // NEW
}

class ChatAttachment {
  final String path;
  final String name;
  final String? mimeType;
  final int? size;
  final AttachmentType type;

  enum AttachmentType { image, document, other }
}
```

#### Step 10.2: Create File Drop Zone
```dart
// lib/widgets/chat/file_drop_zone.dart
class FileDropZone extends StatefulWidget {
  final Widget child;
  final ValueChanged<List<File>> onFilesDropped;

  @override
  Widget build(BuildContext context) {
    return DragTarget<File>(
      onAccept: (file) => onFilesDropped([file]),
      onAcceptWithDetails: (details) => onFilesDropped(details.files),
      builder: (context, candidateData, rejectedData) {
        final isDragging = candidateData.isNotEmpty;

        return Stack(
          children: [
            widget.child,
            if (isDragging)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_upload, size: 48),
                        Text('Drop files to attach'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
```

#### Step 10.3: Create Image Preview Widget
```dart
// lib/widgets/chat/image_preview.dart
class ImagePreview extends StatelessWidget {
  final File image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            image,
            height: 120,
            width: 120,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: Icon(Icons.close),
            onPressed: onRemove,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
```

#### Step 10.4: Create Tagged File Actions
```dart
// lib/widgets/chat/tagged_file_actions.dart
class TaggedFileActions extends StatelessWidget {
  final TaggedFile file;
  final VoidCallback onOpen;
  final VoidCallback onPreview;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      onSelected: (action) => _handleAction(action),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'open',
          child: ListTile(
            leading: Icon(Icons.open_in_new),
            title: Text('Open file'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (_isPreviewable(file))
          PopupMenuItem(
            value: 'preview',
            child: ListTile(
              leading: Icon(Icons.preview),
              title: Text('Preview'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        PopupMenuItem(
          value: 'copy_path',
          child: ListTile(
            leading: Icon(Icons.copy),
            title: Text('Copy path'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'remove',
          child: ListTile(
            leading: Icon(Icons.remove_circle, color: Colors.red),
            title: Text('Remove tag'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  bool _isPreviewable(TaggedFile file) {
    // Check if file is image, PDF, or text
    final ext = file.name.split('.').last.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'pdf', 'txt', 'md']
        .contains(ext);
  }
}
```

#### Step 10.5: Update ChatInputArea
```dart
// lib/widgets/chat/chat_input_area.dart
class ChatInputArea extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return FileDropZone(
      onFilesDropped: _handleFilesDropped,
      child: Container(
        // ... existing content
        child: Column(
          children: [
            // NEW: Attached files preview
            if (_attachedFiles.isNotEmpty)
              _buildAttachmentsPreview(),

            // Existing: Tagged files
            if (taggedFiles.isNotEmpty)
              _buildTaggedFiles(),

            // Input field
            TextField(...),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsPreview() {
    return Wrap(
      spacing: 8,
      children: _attachedFiles.map((file) {
        if (_isImage(file)) {
          return ImagePreview(
            image: file,
            onRemove: () => _removeAttachment(file),
          );
        }
        return AttachedFileChip(
          file: file,
          onRemove: () => _removeAttachment(file),
        );
      }).toList(),
    );
  }
}
```

#### Step 10.6: Update ChatScreen for File Handling
```dart
// lib/screens/chat_screen.dart
class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<File> _attachedFiles = [];

  void _handleFilesDropped(List<File> files) {
    setState(() {
      _attachedFiles.addAll(files);
    });
  }

  Future<void> _sendMessage() async {
    // Build message with attachments
    final message = ChatMessage(
      role: MessageRole.user,
      content: _messageController.text,
      attachments: _attachedFiles.map(_createAttachment).toList(),
      timestamp: DateTime.now(),
    );

    // Clear attachments after sending
    setState(() => _attachedFiles.clear());

    // Send to API with file context
    // ... rest of send logic
  }

  ChatAttachment _createAttachment(File file) {
    final name = file.path.split(RegExp(r'[\\/]')).last;
    return ChatAttachment(
      path: file.path,
      name: name,
      size: file.lengthSync(),
      type: _isImage(file) ? AttachmentType.image : AttachmentType.document,
    );
  }
}
```

---

## Implementation Order & Dependencies

### Phase 1: Foundation (Week 1)
1. **Message Persistence** - Foundation for everything else
2. **ChatMessage model updates** - Add IDs, error types, attachments

### Phase 2: Core Features (Week 2)
3. **Message Actions** - Build on persistence
4. **Better Error Handling** - Works with message actions

### Phase 3: Enhanced UX (Week 3)
5. **Better Input Experience** - Independent feature
6. **Streaming Performance** - Improves existing flow

### Phase 4: Content Rendering (Week 4)
7. **Code Block & Markdown Support** - Independent feature

### Phase 5: File Integration (Week 5)
8. **File Operations** - Completes the chat experience

---

## Testing Checklist

- [ ] Conversation saves correctly after each message
- [ ] Conversations load on app restart
- [ ] Create/delete/switch conversations works
- [ ] Copy button works for all message types
- [ ] Edit user message within 5 minutes
- [ ] Delete user message with confirmation
- [ ] Regenerate assistant response
- [ ] Reply/quote to specific message
- [ ] Auto-grow input field works
- [ ] Paste images/files attaches correctly
- [ ] Quick action chips insert templates
- [ ] Code blocks show syntax highlighting
- [ ] Code block copy button works
- [ ] Markdown renders correctly (headers, lists, tables)
- [ ] Streaming updates are smooth (debounced)
- [ ] Error messages show appropriate actions
- [ ] Retry works for failed messages
- [ ] Drag & drop files attaches to chat
- [ ] Image previews show inline

---

## Future Enhancements (Out of Scope)

- Voice input with speech recognition
- Conversation branching
- Export to PDF
- Share conversations via link
- Collaborative editing
- Message reactions/emojis
- Conversation search across history
- AI-suggested quick actions based on context
- Multi-language support
