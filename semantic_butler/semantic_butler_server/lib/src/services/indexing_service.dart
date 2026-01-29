import 'dart:async';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../constants/indexing_status.dart';
import 'file_watcher_service.dart';
import 'file_extraction_service.dart';
import 'cached_ai_service.dart';
import 'openrouter_client.dart';
import 'dart:convert';
import 'package:semantic_butler_server/server.dart' show getEnv;

class IndexingService {
  static Timer? _cleanupTimer;
  static final Map<int, StreamController<IndexingProgress>>
  _progressControllers = {};
  static final Map<String, Completer<void>> _fileLocks = {};
  static final Set<int> _processingJobs = {};
  static final Map<String, Completer<void>> _folderLocks = {};

  /// Execute an action with a per-file lock to prevent concurrent processing
  Future<T> withFileLock<T>(String path, Future<T> Function() action) async {
    while (_fileLocks.containsKey(path)) {
      await _fileLocks[path]!.future;
    }
    final completer = Completer<void>();
    _fileLocks[path] = completer;

    try {
      return await action();
    } finally {
      _fileLocks.remove(path);
      completer.complete();
    }
  }

  /// Execute an action with a per-folder lock to prevent concurrent indexing
  /// of the same directory by multiple clients
  Future<T> withFolderLock<T>(String folderPath, Future<T> Function() action) async {
    final normalizedPath = folderPath.toLowerCase().replaceAll('\\', '/');
    while (_folderLocks.containsKey(normalizedPath)) {
      await _folderLocks[normalizedPath]!.future;
    }
    final completer = Completer<void>();
    _folderLocks[normalizedPath] = completer;

    try {
      return await action();
    } finally {
      _folderLocks.remove(normalizedPath);
      completer.complete();
    }
  }

  /// Check if a folder is currently being indexed
  bool isFolderLocked(String folderPath) {
    final normalizedPath = folderPath.toLowerCase().replaceAll('\\', '/');
    return _folderLocks.containsKey(normalizedPath);
  }

  Future<IndexingStatus> getIndexingStatus(Session session) async {
    // Optimized: Single query for all file status counts
    final statusCounts = await _getFileStatusCounts(session);

    // Parallel fetch for jobs and db size
    final results = await Future.wait([
      IndexingJob.db.count(
        session,
        where: (t) => t.status.equals(JobStatus.running) | t.status.equals(JobStatus.queued),
      ),
      IndexingJob.db.find(
        session,
        orderBy: (t) => t.startedAt,
        orderDescending: true,
        limit: 10,
      ),
      _calculateDatabaseSize(session),
    ]);

    final activeJobs = results[0] as int;
    final recentJobs = results[1] as List<IndexingJob>;
    final dbSize = results[2] as double;

    return IndexingStatus(
      totalDocuments: statusCounts['indexed'] ?? 0,
      indexedDocuments: statusCounts['indexed'] ?? 0,
      pendingDocuments: statusCounts['pending'] ?? 0,
      failedDocuments: statusCounts['failed'] ?? 0,
      activeJobs: activeJobs,
      databaseSizeMb: dbSize,
      lastActivity: DateTime.now(),
      recentJobs: recentJobs,
    );
  }

  /// Get all file status counts in a single query
  Future<Map<String, int>> _getFileStatusCounts(Session session) async {
    try {
      final result = await session.db.unsafeQuery(
        "SELECT status, COUNT(*) as count FROM file_index GROUP BY status",
      );
      final counts = <String, int>{};
      for (final row in result) {
        if (row.length >= 2) {
          final status = row[0]?.toString() ?? '';
          final count = int.tryParse(row[1]?.toString() ?? '0') ?? 0;
          counts[status] = count;
        }
      }
      return counts;
    } catch (e) {
      session.log('Failed to get status counts: $e', level: LogLevel.warning);
      // Fallback to individual queries
      return {
        FileIndexStatus.indexed: await FileIndex.db.count(
          session,
          where: (t) => t.status.equals(FileIndexStatus.indexed),
        ),
        FileIndexStatus.pending: await FileIndex.db.count(
          session,
          where: (t) => t.status.equals(FileIndexStatus.pending),
        ),
        FileIndexStatus.failed: await FileIndex.db.count(
          session,
          where: (t) => t.status.equals(FileIndexStatus.failed),
        ),
      };
    }
  }

