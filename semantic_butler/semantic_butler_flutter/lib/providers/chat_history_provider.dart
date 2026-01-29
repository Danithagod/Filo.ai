import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/chat/chat_message.dart';
import '../models/chat/conversation.dart';
import '../services/chat_storage_service.dart';
import '../utils/app_logger.dart';

final chatStorageServiceProvider = Provider<ChatStorageService>((ref) {
  return ChatStorageService();
});

final chatHistoryProvider =
    AsyncNotifierProvider<ChatHistoryNotifier, ChatHistoryState>(
      ChatHistoryNotifier.new,
    );

class ChatHistoryState {
  final List<Conversation> conversations;
  final String? currentConversationId;
  final Conversation? currentConversation;
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final int currentOffset;
  final ChatMessage? streamingMessage;

  ChatHistoryState({
    required this.conversations,
    required this.currentConversationId,
    required this.currentConversation,
    this.isLoadingMore = false,
    this.hasMoreMessages = false,
    this.currentOffset = 0,
    this.streamingMessage,
  });

  ChatHistoryState copyWith({
    List<Conversation>? conversations,
    String? currentConversationId,
    Conversation? currentConversation,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    int? currentOffset,
    ChatMessage? streamingMessage,
    bool clearStreamingMessage = false,
  }) {
    return ChatHistoryState(
      conversations: conversations ?? this.conversations,
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      currentConversation: currentConversation ?? this.currentConversation,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      currentOffset: currentOffset ?? this.currentOffset,
      streamingMessage: clearStreamingMessage
          ? null
          : (streamingMessage ?? this.streamingMessage),
    );
  }
}

class ChatHistoryNotifier extends AsyncNotifier<ChatHistoryState> {
  late final ChatStorageService _storageService;
  static const int _pageSize = 20;

  @override
  Future<ChatHistoryState> build() async {
    _storageService = ref.read(chatStorageServiceProvider);

    final conversations = await _storageService.loadConversations();
    final currentId = await _storageService.getCurrentConversationId();

    Conversation? current;
    bool hasMore = false;

    if (currentId != null) {
      try {
        current = conversations.firstWhere((c) => c.id == currentId);
        // Load first page of messages
        final messages = await _storageService.loadMessages(
          currentId,
          limit: _pageSize,
        );
        current = current.copyWith(messages: messages);
        hasMore = messages.length == _pageSize;
      } catch (e) {
        // Reset if not found
      }
    }

    if (current == null) {
      await _storageService.clearCurrentConversationId();
      return ChatHistoryState(
        conversations: conversations,
        currentConversationId: null,
        currentConversation: null,
      );
    }

    return ChatHistoryState(
      conversations: conversations,
      currentConversationId: currentId,
      currentConversation: current,
      hasMoreMessages: hasMore,
      currentOffset: 0,
    );
  }

