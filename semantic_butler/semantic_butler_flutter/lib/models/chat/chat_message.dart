import 'message_role.dart';
import 'tool_result.dart';

/// Message in the chat
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
