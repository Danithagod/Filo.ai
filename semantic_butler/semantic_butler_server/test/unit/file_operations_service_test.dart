import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:semantic_butler_server/src/services/file_operations_service.dart';

void main() {
  group('FileOperationsService', () {
    late FileOperationsService service;
    late Directory tempDir;

    setUp(() async {
      service = FileOperationsService();
      tempDir = await Directory.systemTemp.createTemp('file_ops_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    String getPath(String fileName) => path.join(tempDir.path, fileName);

    test('renameFile with dryRun validates but doesn\'t execute', () async {
      final sourceFile = File(getPath('source.txt'));
      await sourceFile.writeAsString('hello');

      final result = await service.renameFile(
        sourceFile.path,
        'target.txt',
        dryRun: true,
      );

      expect(result.success, isTrue);
      expect(result.isDryRun, isTrue);
      expect(await File(getPath('target.txt')).exists(), isFalse);
      expect(await sourceFile.exists(), isTrue);
    });

    test('renameFile generates undo information', () async {
      final sourceFile = File(getPath('source.txt'));
      await sourceFile.writeAsString('hello');

      final result = await service.renameFile(sourceFile.path, 'target.txt');

      expect(result.success, isTrue);
      expect(result.undoOperation, equals('rename'));
      expect(result.undoPath, equals(sourceFile.path));
      expect(result.newPath, equals(getPath('target.txt')));
    });

    test('undoOperation reverses a rename', () async {
      final sourceFile = File(getPath('source.txt'));
      await sourceFile.writeAsString('hello');
      final originalPath = sourceFile.path;

      final result = await service.renameFile(originalPath, 'target.txt');
      expect(await File(originalPath).exists(), isFalse);

      final undoResult = await service.undoOperation(result);

      expect(undoResult.success, isTrue);
      expect(await File(originalPath).exists(), isTrue);
      expect(await File(getPath('target.txt')).exists(), isFalse);
    });

    test('batchOperations with rollbackOnError', () async {
      final file1 = File(getPath('file1.txt'));
      await file1.writeAsString('content1');

      final file2 = File(getPath('file2.txt'));
      await file2.writeAsString('content2');

      // Re-reading moveFile implementation: it joins basename(sourcePath) to destFolder.
      // So file1.path -> tempDir.path/file1.txt (which already exists if I don't change names)

      // Let's create a subfolder for moves
      final subDir = await Directory(getPath('sub')).create();

      final batchOps = [
        FileOperationRequest(
          type: FileOperationType.move,
          sourcePath: file1.path,
          destinationPath: subDir.path,
        ),
        FileOperationRequest(
          type: FileOperationType.move,
          sourcePath: getPath('non_existent.txt'),
          destinationPath: subDir.path,
        ),
      ];

      final batchResult = await service.batchOperations(
        batchOps,
        rollbackOnError: true,
      );

      expect(batchResult.success, isFalse);
      expect(batchResult.wasRolledBack, isTrue);
      expect(
        batchResult.successCount,
        equals(1),
      ); // One succeeded then rolled back

      // file1 should be back in original location
      expect(await file1.exists(), isTrue);
      expect(await File(path.join(subDir.path, 'file1.txt')).exists(), isFalse);
    });

    test('error classification for path not found', () async {
      final result = await service.deleteFile(getPath('missing.txt'));
      expect(result.success, isFalse);
      expect(result.errorType, equals(FileOperationErrorType.pathNotFound));
    });
  });
}