  Future<void> createNewConversation() async {
    final state = await future;

    final newId = const Uuid().v4();
    final newConversation = Conversation(
      id: newId,
      title: 'New Chat',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storageService.saveConversation(newConversation);
    AppLogger.info(
      'Created and saved new conversation: $newId',
      tag: 'ChatHistory',
    );
    await _storageService.setCurrentConversationId(newId);

    final newConversations = [newConversation, ...state.conversations];

    update(
      (state) => state.copyWith(
        conversations: newConversations,
        currentConversationId: newId,
        currentConversation: newConversation,
        hasMoreMessages: false,
        currentOffset: 0,
      ),
    );
  }

  Future<void> selectConversation(String id, {String? initialMessageId}) async {
    final state = await future;
    if (state.currentConversationId == id && initialMessageId == null) return;

    try {
      final conversations = state.conversations;
      Conversation selected = conversations.firstWhere((c) => c.id == id);

      await _storageService.setCurrentConversationId(id);

      int loadLimit = _pageSize;
      int offset = 0;

      if (initialMessageId != null) {
        final messageOffset = await _storageService.getMessageOffset(
          id,
          initialMessageId,
        );
        // Load up to the page containing the message
        if (messageOffset >= _pageSize) {
          loadLimit =
              messageOffset + 10; // Load everything up to message + some buffer
        }
      }

      // Load messages
      final messages = await _storageService.loadMessages(
        id,
        limit: loadLimit,
        offset: offset,
      );
      selected = selected.copyWith(messages: messages);

      update(
        (state) => state.copyWith(
          currentConversationId: id,
          currentConversation: selected,
          hasMoreMessages: messages.length >= loadLimit,
          currentOffset: 0,
        ),
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> setStreamingMessage(ChatMessage? message) async {
    update(
      (state) => state.copyWith(
        streamingMessage: message,
        clearStreamingMessage: message == null,
      ),
    );
  }

  Future<void> loadMoreMessages() async {
    final state = await future;
    if (state.currentConversationId == null ||
        state.isLoadingMore ||
        !state.hasMoreMessages) {
      return;
    }

    update((state) => state.copyWith(isLoadingMore: true));

    final nextOffset = state.currentOffset + _pageSize;
    final moreMessages = await _storageService.loadMessages(
      state.currentConversationId!,
      limit: _pageSize,
      offset: nextOffset,
    );

    final updatedConversation = state.currentConversation!.copyWith(
      messages: [...moreMessages, ...state.currentConversation!.messages],
    );

    update(
      (state) => state.copyWith(
        currentConversation: updatedConversation,
        isLoadingMore: false,
        hasMoreMessages: moreMessages.length == _pageSize,
        currentOffset: nextOffset,
      ),
    );
  }

  Future<void> addMessage(ChatMessage message) async {
    final state = await future;

    if (state.currentConversation == null) {
      AppLogger.info(
        'No current conversation, creating one before adding message',
        tag: 'ChatHistory',
      );
      await createNewConversation();
    }

    final currentState = await future;
    final currentConversation = currentState.currentConversation!;

    String title = currentConversation.title;
    if (currentConversation.messages.isEmpty && message.role.name == 'user') {
      title = Conversation.generateTitle(message.content);
    }

    // Save to DB
    await _storageService.addMessage(
      currentConversation.id,
      message,
      updateTitle: title != currentConversation.title ? title : null,
    );

    final updatedMessages = [...currentConversation.messages, message];
    final updatedConversation = currentConversation.copyWith(
      title: title,
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    // Update list
    final updatedList = currentState.conversations.map((c) {
      return c.id == updatedConversation.id ? updatedConversation : c;
    }).toList();
    updatedList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    update(
      (state) => state.copyWith(
        conversations: updatedList,
        currentConversationId: updatedConversation.id,
        currentConversation: updatedConversation,
      ),
    );
  }

  Future<void> clearHistory() async {
    final state = await future;
    for (var c in state.conversations) {
      await _storageService.deleteConversation(c.id);
    }
    await _storageService.clearCurrentConversationId();

    update(
      (state) => ChatHistoryState(
        conversations: [],
        currentConversationId: null,
        currentConversation: null,
      ),
    );
  }

  Future<void> deleteConversation(String id) async {
    final state = await future;
    await _storageService.deleteConversation(id);

    final updatedList = state.conversations.where((c) => c.id != id).toList();

    String? newCurrentId = state.currentConversationId;
    Conversation? newCurrentConversation = state.currentConversation;

    if (state.currentConversationId == id) {
      newCurrentId = null;
      newCurrentConversation = null;
      await _storageService.clearCurrentConversationId();

      if (updatedList.isNotEmpty) {
        newCurrentId = updatedList.first.id;
        final messages = await _storageService.loadMessages(
          newCurrentId,
          limit: _pageSize,
        );
        newCurrentConversation = updatedList.first.copyWith(messages: messages);
        await _storageService.setCurrentConversationId(newCurrentId);
      }
    }

    update(
      (state) => state.copyWith(
        conversations: updatedList,
        currentConversationId: newCurrentId,
        currentConversation: newCurrentConversation,
        hasMoreMessages:
            (newCurrentConversation?.messages.length ?? 0) == _pageSize,
        currentOffset: 0,
      ),
    );
  }

  Future<void> dismissMessage(String messageId) async {
    final state = await future;
    await _storageService.deleteMessage(messageId);

    if (state.currentConversation != null) {
      final updatedMessages = state.currentConversation!.messages
          .where((m) => m.id != messageId)
          .toList();

      update(
        (state) => state.copyWith(
          currentConversation: state.currentConversation!.copyWith(
            messages: updatedMessages,
          ),
        ),
      );
    }
  }

  Future<void> renameConversation(String id, String title) async {
    final state = await future;
    await _storageService.renameConversation(id, title);

    final updatedList = state.conversations.map((c) {
      if (c.id == id) {
        return c.copyWith(title: title, updatedAt: DateTime.now());
      }
      return c;
    }).toList();

    Conversation? updatedCurrent = state.currentConversation;
    if (state.currentConversationId == id) {
      updatedCurrent = state.currentConversation!.copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
    }

    update(
      (state) => state.copyWith(
        conversations: updatedList,
        currentConversation: updatedCurrent,
      ),
    );
  }
}
