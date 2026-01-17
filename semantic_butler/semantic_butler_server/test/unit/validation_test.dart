import 'package:test/test.dart';
import 'package:semantic_butler_server/src/utils/validation.dart';

void main() {
  group('InputValidation', () {
    group('validateSearchQuery', () {
      test('accepts valid queries', () {
        // Should not throw
        InputValidation.validateSearchQuery(
          'find documents about machine learning',
        );
        InputValidation.validateSearchQuery('what is the project status?');
        InputValidation.validateSearchQuery('meeting notes from yesterday');
      });

      test('rejects queries exceeding max length', () {
        final longQuery = 'a' * 1001;
        expect(
          () => InputValidation.validateSearchQuery(longQuery),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects SQL injection patterns', () {
        // These patterns contain SQL keywords/operators that are blocked
        final injectionPatterns = [
          "'; DROP TABLE users--",
          "'; DELETE FROM documents;--",
          "1; EXEC xp_cmdshell('dir');--",
          "/**/",
          "select * from table--",
          "INSERT INTO users",
          "UPDATE table SET",
          "-- comment injection",
        ];

        for (final pattern in injectionPatterns) {
          expect(
            () => InputValidation.validateSearchQuery(pattern),
            throwsA(isA<ValidationException>()),
            reason: 'Should reject: $pattern',
          );
        }
      });
    });

    group('validateFilePath', () {
      test('accepts valid paths', () {
        // Should not throw
        InputValidation.validateFilePath('documents/project/readme.md');
        InputValidation.validateFilePath('C:\\Users\\documents\\file.txt');
        InputValidation.validateFilePath('relative/path/to/file');
      });

      test('rejects empty paths', () {
        expect(
          () => InputValidation.validateFilePath(''),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects path traversal attempts (../)', () {
        final traversalPatterns = [
          '../../../etc/passwd',
          'documents/../../../secrets',
          'path/to/../../../file',
          '..\\..\\..\\windows\\system32',
        ];

        for (final pattern in traversalPatterns) {
          expect(
            () => InputValidation.validateFilePath(pattern),
            throwsA(isA<ValidationException>()),
            reason: 'Should reject: $pattern',
          );
        }
      });

      test('rejects null bytes', () {
        expect(
          () => InputValidation.validateFilePath('path/to/file\x00.txt'),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects paths exceeding max length', () {
        final longPath = 'a/' * 2050;
        expect(
          () => InputValidation.validateFilePath(longPath),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validateLimit', () {
      test('accepts valid limits', () {
        // Should not throw
        InputValidation.validateLimit(1);
        InputValidation.validateLimit(50);
        InputValidation.validateLimit(100);
      });

      test('rejects zero or negative limits', () {
        expect(
          () => InputValidation.validateLimit(0),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => InputValidation.validateLimit(-1),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects limits exceeding max', () {
        expect(
          () => InputValidation.validateLimit(101),
          throwsA(isA<ValidationException>()),
        );
      });

      test('respects custom max', () {
        InputValidation.validateLimit(50, max: 50); // Should not throw
        expect(
          () => InputValidation.validateLimit(51, max: 50),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validateThreshold', () {
      test('accepts valid thresholds', () {
        // Should not throw
        InputValidation.validateThreshold(0.0);
        InputValidation.validateThreshold(0.5);
        InputValidation.validateThreshold(1.0);
      });

      test('rejects thresholds below 0', () {
        expect(
          () => InputValidation.validateThreshold(-0.1),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects thresholds above 1', () {
        expect(
          () => InputValidation.validateThreshold(1.1),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validateId', () {
      test('accepts positive IDs', () {
        InputValidation.validateId(1);
        InputValidation.validateId(100);
        InputValidation.validateId(999999);
      });

      test('rejects zero or negative IDs', () {
        expect(
          () => InputValidation.validateId(0),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => InputValidation.validateId(-1),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validatePattern', () {
      test('accepts valid glob patterns', () {
        InputValidation.validatePattern('*.log');
        InputValidation.validatePattern('node_modules/**');
        InputValidation.validatePattern('*.{js,ts}');
      });

      test('rejects empty patterns', () {
        expect(
          () => InputValidation.validatePattern(''),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects excessive wildcards (ReDoS prevention)', () {
        expect(
          () => InputValidation.validatePattern('***'),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => InputValidation.validatePattern('???'),
          throwsA(isA<ValidationException>()),
        );
      });
    });
  });

  group('ValidationException', () {
    test('toString includes message', () {
      final exception = ValidationException('Test error');
      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('ValidationException'));
    });
  });
}
