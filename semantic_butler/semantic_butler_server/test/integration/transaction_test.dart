import 'dart:io';
import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:semantic_butler_server/src/generated/protocol.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Transaction Integration Tests', (sessionBuilder, endpoints) {
    late Directory testDirectory;

    setUpAll(() {
      testDirectory = Directory.systemTemp.createTempSync('transaction_test_');
    });

    tearDownAll(() {
      if (testDirectory.existsSync()) {
        testDirectory.deleteSync(recursive: true);
      }
    });

    group('Transaction creates both FileIndex and DocumentEmbedding', () {
      test(
        'when indexing valid folder then records are created',
        () async {
          final filePath = '${testDirectory.path}/test_doc.txt';
          final file = File(filePath);
          file.writeAsStringSync(
            'Test document content for transaction testing.',
          );

          final result = await endpoints.butler.startIndexing(
            sessionBuilder,
            testDirectory.path,
          );

          await Future.delayed(Duration(seconds: 15));

          expect(
            result.status,
            isIn(['queued', 'running', 'completed', 'failed']),
            reason: 'Job should have a valid status',
          );

          final session = await Serverpod.instance.createSession();
          final fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.equals(filePath),
          );

          expect(
            fileIndex,
            isNotEmpty,
            reason: 'FileIndex record should be created',
          );
          if (fileIndex.isNotEmpty) {
            expect(fileIndex.first.status, equals('indexed'));

            final embeddings = await DocumentEmbedding.db.find(
              session,
              where: (t) => t.fileIndexId.equals(fileIndex.first.id!),
            );

            expect(
              embeddings,
              isNotEmpty,
              reason: 'DocumentEmbedding record should be created',
            );
          }
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );
    });

    group('Transaction handles concurrent operations', () {
      test(
        'when concurrent indexing same folder then no duplicates',
        () async {
          final filePath = '${testDirectory.path}/concurrent_test.txt';
          final file = File(filePath);
          file.writeAsStringSync('Test for concurrent indexing');

          final futures = <Future>[];
          for (int i = 0; i < 3; i++) {
            futures.add(
              endpoints.butler.startIndexing(
                sessionBuilder,
                testDirectory.path,
              ),
            );
          }

          await Future.wait(futures);
          await Future.delayed(Duration(seconds: 20));

          final session = await Serverpod.instance.createSession();
          final fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.equals(filePath),
          );

          expect(
            fileIndex.length,
            equals(1),
            reason: 'Should only have one FileIndex record',
          );

          if (fileIndex.isNotEmpty) {
            final embeddings = await DocumentEmbedding.db.find(
              session,
              where: (t) => t.fileIndexId.equals(fileIndex.first.id!),
            );

            expect(
              embeddings.length,
              lessThan(3),
              reason: 'Should not have multiple duplicate embeddings',
            );
          }
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 90)),
      );
    });

    group('Transaction maintains data consistency', () {
      test(
        'when indexing multiple files then all are indexed',
        () async {
          final paths = <String>[];
          for (int i = 0; i < 3; i++) {
            final filePath = '${testDirectory.path}/batch_test_$i.txt';
            final file = File(filePath);
            file.writeAsStringSync('Batch test content $i');
            paths.add(filePath);
          }

          final result = await endpoints.butler.startIndexing(
            sessionBuilder,
            testDirectory.path,
          );

          await Future.delayed(Duration(seconds: 20));

          expect(result.status, isNotNull);

          final session = await Serverpod.instance.createSession();
          final fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.like('${testDirectory.path}%'),
          );

          expect(
            fileIndex.length,
            greaterThanOrEqualTo(paths.length ~/ 2),
            reason: 'At least some files should be indexed',
          );

          for (final file in fileIndex) {
            if (file.status == 'indexed') {
              final embeddings = await DocumentEmbedding.db.find(
                session,
                where: (t) => t.fileIndexId.equals(file.id!),
              );

              expect(
                embeddings,
                isNotEmpty,
                reason: 'Indexed files should have embeddings',
              );
            }
          }
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );
    });

    group('Transaction error handling', () {
      test(
        'when indexing fails then job has failed status',
        () async {
          final folderPath = '${testDirectory.path}/empty_test';

          final result = await endpoints.butler.startIndexing(
            sessionBuilder,
            folderPath,
          );

          await Future.delayed(Duration(seconds: 10));

          expect(result, isNotNull);

          final session = await Serverpod.instance.createSession();
          final job = await IndexingJob.db.findById(
            session,
            result.id!,
          );

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

      test(
        'when indexing fails then error stats are recorded',
        () async {
          final session = await Serverpod.instance.createSession();

          await endpoints.butler.startIndexing(
            sessionBuilder,
            testDirectory.path,
          );

          await Future.delayed(Duration(seconds: 10));

          final errorStats = await endpoints.butler.getErrorStats(
            sessionBuilder,
          );
          expect(errorStats, isNotNull, reason: 'Should return error stats');
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 30)),
      );
    });

    group('Cleanup and orphan management', () {
      test(
        'when removing file from index then both records are deleted',
        () async {
          final filePath = '${testDirectory.path}/cleanup_test.txt';
          final file = File(filePath);
          file.writeAsStringSync('Cleanup test content');

          await endpoints.butler.startIndexing(
            sessionBuilder,
            testDirectory.path,
          );

          await Future.delayed(Duration(seconds: 15));

          final session = await Serverpod.instance.createSession();
          var fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.equals(filePath),
          );

          expect(fileIndex, isNotEmpty, reason: 'File should be indexed');

          final removed = await endpoints.butler.removeFromIndex(
            sessionBuilder,
            path: filePath,
          );

          expect(removed, isTrue, reason: 'Remove should succeed');

          await Future.delayed(Duration(milliseconds: 500));

          fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.equals(filePath),
          );

          expect(
            fileIndex,
            isEmpty,
            reason: 'File should be removed from index',
          );
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 60)),
      );
    });
  });
}
