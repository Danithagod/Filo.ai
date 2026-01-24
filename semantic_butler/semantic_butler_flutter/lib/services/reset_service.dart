import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';
import '../utils/app_logger.dart';

/// Provider for the ResetService
final resetServiceProvider = Provider<ResetService>((ref) {
  final client = ref.watch(clientProvider);
  return ResetService(client);
});

/// Service to handle database reset operations in the Flutter app
class ResetService {
  final Client client;

  ResetService(this.client);

  /// Get a preview of what will be deleted during a reset
  Future<ResetPreview> getPreview() async {
    try {
      AppLogger.info('Fetching reset preview...', tag: 'ResetService');
      return await client.butler.previewReset();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to fetch reset preview',
        tag: 'ResetService',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Generate a one-time confirmation code for reset
  Future<String> generateConfirmationCode() async {
    try {
      AppLogger.info(
        'Generating reset confirmation code...',
        tag: 'ResetService',
      );
      return await client.butler.generateResetConfirmationCode();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to generate reset confirmation code',
        tag: 'ResetService',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Execute the database reset
  ///
  /// [scope] - Reset scope: 'dataOnly', 'full', or 'soft'
  /// [confirmationCode] - Code generated via [generateConfirmationCode]
  Future<ResetResult> resetDatabase({
    required String scope,
    required String confirmationCode,
    bool dryRun = false,
  }) async {
    try {
      AppLogger.warning(
        'Executing database reset: scope=$scope, dryRun=$dryRun',
        tag: 'ResetService',
      );
      return await client.butler.resetDatabase(
        scope: scope,
        confirmationCode: confirmationCode,
        dryRun: dryRun,
      );
    } catch (e, stack) {
      AppLogger.error(
        'Database reset failed',
        tag: 'ResetService',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