  Future<ErrorStats> getErrorStats(Session session) async {
    final totalErrors = await FileIndex.db.count(
      session,
      where: (t) => t.status.equals(FileIndexStatus.failed),
    );

    return ErrorStats(
      totalErrors: totalErrors,
      byCategory: [],
      generatedAt: DateTime.now(),
    );
  }

  Future<double> _calculateDatabaseSize(Session session) async {
    try {
      // Try PostgreSQL first
      final result = await session.db.unsafeQuery(
        "SELECT pg_database_size(current_database()) / 1024.0 / 1024.0",
      );
      if (result.isNotEmpty && result.first.isNotEmpty) {
        return double.tryParse(result.first.first.toString()) ?? 0.0;
      }
    } catch (e) {
      // Fallback for SQLite or other databases
      try {
        final result = await session.db.unsafeQuery(
          "SELECT (page_count * page_size) / 1024.0 / 1024.0 FROM pragma_page_count(), pragma_page_size()",
        );
        if (result.isNotEmpty && result.first.isNotEmpty) {
          return double.tryParse(result.first.first.toString()) ?? 0.0;
        }
      } catch (_) {
        session.log(
          'Failed to calculate DB size with SQLite fallback: $e',
          level: LogLevel.debug,
        );
      }
    }
    return 0.0;
  }

  Future<IndexingJob?> getIndexingJob(Session session, int jobId) async {
    return await IndexingJob.db.findById(session, jobId);
  }

  Future<IndexingJob> startIndexing(Session session, String folderPath) async {
    // HYBRID ARCHITECTURE CHANGE:
    // Server-side indexing is disabled in favor of Client-side indexing + Upload.
    throw UnsupportedError(
      'Server-side indexing is deprecated. Use Client-side indexing and upload results.',
    );
  }

  Future<bool> cancelIndexingJob(Session session, int jobId) async {
    final job = await IndexingJob.db.findById(session, jobId);
    if (job == null) return false;

    job.status = 'cancelled';
    job.completedAt = DateTime.now();
    await IndexingJob.db.updateRow(session, job);

    _progressControllers[jobId]?.add(
      IndexingProgress(
        jobId: jobId,
        status: 'cancelled',
        processedFiles: job.processedFiles,
        totalFiles: job.totalFiles,
        failedFiles: job.failedFiles,
        skippedFiles: job.skippedFiles,
        progressPercent: job.totalFiles > 0
            ? (job.processedFiles / job.totalFiles * 100)
            : 0.0,
        timestamp: DateTime.now(),
      ),
    );

    return true;
  }

  Future<WatchedFolder> enableSmartIndexing(
    Session session,
    String folderPath,
  ) async {
    final service = WatcherManager.getInstance(session);
    return await service.startWatching(folderPath);
  }

