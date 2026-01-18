import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation indices for HomeScreen tabs
class NavigationIndex {
  static const int home = 0;
  static const int index = 1;
  static const int chat = 2;
  static const int files = 3;
  static const int settings = 4;
}

/// Context data for navigating to chat with file context
class ChatNavigationContext {
  /// The file path to provide as context
  final String filePath;

  /// The file name for display
  final String fileName;

  /// Optional pre-filled message about the file
  final String? initialMessage;

  ChatNavigationContext({
    required this.filePath,
    required this.fileName,
    this.initialMessage,
  });
}

/// State for main navigation controller
class NavigationState {
  /// Currently selected tab index
  final int selectedIndex;

  /// Context for chat navigation (if navigating to chat with file context)
  final ChatNavigationContext? chatContext;

  NavigationState({
    this.selectedIndex = 0,
    this.chatContext,
  });

  NavigationState copyWith({
    int? selectedIndex,
    ChatNavigationContext? chatContext,
    bool clearChatContext = false,
  }) {
    return NavigationState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      chatContext: clearChatContext ? null : (chatContext ?? this.chatContext),
    );
  }
}

/// Notifier for navigation state changes
class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() {
    return NavigationState();
  }

  /// Navigate to a specific tab
  void navigateTo(int index) {
    state = state.copyWith(selectedIndex: index, clearChatContext: true);
  }

  /// Navigate to chat with file context
  void navigateToChatWithContext(ChatNavigationContext context) {
    state = NavigationState(
      selectedIndex: NavigationIndex.chat,
      chatContext: context,
    );
  }

  /// Clear chat context after it's been consumed
  void clearChatContext() {
    state = state.copyWith(clearChatContext: true);
  }
}

/// Provider for navigation state
final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(
      NavigationNotifier.new,
    );
