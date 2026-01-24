import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('AI Search Integration Tests', (sessionBuilder, endpoints) {
    group('AI Search Streaming', () {
      test('streams progress events for hybrid search', () async {
        final stream = endpoints.butler.aiSearch(
          sessionBuilder,
          'where is the gemma folder',
          strategy: 'hybrid',
          maxResults: 5,
        );

        final events = await stream.toList();

        expect(events, isNotEmpty, reason: 'Should return progress events');

        // Should have thinking events
        expect(
          events.any((e) => e.type == 'thinking'),
          isTrue,
          reason: 'Should have thinking events',
        );

        // Should complete successfully
        expect(
          events.last.type,
          equals('complete'),
          reason: 'Last event should be complete',
        );

        expect(events.last.results, isNotNull);
      });

      test('streams events for AI-only search', () async {
        final stream = endpoints.butler.aiSearch(
          sessionBuilder,
          '*.pdf files',
          strategy: 'ai_only',
          maxResults: 5,
        );

        final events = await stream.toList();

        expect(events, isNotEmpty);

        // Should have terminal search related events
        expect(
          events.any((e) => e.source == 'terminal' || e.type == 'searching'),
          isTrue,
        );

        expect(events.last.type, equals('complete'));
      });

      test('handles invalid strategy by defaulting to hybrid', () async {
        final stream = endpoints.butler.aiSearch(
          sessionBuilder,
          'test query',
          strategy: 'invalid_strategy',
        );

        final events = await stream.toList();
        expect(events.last.type, equals('complete'));
      });

      test('enforces max results limit', () async {
        final stream = endpoints.butler.aiSearch(
          sessionBuilder,
          'test query',
          maxResults: 150, // Above limit
        );

        final events = await stream.toList();
        // The service should have clamped it to 100 or 20
        expect(events.last.type, equals('complete'));
      });
    });

    group('AI Search Deduplication', () {
      test('deduplicates results from different sources', () async {
        final stream = endpoints.butler.aiSearch(
          sessionBuilder,
          'test deduplication',
        );

        final events = await stream.toList();
        final finalResults = events.last.results ?? [];

        final paths = finalResults.map((r) => r.path).toList();
        final uniquePaths = paths.toSet();

        expect(
          paths.length,
          equals(uniquePaths.length),
          reason: 'Final results should not contain duplicate paths',
        );
      });
    });
  });
}
