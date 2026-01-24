import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/chat/chat_message.dart';
import '../models/chat/conversation.dart';
import '../models/chat/message_role.dart';
import '../models/chat/tool_result.dart';
import 'chat_database.dart';
import '../utils/background_processor.dart';

class ChatStorageService {
  static const String _currentConversationKey = 'chat_current_id';
  final ChatDatabase _dbHelper = ChatDatabase();
  final BackgroundProcessor _backgroundProcessor = BackgroundProcessor();

  Future<void> saveConversation(Conversation conversation) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Save conversation metadata
      await txn.insert(
        'conversations',
        {
          'id': conversation.id,
          'title': conversation.title,
          'created_at': conversation.createdAt.toIso8601String(),
          'updated_at': conversation.updatedAt.toIso8601String(),
          'pinned_index': conversation.pinnedIndex,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save messages (latest ones)
      // Usually we only save the full list when it's small or we just save the new messages.
      // For this refactor, we'll ensure messages are saved individually.
      for (final message in conversation.messages) {
        await _saveMessageTxn(txn, message, conversation.id);
      }
    });
  }

  Future<void> addMessage(
    String conversationId,
    ChatMessage message, {
    String? updateTitle,
  }) async {
    final db = await _dbHelper.database;
    await _saveMessageTxn(db, message, conversationId);

    // Update conversation updatedAt and optionally title
    final Map<String, dynamic> updates = {
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (updateTitle != null) {
      updates['title'] = updateTitle;
    }

    await db.update(
      'conversations',
      updates,
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> _saveMessageTxn(
    dynamic dbOrTxn,
    ChatMessage message,
    String conversationId,
  ) async {
    final metadata = {
      'status_message': message.statusMessage,
      'current_tool': message.currentTool,
      'tools_used': message.toolsUsed,
      'tool_results': message.toolResults?.map((t) => t.toJson()).toList(),
      'tagged_files': message.taggedFiles,
      'attachments': message.attachments,
      'error': message.error?.toString(),
      'edited_at': message.editedAt?.toIso8601String(),
      'is_error': message.isError,
    };

    await dbOrTxn.insert(
      'messages',
      {
        'id': message.id,
        'conversation_id': conversationId,
        'role': message.role.name,
        'content': message.content,
        'timestamp': message.timestamp?.toIso8601String(),
        'is_edited': message.isEdited ? 1 : 0,
        'is_deleted': message.isDeleted ? 1 : 0,
        'reply_to_id': message.replyToId,
        'metadata': await _backgroundProcessor.encodeJson(metadata),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Conversation>> loadConversations() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      orderBy: 'updated_at DESC',
    );

    final List<Conversation> conversations = [];
    for (final map in maps) {
      // Note: We don't load ALL messages here to keep it efficient.
      // We load the conversation metadata first.
      conversations.add(
        Conversation(
          id: map['id'],
          title: map['title'],
          messages: [], // To be loaded on demand or just the latest few
          createdAt: DateTime.parse(map['created_at']),
          updatedAt: DateTime.parse(map['updated_at']),
          pinnedIndex: map['pinned_index'],
        ),
      );
    }
    return conversations;
  }

  Future<List<ChatMessage>> loadMessages(
    String conversationId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return Future.wait(
      maps.map((map) async {
        final metadata = await _backgroundProcessor.decodeJson(
          map['metadata'] ?? '{}',
        );
        return ChatMessage(
          id: map['id'],
          role: MessageRole.values.firstWhere((e) => e.name == map['role']),
          content: map['content'],
          timestamp: map['timestamp'] != null
              ? DateTime.parse(map['timestamp'])
              : null,
          isEdited: map['is_edited'] == 1,
          isDeleted: map['is_deleted'] == 1,
          replyToId: map['reply_to_id'],
          statusMessage: metadata['status_message'],
          currentTool: metadata['current_tool'],
          toolsUsed: metadata['tools_used'],
          toolResults: metadata['tool_results'] != null
              ? (metadata['tool_results'] as List)
                    .map((t) => ToolResult.fromJson(t))
                    .toList()
              : null,
          taggedFiles: metadata['tagged_files'] != null
              ? List<String>.from(metadata['tagged_files'])
              : null,
          attachments: metadata['attachments'] != null
              ? List<Map<String, dynamic>>.from(metadata['attachments'])
              : null,
          editedAt: metadata['edited_at'] != null
              ? DateTime.parse(metadata['edited_at'])
              : null,
          isError: _parseBool(metadata['is_error']),
        );
      }),
    ).then((list) => list.reversed.toList());
  }

  Future<void> deleteConversation(String id) async {
    final db = await _dbHelper.database;
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
    // CASCADE delete should handle messages
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await _dbHelper.database;
    await db.delete('messages', where: 'id = ?', whereArgs: [messageId]);
  }

  Future<int> getMessageOffset(String conversationId, String messageId) async {
    final db = await _dbHelper.database;
    // Count messages more recent than the given message to find its offset in DESC order
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM messages 
      WHERE conversation_id = ? AND timestamp > (
        SELECT timestamp FROM messages WHERE id = ?
      )
      ''',
      [conversationId, messageId],
    );

    return result.first['count'] as int;
  }

  Future<String?> getCurrentConversationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentConversationKey);
  }

  Future<void> setCurrentConversationId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentConversationKey, id);
  }

  Future<void> clearCurrentConversationId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentConversationKey);
  }

  Future<List<Map<String, dynamic>>> searchMessages(String query) async {
    if (query.trim().isEmpty) return [];
    final db = await _dbHelper.database;

    // Use FTS5 MATCH query for deep, high-performance keyword searching
    // We join back to the original messages/conversations for full metadata
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT m.*, c.title as conversation_title 
      FROM messages_search fts
      JOIN messages m ON fts.message_id = m.id
      JOIN conversations c ON m.conversation_id = c.id
      WHERE messages_search MATCH ? AND m.is_deleted = 0
      ORDER BY m.timestamp DESC
      LIMIT 100
    ''',
      ['$query*'], // Prefix matching for better search-as-you-type feel
    );

    return results;
  }

  Future<void> renameConversation(String id, String newTitle) async {
    final db = await _dbHelper.database;
    await db.update(
      'conversations',
      {'title': newTitle, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

/// Helper to safely parse boolean values from JSON that might be stored as
/// double (0.0/1.0), int (0/1), or bool.
bool _parseBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return defaultValue;
}
