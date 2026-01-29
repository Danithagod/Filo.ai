import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';

import 'package:semantic_butler_server/src/utils/encoding_detector.dart';

void main() {
  group('EncodingDetector', () {
    group('detectEncoding', () {
      test('detects UTF-8 with BOM', () {
        final bytes = [0xEF, 0xBB, 0xBF, 0x48, 0x65, 0x6C, 0x6C, 0x6F]; // Hello
        final result = EncodingDetector.detectEncoding(bytes);
        expect(result.encoding, utf8);
        expect(result.bomOffset, 3);
        expect(result.hasBom, true);
      });

      test('detects UTF-16 LE with BOM', () {
        final bytes = [0xFF, 0xFE, 0x48, 0x00, 0x65, 0x00]; // Hello
        final result = EncodingDetector.detectEncoding(bytes);
        expect(result.encoding, utf16Le);
        expect(result.bomOffset, 2);
        expect(result.hasBom, true);
      });

      test('detects UTF-16 BE with BOM', () {
        final bytes = [0xFE, 0xFF, 0x00, 0x48, 0x00, 0x65]; // Hello
        final result = EncodingDetector.detectEncoding(bytes);
        expect(result.encoding, utf16Be);
        expect(result.bomOffset, 2);
        expect(result.hasBom, true);
      });

      test('detects ASCII text', () {
        final bytes = [0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x57, 0x6F, 0x72, 0x6C, 0x64];
        final result = EncodingDetector.detectEncoding(bytes);
        expect(result.isAscii, true);
        expect(result.encoding, ascii);
      });

      test('detects UTF-8 without BOM', () {
        final bytes = [0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0xC3, 0xA9]; // Hello é
        final result = EncodingDetector.detectEncoding(bytes);
        expect(result.encoding, utf8);
        expect(result.hasBom, false);
      });

      test('returns empty result for empty bytes', () {
        final result = EncodingDetector.detectEncoding([]);
        expect(result.bomOffset, 0);
      });
    });

    group('isBinary', () {
      test('returns false for text file', () async () {
        // Create a temporary text file
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/test_text.txt');
        try {
          await tempFile.writeAsString('Hello, World!\nThis is a text file.');
          expect(EncodingDetector.isBinary(tempFile.path), false);
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      });

      test('returns true for binary file with null bytes', () async () {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/test_binary.bin');
        try {
          final bytes = [0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03];
          await tempFile.writeAsBytes(bytes);
          expect(EncodingDetector.isBinary(tempFile.path), true);
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      });

      test('returns false for missing file', () {
        expect(EncodingDetector.isBinary('/nonexistent/file.txt'), false);
      });
    });

    group('readFile', () {
      test('reads UTF-8 file correctly', () async {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/test_utf8.txt');
        try {
          await tempFile.writeAsString('Hello, World!', encoding: utf8);
          final content = EncodingDetector.readFile(tempFile.path);
          expect(content, 'Hello, World!');
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      });

      test('reads UTF-8 file with BOM correctly', () async {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/test_utf8_bom.txt');
        try {
          final bom = [0xEF, 0xBB, 0xBF];
          final contentBytes = utf8.encode('Hello with BOM!');
          await tempFile.writeAsBytes([...bom, ...contentBytes]);
          final content = EncodingDetector.readFile(tempFile.path);
          expect(content, 'Hello with BOM!');
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      });

      test('returns empty string for empty file', () async {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/test_empty.txt');
        try {
          await tempFile.writeAsString('');
          final content = EncodingDetector.readFile(tempFile.path);
          expect(content, '');
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      });
    });

    group('readFileLines', () {
      test('limits lines to maxLines', () async {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/test_lines.txt');
        try {
          final content = 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5';
          await tempFile.writeAsString(content);
          final result = EncodingDetector.readFileLines(tempFile.path, maxLines: 3);
          final lines = result.split('\n');
          expect(lines.length, 3);
          expect(lines.last, 'Line 3');
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      });

      test('returns all lines when file has fewer lines than maxLines', () async {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/test_lines2.txt');
        try {
          final content = 'Line 1\nLine 2';
          await tempFile.writeAsString(content);
          final result = EncodingDetector.readFileLines(tempFile.path, maxLines: 10);
          final lines = result.split('\n');
          expect(lines.length, 2);
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      });
    });

    group('readFileAsync', () {
      test('reads file asynchronously', () async {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/test_async.txt');
        try {
          await tempFile.writeAsString('Async content');
          final content = await EncodingDetector.readFileAsync(tempFile.path);
          expect(content, 'Async content');
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      });
    });

    group('readFileLinesAsync', () {
      test('reads lines asynchronously with limit', () async {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/test_async_lines.txt');
        try {
          final content = 'L1\nL2\nL3\nL4\nL5';
          await tempFile.writeAsString(content);
          final result = await EncodingDetector.readFileLinesAsync(
            tempFile.path,
            maxLines: 2,
          );
          final lines = result.split('\n');
          expect(lines.length, 2);
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      });
    });

    group('EncodingDetection', () {
      test('encodingName returns correct names', () {
        final utf8Detection = EncodingDetection(
          encoding: utf8,
          bomOffset: 0,
        );
        expect(utf8Detection.encodingName, 'UTF-8');

        final utf16LeDetection = EncodingDetection(
          encoding: utf16Le,
          bomOffset: 0,
        );
        expect(utf16LeDetection.encodingName, 'UTF-16 LE');

        final asciiDetection = EncodingDetection(
          encoding: ascii,
          bomOffset: 0,
          isAscii: true,
        );
        expect(asciiDetection.encodingName, 'ASCII');
      });

      test('toString returns informative string', () {
        final detection = EncodingDetection(
          encoding: utf8,
          bomOffset: 3,
          hasBom: true,
        );
        final str = detection.toString();
        expect(str, contains('UTF-8'));
        expect(str, contains('3'));
        expect(str, contains('true'));
      });
    });
  });

  group('EncodingDetection edge cases', () {
    test('handles UTF-8 validity', () {
      // Test via detection - valid UTF-8
      final validUtf8 = [0x48, 0x65, 0x6C, 0x6C, 0x6F, 0xC2, 0xA9]; // Hello ©
      final result = EncodingDetector.detectEncoding(validUtf8);
      expect(result.encodingName, contains('UTF-8'));
    });

    test('detects encoding for mixed content', () {
      // ASCII content
      final asciiBytes = [0x48, 0x65, 0x6C, 0x6C, 0x6F];
      final result = EncodingDetector.detectEncoding(asciiBytes);
      expect(result.encoding, ascii);
    });
  });
}