  Future<void> disableSmartIndexing(Session session, String folderPath) async {
    final service = WatcherManager.getInstance(session);
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

  /// Re-index a list of files (triggered by watcher)
  Future<void> reindexFiles(Session session, List<String> paths) async {
    final extractionService = FileExtractionService();
    final aiService = CachedAIService(
      client: OpenRouterClient(
        apiKey: getEnv('OPENROUTER_API_KEY'),
      ),
    );

    for (final path in paths) {
      try {
        final file = File(path);
        if (!await file.exists()) continue;
        await _indexFile(session, file, extractionService, aiService);
      } catch (e) {
        session.log(
          'Background re-indexing failed for $path: $e',
          level: LogLevel.error,
        );
      }
    }
  }

  /// Remove a file from the index (triggered by watcher or manual delete)
  Future<void> removeFileFromIndex(Session session, String path) async {
    try {
      final fileIndex = await FileIndex.db.findFirstRow(
        session,
        where: (t) => t.path.equals(path),
      );

      if (fileIndex != null) {
        // All related records (including embeddings) are deleted via CASCADE
        // if configured in the model, or we delete them explicitly from managed tables.

        // Deletions from managed tables
        await DocumentEmbedding.db.deleteWhere(
          session,
          where: (t) => t.fileIndexId.equals(fileIndex.id!),
        );
        await FileIndex.db.deleteRow(session, fileIndex);

        session.log('Removed file from index: $path', level: LogLevel.info);
      }
    } catch (e) {
      session.log(
        'Failed to remove file $path from index: $e',
        level: LogLevel.error,
      );
    }
  }

  /// Initialize callbacks for the global WatcherManager
  void initializeWatcherCallbacks(Serverpod pod) {
    WatcherManager.setupCallbacks(
      onFilesChanged: (paths) async {
        final session = await pod.createSession(enableLogging: true);
        try {
          await reindexFiles(session, paths);
        } finally {
          await session.close();
        }
      },
      onFileRemoved: (path) async {
        final session = await pod.createSession(enableLogging: true);
        try {
          await removeFileFromIndex(session, path);
        } finally {
          await session.close();
        }
      },
    );
  }

  Future<void> _processIndexingJob(Serverpod pod, int jobId) async {
    final session = await pod.createSession(enableLogging: true);
    try {
      final job = await IndexingJob.db.findById(session, jobId);
      if (job == null) return;

      job.status = 'running';
      await IndexingJob.db.updateRow(session, job);

      final dir = Directory(job.folderPath);
      if (!await dir.exists()) {
        job.status = 'failed';
        await IndexingJob.db.updateRow(session, job);
        return;
      }

      final files = <File>[];
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && FileExtractionService.isSupported(entity.path)) {
          files.add(entity);
        }
      }

      job.totalFiles = files.length;
      await IndexingJob.db.updateRow(session, job);

      final extractionService = FileExtractionService();
      // ButlerEndpoint lazily creates services, we can do the same or use session.server
      final aiService = CachedAIService(
        client: OpenRouterClient(
          apiKey: getEnv('OPENROUTER_API_KEY'),
        ),
      );

      int consecutiveFailures = 0;
      const maxConsecutiveFailures = 10;

      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        // Check for cancellation
        final currentJob = await IndexingJob.db.findById(session, jobId);
        if (currentJob?.status == 'cancelled') return;

        try {
          // Skip if already indexed and unchanged
          final existing = await FileIndex.db.findFirstRow(
            session,
            where: (t) => t.path.equals(file.path),
          );

          if (existing != null && existing.status == 'indexed') {
            final stat = await file.stat();
            if (existing.fileModifiedAt?.isAtSameMomentAs(stat.modified) ??
                false) {
              job.skippedFiles++;
              // Only update DB every 20 skipped files or at the end
              if (job.skippedFiles % 20 == 0) {
                await IndexingJob.db.updateRow(session, job);
              }
              _notifyProgress(jobId, job);
              continue;
            }
          }

          // Full extraction and indexing
          await _indexFile(session, file, extractionService, aiService);

          job.processedFiles++;
          consecutiveFailures = 0; // Reset on success

          // Update DB every 5 files to reduce load
          if (job.processedFiles % 5 == 0 || i == files.length - 1) {
            await IndexingJob.db.updateRow(session, job);
          }
          _notifyProgress(jobId, job);
        } catch (e) {
          session.log(
            'Failed to index ${file.path}: $e',
            level: LogLevel.error,
          );

          consecutiveFailures++;

          // Try to update the record with error status if possible
          try {
            final existing = await FileIndex.db.findFirstRow(
              session,
              where: (t) => t.path.equals(file.path),
            );
            if (existing != null) {
              existing.status = 'failed';
              existing.errorMessage = e.toString();
              await FileIndex.db.updateRow(session, existing);
            }
          } catch (_) {}

          job.failedFiles++;
          await IndexingJob.db.updateRow(session, job);
          _notifyProgress(jobId, job);

          // Stop job if AI service seems completely unavailable
          if (consecutiveFailures >= maxConsecutiveFailures) {
            session.log(
              'Job $jobId aborted: Too many consecutive failures ($consecutiveFailures)',
              level: LogLevel.error,
            );
            job.status = 'failed';
            job.errorMessage =
                'Mass failures detected. AI service may be unavailable.';
            await IndexingJob.db.updateRow(session, job);
            return;
          }
        }
      }

