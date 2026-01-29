import 'package:test/test.dart';
import 'package:semantic_butler_server/src/services/search_conversation_provider.dart';

void main() {
  group('SearchConversationProvider Tests', () {
    late SearchConversationProvider provider;

    setUp(() {
      provider = SearchConversationProvider.instance;
      // Clear sessions if possible, or use unique IDs for each test
    });

    test('Should add turns and retrieve context', () {
      final sessionId = 'test_session_1';
      provider.addTurn(sessionId, 'find pdfs', 'Found 2 results');

      final context = provider.getContextForAI(sessionId);
      expect(context, contains('find pdfs'));
      expect(context, contains('Previous search context'));
    });

    test('Should handle multiple turns', () {
      final sessionId = 'test_session_2';
      provider.addTurn(sessionId, 'query 1', null);
      provider.addTurn(sessionId, 'query 2', null);

      final context = provider.getContextForAI(sessionId);
      expect(context, contains('query 1'));
      expect(context, contains('query 2'));
    });

    test('Should clear session', () {
      final sessionId = 'test_session_3';
      provider.addTurn(sessionId, 'temp', null);
      provider.clearSession(sessionId);

      final context = provider.getContextForAI(sessionId);
      expect(context, isEmpty);
    });

    test('Non-existent session returns empty context', () {
      expect(provider.getContextForAI('non_existent'), isEmpty);
    });
  });
}
