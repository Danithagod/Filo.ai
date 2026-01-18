import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

/// Database-backed locking service using PostgreSQL advisory locks
///
/// Advisory locks provide a way to coordinate access to resources
/// across multiple database sessions. They are automatically released
/// when the session ends or transaction completes.
class LockService {
  /// Default lock timeout (how long to wait for lock acquisition)
  static const Duration defaultLockTimeout = Duration(seconds: 5);

  /// Generate a 64-bit integer lock ID from a resource ID using SHA-256
  static int _generateLockId(String resourceId) {
    final bytes = utf8.encode(resourceId);
    final hash = sha256.convert(bytes);
    // Take the first 8 bytes (64 bits) of the hash
    final digestBytes = hash.bytes.sublist(0, 8);
    // Convert to 64-bit integer (BigInt to ensure signed 64-bit compatibility with Postgres bigint)
    // We use a safe conversion: bytes -> BigInt -> signed 64-bit int
    BigInt id = BigInt.zero;
    for (var i = 0; i < 8; i++) {
      id = (id << 8) | BigInt.from(digestBytes[i]);
    }
    // Handle overflow for signed 64-bit integer (Dart ints are 64-bit, Postgres bigints are signed 64-bit)
    // Dart web might be issue, but this is server-side code (VM).
    // To ensure it fits in Postgres bigint signed range:
    // If bit 63 is set, interpret as negative.
    if (id >= BigInt.from(1) << 63) {
      id = id - (BigInt.from(1) << 64);
    }
    return id.toInt();
  }

  /// Try to acquire a lock for the specified resource
  ///
  /// [session] - Database session
  /// [resourceId] - Unique identifier for the resource (e.g., file path)
  /// [timeout] - Optional timeout. If provided, will retry acquisition until timeout.
  ///
  /// Returns true if lock was acquired, false otherwise
  static Future<bool> tryAcquireLock(
    Session session,
    String resourceId, {
    Duration? timeout,
  }) async {
    final int lockId = _generateLockId(resourceId);

    session.log(
      'Attempting to acquire lock for resource: $resourceId (lockId: $lockId)',
      level: LogLevel.debug,
    );

    final startTime = DateTime.now();
    final effectiveTimeout = timeout ?? Duration.zero;

    // Retry loop
    while (true) {
      try {
        // Try to acquire advisory lock (non-blocking)
        // pg_try_advisory_lock is session-scoped
        final result = await session.db.unsafeQuery(
          'SELECT pg_try_advisory_lock($lockId) as acquired',
        );

        final acquired = result.first[0] as bool? ?? false;

        if (acquired) {
          session.log(
            'Lock acquired for resource: $resourceId',
            level: LogLevel.debug,
          );
          return true;
        }

        // Check if we timed out
        if (DateTime.now().difference(startTime) >= effectiveTimeout) {
          session.log(
            'Failed to acquire lock for resource: $resourceId (already locked, timeout reached)',
            level: LogLevel.warning,
          );
          return false;
        }

        // Wait with randomized backoff (50ms - 200ms)
        final backoff = 50 + Random().nextInt(150);
        await Future.delayed(Duration(milliseconds: backoff));
      } catch (e) {
        session.log(
          'Error acquiring lock for $resourceId: $e',
          level: LogLevel.error,
        );
        // On error (e.g. DB connection lost), do not retry indefinitely if not intended,
        // but for now we treat error as "failed to acquire" and respect timeout loop behavior
        // or just return false to be safe.
        // Returning false is safer to prevent endless error loops.
        return false;
      }
    }
  }

  /// Release a lock for the specified resource
  static Future<void> releaseLock(
    Session session,
    String resourceId,
  ) async {
    final int lockId = _generateLockId(resourceId);

    session.log(
      'Releasing lock for resource: $resourceId (lockId: $lockId)',
      level: LogLevel.debug,
    );

    try {
      await session.db.unsafeQuery(
        'SELECT pg_advisory_unlock($lockId)',
      );
    } catch (e) {
      session.log(
        'Error releasing lock for $resourceId: $e',
        level: LogLevel.warning,
      );
    }
  }

  /// Execute a function while holding a lock
  ///
  /// [timeout] - Optional timeout for lock acquisition.
  /// Throws [LockException] if lock cannot be acquired or operation fails.
  static Future<T> withLock<T>(
    Session session,
    String resourceId,
    Future<T> Function() operation, {
    Duration? timeout,
  }) async {
    final acquired = await tryAcquireLock(
      session,
      resourceId,
      timeout: timeout,
    );

    if (!acquired) {
      throw LockException('Failed to acquire lock for resource: $resourceId');
    }

    try {
      return await operation();
    } finally {
      await releaseLock(session, resourceId);
    }
  }

  /// Check if a resource is currently locked (without acquiring)
  ///
  /// Uses pg_locks system view to check status without side effects.
  static Future<bool> isLocked(
    Session session,
    String resourceId,
  ) async {
    final int lockId = _generateLockId(resourceId);

    try {
      // Query pg_locks system view
      // We look for 'advisory' locks with the specific 64-bit key.
      // Postgres stores 64-bit advisory keys split into classid (high 32) and objid (low 32)
      // IF using pg_advisory_lock(int, int).
      // BUT we use pg_try_advisory_lock(bigint).
      // For bigint locks, Postgres stores the keys in 'classid' and 'objid' columns specially.
      // Reference: "The 64-bit form is stored with the upper 32 bits in classid and the lower 32 bits in objid."

      // We need to split our Dart 64-bit int back into two 32-bit queries for robust matching
      // OR pass it as a bigint parameter.
      // Simplest is to pass the param as string and cast to bigint in SQL for direct comparison if pg_locks allows.
      // But pg_locks doesn't expose a single 'key' column for 64-bit locks easily.
      // Checks: "((classid::bigint << 32) | objid::bigint) = $lockId" logic.

      final result = await session.db.unsafeQuery('''
        SELECT COUNT(*) > 0 
        FROM pg_locks 
        WHERE locktype = 'advisory' 
          AND ((classid::bigint << 32) | objid::bigint) = $lockId
        ''');

      final isLocked = result.first[0] as bool? ?? false;
      return isLocked;
    } catch (e) {
      session.log(
        'Error checking lock status for $resourceId: $e',
        level: LogLevel.error,
      );
      // Fail safe: assume it might be locked or just return false and let caller handle
      // Returning false (not locked) is better for monitoring, but risky for logic.
      // But isLocked is mainly for info/UI.
      return false;
    }
  }
}

class LockException implements Exception {
  final String message;
  LockException(this.message);
  @override
  String toString() => 'LockException: $message';
}
