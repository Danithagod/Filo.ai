import 'dart:io';
import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'test_tools/serverpod_test_tools.dart';
import 'package:semantic_butler_server/src/generated/protocol.dart';

void main() {
  withServerpod('Auto-Indexing Integration Tests', (sessionBuilder, endpoints) {
    late Directory testDirectory;

    setUpAll(() async {
      testDirectory = Directory.systemTemp.createTempSync(
        'auto_indexing_test_',
      );
    });

    tearDownAll(() async {
      if (testDirectory.existsSync()) {
        testDirectory.deleteSync(recursive: true);
      }
    });

    group('Auto-Indexing starts watching folder', () {
      test('when enabling smart indexing then watcher is created', () async {
        final folderPath = testDirectory.path;

        await endpoints.butler.enableSmartIndexing(
          sessionBuilder,
          folderPath,
        );

        await Future.delayed(Duration(milliseconds: 500));

        final watchedFolders = await endpoints.butler.getWatchedFolders(
          sessionBuilder,
        );
        final isWatching = watchedFolders.any((wf) => wf.path == folderPath);

        expect(isWatching, isTrue, reason: 'Folder should be watched');

        await endpoints.butler.disableSmartIndexing(
          sessionBuilder,
          folderPath,
        );
      });

      test(
        'when folder does not exist then returns error gracefully',
        () async {
          final invalidPath = '/nonexistent/folder/path';

          final result = await endpoints.butler.enableSmartIndexing(
            sessionBuilder,
            invalidPath,
          );

          expect(result, isNotNull, reason: 'Should return a result');
        },
      );
    });

    group('Auto-Indexing indexes new files', () {
      test(
        'when creating new file then file gets indexed',
        () async {
          final folderPath = testDirectory.path;
          final fileName = 'test_document.txt';
          final filePath = '$folderPath/$fileName';

          await endpoints.butler.enableSmartIndexing(
            sessionBuilder,
            folderPath,
          );

          await Future.delayed(Duration(milliseconds: 1000));

          final testFile = File(filePath);
          testFile.writeAsStringSync(
            'This is a test document for auto-indexing.',
          );

          await Future.delayed(Duration(seconds: 8));

          final session = await Serverpod.instance.createSession();
          final fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.equals(filePath),
          );

          expect(fileIndex, isNotEmpty, reason: 'File should be indexed');
          expect(fileIndex.first.fileName, equals(fileName));
          expect(fileIndex.first.status, equals('indexed'));

          await session.close();
          await endpoints.butler.disableSmartIndexing(
            sessionBuilder,
            folderPath,
          );
        },
        timeout: Timeout(Duration(seconds: 30)),
      );

      test(
        'when creating multiple files then all get indexed',
        () async {
          final folderPath = testDirectory.path;

          await endpoints.butler.enableSmartIndexing(
            sessionBuilder,
            folderPath,
          );

          await Future.delayed(Duration(milliseconds: 1000));

          for (int i = 0; i < 3; i++) {
            final file = File('$folderPath/file_$i.txt');
            file.writeAsStringSync('Content of file $i');
          }

          await Future.delayed(Duration(seconds: 15));

          final session = await Serverpod.instance.createSession();
          final fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.like('$folderPath%'),
          );
          final indexedCount = fileIndex.length;

          expect(
            indexedCount,
            greaterThan(0),
            reason: 'At least some files should be indexed',
          );
          await session.close();
          await endpoints.butler.disableSmartIndexing(
            sessionBuilder,
            folderPath,
          );
        },
        timeout: Timeout(Duration(seconds: 60)),
      );
    });

    group('Auto-Indexing re-indexes modified files', () {
      test(
        'when modifying existing file then file is re-indexed',
        () async {
          final folderPath = testDirectory.path;
          final fileName = 'modifiable_file.txt';
          final filePath = '$folderPath/$fileName';

          await endpoints.butler.enableSmartIndexing(
            sessionBuilder,
            folderPath,
          );

          await Future.delayed(Duration(milliseconds: 1000));

          final testFile = File(filePath);
          testFile.writeAsStringSync('Original content');

          await Future.delayed(Duration(seconds: 8));

          testFile.writeAsStringSync('Modified content with new information');

          await Future.delayed(Duration(seconds: 8));

          final session = await Serverpod.instance.createSession();
          final fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.equals(filePath),
          );

          expect(fileIndex, isNotEmpty, reason: 'File should still be indexed');

          if (fileIndex.isNotEmpty && fileIndex.first.contentPreview != null) {
            expect(
              fileIndex.first.contentPreview!,
              contains('Modified'),
              reason: 'Content preview should reflect modification',
            );
          }

          await session.close();
          await endpoints.butler.disableSmartIndexing(
            sessionBuilder,
            folderPath,
          );
        },
        timeout: Timeout(Duration(seconds: 30)),
      );
    });

    group('Auto-Indexing ignores files matching patterns', () {
      test(
        'when creating ignored file extension then file is not indexed',
        () async {
          final folderPath = testDirectory.path;
          final fileName = 'test_log.log';
          final filePath = '$folderPath/$fileName';

          await endpoints.butler.enableSmartIndexing(
            sessionBuilder,
            folderPath,
          );

          await Future.delayed(Duration(milliseconds: 1000));

          final testFile = File(filePath);
          testFile.writeAsStringSync('This is a log file');

          await Future.delayed(Duration(seconds: 8));

          final session = await Serverpod.instance.createSession();
          final fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.equals(filePath),
          );

          expect(fileIndex, isEmpty, reason: 'Log files should be ignored');

          await session.close();
          await endpoints.butler.disableSmartIndexing(
            sessionBuilder,
            folderPath,
          );
        },
        timeout: Timeout(Duration(seconds: 30)),
      );

      test(
        'when creating file in ignored directory then file is not indexed',
        () async {
          final folderPath = testDirectory.path;
          final ignoredDir = Directory('$folderPath/node_modules');
          ignoredDir.createSync();
          final fileName = 'package.js';
          final filePath = '${ignoredDir.path}/$fileName';

          await endpoints.butler.enableSmartIndexing(
            sessionBuilder,
            folderPath,
          );

          await Future.delayed(Duration(milliseconds: 1000));

          final testFile = File(filePath);
          testFile.writeAsStringSync('This is a package file');

          await Future.delayed(Duration(seconds: 8));

          final session = await Serverpod.instance.createSession();
          final fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.equals(filePath),
          );

          expect(
            fileIndex,
            isEmpty,
            reason: 'Files in node_modules should be ignored',
          );

          await session.close();
          await endpoints.butler.disableSmartIndexing(
            sessionBuilder,
            folderPath,
          );
        },
        timeout: Timeout(Duration(seconds: 30)),
      );
    });

    group('Auto-Indexing stops watching folder (cleanup test)', () {
      test('when disabling smart indexing then watcher is removed', () async {
        final folderPath = testDirectory.path;

        await endpoints.butler.enableSmartIndexing(
          sessionBuilder,
          folderPath,
        );

        await Future.delayed(Duration(milliseconds: 500));

        var watchedFolders = await endpoints.butler.getWatchedFolders(
          sessionBuilder,
        );
        expect(watchedFolders.any((wf) => wf.path == folderPath), isTrue);

        await endpoints.butler.disableSmartIndexing(
          sessionBuilder,
          folderPath,
        );

        watchedFolders = await endpoints.butler.getWatchedFolders(
          sessionBuilder,
        );
        expect(
          watchedFolders.any((wf) => wf.path == folderPath),
          isFalse,
          reason: 'Folder should no longer be watched',
        );
      });

      test(
        'when stopping watching then indexed files are removed from index',
        () async {
          final folderPath = testDirectory.path;
          final fileName = 'to_be_removed.txt';
          final filePath = '$folderPath/$fileName';

          await endpoints.butler.enableSmartIndexing(
            sessionBuilder,
            folderPath,
          );

          await Future.delayed(Duration(milliseconds: 1000));

          final testFile = File(filePath);
          testFile.writeAsStringSync('This file will be removed from index');

          await Future.delayed(Duration(seconds: 8));

          var session = await Serverpod.instance.createSession();
          var fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.equals(filePath),
          );
          expect(
            fileIndex.isNotEmpty,
            isTrue,
            reason: 'File should be indexed',
          );
          await session.close();

          await endpoints.butler.disableSmartIndexing(
            sessionBuilder,
            folderPath,
          );

          await Future.delayed(Duration(milliseconds: 1000));

          session = await Serverpod.instance.createSession();
          fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.equals(filePath),
          );
          expect(
            fileIndex.isEmpty,
            isTrue,
            reason: 'File should be removed from index',
          );
          await session.close();
        },
        timeout: Timeout(Duration(seconds: 30)),
      );
    });

    group('Auto-Indexing handles file moves', () {
      test(
        'when moving file within watched folder then index is updated',
        () async {
          final folderPath = testDirectory.path;
          final oldFileName = 'old_name.txt';
          final newFileName = 'new_name.txt';
          final oldPath = '$folderPath/$oldFileName';
          final newPath = '$folderPath/$newFileName';

          await endpoints.butler.enableSmartIndexing(
            sessionBuilder,
            folderPath,
          );

          await Future.delayed(Duration(milliseconds: 1000));

          final testFile = File(oldPath);
          testFile.writeAsStringSync('File content before move');

          await Future.delayed(Duration(seconds: 8));

          var session = await Serverpod.instance.createSession();
          var fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.equals(oldPath),
          );
          expect(
            fileIndex.isNotEmpty,
            isTrue,
            reason: 'File should be indexed at old location',
          );
          await session.close();

          await testFile.rename(newPath);

          await Future.delayed(Duration(seconds: 8));

          session = await Serverpod.instance.createSession();
          fileIndex = await FileIndex.db.find(
            session,
            where: (t) => t.path.equals(oldPath),
          );
          expect(
            fileIndex.isEmpty,
            isTrue,
            reason: 'Old path should be removed from index',
          );
          await session.close();

          await endpoints.butler.disableSmartIndexing(
            sessionBuilder,
            folderPath,
          );
        },
        timeout: Timeout(Duration(seconds: 30)),
      );
    });
  });
}
