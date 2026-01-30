import 'package:flutter/material.dart';

/// Types of errors that can occur during chat
enum ChatErrorType {
  network,
  timeout,
  apiRateLimit,
  apiAuth,
  apiServer,
  streamingLost,
  unknown,
}

/// Typed error class for chat operations
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

  /// Factory constructor for network errors
  factory ChatError.network([String? details]) {
    return ChatError(
      type: ChatErrorType.network,
      message: 'Network connection failed',
      details: details,
      isRetryable: true,
      timestamp: DateTime.now(),
    );
  }

  /// Factory constructor for timeout errors
  factory ChatError.timeout() {
    return ChatError(
      type: ChatErrorType.timeout,
      message: 'Request timed out',
      isRetryable: true,
      timestamp: DateTime.now(),
    );
  }

  /// Factory constructor for API rate limit errors
  factory ChatError.rateLimit() {
    return ChatError(
      type: ChatErrorType.apiRateLimit,
      message: 'Too many requests. Please wait a moment.',
      isRetryable: true,
      timestamp: DateTime.now(),
    );
  }

  /// Factory constructor for authentication errors
  factory ChatError.auth([String? details]) {
    return ChatError(
      type: ChatErrorType.apiAuth,
      message: 'Authentication failed',
      details: details,
      isRetryable: false,
      timestamp: DateTime.now(),
    );
  }

  /// Factory constructor for server errors
  factory ChatError.server([String? details]) {
    return ChatError(
      type: ChatErrorType.apiServer,
      message: 'Server error occurred',
      details: details,
      isRetryable: true,
      timestamp: DateTime.now(),
    );
  }

  /// Factory constructor for streaming lost errors
  factory ChatError.streamingLost() {
    return ChatError(
      type: ChatErrorType.streamingLost,
      message: 'Connection lost during streaming',
      isRetryable: true,
      timestamp: DateTime.now(),
    );
  }

  /// Factory constructor for unknown errors
  factory ChatError.unknown(String details) {
    return ChatError(
      type: ChatErrorType.unknown,
      message: 'An unexpected error occurred',
      details: details,
      isRetryable: true,
      timestamp: DateTime.now(),
    );
  }

  /// User-friendly message for display
  String get userMessage {
    switch (type) {
      case ChatErrorType.network:
        return 'No internet connection. Please check your network.';
      case ChatErrorType.timeout:
        return 'The request took too long. Please try again.';
      case ChatErrorType.apiRateLimit:
        return 'Too many requests. Please wait a moment before trying again.';
      case ChatErrorType.apiAuth:
        return 'AI features require an API key. Please add your OpenRouter API key to the .env file in the server folder.';
      case ChatErrorType.apiServer:
        return 'Server error. Please try again later.';
      case ChatErrorType.streamingLost:
        return 'Connection was interrupted. Please try again.';
      case ChatErrorType.unknown:
        return message;
    }
  }

  /// Suggested actions based on error type
  List<String> get suggestedActions {
    switch (type) {
      case ChatErrorType.network:
        return ['Check connection', 'Retry'];
      case ChatErrorType.timeout:
        return ['Try again', 'Check server status'];
      case ChatErrorType.apiRateLimit:
        return ['Wait', 'Retry'];
      case ChatErrorType.apiAuth:
        return ['Add API key to .env', 'Restart server'];
      case ChatErrorType.apiServer:
        return ['Retry', 'Contact support'];
      case ChatErrorType.streamingLost:
        return ['Retry'];
      case ChatErrorType.unknown:
        return ['Retry'];
    }
  }

  /// Icon for the error type
  IconData get icon {
    switch (type) {
      case ChatErrorType.network:
        return Icons.wifi_off;
      case ChatErrorType.timeout:
        return Icons.access_time;
      case ChatErrorType.apiRateLimit:
        return Icons.speed;
      case ChatErrorType.apiAuth:
        return Icons.lock;
      case ChatErrorType.apiServer:
        return Icons.cloud_off;
      case ChatErrorType.streamingLost:
        return Icons.sync_problem;
      case ChatErrorType.unknown:
        return Icons.error_outline;
    }
  }

  /// Color for the error type
  Color color(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case ChatErrorType.apiAuth:
        return colorScheme.error;
      case ChatErrorType.apiServer:
        return colorScheme.error;
      default:
        return colorScheme.error;
    }
  }

  @override
  String toString() => 'ChatError($type: $message)';
}
