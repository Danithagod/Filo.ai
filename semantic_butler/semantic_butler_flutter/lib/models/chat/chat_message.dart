import 'message_role.dart';
import 'tool_result.dart';
import 'chat_error.dart';
import '../../utils/chat_constants.dart';

/// Message in the chat
class ChatMessage {
  final String? id;
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

  // Persistence fields
  final bool isEdited;
  final bool isDeleted;
  final String? replyToId;
  final DateTime? editedAt;

  // Error handling (NEW)
  final ChatError? error;

  // Attachments (NEW) - list of file paths or metadata
  final List<Map<String, dynamic>>? attachments;

  ChatMessage({
    this.id,
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
    this.isEdited = false,
    this.isDeleted = false,
    this.replyToId,
    this.editedAt,
    this.error,
    this.attachments,
  });

  /// Check if message can be edited (user messages, within 5 minutes)
  bool get canEdit {
    if (role != MessageRole.user || isStreaming || isDeleted) return false;
    if (timestamp == null) return true;
    return DateTime.now().difference(timestamp!) <
        ChatConstants.editWindowDuration;
  }

  /// Check if message can be deleted
  bool get canDelete => role == MessageRole.user && !isStreaming;

  /// Check if assistant response can be regenerated
  bool get canRegenerate => role == MessageRole.assistant && !isStreaming;

  /// Check if message has an error
  bool get hasError => error != null || isError;

  /// Check if error is retryable
  bool get isRetryable => error?.isRetryable ?? false;

  ChatMessage copyWith({
    String? id,
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
    bool? isEdited,
    bool? isDeleted,
    String? replyToId,
    DateTime? editedAt,
    ChatError? error,
    List<Map<String, dynamic>>? attachments,
  }) {
    return ChatMessage(
      id: id ?? this.id,
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
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToId: replyToId ?? this.replyToId,
      editedAt: editedAt ?? this.editedAt,
      error: error ?? this.error,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'tools_used': toolsUsed,
      'is_error': isError,
      // 'is_streaming': isStreaming, // Don't persist streaming state
      'status_message': statusMessage,
      'current_tool': currentTool,
      'tool_results': toolResults?.map((t) => t.toJson()).toList(),
      'timestamp': timestamp?.toIso8601String(),
      'tagged_files': taggedFiles,
      'is_edited': isEdited,
      'is_deleted': isDeleted,
      'reply_to_id': replyToId,
      'edited_at': editedAt?.toIso8601String(),
      'error': error?.toString(),
      'attachments': attachments,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      role: MessageRole.values.firstWhere((e) => e.name == json['role']),
      content: json['content'],
      toolsUsed: json['tools_used'],
      isError: _parseBool(json['is_error']),
      isStreaming: false, // Always false when loading from storage
      statusMessage: json['status_message'],
      currentTool: json['current_tool'],
      toolResults: (json['tool_results'] as List?)
          ?.map((t) => ToolResult.fromJson(t))
          .toList(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
      taggedFiles: (json['tagged_files'] as List?)?.cast<String>(),
      isEdited: _parseBool(json['is_edited']),
      isDeleted: _parseBool(json['is_deleted']),
      replyToId: json['reply_to_id'],
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'])
          : null,
      error: json['error'] != null
          ? ChatError.unknown(json['error'] as String)
          : null,
      attachments: (json['attachments'] as List?)?.cast<Map<String, dynamic>>(),
    );
  }

  /// Helper to safely parse boolean values from JSON that might be stored as
  /// double (0.0/1.0), int (0/1), or bool.
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
}
