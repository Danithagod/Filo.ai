import 'dart:math';

import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import './metrics_service.dart';
import './circuit_breaker.dart';

/// Reset scopes for database reset operations
class ResetScope {
  /// Delete all application data rows, keep schema
  static const String dataOnly = 'dataOnly';

  /// Full reset - truncate all tables
  static const String full = 'full';

  /// Soft reset - clear data but keep configuration (ignore patterns)
  static const String soft = 'soft';
}

/// Service for managing database reset operations
///
/// Provides safe, transactional reset functionality with:
/// - Confirmation codes for safety
/// - Rate limiting to prevent accidental repeated resets
/// - Dry run mode for previewing changes
/// - Proper foreign key deletion order
class ResetService {
  /// Singleton instance
  static final ResetService instance = ResetService._();

  ResetService._();

  /// All application tables in the correct deletion order (FK dependencies first)
  static const List<String> applicationTables = [
    'document_embedding', // References file_index
    'indexing_job_detail', // References indexing_job
    'indexing_job',
    'file_index',
    'watched_folders',
    'search_history',
    'tag_taxonomy',
    'ignore_pattern',
    'agent_file_command',
    'saved_search_preset',
  ];

  /// Tables to preserve during soft reset (configuration only)
  static const List<String> configurationTables = [
    'ignore_pattern',
  ];

  /// Active confirmation codes with expiration times
  final Map<String, DateTime> _confirmationCodes = {};

  /// Rate limit: last reset timestamp
  DateTime? _lastResetTime;

  /// Rate limit window (1 hour between resets)
  static const Duration rateLimitWindow = Duration(hours: 1);

  /// Confirmation code expiration (5 minutes)
  static const Duration codeExpiration = Duration(minutes: 5);

  // ==========================================================================
  // CONFIRMATION CODE MANAGEMENT
  // ==========================================================================

  /// Generate a time-limited confirmation code
  ///
  /// The code format is: RESET-DESK-SENSE-{RANDOM}
  /// Code expires after 5 minutes
  String generateConfirmationCode() {
    // Clean up expired codes
    _cleanupExpiredCodes();

    // Generate random suffix
    final random = Random.secure();
    final suffix = List.generate(6, (_) => random.nextInt(10)).join();
    final code = 'RESET-DESK-SENSE-$suffix';

    // Store with expiration
    _confirmationCodes[code] = DateTime.now().add(codeExpiration);

    return code;
  }

  /// Validate a confirmation code
  ///
  /// Returns true if the code is valid and not expired
  bool validateConfirmationCode(String code) {
    _cleanupExpiredCodes();

    final expiration = _confirmationCodes[code];
    if (expiration == null) {
      return false;
    }

    if (DateTime.now().isAfter(expiration)) {
      _confirmationCodes.remove(code);
      return false;
    }

    return true;
  }

  /// Consume a confirmation code (mark as used)
  void consumeConfirmationCode(String code) {
    _confirmationCodes.remove(code);
  }

  /// Clean up expired confirmation codes
  void _cleanupExpiredCodes() {
    final now = DateTime.now();
    _confirmationCodes.removeWhere((_, expiration) => now.isAfter(expiration));
  }

  // ==========================================================================
  // RATE LIMITING
  // ==========================================================================

  /// Check if reset is allowed (rate limiting)
  ///
  /// Returns null if allowed, or the remaining wait time if rate limited
  Duration? checkRateLimit() {
    if (_lastResetTime == null) {
      return null;
    }

    final elapsed = DateTime.now().difference(_lastResetTime!);
    if (elapsed >= rateLimitWindow) {
      return null;
    }

    return rateLimitWindow - elapsed;
  }

  /// Record that a reset was performed
  void recordReset() {
    _lastResetTime = DateTime.now();
  }

  // ==========================================================================
  // PREVIEW
  // ==========================================================================

  /// Get a preview of what will be deleted
  ///
  /// Returns row counts per table without making any changes
  Future<ResetPreview> getPreview(Session session) async {
    final stats = <String, int>{};

    for (final table in applicationTables) {
      final count = await _getTableRowCount(session, table);
      stats[table] = count;
    }

    final totalRows = stats.values.fold(0, (a, b) => a + b);
    final estimatedSeconds = _estimateResetTime(totalRows);

    return ResetPreview(
      tables: stats,
      totalRows: totalRows,
      estimatedTimeSeconds: estimatedSeconds,
    );
  }

