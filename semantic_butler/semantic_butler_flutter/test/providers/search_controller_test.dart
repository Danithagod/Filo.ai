// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import 'package:semantic_butler_flutter/main.dart';
import 'package:semantic_butler_flutter/providers/search_controller.dart' as sc;
import 'package:semantic_butler_flutter/providers/search_controller.dart';

// Manual Mocks

// Helper to create a dummy client for the super constructor
Client _createDummyClient() {
  return Client('http://dummy/', authenticationKeyManager: null);
}

class MockButler extends EndpointButler {
  MockButler() : super(_createDummyClient());

  final List<SearchResult> _mockHybridResults = [];
  final List<AISearchProgress> _mockAiProgress = [];
  String? _mockError;

  void setHybridResults(List<SearchResult> results) {
    _mockHybridResults.clear();
    _mockHybridResults.addAll(results);
  }

  void setAiProgress(List<AISearchProgress> progress) {
    _mockAiProgress.clear();
    _mockAiProgress.addAll(progress);
  }

  void setMockError(String? error) {
    _mockError = error;
  }

  @override
  Future<List<SearchResult>> hybridSearch(
    String query, {
    double? threshold,
    int? limit,
    int? offset,
    double? semanticWeight,
    double? keywordWeight,
    SearchFilters? filters,
  }) async {
    if (_mockError != null) throw Exception(_mockError);
    return _mockHybridResults;
  }

  @override
  Future<List<SearchResult>> semanticSearch(
    String query, {
    required int limit,
    required double threshold,
    required int offset,
    SearchFilters? filters,
  }) async {
    if (_mockError != null) throw Exception(_mockError);
    return _mockHybridResults;
  }

  @override
  Stream<SearchResult> semanticSearchStream(
    String query, {
    required int limit,
    required double threshold,
    required int offset,
    SearchFilters? filters,
  }) {
    return Stream.fromIterable(_mockHybridResults);
  }

  @override
  Stream<AISearchProgress> aiSearch(
    String query, {
    String? strategy,
    int? maxResults,
    SearchFilters? filters,
  }) {
    if (_mockError != null) {
      return Stream.error(Exception(_mockError));
    }
    return Stream.fromIterable(_mockAiProgress);
  }

  @override
  Future<List<SearchFacet>> getSearchFacets(
    String query, {
    SearchFilters? filters,
  }) async {
    return [];
  }
}

class MockClient extends Client {
  final MockButler _mockButler;

  MockClient(this._mockButler)
    : super('http://localhost:8080/', authenticationKeyManager: null);

  @override
  MockButler get butler => _mockButler;
}

void main() {
  late MockButler mockButler;
  late MockClient mockClient;

  setUp(() {
    mockButler = MockButler();
    mockClient = MockClient(mockButler);
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        clientProvider.overrideWithValue(mockClient),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SearchController', () {
    test('initial state is correct', () {
      final container = createContainer();
      final state = container.read(searchControllerProvider);
      expect(state.query, '');
      expect(state.results, isEmpty);
      expect(state.isLoading, false);
      expect(state.mode, sc.SearchMode.hybrid);
    });

    test('init updates state and performs search if query not empty', () async {
      final container = createContainer();
      final controller = container.read(searchControllerProvider.notifier);

      mockButler.setHybridResults([
        SearchResult(
          id: 1,
          relevanceScore: 0.9,
          contentPreview: 'Test content',
          path: '/path/to/file.txt',
          fileName: 'Test File',
          indexedAt: DateTime.now(),
          tags: [],
          fileSizeBytes: 1024,
        ),
      ]);

      controller.init('test query', sc.SearchMode.hybrid, null);

      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(searchControllerProvider);
      expect(state.query, 'test query');
      expect(state.mode, sc.SearchMode.hybrid);
      expect(state.results.length, 1);
      expect(state.results.first.fileName, 'Test File');
    });

    test('validation prevents empty search', () async {
      final container = createContainer();
      final controller = container.read(searchControllerProvider.notifier);

      await controller.performSearch(query: '   ');

      final state = container.read(searchControllerProvider);
      expect(state.error, 'Please enter a search query');
      expect(state.isLoading, false);
    });

    test('ai search updates progress and results', () async {
      final container = createContainer();
      final controller = container.read(searchControllerProvider.notifier);

      mockButler.setAiProgress([
        AISearchProgress(type: 'thinking', message: 'Analyzing...'),
        AISearchProgress(
          type: 'searching',
          message: 'Found results',
          results: [
            AISearchResult(
              path: '/path/ai.txt',
              fileName: 'ai.txt',
              isDirectory: false,
              source: 'index',
              relevanceScore: 0.8,
              matchReason: 'Found it',
              suggestedQuery: 'better query',
              tags: [],
            ),
          ],
        ),
        AISearchProgress(
          type: 'complete',
          results: [
            AISearchResult(
              path: '/path/ai.txt',
              fileName: 'ai.txt',
              isDirectory: false,
              source: 'index',
              relevanceScore: 0.8,
              matchReason: 'Found it',
              suggestedQuery: 'better query',
              tags: [],
            ),
          ],
        ),
      ]);

      await controller.performSearch(query: 'ai query', mode: sc.SearchMode.ai);

      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(searchControllerProvider);
      expect(state.mode, sc.SearchMode.ai);
      expect(state.results.length, 1);
      // Wait, list might grow if duplicate results are added from searching and complete?
      // SearchController logic: newResults = state.results; if (progress.results != null) ...
      // If same path, logic: .where((r) => paths.add(r.path)) deduplicates?
      // Controller logic:
      //  if (progress.results != null && progress.results!.isNotEmpty) {
      //           final Set<String> paths = {};
      //           newResults = progress.results!
      //               .map((r) {
      //                 return UnifiedSearchResult.fromAISearchResult(r);
      //               })
      //               .where((r) => paths.add(r.path))
      //               .toList();
      //  }
      // It REPLACES newResults with latest progress.results!
      // It does NOT append.
      // So if 'searching' event has results, and 'complete' event has same results, it's fine.

      expect(state.results.first.fileName, 'ai.txt');
      expect(state.suggestedQuery, 'better query');
      expect(state.isLoading, false);
      expect(state.progressHistory.length, isNotEmpty);
    });

    test(
      'error fallback triggers traditional search on transient error',
      () async {
        final container = createContainer();
        final controller = container.read(searchControllerProvider.notifier);

        mockButler.setMockError('Connection timeout');
        mockButler.setHybridResults([
          SearchResult(
            id: 3,
            relevanceScore: 0.7,
            contentPreview: 'Fallback Content',
            path: '/path/fallback.txt',
            fileName: 'fallback.txt',
            indexedAt: DateTime.now(),
            tags: [],
            fileSizeBytes: 2048,
          ),
        ]);

        await controller.performSearch(
          query: 'fail query',
          mode: sc.SearchMode.ai,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        final state = container.read(searchControllerProvider);

        expect(state.mode, sc.SearchMode.hybrid);
      },
    );
  });
}
