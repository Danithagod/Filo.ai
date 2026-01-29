import 'dart:io';
import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';
import 'package:serverpod/serverpod.dart';

void main() {
  withServerpod('Vector Search Integration Tests', (sessionBuilder, endpoints) {
    String testFilePath1;
    String testFilePath2;
    String testFilePath3;

    setUpAll(() async {
      final testDir = Directory.systemTemp.createTempSync(
        'vector_search_test_',
      );

      testFilePath1 = '${testDir.path}/document1.txt';
      testFilePath2 = '${testDir.path}/document2.txt';
      testFilePath3 = '${testDir.path}/document3.txt';

      final file1 = File(testFilePath1);
      final file2 = File(testFilePath2);
      final file3 = File(testFilePath3);

      file1.writeAsStringSync(
        'Python programming language tutorial for beginners. '
        'Learn Python basics, variables, functions, and object-oriented programming concepts.',
      );

      file2.writeAsStringSync(
        'JavaScript web development guide. '
        'Create interactive websites using HTML, CSS, and JavaScript frameworks.',
      );

      file3.writeAsStringSync(
        'Data science with Python. '
        'Use Python for machine learning, data analysis, and visualization with libraries like pandas and numpy.',
      );
    });

    tearDownAll(() async {
      if (Directory.systemTemp.existsSync()) {
        Directory.systemTemp.deleteSync(recursive: true);
      }
    });

    group('Vector search finds relevant results', () {
      test(
        'when searching for Python then returns Python-related documents',
        () async {
          final session = await Serverpod.instance.createSession();
          await endpoints.butler.startIndexing(
            sessionBuilder,
            Directory.systemTemp.path,
          );
          await Future.delayed(Duration(seconds: 45));

          final results = await endpoints.butler.semanticSearch(
            sessionBuilder,
            'Python programming',
            limit: 10,
            threshold: 0.1,
            offset: 0,
          );

          expect(results, isNotEmpty, reason: 'Should return search results');
          expect(results.length, greaterThan(0));

          final pythonDocs = results.where(
            (r) => r.contentPreview?.toLowerCase().contains('python') ?? false,
          );
          expect(
            pythonDocs.length,
            greaterThanOrEqualTo(2),
            reason: 'Should find at least 2 Python-related documents',
          );
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );

      test(
        'when searching for JavaScript then returns JavaScript documents',
        () async {
          final session = await Serverpod.instance.createSession();
          await endpoints.butler.startIndexing(
            sessionBuilder,
            Directory.systemTemp.path,
          );
          await Future.delayed(Duration(seconds: 20));

          final results = await endpoints.butler.semanticSearch(
            sessionBuilder,
            'JavaScript web development',
            limit: 10,
            threshold: 0.1,
            offset: 0,
          );

          expect(results, isNotEmpty);

          final jsDocs = results.where(
            (r) =>
                r.contentPreview?.toLowerCase().contains('javascript') ?? false,
          );
          expect(
            jsDocs.length,
            equals(1),
            reason: 'Should find 1 JavaScript document',
          );
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );
    });

    group('Vector search filters by threshold', () {
      test(
        'when threshold is high then returns only highly relevant results',
        () async {
          final session = await Serverpod.instance.createSession();
          await endpoints.butler.startIndexing(
            sessionBuilder,
            Directory.systemTemp.path,
          );
          await Future.delayed(Duration(seconds: 20));

          final results = await endpoints.butler.semanticSearch(
            sessionBuilder,
            'Python data science',
            limit: 10,
            threshold: 0.8,
            offset: 0,
          );

          expect(results, isNotEmpty);

          for (final result in results) {
            expect(
              result.relevanceScore,
              greaterThanOrEqualTo(0.8),
              reason:
                  'All results should meet threshold: ${result.relevanceScore}',
            );
          }
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );

      test(
        'when threshold is low then returns more results',
        () async {
          final session = await Serverpod.instance.createSession();
          await endpoints.butler.startIndexing(
            sessionBuilder,
            Directory.systemTemp.path,
          );
          await Future.delayed(Duration(seconds: 20));

          final lowThresholdResults = await endpoints.butler.semanticSearch(
            sessionBuilder,
            'programming',
            limit: 10,
            threshold: 0.1,
            offset: 0,
          );

          final highThresholdResults = await endpoints.butler.semanticSearch(
            sessionBuilder,
            'programming',
            limit: 10,
            threshold: 0.7,
            offset: 0,
          );

          expect(
            lowThresholdResults.length,
            greaterThanOrEqualTo(highThresholdResults.length),
            reason: 'Lower threshold should return equal or more results',
          );
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );
    });

    group('Vector search respects limit', () {
      test(
        'when limit is specified then returns at most that many results',
        () async {
          final session = await Serverpod.instance.createSession();
          await endpoints.butler.startIndexing(
            sessionBuilder,
            Directory.systemTemp.path,
          );
          await Future.delayed(Duration(seconds: 20));

          final results = await endpoints.butler.semanticSearch(
            sessionBuilder,
            'programming',
            limit: 2,
            threshold: 0.1,
            offset: 0,
          );

          expect(
            results.length,
            lessThanOrEqualTo(2),
            reason: 'Should not exceed limit of 2 results',
          );
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );

      test(
        'when limit is 1 then returns single best result',
        () async {
          final session = await Serverpod.instance.createSession();
          await endpoints.butler.startIndexing(
            sessionBuilder,
            Directory.systemTemp.path,
          );
          await Future.delayed(Duration(seconds: 20));

          final results = await endpoints.butler.semanticSearch(
            sessionBuilder,
            'Python',
            limit: 1,
            threshold: 0.1,
            offset: 0,
          );

          expect(
            results.length,
            equals(1),
            reason: 'Should return exactly 1 result',
          );
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );
    });

    group('Vector search returns results with similarity scores', () {
      test(
        'when searching then all results have relevance scores',
        () async {
          final session = await Serverpod.instance.createSession();
          await endpoints.butler.startIndexing(
            sessionBuilder,
            Directory.systemTemp.path,
          );
          await Future.delayed(Duration(seconds: 20));

          final results = await endpoints.butler.semanticSearch(
            sessionBuilder,
            'programming',
            limit: 10,
            threshold: 0.1,
            offset: 0,
          );

          expect(results, isNotEmpty);

          for (final result in results) {
            expect(
              result.relevanceScore,
              isNotNull,
              reason: 'Each result should have a relevance score',
            );
            expect(
              result.relevanceScore,
              greaterThan(0.0),
              reason: 'Score should be positive',
            );
            expect(
              result.relevanceScore,
              lessThanOrEqualTo(1.0),
              reason: 'Score should not exceed 1.0',
            );
          }
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );

      test(
        'when searching then results are sorted by relevance',
        () async {
          final session = await Serverpod.instance.createSession();
          await endpoints.butler.startIndexing(
            sessionBuilder,
            Directory.systemTemp.path,
          );
          await Future.delayed(Duration(seconds: 20));

          final results = await endpoints.butler.semanticSearch(
            sessionBuilder,
            'Python',
            limit: 10,
            threshold: 0.1,
            offset: 0,
          );

          expect(results.length, greaterThan(1));

          for (int i = 1; i < results.length; i++) {
            expect(
              results[i].relevanceScore,
              lessThanOrEqualTo(results[i - 1].relevanceScore),
              reason: 'Results should be sorted by descending relevance',
            );
          }
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );
    });

    group('Vector search handles no matches', () {
      test(
        'when query is completely unrelated then returns empty results',
        () async {
          final session = await Serverpod.instance.createSession();
          await endpoints.butler.startIndexing(
            sessionBuilder,
            Directory.systemTemp.path,
          );
          await Future.delayed(Duration(seconds: 20));

          final results = await endpoints.butler.semanticSearch(
            sessionBuilder,
            'quantum physics black holes',
            limit: 10,
            threshold: 0.5,
            offset: 0,
          );

          expect(
            results,
            isEmpty,
            reason: 'Should return no results for unrelated query',
          );
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );
    });

    group('Vector search uses pgvector index (performance test)', () {
      test(
        'when searching 3 documents then query time is acceptable',
        () async {
          final session = await Serverpod.instance.createSession();
          await endpoints.butler.startIndexing(
            sessionBuilder,
            Directory.systemTemp.path,
          );
          await Future.delayed(Duration(seconds: 20));

          final searchStartTime = DateTime.now();
          await endpoints.butler.semanticSearch(
            sessionBuilder,
            'software development',
            limit: 10,
            threshold: 0.1,
            offset: 0,
          );
          final searchDuration = DateTime.now().difference(searchStartTime);

          expect(
            searchDuration.inSeconds,
            lessThan(5),
            reason: 'Search should complete in less than 5 seconds',
          );
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );

      test(
        'when searching repeatedly then performance remains consistent',
        () async {
          final session = await Serverpod.instance.createSession();
          await endpoints.butler.startIndexing(
            sessionBuilder,
            Directory.systemTemp.path,
          );
          await Future.delayed(Duration(seconds: 20));

          final durations = <Duration>[];
          for (int i = 0; i < 5; i++) {
            final start = DateTime.now();
            await endpoints.butler.semanticSearch(
              sessionBuilder,
              'programming',
              limit: 10,
              threshold: 0.1,
              offset: 0,
            );
            durations.add(DateTime.now().difference(start));
          }

          final avgDuration =
              durations.reduce((a, b) => a + b) ~/ durations.length;
          expect(
            avgDuration.inMilliseconds,
            lessThan(5000),
            reason: 'Average search time should be under 5 seconds',
          );
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );
    });
  });
}
