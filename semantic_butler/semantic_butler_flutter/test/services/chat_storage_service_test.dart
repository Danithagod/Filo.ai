import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:semantic_butler_flutter/models/chat/chat_message.dart';
import 'package:semantic_butler_flutter/models/chat/conversation.dart';
import 'package:semantic_butler_flutter/models/chat/message_role.dart';
import 'package:semantic_butler_flutter/services/chat_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String _path = Directory.systemTemp.createTempSync().path;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return _path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
    SharedPreferences.setMockInitialValues({});
  });

  group('ChatStorageService', () {
    test('save and load conversation', () async {
      final service = ChatStorageService();

      final conversation = Conversation(
        id: 'test_id',
        title: 'Test Chat',
        messages: [
          ChatMessage(
            role: MessageRole.user,
            content: 'Hello',
            timestamp: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.saveConversation(conversation);

      final loaded = await service.loadConversations();
      expect(loaded.length, 1);
      expect(loaded.first.id, conversation.id);
      expect(loaded.first.title, conversation.title);
      expect(loaded.first.messages.length, 1);
      expect(loaded.first.messages.first.content, 'Hello');
    });

    test('delete conversation', () async {
      final service = ChatStorageService();
      final conversation = Conversation(
        id: 'delete_id',
        title: 'Delete Chat',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.saveConversation(conversation);
      await service.deleteConversation(conversation.id);

      final loaded = await service.loadConversations();
      expect(loaded.isEmpty, true);
    });
  });
}