  /// Get row count for a specific table using raw SQL
  Future<int> _getTableRowCount(Session session, String tableName) async {
    try {
      // Use raw SQL since Serverpod ORM requires model-specific access
      final result = await session.db.unsafeQuery(
        'SELECT COUNT(*) as count FROM "$tableName"',
      );

      if (result.isNotEmpty && result.first.isNotEmpty) {
        return int.tryParse(result.first.first.toString()) ?? 0;
      }
      return 0;
    } catch (e) {
      // Table might not exist or other error
      session.log(
        'Warning: Could not count rows in $tableName: $e',
        level: LogLevel.warning,
      );
      return 0;
    }
  }

  /// Estimate reset time based on row count
  ///
  /// Rough estimate: ~100 rows per second for deletion
  int _estimateResetTime(int totalRows) {
    if (totalRows == 0) return 0;
    if (totalRows < 100) return 1;
    return (totalRows / 100).ceil();
  }

  // ==========================================================================
  // RESET OPERATIONS
  // ==========================================================================

  /// Reset the database
  ///
  /// [session] - Database session
  /// [scope] - Reset scope: 'dataOnly', 'full', or 'soft'
  /// [confirmationCode] - Required confirmation code
  /// [dryRun] - If true, preview only without making changes
  Future<ResetResult> resetDatabase(
    Session session, {
    required String scope,
    required String confirmationCode,
    bool dryRun = false,
  }) async {
    final startTime = DateTime.now();

    // Validate confirmation code
    if (!validateConfirmationCode(confirmationCode)) {
      return ResetResult(
        success: false,
        affectedRows: {},
        durationMs: 0,
        scope: scope,
        errorMessage: 'Invalid or expired confirmation code',
      );
    }

    // Check rate limit
    final rateLimitRemaining = checkRateLimit();
    if (rateLimitRemaining != null) {
      return ResetResult(
        success: false,
        affectedRows: {},
        durationMs: 0,
        scope: scope,
        errorMessage:
            'Rate limited. Please wait ${rateLimitRemaining.inMinutes} minutes before resetting again.',
      );
    }

    // Consume the confirmation code
    if (!dryRun) {
      consumeConfirmationCode(confirmationCode);
    }

    // Determine which tables to delete
    final tablesToDelete = _getTablesToDelete(scope);

    // Perform reset in transaction
    try {
      final affectedRows = <String, int>{};

      await session.db.transaction((transaction) async {
        for (final table in tablesToDelete) {
          int count = 0;

          if (!dryRun) {
            count = await _truncateTable(session, table, transaction);
          } else {
            count = await _getTableRowCount(session, table);
          }

          affectedRows[table] = count;
        }
      });

      // Record reset time for rate limiting
      if (!dryRun) {
        recordReset();
        _resetInMemoryServices();
      }

      final durationMs = DateTime.now().difference(startTime).inMilliseconds;

      session.log(
        'Database reset completed: ${dryRun ? "[DRY RUN] " : ""}${affectedRows.values.fold(0, (a, b) => a + b)} rows affected',
        level: LogLevel.info,
      );

      return ResetResult(
        success: true,
        affectedRows: affectedRows,
        durationMs: durationMs,
        scope: scope,
      );
    } catch (e, stackTrace) {
      session.log(
        'Database reset failed: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );

      return ResetResult(
        success: false,
        affectedRows: {},
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        scope: scope,
        errorMessage: 'Reset failed: $e',
      );
    }
  }

  /// Get list of tables to delete based on scope
  List<String> _getTablesToDelete(String scope) {
    if (scope == ResetScope.soft) {
      return applicationTables
          .where((t) => !configurationTables.contains(t))
          .toList();
    }
    return applicationTables;
  }

  /// Truncate a table and return the number of rows deleted
  Future<int> _truncateTable(
    Session session,
    String tableName,
    Transaction transaction,
  ) async {
    try {
      // Get count before deletion
      final countBefore = await _getTableRowCount(session, tableName);

      if (countBefore == 0) {
        return 0;
      }

      // Use DELETE instead of TRUNCATE to work within transaction
      await session.db.unsafeQuery(
        'DELETE FROM "$tableName"',
      );

      session.log(
        'Deleted $countBefore rows from $tableName',
        level: LogLevel.debug,
      );

      return countBefore;
    } catch (e) {
      session.log(
        'Failed to truncate $tableName: $e',
        level: LogLevel.error,
      );
      rethrow;
    }
  }

  /// Reset in-memory services after database reset
  void _resetInMemoryServices() {
    // Reset metrics
    MetricsService.instance.reset();

    // Reset circuit breakers
    CircuitBreakerRegistry.instance.resetAll();
  }

  // ==========================================================================
  // TESTING HELPERS
  // ==========================================================================

  /// Reset the service state (for testing)
  void reset() {
    _confirmationCodes.clear();
    _lastResetTime = null;
  }

  /// Get count of active confirmation codes (for testing)
  int get activeCodeCount => _confirmationCodes.length;
}
