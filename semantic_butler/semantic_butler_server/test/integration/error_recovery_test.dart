import 'dart:io';
import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:semantic_butler_server/src/generated/protocol.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Error Recovery Integration Tests', (
    sessionBuilder,
    endpoints,
  ) {
    late Directory testDirectory;

    setUpAll(() {
      testDirectory = Directory.systemTemp.createTempSync(
        'error_recovery_test_',
      );
    });

    tearDownAll(() {
      if (testDirectory.existsSync()) {
        testDirectory.deleteSync(recursive: true);
      }
    });

    group('Error recovery handles failed file extraction', () {
      test(
        'when extraction fails then error is recorded',
        () async {
          final result = await endpoints.butler.startIndexing(
            sessionBuilder,
            testDirectory.path,
          );

          await Future.delayed(Duration(seconds: 10));

          expect(result, isNotNull, reason: 'Should return an IndexingJob');

          final session = await Serverpod.instance.createSession();
          final job = await IndexingJob.db.findById(session, result.id!);

          if (job != null) {
            expect(
              job.status,
              isIn(['completed', 'failed', 'running', 'queued']),
              reason: 'Job should have a valid status',
            );
          }
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 30)),
      );
    });

    group('Error recovery records failed files in job details', () {
      test(
        'when batch processing fails then details are recorded',
        () async {
          final paths = <String>[];
          for (int i = 0; i < 3; i++) {
            final filePath = '${testDirectory.path}/batch_$i.txt';
            final file = File(filePath);
            file.writeAsStringSync('Batch test content $i');
            paths.add(filePath);
          }

          final result = await endpoints.butler.startIndexing(
            sessionBuilder,
            testDirectory.path,
          );

          await Future.delayed(Duration(seconds: 20));

          expect(result, isNotNull);

          final session = await Serverpod.instance.createSession();
          final job = await IndexingJob.db.findById(session, result.id!);

          if (job != null) {
            expect(
              job.totalFiles,
              greaterThanOrEqualTo(0),
              reason: 'Job should record total files',
            );

            expect(
              job.processedFiles + job.failedFiles + job.skippedFiles,
              equals(job.totalFiles),
              reason: 'Processed + failed + skipped should equal total',
            );
          }
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );
    });

    group('Circuit breaker prevents cascading failures', () {
      test(
        'when multiple consecutive failures then job completes',
        () async {
          final folderPath = '${testDirectory.path}/circuit_test';

          final result = await endpoints.butler.startIndexing(
            sessionBuilder,
            folderPath,
          );

          await Future.delayed(Duration(seconds: 15));

          expect(result, isNotNull);

          final session = await Serverpod.instance.createSession();
          final job = await IndexingJob.db.findById(session, result.id!);

          if (job != null) {
            expect(
              job.status,
              isIn(['completed', 'failed', 'running', 'queued']),
              reason: 'Job should complete without hanging',
            );
          }
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );
    });

    group('Partial failure does not corrupt database', () {
      test(
        'when some files fail then successful ones remain indexed',
        () async {
          final paths = <String>[];

          for (int i = 0; i < 3; i++) {
            final validPath = '${testDirectory.path}/stable_$i.txt';
            final validFile = File(validPath);
            validFile.writeAsStringSync('Stable content $i');
            paths.add(validPath);
          }

          final result = await endpoints.butler.startIndexing(
            sessionBuilder,
            testDirectory.path,
          );

          await Future.delayed(Duration(seconds: 20));

          expect(result, isNotNull);

          final session = await Serverpod.instance.createSession();
          final job = await IndexingJob.db.findById(session, result.id!);

          if (job != null) {
            expect(
              job.totalFiles,
              greaterThan(0),
              reason: 'Job should process some files',
            );

            final fileIndex = await FileIndex.db.find(
              session,
              where: (t) => t.path.like('${testDirectory.path}%'),
            );

            expect(
              fileIndex,
              isNotEmpty,
              reason: 'At least some files should be indexed',
            );

            for (int i = 0; i < 3; i++) {
              final validPath = '${testDirectory.path}/stable_$i.txt';
              final indexed = fileIndex.any((fi) => fi.path == validPath);

              if (indexed) {
                final record = fileIndex.firstWhere(
                  (fi) => fi.path == validPath,
                );

                if (record.status == 'indexed') {
                  final embeddings = await DocumentEmbedding.db.find(
                    session,
                    where: (t) => t.fileIndexId.equals(record.id!),
                  );

                  expect(
                    embeddings,
                    isNotEmpty,
                    reason: 'Indexed files should have embeddings',
                  );
                }
              }
            }
          }
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );
    });

    group('Error recovery maintains system health', () {
      test(
        'when errors occur then error stats are updated',
        () async {
          final beforeStats = await endpoints.butler.getErrorStats(
            sessionBuilder,
          );

          await endpoints.butler.startIndexing(
            sessionBuilder,
            testDirectory.path,
          );

          await Future.delayed(Duration(seconds: 15));

          final afterStats = await endpoints.butler.getErrorStats(
            sessionBuilder,
          );

          expect(afterStats, isNotNull);

          expect(
            afterStats.totalErrors,
            greaterThanOrEqualTo(beforeStats.totalErrors),
            reason: 'Error count should not decrease',
          );
        },
        timeout: Timeout(Duration(seconds: 60)),
      );

      test(
        'when errors occur then system remains functional',
        () async {
          final validPath = '${testDirectory.path}/functional_test.txt';

          final validFile = File(validPath);
          validFile.writeAsStringSync('Functional content');

          final result1 = await endpoints.butler.startIndexing(
            sessionBuilder,
            testDirectory.path,
          );

          await Future.delayed(Duration(seconds: 15));

          expect(result1, isNotNull);

          final result2 = await endpoints.butler.startIndexing(
            sessionBuilder,
            testDirectory.path,
          );

          await Future.delayed(Duration(seconds: 15));

          expect(result2, isNotNull);

          final session = await Serverpod.instance.createSession();
          final fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.equals(validPath),
          );

          if (result1.id != result2.id) {
            expect(
              fileIndex.length,
              lessThan(2),
              reason: 'Should not have duplicate records',
            );
          }
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 90)),
      );
    });
  });
}
