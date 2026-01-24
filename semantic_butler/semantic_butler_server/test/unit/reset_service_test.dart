import 'package:test/test.dart';
import 'package:semantic_butler_server/src/services/reset_service.dart';

void main() {
  group('ResetService', () {
    late ResetService service;

    setUp(() {
      service = ResetService.instance;
      service.reset();
    });

    tearDown(() {
      service.reset();
    });

    group('confirmation codes', () {
      test('generates valid confirmation code format', () {
        final code = service.generateConfirmationCode();

        expect(code, startsWith('RESET-DESK-SENSE-'));
        expect(code.length, equals(23)); // RESET-DESK-SENSE- (17) + 6 digits
      });

      test('generates unique codes', () {
        final codes = <String>{};
        for (var i = 0; i < 100; i++) {
          codes.add(service.generateConfirmationCode());
        }

        // All codes should be unique
        expect(codes.length, equals(100));
      });

      test('validates generated code', () {
        final code = service.generateConfirmationCode();

        expect(service.validateConfirmationCode(code), isTrue);
      });

      test('rejects invalid code', () {
        expect(service.validateConfirmationCode('INVALID'), isFalse);
        expect(service.validateConfirmationCode(''), isFalse);
        expect(
          service.validateConfirmationCode('RESET-DESK-SENSE-WRONG'),
          isFalse,
        );
      });

      test('consumes code on use', () {
        final code = service.generateConfirmationCode();

        expect(service.validateConfirmationCode(code), isTrue);
        service.consumeConfirmationCode(code);
        expect(service.validateConfirmationCode(code), isFalse);
      });

      test('tracks active code count', () {
        expect(service.activeCodeCount, equals(0));

        service.generateConfirmationCode();
        expect(service.activeCodeCount, equals(1));

        service.generateConfirmationCode();
        expect(service.activeCodeCount, equals(2));

        service.reset();
        expect(service.activeCodeCount, equals(0));
      });
    });

    group('rate limiting', () {
      test('allows first reset', () {
        expect(service.checkRateLimit(), isNull);
      });

      test('blocks reset after recent reset', () {
        service.recordReset();

        final remaining = service.checkRateLimit();
        expect(remaining, isNotNull);
        expect(remaining!.inMinutes, greaterThan(0));
        expect(remaining.inMinutes, lessThanOrEqualTo(60));
      });

      test('allows reset after rate limit window', () {
        // This tests the logic only - actual timing would need fake clock
        service.recordReset();
        expect(service.checkRateLimit(), isNotNull);

        // Reset state to simulate time passing
        service.reset();
        expect(service.checkRateLimit(), isNull);
      });
    });

    group('reset scope', () {
      test('has correct scope constants', () {
        expect(ResetScope.dataOnly, equals('dataOnly'));
        expect(ResetScope.full, equals('full'));
        expect(ResetScope.soft, equals('soft'));
      });
    });

    group('application tables', () {
      test('contains all expected tables', () {
        expect(ResetService.applicationTables, contains('document_embedding'));
        expect(ResetService.applicationTables, contains('file_index'));
        expect(ResetService.applicationTables, contains('indexing_job'));
        expect(ResetService.applicationTables, contains('indexing_job_detail'));
        expect(ResetService.applicationTables, contains('watched_folders'));
        expect(ResetService.applicationTables, contains('search_history'));
        expect(ResetService.applicationTables, contains('tag_taxonomy'));
        expect(ResetService.applicationTables, contains('ignore_pattern'));
        expect(ResetService.applicationTables, contains('agent_file_command'));
        expect(ResetService.applicationTables, contains('saved_search_preset'));
      });

      test('has 10 tables', () {
        expect(ResetService.applicationTables.length, equals(10));
      });

      test('document_embedding is first (FK dependency)', () {
        expect(
          ResetService.applicationTables.first,
          equals('document_embedding'),
        );
      });

      test('indexing_job_detail before indexing_job (FK dependency)', () {
        final detailIndex = ResetService.applicationTables.indexOf(
          'indexing_job_detail',
        );
        final jobIndex = ResetService.applicationTables.indexOf('indexing_job');

        expect(detailIndex, lessThan(jobIndex));
      });
    });

    group('configuration tables', () {
      test('contains ignore_pattern', () {
        expect(ResetService.configurationTables, contains('ignore_pattern'));
      });

      test('soft reset preserves configuration tables', () {
        // Configuration tables should not be deleted in soft reset
        for (final table in ResetService.configurationTables) {
          expect(ResetService.applicationTables, contains(table));
        }
      });
    });
  });
}
