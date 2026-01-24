import 'dart:async';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'file_watcher_service.dart';

class IndexingService {
  static Timer? _cleanupTimer;

  Future<IndexingStatus> getIndexingStatus(Session session) async {
    final totalIndexed = await FileIndex.db.count(
      session,
      where: (t) => t.status.equals('indexed'),
    );

    final activeJobs = await IndexingJob.db.count(
      session,
      where: (t) => t.status.equals('running') | t.status.equals('queued'),
    );

    final recentJobs = await IndexingJob.db.find(
      session,
      orderBy: (t) => t.startedAt,
      orderDescending: true,
      limit: 10,
    );

    return IndexingStatus(
      totalDocuments: totalIndexed,
      indexedDocuments: totalIndexed,
      pendingDocuments: 0, // Placeholder
      failedDocuments: 0, // Placeholder
      activeJobs: activeJobs,
      databaseSizeMb: 0.0, // Placeholder
      lastActivity: DateTime.now(),
      recentJobs: recentJobs,
    );
  }

  Future<IndexingJob?> getIndexingJob(Session session, int jobId) async {
    return await IndexingJob.db.findById(session, jobId);
  }

  Future<IndexingJob> startIndexing(Session session, String folderPath) async {
    var job = IndexingJob(
      folderPath: folderPath,
      status: 'queued',
      totalFiles: 0,
      processedFiles: 0,
      failedFiles: 0,
      skippedFiles: 0,
      startedAt: DateTime.now(),
    );

    return await IndexingJob.db.insertRow(session, job);
  }

  Future<bool> cancelIndexingJob(Session session, int jobId) async {
    final job = await IndexingJob.db.findById(session, jobId);
    if (job == null) return false;

    job.status = 'cancelled';
    await IndexingJob.db.updateRow(session, job);
    return true;
  }

  Future<WatchedFolder> enableSmartIndexing(
    Session session,
    String folderPath,
  ) async {
    final service = FileWatcherService(session);
    return await service.startWatching(folderPath);
  }

  Future<void> disableSmartIndexing(Session session, String folderPath) async {
    final service = FileWatcherService(session);
    await service.stopWatching(folderPath);
  }

  Future<WatchedFolder?> toggleSmartIndexing(
    Session session,
    String folderPath,
  ) async {
    final existing = await WatchedFolder.db.findFirstRow(
      session,
      where: (t) => t.path.equals(folderPath),
    );

    if (existing != null && existing.isEnabled) {
      await disableSmartIndexing(session, folderPath);
      return null;
    } else {
      return await enableSmartIndexing(session, folderPath);
    }
  }

  Stream<IndexingProgress> streamProgress(Session session) async* {
    // Placeholder stream
    yield* Stream.empty();
  }

  static void startWatcherCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      // Periodic cleanup logic placeholder
    });
  }

  static void stopWatcherCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  static Future<void> disposeAllWatchers() async {
    // Implementation placeholder
  }
}