      job.status = 'completed';
      job.completedAt = DateTime.now();
      await IndexingJob.db.updateRow(session, job);
      _notifyProgress(jobId, job);
    } catch (e) {
      session.log('Job $jobId failed: $e', level: LogLevel.error);
    } finally {
      await session.close();
      await _progressControllers[jobId]?.close();
      _progressControllers.remove(jobId);
    }
  }

  Future<void> _indexFile(
    Session session,
    File file,
    FileExtractionService extractionService,
    CachedAIService aiService,
  ) async {
    final path = file.path;

    await withFileLock(path, () async {
      try {
        final stat = await file.stat();

        // 1. Extract content
        final extraction = await extractionService.extractText(path);

        // 2. Prepare or update FileIndex entry
        var existing = await FileIndex.db.findFirstRow(
          session,
          where: (t) => t.path.equals(path),
        );

        final fileIndex = FileIndex(
          id: existing?.id,
          path: path,
          fileName: extraction.fileName,
          contentHash: extraction.contentHash,
          fileSizeBytes: extraction.fileSizeBytes,
          mimeType: extraction.mimeType,
          contentPreview: extraction.preview,
          isTextContent: FileExtractionService.isSupported(path),
          documentCategory: extraction.documentCategory,
          status: 'indexed',
          indexedAt: DateTime.now(),
          fileCreatedAt: stat.changed,
          fileModifiedAt: stat.modified,
          wordCount: extraction.wordCount,
          pageCount: extraction.pageCount,
          embeddingModel: 'openai/text-embedding-3-small',
        );

        // 3. Generate embeddings BEFORE transaction
        final contentToEmbed = extraction.content.length > 8000
            ? extraction.content.substring(0, 8000)
            : extraction.content;

        final embedding = await aiService.generateEmbedding(contentToEmbed);

        // 4. Perform database operations in a single short transaction
        await session.db.transaction((transaction) async {
          int fileIndexId;
          if (existing != null) {
            await FileIndex.db.updateRow(
              session,
              fileIndex,
              transaction: transaction,
            );
            fileIndexId = existing.id!;

            // Clear old embeddings for this file
            await DocumentEmbedding.db.deleteWhere(
              session,
              where: (t) => t.fileIndexId.equals(fileIndexId),
              transaction: transaction,
            );
          } else {
            final inserted = await FileIndex.db.insertRow(
              session,
              fileIndex,
              transaction: transaction,
            );
            fileIndexId = inserted.id!;
          }

          final docEmbedding = DocumentEmbedding(
            fileIndexId: fileIndexId,
            chunkIndex: 0,
            chunkText: contentToEmbed,
            embedding: Vector(embedding),
            embeddingJson: jsonEncode(embedding),
            dimensions: embedding.length,
          );

          await DocumentEmbedding.db.insertRow(
            session,
            docEmbedding,
            transaction: transaction,
          );
        });
      } catch (e) {
        session.log('Failed to index $path: $e', level: LogLevel.error);
        rethrow;
      }
    });
  }

  void _notifyProgress(int jobId, IndexingJob job) {
    final progress = IndexingProgress(
      jobId: jobId,
      status: job.status,
      processedFiles: job.processedFiles,
      totalFiles: job.totalFiles,
      failedFiles: job.failedFiles,
      skippedFiles: job.skippedFiles,
      progressPercent: job.totalFiles > 0
          ? (job.processedFiles / job.totalFiles * 100)
          : 0.0,
      timestamp: DateTime.now(),
    );
    _progressControllers[jobId]?.add(progress);
    // Also send via Serverpod messages for real-time updates if needed
  }

  Stream<IndexingProgress> streamProgress(Session session, int jobId) {
    final controller = _progressControllers.putIfAbsent(
      jobId,
      () => StreamController<IndexingProgress>.broadcast(),
    );
    return controller.stream;
  }

  static void startWatcherCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _cleanupCompletedProgressControllers();
    });
  }

  /// Clean up stream controllers for completed jobs to prevent memory leaks
  static void _cleanupCompletedProgressControllers() {
    final toRemove = <int>[];
    for (final entry in _progressControllers.entries) {
      if (entry.value.isClosed) {
        toRemove.add(entry.key);
      }
    }
    for (final jobId in toRemove) {
      _progressControllers.remove(jobId);
    }
  }

  /// Close and remove a specific job's progress controller
  static Future<void> closeProgressController(int jobId) async {
    final controller = _progressControllers.remove(jobId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }

  static void stopWatcherCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  static Future<void> disposeAllWatchers() async {
    await WatcherManager.dispose();
  }

  /// Recover jobs that were stuck in 'running' or 'queued' status (e.g. after crash)
  Future<void> recoverStuckJobs(Serverpod pod) async {
    final session = await pod.createSession(enableLogging: true);
    try {
      final stuckJobs = await IndexingJob.db.find(
        session,
        where: (t) => t.status.equals(JobStatus.running) | t.status.equals(JobStatus.queued),
      );

      for (final job in stuckJobs) {
        final jobId = job.id!;
        
        // Check if job is already being processed to prevent race condition
        if (_processingJobs.contains(jobId)) {
          session.log(
            'Job $jobId already being processed, skipping recovery',
            level: LogLevel.info,
          );
          continue;
        }
        
        session.log(
          'Recovering stuck job $jobId for ${job.folderPath}',
          level: LogLevel.info,
        );
        // Reset and restart
        job.status = JobStatus.queued;
        await IndexingJob.db.updateRow(session, job);
        
        // Mark as processing before starting
        _processingJobs.add(jobId);
        unawaited(_processIndexingJob(pod, jobId).whenComplete(() {
          _processingJobs.remove(jobId);
        }));
      }
    } catch (e) {
      session.log('Job recovery failed: $e', level: LogLevel.error);
    } finally {
      await session.close();
    }
  }

  /// Create a new indexing job for a client-managed process
  /// Returns null if the folder is already being indexed by another client
  Future<IndexingJob?> createClientJob(
    Session session,
    String folderPath,
    int totalFiles,
  ) async {
    // Check if folder is already being indexed
    if (isFolderLocked(folderPath)) {
      session.log(
        'Folder $folderPath is already being indexed by another client',
        level: LogLevel.warning,
      );
      return null;
    }

    // Check for existing active jobs on this folder
    final existingJobs = await IndexingJob.db.find(
      session,
      where: (t) =>
          t.folderPath.equals(folderPath) &
          (t.status.equals(JobStatus.running) | t.status.equals(JobStatus.queued)),
    );
    if (existingJobs.isNotEmpty) {
      session.log(
        'Active job already exists for $folderPath (job ${existingJobs.first.id})',
        level: LogLevel.warning,
      );
      return existingJobs.first; // Return existing job instead of creating duplicate
    }

    final job = IndexingJob(
      folderPath: folderPath,
      status: JobStatus.running,
      totalFiles: totalFiles,
      processedFiles: 0,
      failedFiles: 0,
      skippedFiles: 0,
      startedAt: DateTime.now(),
    );

    final inserted = await IndexingJob.db.insertRow(session, job);
    session.log(
      'Created client-managed indexing job ${inserted.id} for $folderPath',
      level: LogLevel.info,
    );
    return inserted;
  }

  /// Update the status and progress of a client-managed indexing job
  Future<IndexingJob?> updateJobStatus(
    Session session, {
    required int jobId,
    required String status,
    required int processedFiles,
    required int failedFiles,
    required int skippedFiles,
    String? errorMessage,
  }) async {
    final job = await IndexingJob.db.findById(session, jobId);
    if (job == null) {
      session.log(
        'Job $jobId not found for update',
        level: LogLevel.warning,
      );
      return null;
    }

    job.status = status;
    job.processedFiles = processedFiles;
    job.failedFiles = failedFiles;
    job.skippedFiles = skippedFiles;
    job.errorMessage = errorMessage;

    if (JobStatus.isTerminal(status)) {
      job.completedAt = DateTime.now();
    }

    await IndexingJob.db.updateRow(session, job);

    // Notify progress streams
    _notifyProgress(jobId, job);

    session.log(
      'Updated job $jobId: status=$status, progress=${job.processedFiles}/${job.totalFiles}',
      level: LogLevel.debug,
    );

    return job;
  }

  /// Create or update a detailed record for a specific file within a job
  Future<IndexingJobDetail> updateJobDetail(
    Session session, {
    required int jobId,
    required String filePath,
    required String status,
    String? errorMessage,
    String? errorCategory,
  }) async {
    // 1. Check if record already exists
    var detail = await IndexingJobDetail.db.findFirstRow(
      session,
      where: (t) => t.jobId.equals(jobId) & t.filePath.equals(filePath),
    );

    if (detail != null) {
      detail.status = status;
      detail.errorMessage = errorMessage;
      detail.errorCategory = errorCategory;
      if (JobDetailStatus.isTerminal(status)) {
        detail.completedAt = DateTime.now();
      }
      return await IndexingJobDetail.db.updateRow(session, detail);
    } else {
      detail = IndexingJobDetail(
        jobId: jobId,
        filePath: filePath,
        status: status,
        startedAt: DateTime.now(),
        errorMessage: errorMessage,
        errorCategory: errorCategory,
      );
      if (JobDetailStatus.isTerminal(status)) {
        detail.completedAt = DateTime.now();
      }
      return await IndexingJobDetail.db.insertRow(session, detail);
    }
  }

  Future<List<IndexingJobDetail>> getJobDetails(
    Session session,
    int jobId,
  ) async {
    return await IndexingJobDetail.db.find(
      session,
      where: (t) => t.jobId.equals(jobId),
      orderBy: (t) => t.id, // Or updatedAt
    );
  }

  /// Check if a file with the given path and hash already exists in the index
  Future<FileIndex?> checkHash(
    Session session,
    String path,
    String contentHash,
  ) async {
    return await FileIndex.db.findFirstRow(
      session,
      where: (t) => t.path.equals(path) & t.contentHash.equals(contentHash),
    );
  }

  /// Cancel an active indexing job
  Future<bool> cancelJob(Session session, int jobId) async {
    final job = await IndexingJob.db.findById(session, jobId);
    if (job == null) {
      session.log('Job $jobId not found for cancellation', level: LogLevel.warning);
      return false;
    }

    if (!JobStatus.isActive(job.status)) {
      session.log(
        'Job $jobId cannot be cancelled (status: ${job.status})',
        level: LogLevel.warning,
      );
      return false;
    }

    job.status = JobStatus.cancelled;
    job.completedAt = DateTime.now();
    job.errorMessage = 'Cancelled by user';
    await IndexingJob.db.updateRow(session, job);

    // Remove from processing jobs set
    _processingJobs.remove(jobId);

    // Close progress controller
    await closeProgressController(jobId);

    session.log('Job $jobId cancelled successfully', level: LogLevel.info);
    return true;
  }
}
