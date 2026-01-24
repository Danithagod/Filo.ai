import 'package:test/test.dart';
import 'package:semantic_butler_server/src/generated/protocol.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Reset functionality', (sessionBuilder, endpoints) {
    setUp(() async {
      // Setup some test data before each test if needed
      // However, reset test is best run on a populated DB
    });

    test('when generating reset code then code is returned', () async {
      final code = await endpoints.butler.generateResetConfirmationCode(
        sessionBuilder,
      );
      expect(code, isNotEmpty);
      expect(code, isA<String>());
      expect(code.length, greaterThan(10));
    });

    test('when previewing reset then counts are returned', () async {
      final preview = await endpoints.butler.previewReset(sessionBuilder);
      expect(preview, isA<ResetPreview>());
      expect(preview.tables, isNotEmpty);
      expect(preview.totalRows, isNotNull);
    });

    test('when executing reset with invalid code then it fails', () async {
      final result = await endpoints.butler.resetDatabase(
        sessionBuilder,
        scope: 'dataOnly',
        confirmationCode: 'INVALID-CODE',
        dryRun: false,
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Invalid or expired'));
    });

    test('when executing full reset then data is cleared', () async {
      // 1. Generate code
      final code = await endpoints.butler.generateResetConfirmationCode(
        sessionBuilder,
      );

      // 2. Execute reset
      final result = await endpoints.butler.resetDatabase(
        sessionBuilder,
        scope: 'full',
        confirmationCode: code,
        dryRun: false,
      );

      expect(result.success, isTrue);
      expect(result.scope, 'full');

      // 3. Verify preview is zero
      final preview = await endpoints.butler.previewReset(sessionBuilder);
      expect(preview.totalRows, 0);
      for (var count in preview.tables.values) {
        expect(count, 0);
      }
    });

    test(
      'when executing soft reset then ignore patterns might be preserved',
      () async {
        // Note: This test assumes we can insert an ignore pattern first
        // For now, we'll just verify the scope is returned correctly
        final code = await endpoints.butler.generateResetConfirmationCode(
          sessionBuilder,
        );

        final result = await endpoints.butler.resetDatabase(
          sessionBuilder,
          scope: 'soft',
          confirmationCode: code,
          dryRun: false,
        );

        expect(result.success, isTrue);
        expect(result.scope, 'soft');
      },
    );
  });
}
