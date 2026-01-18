import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/cache_service.dart';

/// Health check endpoint for monitoring system health
/// Public endpoint - no authentication required
class HealthEndpoint extends Endpoint {
  /// Check system health
  /// Returns overall status and component-level health metrics
  Future<HealthCheck> check(Session session) async {
    final checkedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();

    // 1. Check database connectivity
    bool databaseHealthy = false;
    try {
      await session.db.unsafeQuery('SELECT 1');
      databaseHealthy = true;
    } catch (e) {
      session.log('Database health check failed: $e', level: LogLevel.error);
    }

    // 2. Check pgvector extension
    bool pgvectorHealthy = false;
    try {
      final result = await session.db.unsafeQuery(
        "SELECT 1 FROM pg_extension WHERE extname = 'vector'",
      );
      pgvectorHealthy = result.isNotEmpty;
    } catch (e) {
      session.log('pgvector health check failed: $e', level: LogLevel.warning);
      // Not critical - fallback to Dart vector operations
    }

    // 3. Check WatchedFolders from database (no in-memory watcher service access)
    bool watcherHealthy = false;
    int activeWatcherCount = 0;
    String? watcherDetails;
    try {
      final watchedFolders = await WatchedFolder.db.find(
        session,
        where: (t) => t.isEnabled.equals(true),
      );
      activeWatcherCount = watchedFolders.length;
      watcherHealthy =
          activeWatcherCount > 0 ||
          true; // Healthy even if no watchers configured

      // Check if any folders have recent activity
      final now = DateTime.now();
      int staleWatchers = 0;
      for (final folder in watchedFolders) {
        final lastEvent = folder.lastEventAt;
        if (lastEvent != null && now.difference(lastEvent).inHours > 24) {
          staleWatchers++;
        }
      }

      if (staleWatchers > 0) {
        watcherDetails = '$staleWatchers watcher(s) without recent activity';
      }
    } catch (e) {
      session.log('Watcher health check failed: $e', level: LogLevel.warning);
      watcherDetails = 'Failed to retrieve watcher status';
    }

    // 4. Check cache hit rate
    double? cacheHitRate;
    try {
      final cacheStats = CacheService.instance.stats;
      final hits = cacheStats.hits;
      final misses = cacheStats.misses;
      final total = hits + misses;

      if (total > 0) {
        cacheHitRate = (hits / total) * 100;
      }
    } catch (e) {
      session.log('Cache health check failed: $e', level: LogLevel.warning);
    }

    // 5. Calculate API response time (this endpoint)
    stopwatch.stop();
    final apiResponseTimeMs = stopwatch.elapsedMilliseconds.toDouble();

    // Determine overall status
    String overallStatus;
    if (!databaseHealthy) {
      overallStatus = 'unhealthy';
    } else if (!watcherHealthy || (cacheHitRate != null && cacheHitRate < 30)) {
      overallStatus = 'degraded';
    } else {
      overallStatus = 'healthy';
    }

    return HealthCheck(
      status: overallStatus,
      databaseHealthy: databaseHealthy,
      pgvectorHealthy: pgvectorHealthy,
      watcherHealthy: watcherHealthy,
      activeWatcherCount: activeWatcherCount,
      cacheHitRate: cacheHitRate,
      apiResponseTimeMs: apiResponseTimeMs,
      checkedAt: checkedAt,
      watcherDetails: watcherDetails,
    );
  }
}
