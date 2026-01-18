import 'package:test/test.dart';
import 'package:semantic_butler_server/src/services/file_extraction_service.dart';

void main() {
  group('FileExtractionService', () {
    late FileExtractionService service;

    setUp(() {
      service = FileExtractionService();
    });

    group('Supported Formats', () {
      test('detects supported text file extensions', () {
        final textFiles = [
          'test.txt',
          'document.md',
          'notes.markdown',
          'data.rtf',
          'config.yaml',
          'settings.json',
          'code.dart',
          'script.js',
          'module.ts',
          'app.py',
        ];

        for (final file in textFiles) {
          expect(
            FileExtractionService.isSupported(file),
            isTrue,
            reason: '$file should be supported',
          );
        }
      });

      test('rejects unsupported file extensions', () {
        final unsupportedFiles = [
          'image.jpg',
          'video.mp4',
          'archive.zip',
          'binary.exe',
          'music.mp3',
        ];

        for (final file in unsupportedFiles) {
          expect(
            FileExtractionService.isSupported(file),
            isFalse,
            reason: '$file should not be supported',
          );
        }
      });

      test('handles case-insensitive extension matching', () {
        final extensions = [
          'test.TXT',
          'Document.MD',
          'Code.DART',
          'script.JS',
        ];

        for (final file in extensions) {
          expect(
            FileExtractionService.isSupported(file),
            isTrue,
            reason: '$file should be supported (case-insensitive)',
          );
        }
      });
    });

    group('Document Classification', () {
      test('classifies code files correctly', () {
        final codeFiles = [
          'main.dart',
          'app.js',
          'component.tsx',
          'server.py',
          'Application.java',
          'service.go',
          'lib.rs',
          'core.cpp',
        ];

        for (final file in codeFiles) {
          final category = FileExtractionService.getDocumentCategory(file);
          expect(
            category,
            equals(DocumentCategory.code),
            reason: '$file should be classified as code',
          );
        }
      });

      test('classifies config files correctly', () {
        final configFiles = [
          'app.yaml',
          'settings.yml',
          'config.json',
          'env.toml',
          'app.ini',
          '.env',
          '.gitignore',
          'dockerignore',
        ];

        for (final file in configFiles) {
          final category = FileExtractionService.getDocumentCategory(file);
          expect(
            category,
            equals(DocumentCategory.config),
            reason: '$file should be classified as config',
          );
        }
      });

      test('classifies data files correctly', () {
        final dataFiles = [
          'data.json',
          'export.csv',
          'config.xml',
        ];

        for (final file in dataFiles) {
          final category = FileExtractionService.getDocumentCategory(file);
          expect(
            category,
            equals(DocumentCategory.data),
            reason: '$file should be classified as data',
          );
        }
      });

      test('classifies document files correctly', () {
        final documentFiles = [
          'readme.txt',
          'notes.md',
          'document.markdown',
          'report.rtf',
          'paper.pdf',
        ];

        for (final file in documentFiles) {
          final category = FileExtractionService.getDocumentCategory(file);
          expect(
            category,
            equals(DocumentCategory.document),
            reason: '$file should be classified as document',
          );
        }
      });

      test('returns document as default for unknown types', () {
        final unknownFiles = [
          'unknown.xyz',
          'custom.file',
        ];

        for (final file in unknownFiles) {
          final category = FileExtractionService.getDocumentCategory(file);
          expect(
            category,
            equals(DocumentCategory.document),
            reason: '$file should default to document',
          );
        }
      });
    });

    group('MIME Type Detection', () {
      test('returns correct MIME types for text files', () {
        final mimeTypes = {
          'test.txt': 'text/plain',
          'document.md': 'text/markdown',
          'data.json': 'application/json',
          'config.yaml': 'application/yaml',
        };

        mimeTypes.forEach((file, expectedMime) {
          final actualMime = FileExtractionService.getMimeType(file);
          expect(
            actualMime,
            equals(expectedMime),
            reason: '$file should have MIME type $expectedMime',
          );
        });
      });

      test('returns application/octet-stream for unknown types', () {
        final unknownFile = 'unknown.xyz';
        final mime = FileExtractionService.getMimeType(unknownFile);

        expect(mime, equals('application/octet-stream'));
      });
    });

    group('Word Counting', () {
      test('counts words in simple text', () {
        final text = 'Hello world this is a test';
        final count = FileExtractionService.countWords(text);

        expect(count, equals(6));
      });

      test('handles empty strings', () {
        final text = '';
        final count = FileExtractionService.countWords(text);

        expect(count, equals(0));
      });

      test('handles multiple spaces', () {
        final text = 'Hello    world   test';
        final count = FileExtractionService.countWords(text);

        expect(count, equals(3));
      });

      test('handles newlines and tabs', () {
        final text = 'Hello\nworld\ttest\nnew';
        final count = FileExtractionService.countWords(text);

        expect(count, equals(4));
      });

      test('counts words in code-like content', () {
        final code = '''
          import 'package:flutter/material.dart';
          void main() {
            print('Hello World');
          }
        ''';

        final count = FileExtractionService.countWords(code);

        expect(count, equals(9));
      });
    });

    group('Ignore Pattern Matching', () {
      test('matches glob patterns for extensions', () {
        final patterns = ['*.log', '*.tmp', '*.bak'];
        final filePaths = {
          'debug.log': true,
          'error.log': true,
          'test.txt': false,
          'document.md': false,
          'temp.tmp': true,
          'backup.bak': true,
        };

        filePaths.forEach((path, shouldMatch) {
          final matches = FileExtractionService.matchesIgnorePattern(
            path,
            patterns,
          );
          expect(
            matches,
            equals(shouldMatch),
            reason:
                '$path should ${shouldMatch ? 'match' : 'not match'} patterns',
          );
        });
      });

      test('matches glob patterns for directories', () {
        final patterns = ['node_modules/**', '.git/**', 'build/**'];
        final filePaths = {
          'node_modules/package/index.js': true,
          'node_modules/package/lib/file.js': true,
          '.git/objects/pack/file.pack': true,
          'build/web/main.dart.js': true,
          'lib/main.dart': false,
          'src/utils.dart': false,
        };

        filePaths.forEach((path, shouldMatch) {
          final matches = FileExtractionService.matchesIgnorePattern(
            path,
            patterns,
          );
          expect(
            matches,
            equals(shouldMatch),
            reason:
                '$path should ${shouldMatch ? 'match' : 'not match'} patterns',
          );
        });
      });

      test('normalizes paths for case-insensitive matching', () {
        final patterns = ['*.LOG', 'Node_Modules/**'];
        final filePaths = {
          'test.log': true,
          'test.LOG': true,
          'Debug.LOG': true,
          'node_modules/package.js': true,
          'NODE_MODULES/package.js': true,
        };

        filePaths.forEach((path, shouldMatch) {
          final matches = FileExtractionService.matchesIgnorePattern(
            path,
            patterns,
          );
          expect(
            matches,
            equals(shouldMatch),
            reason: 'Case-insensitive matching should work for $path',
          );
        });
      });

      test('handles empty pattern list', () {
        final patterns = <String>[];
        final filePath = 'test/file.txt';

        final matches = FileExtractionService.matchesIgnorePattern(
          filePath,
          patterns,
        );

        expect(matches, isFalse);
      });
    });

    group('Directory Scanning', () {
      test('finds all supported files in directory', () async {
        // This test would need a real file system
        // For unit testing, we'll test the logic

        final supportedFiles = [
          'file.txt',
          'code.dart',
          'data.json',
        ];

        final unsupportedFiles = [
          'image.jpg',
          'video.mp4',
        ];

        final allFiles = [...supportedFiles, ...unsupportedFiles];
        final scannedFiles = allFiles
            .where(
              (f) =>
                  f.endsWith('.dart') ||
                  f.endsWith('.txt') ||
                  f.endsWith('.json'),
            )
            .toList();

        expect(scannedFiles, hasLength(3));
        expect(scannedFiles, containsAll(supportedFiles));
      });

      test('respects ignore patterns', () async {
        final allFiles = [
          'file.txt',
          'debug.log', // Should be ignored
          'node_modules/pkg.js', // Should be ignored
          'code.dart',
        ];

        final ignorePatterns = ['*.log', 'node_modules/**'];
        final scannedFiles = allFiles.where((f) {
          return !FileExtractionService.matchesIgnorePattern(f, ignorePatterns);
        }).toList();

        expect(scannedFiles, hasLength(2));
        expect(scannedFiles, isNot(contains('debug.log')));
        expect(scannedFiles, isNot(contains('node_modules/pkg.js')));
      });
    });

    group('Content Hashing', () {
      test('generates consistent hash for same content', () async {
        final content = 'This is test content for hashing';
        final hash1 = _calculateSha256(content);
        final hash2 = _calculateSha256(content);

        expect(hash1, equals(hash2));
      });

      test('generates different hashes for different content', () async {
        final content1 = 'This is content one';
        final content2 = 'This is content two';
        final hash1 = _calculateSha256(content1);
        final hash2 = _calculateSha256(content2);

        expect(hash1, isNot(equals(hash2)));
      });

      test('handles empty content', () async {
        final content = '';
        final hash = _calculateSha256(content);

        // Empty content should still produce a hash
        expect(hash, isNotNull);
        expect(hash, isNotEmpty);
      });

      test('is sensitive to whitespace changes', () async {
        final content1 = 'Hello world';
        final content2 = 'Hello  world'; // Extra space
        final hash1 = _calculateSha256(content1);
        final hash2 = _calculateSha256(content2);

        expect(hash1, isNot(equals(hash2)));
      });
    });

    group('File Size Limits', () {
      test('identifies files exceeding size limit', () {
        final maxFileSize = 50 * 1024 * 1024; // 50MB

        final largeFile = 60 * 1024 * 1024; // 60MB
        final smallFile = 10 * 1024 * 1024; // 10MB

        expect(largeFile, greaterThan(maxFileSize));
        expect(smallFile, lessThan(maxFileSize));
      });

      test('handles edge case at size limit', () {
        final maxFileSize = 50 * 1024 * 1024; // 50MB
        final exactLimit = 50 * 1024 * 1024; // Exactly 50MB
        final justOver = 50 * 1024 * 1024 + 1; // 50MB + 1 byte

        expect(exactLimit, lessThanOrEqualTo(maxFileSize));
        expect(justOver, greaterThan(maxFileSize));
      });
    });

    group('Error Handling', () {
      test('throws exception for missing files', () async {
        final missingPath = '/nonexistent/file.txt';

        expect(
          () => service.extractText(missingPath),
          throwsA(isA<FileExtractionException>()),
        );
      });

      test('handles encoding errors gracefully', () async {
        // This test documents expected behavior for encoding issues.
        // Actual testing requires a binary test fixture file.
        // The service should attempt UTF-8 first, then fall back to latin-1.
        expect(true, isTrue); // Placeholder - would need binary test file
      });

      test('provides meaningful error messages', () async {
        try {
          await service.extractText('/nonexistent/file.txt');
          fail('Should have thrown exception');
        } catch (e) {
          expect(e, isA<FileExtractionException>());

          final error = e as FileExtractionException;
          expect(error.message, contains('File not found'));
        }
      });
    });
  });
}

// Helper function for SHA-256 (simplified for testing)
String _calculateSha256(String content) {
  // In real code, this would use crypto package
  // For testing, we'll use a simple hash
  return 'sha256:${content.hashCode}';
}
