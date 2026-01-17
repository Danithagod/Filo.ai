import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:serverpod/serverpod.dart';
import '../../server.dart' show getEnv;
import '../generated/protocol.dart';
import '../services/openrouter_client.dart';
import '../services/ai_service.dart';
import '../services/cached_ai_service.dart';
import '../services/cache_service.dart';
import '../services/metrics_service.dart';
import '../services/file_extraction_service.dart';
import '../services/file_watcher_service.dart';
import '../services/auth_service.dart';
import '../services/rate_limit_service.dart';
import '../services/tag_taxonomy_service.dart';
import '../utils/validation.dart';
import '../config/ai_models.dart';

/// Main endpoint for Semantic Desktop Butler
/// Handles semantic search, document indexing, and status queries
///
/// Now powered by OpenRouter for multi-provider AI access
class ButlerEndpoint extends Endpoint {
  // Services - lazily initialized
  OpenRouterClient? _openRouterClient;
  AIService? _aiService;
  CachedAIService? _cachedAiService;
  final FileExtractionService _extractionService = FileExtractionService();
  final MetricsService _metrics = MetricsService.instance;

  /// Track all OpenRouterClient instances for cleanup
  static final List<OpenRouterClient> _allClients = [];

  /// Dispose the HTTP client when this endpoint is no longer needed
  void disposeClient() {
    _openRouterClient?.dispose();
    _openRouterClient = null;
    _aiService = null;
    _cachedAiService = null;
  }

  /// Dispose all resources (call on server shutdown)
  static Future<void> disposeAll() async {
    // Dispose all tracked HTTP clients
    for (final client in _allClients) {
      client.dispose();
    }
    _allClients.clear();

    // Also dispose file watchers
    await disposeAllWatchers();
  }

  /// File watcher instances per-session (for smart indexing)
  static final Map<String, FileWatcherService> _fileWatchers = {};

  /// Track last access time for each watcher to enable cleanup
  static final Map<String, DateTime> _fileWatcherLastAccess = {};

  /// Maximum age for idle file watchers before cleanup (30 minutes)
  static const Duration _watcherMaxIdleTime = Duration(minutes: 30);

  /// Clean up file watchers for sessions that have been idle too long
  /// Call this periodically or when system resources are low
  static Future<void> cleanupIdleWatchers() async {
    final now = DateTime.now();
    final expiredSessions = <String>[];

    for (final entry in _fileWatcherLastAccess.entries) {
      if (now.difference(entry.value) > _watcherMaxIdleTime) {
        expiredSessions.add(entry.key);
      }
    }

    for (final sessionId in expiredSessions) {
      await _cleanupWatcherForSession(sessionId);
    }
  }

  /// Clean up watcher for a specific session
  static Future<void> _cleanupWatcherForSession(String sessionId) async {
    final watcher = _fileWatchers.remove(sessionId);
    _fileWatcherLastAccess.remove(sessionId);
    if (watcher != null) {
      await watcher.dispose();
    }
  }

  /// Clean up all file watchers (call on server shutdown)
  static Future<void> disposeAllWatchers() async {
    for (final watcher in _fileWatchers.values) {
      await watcher.dispose();
    }
    _fileWatchers.clear();
    _fileWatcherLastAccess.clear();
  }

  /// Get OpenRouter API key from environment (.env file or system env)
  String get _openRouterApiKey => getEnv('OPENROUTER_API_KEY');

  /// Get OpenRouter client (lazily initialized)
  OpenRouterClient get openRouterClient {
    if (_openRouterClient == null) {
      _openRouterClient = OpenRouterClient(
        apiKey: _openRouterApiKey,
        siteUrl: getEnv(
          'OPENROUTER_SITE_URL',
          defaultValue: 'https://semantic-butler.app',
        ),
        siteName: getEnv(
          'OPENROUTER_SITE_NAME',
          defaultValue: 'Semantic Desktop Butler',
        ),
      );
      // Track for cleanup
      _allClients.add(_openRouterClient!);
    }
    return _openRouterClient!;
  }

  /// Get AI service (lazily initialized)
  AIService get aiService {
    _aiService ??= AIService(client: openRouterClient);
    return _aiService!;
  }

  /// Get cached AI service (lazily initialized) - use this for embeddings/summaries/tags
  CachedAIService get cachedAiService {
    _cachedAiService ??= CachedAIService(client: openRouterClient);
    return _cachedAiService!;
  }

  /// Get a client identifier from session for rate limiting
  /// Uses session ID as the primary identifier
  String _getClientIdentifier(Session session) {
    // Session doesn't expose HTTP request info directly in Serverpod,
    // so we use the session ID for rate limiting
    return session.sessionId.toString();
  }

  // ==========================================================================
  // SEMANTIC SEARCH
  // ==========================================================================

  /// Semantic search across indexed documents
  ///
  /// [query] - Natural language search query
  /// [limit] - Maximum number of results to return (default: 10)
  /// [threshold] - Minimum relevance score (0.0 to 1.0, default: 0.3)
  Future<List<SearchResult>> semanticSearch(
    Session session,
    String query, {
    int limit = 10,
    double threshold = 0.3,
  }) async {
    // Security: Validate authentication
    AuthService.requireAuth(session);

    // Security: Rate limiting (60 requests per minute)
    // Use composite key of IP + session ID to prevent bypass via session recreation
    final clientId = _getClientIdentifier(session);
    RateLimitService.instance.requireRateLimit(clientId, 'semanticSearch');

    // Security: Input validation
    InputValidation.validateLimit(limit);
    InputValidation.validateThreshold(threshold);
    if (query.isNotEmpty) {
      InputValidation.validateSearchQuery(query);
    }

    final stopwatch = Stopwatch()..start();

    try {
      // 0. Handle empty query: Return recently indexed documents
      if (query.trim().isEmpty) {
        final recentDocs = await FileIndex.db.find(
          session,
          where: (t) => t.status.equals('indexed'),
          orderBy: (t) => t.indexedAt,
          orderDescending: true,
          limit: limit,
        );

        return recentDocs.map((doc) {
          final tags = doc.tagsJson != null
              ? _parseTagList(doc.tagsJson!)
              : <String>[];

          return SearchResult(
            id: doc.id!,
            path: doc.path,
            fileName: doc.fileName,
            relevanceScore: 1.0, // Treat as highly relevant (recent)
            contentPreview: doc.contentPreview,
            tags: tags,
            indexedAt: doc.indexedAt,
            fileSizeBytes: doc.fileSizeBytes,
            mimeType: doc.mimeType,
          );
        }).toList();
      }

      // 1. Generate embedding for the query using OpenRouter
      final queryEmbedding = await aiService.generateEmbedding(query);

      // 2. Perform vector search using pgvector
      final queryEmbeddingJson = jsonEncode(queryEmbedding);
      final results = <_ScoredResult>[];

      try {
        // Use vector cosine similarity operator (<=>)
        // 1 - (a <=> b) gives cosine similarity
        // SECURITY: Using parameterized queries to prevent SQL injection
        // PERFORMANCE: Using JOIN to avoid N+1 query problem
        final searchQuery = '''
          SELECT
            de."fileIndexId",
            1 - (de.embedding <=> \$1::vector) as similarity,
            fi.id, fi.path, fi."fileName", fi."contentPreview",
            fi."tagsJson", fi."indexedAt", fi."fileSizeBytes", fi."mimeType"
          FROM document_embedding de
          JOIN file_index fi ON de."fileIndexId" = fi.id
          WHERE 1 - (de.embedding <=> \$1::vector) > \$2
          ORDER BY de.embedding <=> \$1::vector
          LIMIT \$3
        ''';

        final rows = await session.db.unsafeQuery(
          searchQuery,
          parameters: QueryParameters.positional([
            queryEmbeddingJson,
            threshold,
            limit,
          ]),
        );

        // Map rows directly to results without additional queries (N+1 fix)
        for (final row in rows) {
          final similarity = row[1] as double;
          final doc = FileIndex(
            id: row[2] as int,
            path: row[3] as String,
            fileName: row[4] as String,
            contentPreview: row[5] as String?,
            tagsJson: row[6] as String?,
            indexedAt: row[7] as DateTime?,
            fileSizeBytes: (row[8] as int?) ?? 0,
            mimeType: row[9] as String?,
            // Required fields with defaults
            contentHash: '',
            status: 'indexed',
            embeddingModel: '',
            isTextContent: true,
          );
          results.add(_ScoredResult(doc: doc, score: similarity));
        }
      } catch (e) {
        // Fallback to Dart-based search if pgvector fails (e.g. extension not installed)
        session.log(
          'pgvector search failed, falling back to Dart implementation: $e',
          level: LogLevel.warning,
        );

        // Original implementation as fallback
        final allDocs = await FileIndex.db.find(
          session,
          where: (t) => t.status.equals('indexed'),
        );

        for (final doc in allDocs) {
          final embeddings = await DocumentEmbedding.db.find(
            session,
            where: (t) => t.fileIndexId.equals(doc.id!),
          );

          if (embeddings.isEmpty) continue;

          double maxSimilarity = 0.0;
          for (final emb in embeddings) {
            final docEmbedding = _parseEmbedding(emb.embeddingJson);
            final similarity = _cosineSimilarity(queryEmbedding, docEmbedding);
            if (similarity > maxSimilarity) {
              maxSimilarity = similarity;
            }
          }

          if (maxSimilarity >= threshold) {
            results.add(_ScoredResult(doc: doc, score: maxSimilarity));
          }
        }

        results.sort((a, b) => b.score.compareTo(a.score));
      }

      final topResults = results.take(limit).toList();

      // 5. Log search history
      stopwatch.stop();
      await SearchHistory.db.insertRow(
        session,
        SearchHistory(
          query: query,
          resultCount: topResults.length,
          topResultId: topResults.isNotEmpty ? topResults.first.doc.id : null,
          queryTimeMs: stopwatch.elapsedMilliseconds,
          searchedAt: DateTime.now(),
        ),
      );

      // 6. Map to SearchResult DTOs
      return topResults.map((r) {
        final tags = r.doc.tagsJson != null
            ? _parseTagList(r.doc.tagsJson!)
            : <String>[];

        return SearchResult(
          id: r.doc.id!,
          path: r.doc.path,
          fileName: r.doc.fileName,
          relevanceScore: r.score,
          contentPreview: r.doc.contentPreview,
          tags: tags,
          indexedAt: r.doc.indexedAt,
          fileSizeBytes: r.doc.fileSizeBytes,
          mimeType: r.doc.mimeType,
        );
      }).toList();
    } catch (e) {
      session.log('Semantic search error: $e', level: LogLevel.error);
      rethrow;
    }
  }

  // ==========================================================================
  // DOCUMENT INDEXING
  // ==========================================================================

  /// Start indexing documents from specified folder path
  Future<IndexingJob> startIndexing(
    Session session,
    String folderPath,
  ) async {
    // Security: Validate authentication
    AuthService.requireAuth(session);

    // Security: Rate limiting (10 requests per minute for indexing)
    final clientId = _getClientIdentifier(session);
    RateLimitService.instance.requireRateLimit(
      clientId,
      'startIndexing',
      limit: 10,
    );

    // Security: Input validation
    InputValidation.validateFilePath(folderPath);

    // Create a new indexing job
    final job = IndexingJob(
      folderPath: folderPath,
      status: 'queued',
      totalFiles: 0,
      processedFiles: 0,
      failedFiles: 0,
      skippedFiles: 0,
    );

    final insertedJob = await IndexingJob.db.insertRow(session, job);

    // Start indexing in background with a new session
    // The original session will close when the request completes,
    // so we need to create a child session for the background work
    unawaited(_processIndexingJobSafe(session.serverpod, insertedJob.id!));

    return insertedJob;
  }

  /// Safe wrapper for background indexing job that creates its own session
  Future<void> _processIndexingJobSafe(Serverpod serverpod, int jobId) async {
    // Create a new internal session for background processing
    // This ensures the session stays open even after the HTTP request completes
    final session = await serverpod.createSession();

    try {
      // Fetch the job from database
      final job = await IndexingJob.db.findById(session, jobId);
      if (job == null) {
        session.log('Indexing job $jobId not found', level: LogLevel.error);
        return;
      }

      await _processIndexingJob(session, job);
    } catch (e, stackTrace) {
      session.log(
        'Background indexing job $jobId failed unexpectedly: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
    } finally {
      // Always close the session when done
      await session.close();
    }
  }

  /// Process an indexing job (background task)
  Future<void> _processIndexingJob(Session session, IndexingJob job) async {
    try {
      // Update job status to running
      job.status = 'running';
      job.startedAt = DateTime.now();
      await IndexingJob.db.updateRow(session, job);

      // Fetch ignore patterns from database
      List<String> ignorePatterns;
      try {
        ignorePatterns = await getIgnorePatternStrings(session);
        session.log(
          'Loaded ${ignorePatterns.length} ignore patterns',
          level: LogLevel.debug,
        );
      } catch (e) {
        session.log(
          'Failed to load ignore patterns, continuing without: $e',
          level: LogLevel.warning,
        );
        ignorePatterns = [];
      }

      // Scan directory for files (applying ignore patterns)
      List<String> files;
      try {
        files = await _extractionService
            .scanDirectory(job.folderPath, ignorePatterns: ignorePatterns)
            .timeout(const Duration(minutes: 5));
      } catch (e) {
        session.log('Failed to scan directory: $e', level: LogLevel.error);
        job.status = 'failed';
        job.errorMessage = 'Failed to scan directory: $e';
        job.completedAt = DateTime.now();
        await IndexingJob.db.updateRow(session, job);
        return;
      }

      job.totalFiles = files.length;
      await IndexingJob.db.updateRow(session, job);

      // Process files in batches - optimized for performance
      // Increased batch size and reduced delay with caching enabled
      const batchSize = 25; // Increased from 5 for better throughput
      for (var i = 0; i < files.length; i += batchSize) {
        try {
          final batch = files.sublist(
            i,
            i + batchSize > files.length ? files.length : i + batchSize,
          );

          final results = await _processBatch(
            session,
            batch,
          ).timeout(const Duration(minutes: 10));

          job.processedFiles += results.indexedCount;
          job.failedFiles += results.failedCount;
          job.skippedFiles += results.skippedCount;

          // Update progress
          await IndexingJob.db.updateRow(session, job);

          // Minimal delay between batches (caching reduces API load)
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          session.log('Batch processing failed: $e', level: LogLevel.warning);
          job.failedFiles += batchSize;
          await IndexingJob.db.updateRow(session, job);
          // Continue with next batch instead of failing entire job
        }
      }

      // Mark job as completed
      job.status = 'completed';
      job.completedAt = DateTime.now();
      await IndexingJob.db.updateRow(session, job);
    } catch (e, stackTrace) {
      session.log(
        'Indexing job failed: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );

      // Try to update job status, but don't fail if this also fails
      try {
        job.status = 'failed';
        job.errorMessage = e.toString().length > 500
            ? '${e.toString().substring(0, 500)}...'
            : e.toString();
        job.completedAt = DateTime.now();
        await IndexingJob.db.updateRow(session, job);
      } catch (updateError) {
        session.log(
          'Failed to update job status: $updateError',
          level: LogLevel.error,
        );
      }
    }
  }

  /// Process a batch of files
  Future<_BatchResult> _processBatch(
    Session session,
    List<String> filePaths,
  ) async {
    int indexed = 0;
    int failed = 0;
    int skipped = 0;

    // 1. Extract content and filter already indexed files
    final itemsToProcess = <_BatchItem>[];

    for (final path in filePaths) {
      try {
        final existing = await FileIndex.db.findFirstRow(
          session,
          where: (t) => t.path.equals(path),
        );

        // Retry extraction up to 3 times
        final extraction = await _retry(
          () => _extractionService.extractText(path),
          maxAttempts: 3,
        );

        // Skip if content unchanged
        if (existing != null &&
            existing.contentHash == extraction.contentHash) {
          skipped++;
          continue;
        }

        itemsToProcess.add(
          _BatchItem(
            path: path,
            extraction: extraction,
            existingIndex: existing,
          ),
        );
      } catch (e) {
        failed++;
        session.log('Failed to extract $path: $e', level: LogLevel.warning);
        await _recordIndexingError(session, path, 'Extraction failed: $e');
      }
    }

    if (itemsToProcess.isEmpty) {
      return _BatchResult(indexed, failed, skipped);
    }

    // 2. Generate summaries for large documents in parallel
    final summaryFutures = itemsToProcess.map((item) async {
      try {
        if (item.extraction.wordCount > 500) {
          return await _retry(
            () => aiService.summarize(
              item.extraction.content,
              maxWords: 250,
              focusArea: 'key topics and main ideas',
            ),
            maxAttempts: 2,
          );
        } else {
          return item.extraction.content;
        }
      } catch (e) {
        session.log(
          'Summary generation failed for ${item.path}, using preview: $e',
          level: LogLevel.warning,
        );
        return item.extraction.preview;
      }
    });

    final summaries = await Future.wait(summaryFutures);

    // 3. Generate embeddings from summaries (not full content)
    List<List<double>> embeddings;
    try {
      embeddings = await _retry(
        () => aiService.generateEmbeddings(summaries),
        maxAttempts: 3,
      );
    } catch (e) {
      session.log(
        'Failed to generate embeddings for batch: $e',
        level: LogLevel.error,
      );
      return _BatchResult(indexed, failed + itemsToProcess.length, skipped);
    }

    // 4. Process each file with its embedding in parallel (generating tags)
    final processingFutures = List.generate(itemsToProcess.length, (i) async {
      final item = itemsToProcess[i];
      final embedding = embeddings[i];
      final summary = summaries[i];

      try {
        // Generate tags
        final tags = await _retry(
          () => aiService.generateTags(
            item.extraction.content,
            fileName: item.extraction.fileName,
          ),
          maxAttempts: 2,
        );

        // Record tags in taxonomy for analytics
        try {
          await TagTaxonomyService.recordDocumentTags(session, tags);
        } catch (e) {
          // Don't fail indexing if taxonomy update fails
          session.log(
            'Failed to record tag taxonomy: $e',
            level: LogLevel.warning,
          );
        }

        // Create/Update FileIndex record
        final fileIndex = FileIndex(
          id: item.existingIndex?.id,
          path: item.path,
          fileName: item.extraction.fileName,
          contentHash: item.extraction.contentHash,
          fileSizeBytes: item.extraction.fileSizeBytes,
          mimeType: item.extraction.mimeType,
          contentPreview: item.extraction.preview,
          summary: item.extraction.wordCount > 500 ? summary : null,
          tagsJson: tags.toJson(),
          status: 'indexed',
          embeddingModel: AIModels.embeddingDefault,
          indexedAt: DateTime.now(),
          isTextContent: true,
          documentCategory: item.extraction.documentCategory,
          wordCount: item.extraction.wordCount,
          fileCreatedAt: item.extraction.fileCreatedAt,
          fileModifiedAt: item.extraction.fileModifiedAt,
        );

        FileIndex savedIndex;
        if (item.existingIndex != null) {
          savedIndex = await FileIndex.db.updateRow(session, fileIndex);

          // Delete old embeddings
          await DocumentEmbedding.db.deleteWhere(
            session,
            where: (t) => t.fileIndexId.equals(item.existingIndex!.id!),
          );
        } else {
          // Try insert, fall back to update if duplicate key
          try {
            savedIndex = await FileIndex.db.insertRow(session, fileIndex);
          } catch (e) {
            // Likely duplicate key - find existing and update instead
            final existing = await FileIndex.db.findFirstRow(
              session,
              where: (t) => t.path.equals(item.path),
            );
            if (existing != null) {
              fileIndex.id = existing.id;
              savedIndex = await FileIndex.db.updateRow(session, fileIndex);
              // Delete old embeddings
              await DocumentEmbedding.db.deleteWhere(
                session,
                where: (t) => t.fileIndexId.equals(existing.id!),
              );
            } else {
              rethrow; // Not a duplicate key issue
            }
          }
        }

        // Store embedding
        final embeddingRecord = await DocumentEmbedding.db.insertRow(
          session,
          DocumentEmbedding(
            fileIndexId: savedIndex.id!,
            chunkIndex: 0,
            chunkText: item.extraction.preview,
            embeddingJson: jsonEncode(embedding),
            dimensions: aiService.getEmbeddingDimensions(),
          ),
        );

        // Update vector column directly (optional - Dart fallback works without it)
        // SECURITY: Using parameterized query to prevent SQL injection
        try {
          await session.db.unsafeQuery(
            'UPDATE document_embedding SET embedding = \$1::vector WHERE id = \$2',
            parameters: QueryParameters.positional([
              jsonEncode(embedding),
              embeddingRecord.id,
            ]),
          );
        } catch (e) {
          // pgvector extension not installed - this is OK, Dart fallback works
          // Only log once per session to avoid log spam
        }

        return true; // Success
      } catch (e) {
        session.log(
          'Failed to index ${item.path}: $e',
          level: LogLevel.warning,
        );
        await _recordIndexingError(session, item.path, 'Indexing failed: $e');
        return false; // Failure
      }
    });

    final results = await Future.wait(processingFutures);
    for (final success in results) {
      if (success) {
        indexed++;
      } else {
        failed++;
      }
    }

    return _BatchResult(indexed, failed, skipped);
  }

  /// Record indexing error to database
  Future<void> _recordIndexingError(
    Session session,
    String path,
    String errorMessage,
  ) async {
    try {
      final existing = await FileIndex.db.findFirstRow(
        session,
        where: (t) => t.path.equals(path),
      );

      if (existing != null) {
        existing.status = 'failed';
        existing.errorMessage = errorMessage;
        await FileIndex.db.updateRow(session, existing);
      } else {
        await FileIndex.db.insertRow(
          session,
          FileIndex(
            path: path,
            fileName: path.split(Platform.pathSeparator).last,
            contentHash: '',
            fileSizeBytes: 0,
            status: 'failed',
            errorMessage: errorMessage,
            indexedAt: DateTime.now(),
            embeddingModel: AIModels.embeddingDefault,
            tagsJson: null,
            isTextContent: false,
          ),
        );
      }
    } catch (e) {
      session.log(
        'Failed to record indexing error for $path: $e',
        level: LogLevel.error,
      );
    }
  }

  /// Generic retry helper
  Future<T> _retry<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await action();
      } catch (e) {
        if (attempts >= maxAttempts) rethrow;
        await Future.delayed(delay * attempts); // Exponential-ish backoff
      }
    }
  }

  // ==========================================================================
  // STATUS & STATISTICS
  // ==========================================================================

  /// Get current indexing status
  Future<IndexingStatus> getIndexingStatus(Session session) async {
    final totalDocs = await FileIndex.db.count(session);
    final indexedDocs = await FileIndex.db.count(
      session,
      where: (t) => t.status.equals('indexed'),
    );
    final pendingDocs = await FileIndex.db.count(
      session,
      where: (t) => t.status.equals('pending'),
    );
    final failedDocs = await FileIndex.db.count(
      session,
      where: (t) => t.status.equals('failed'),
    );

    final activeJobs = await IndexingJob.db.count(
      session,
      where: (t) => t.status.equals('running'),
    );

    // Get last activity
    final lastIndexed = await FileIndex.db.findFirstRow(
      session,
      orderBy: (t) => t.indexedAt,
      orderDescending: true,
    );

    // Get recent jobs history
    final recentJobs = await IndexingJob.db.find(
      session,
      orderBy: (t) => t.startedAt,
      orderDescending: true,
      limit: 10,
    );

    // Calculate estimated time remaining for active jobs
    int? estimatedTimeRemainingSeconds;
    if (activeJobs > 0 && recentJobs.isNotEmpty) {
      final activeJob = recentJobs.firstWhere(
        (j) => j.status == 'running',
        orElse: () => recentJobs.first,
      );

      if (activeJob.startedAt != null && activeJob.totalFiles > 0) {
        final processed =
            activeJob.processedFiles +
            activeJob.failedFiles +
            activeJob.skippedFiles;
        final elapsed = DateTime.now()
            .difference(activeJob.startedAt!)
            .inSeconds;

        if (processed > 0 && elapsed > 0) {
          final filesPerSecond = processed / elapsed;
          final remaining = activeJob.totalFiles - processed;
          estimatedTimeRemainingSeconds = (remaining / filesPerSecond).ceil();
        }
      }
    }

    // Update metrics
    _metrics.setIndexedDocuments(indexedDocs);
    _metrics.setActiveJobs(activeJobs);

    return IndexingStatus(
      totalDocuments: totalDocs,
      indexedDocuments: indexedDocs,
      pendingDocuments: pendingDocs,
      failedDocuments: failedDocs,
      activeJobs: activeJobs,
      databaseSizeMb: await _estimateDatabaseSize(session),
      lastActivity: lastIndexed?.indexedAt,
      recentJobs: recentJobs,
      estimatedTimeRemainingSeconds: estimatedTimeRemainingSeconds,
      cacheHitRate: CacheService.instance.stats.hitRate,
    );
  }

  /// Get database statistics
  Future<DatabaseStats> getDatabaseStats(Session session) async {
    final fileCount = await FileIndex.db.count(session);
    final embeddingCount = await DocumentEmbedding.db.count(session);

    return DatabaseStats(
      totalSizeMb: await _estimateDatabaseSize(session),
      fileCount: fileCount,
      embeddingCount: embeddingCount,
      avgEmbeddingTimeMs: await _getAvgEmbeddingTime(session),
      lastUpdated: DateTime.now(),
    );
  }

  /// Get recent search history
  Future<List<SearchHistory>> getSearchHistory(
    Session session, {
    int limit = 20,
  }) async {
    return await SearchHistory.db.find(
      session,
      orderBy: (t) => t.searchedAt,
      orderDescending: true,
      limit: limit,
    );
  }

  /// Get AI usage statistics (cost tracking)
  Future<Map<String, dynamic>> getAIUsageStats(Session session) async {
    final stats = aiService.usageStats;
    return {
      'total_input_tokens': stats.totalInputTokens,
      'total_output_tokens': stats.totalOutputTokens,
      'total_tokens': stats.totalTokens,
      'estimated_cost_usd': stats.totalCost,
    };
  }

  /// Clear all indexed data
  Future<void> clearIndex(Session session) async {
    await DocumentEmbedding.db.deleteWhere(session, where: (t) => t.id > 0);
    await FileIndex.db.deleteWhere(session, where: (t) => t.id > 0);
    await IndexingJob.db.deleteWhere(session, where: (t) => t.id > 0);
  }

  // ==========================================================================
  // REAL-TIME STREAMING
  // ==========================================================================

  /// Stream real-time indexing progress for a specific job
  ///
  /// Yields [IndexingProgress] updates every 500ms while the job is running.
  /// Automatically completes when the job finishes or fails.
  Stream<IndexingProgress> streamIndexingProgress(
    Session session,
    int jobId,
  ) async* {
    // Security: Validate authentication
    AuthService.requireAuth(session);

    const updateInterval = Duration(milliseconds: 500);
    var isRunning = true;

    while (isRunning) {
      // Fetch current job state
      final job = await IndexingJob.db.findById(session, jobId);

      if (job == null) {
        // Job not found, emit error and stop
        yield IndexingProgress(
          jobId: jobId,
          status: 'not_found',
          totalFiles: 0,
          processedFiles: 0,
          failedFiles: 0,
          skippedFiles: 0,
          progressPercent: 0.0,
          timestamp: DateTime.now(),
        );
        return;
      }

      // Calculate progress percentage
      final totalProcessed =
          job.processedFiles + job.failedFiles + job.skippedFiles;
      final progressPercent = job.totalFiles > 0
          ? (totalProcessed / job.totalFiles * 100).clamp(0.0, 100.0)
          : 0.0;

      // Calculate estimated time remaining
      int? estimatedSecondsRemaining;
      if (job.startedAt != null && job.totalFiles > 0 && totalProcessed > 0) {
        final elapsed = DateTime.now().difference(job.startedAt!).inSeconds;
        if (elapsed > 0) {
          final filesPerSecond = totalProcessed / elapsed;
          if (filesPerSecond > 0) {
            final remaining = job.totalFiles - totalProcessed;
            estimatedSecondsRemaining = (remaining / filesPerSecond).ceil();
          }
        }
      }

      // Yield progress update
      yield IndexingProgress(
        jobId: jobId,
        status: job.status,
        totalFiles: job.totalFiles,
        processedFiles: job.processedFiles,
        failedFiles: job.failedFiles,
        skippedFiles: job.skippedFiles,
        progressPercent: progressPercent,
        estimatedSecondsRemaining: estimatedSecondsRemaining,
        currentFile: null, // Would need job-level tracking to populate
        timestamp: DateTime.now(),
      );

      // Check if job is still running
      if (job.status != 'running') {
        isRunning = false;
        continue;
      }

      // Wait before next update
      await Future.delayed(updateInterval);
    }
  }

  // ==========================================================================
  // SMART INDEXING (File Watching)
  // ==========================================================================

  /// Get or create a file watcher service for this session
  FileWatcherService _getFileWatcher(Session session) {
    final sessionId = session.sessionId.toString();
    if (!_fileWatchers.containsKey(sessionId)) {
      _fileWatchers[sessionId] = FileWatcherService(
        session,
        onFilesChanged: (paths) async {
          // Re-index changed files
          session.log(
            'Smart indexing: Re-indexing ${paths.length} changed files',
            level: LogLevel.info,
          );
          await _processBatch(session, paths);
        },
      );
    }
    // Update last access time to prevent cleanup while session is active
    _fileWatcherLastAccess[sessionId] = DateTime.now();
    return _fileWatchers[sessionId]!;
  }

  /// Enable smart indexing for a folder (starts file watching)
  Future<WatchedFolder> enableSmartIndexing(
    Session session,
    String folderPath,
  ) async {
    final watcher = _getFileWatcher(session);
    return await watcher.startWatching(folderPath);
  }

  /// Disable smart indexing for a folder (stops file watching)
  Future<void> disableSmartIndexing(
    Session session,
    String folderPath,
  ) async {
    final watcher = _getFileWatcher(session);
    await watcher.stopWatching(folderPath);
  }

  /// Get all watched folders
  Future<List<WatchedFolder>> getWatchedFolders(Session session) async {
    return await WatchedFolder.db.find(session);
  }

  /// Toggle smart indexing for a folder
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
      existing.isEnabled = false;
      await WatchedFolder.db.updateRow(session, existing);
      return existing;
    } else {
      return await enableSmartIndexing(session, folderPath);
    }
  }

  // ==========================================================================
  // IGNORE PATTERNS
  // ==========================================================================

  /// Add an ignore pattern
  /// [pattern] - Glob pattern like "*.log", "node_modules/**"
  /// [patternType] - Type: "file", "directory", or "both"
  Future<IgnorePattern> addIgnorePattern(
    Session session,
    String pattern, {
    String patternType = 'both',
    String? description,
  }) async {
    final ignorePattern = IgnorePattern(
      pattern: pattern,
      patternType: patternType,
      description: description,
      createdAt: DateTime.now(),
    );
    return await IgnorePattern.db.insertRow(session, ignorePattern);
  }

  /// Remove an ignore pattern by ID
  Future<int> removeIgnorePattern(Session session, int patternId) async {
    final deleted = await IgnorePattern.db.deleteWhere(
      session,
      where: (t) => t.id.equals(patternId),
    );
    return deleted.length;
  }

  /// List all ignore patterns
  Future<List<IgnorePattern>> listIgnorePatterns(Session session) async {
    return await IgnorePattern.db.find(
      session,
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
  }

  /// Get ignore patterns as list of strings for filtering
  /// Used by the indexing process to filter out ignored files
  Future<List<String>> getIgnorePatternStrings(Session session) async {
    final patterns = await IgnorePattern.db.find(session);
    return patterns.map((p) => p.pattern).toList();
  }

  // ==========================================================================
  // FILE REMOVAL
  // ==========================================================================

  /// Remove a file from the index by path or ID
  /// Returns true if the file was removed, false if not found
  Future<bool> removeFromIndex(
    Session session, {
    String? path,
    int? id,
  }) async {
    if (path == null && id == null) {
      throw ArgumentError('Either path or id must be provided');
    }

    FileIndex? fileIndex;
    if (id != null) {
      fileIndex = await FileIndex.db.findById(session, id);
    } else if (path != null) {
      fileIndex = await FileIndex.db.findFirstRow(
        session,
        where: (t) => t.path.equals(path),
      );
    }

    if (fileIndex == null) {
      return false;
    }

    // Delete associated embeddings first
    await DocumentEmbedding.db.deleteWhere(
      session,
      where: (t) => t.fileIndexId.equals(fileIndex!.id!),
    );

    // Delete the file index
    await FileIndex.db.deleteRow(session, fileIndex);

    return true;
  }

  /// Remove multiple files from the index by paths
  Future<int> removeMultipleFromIndex(
    Session session,
    List<String> paths,
  ) async {
    int removed = 0;
    for (final path in paths) {
      if (await removeFromIndex(session, path: path)) {
        removed++;
      }
    }
    return removed;
  }

  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================

  /// Parse embedding from JSON string
  List<double> _parseEmbedding(String json) {
    final List<dynamic> parsed = jsonDecode(json);
    return parsed.map((e) => (e as num).toDouble()).toList();
  }

  /// Parse tag list from JSON
  List<String> _parseTagList(String tagsJson) {
    try {
      final tags = DocumentTags.fromJson(tagsJson);
      return tags.toTagList();
    } catch (e) {
      return [];
    }
  }

  /// Calculate cosine similarity between two vectors
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }

    return dotProduct / (_sqrt(normA) * _sqrt(normB));
  }

  /// Square root helper
  double _sqrt(double x) {
    if (x < 0) throw ArgumentError('Cannot compute sqrt of negative number');
    if (x == 0) return 0;

    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  /// Estimate database size based on content
  /// This is an approximation based on indexed content
  Future<double> _estimateDatabaseSize(Session session) async {
    // Get total content size from file indices
    final files = await FileIndex.db.find(session);

    int totalBytes = 0;
    for (final file in files) {
      totalBytes += file.fileSizeBytes;
      // Estimate embedding storage (768 dimensions * 4 bytes per float)
      totalBytes += 768 * 4;
      // Estimate metadata overhead
      totalBytes += 500;
    }

    // Convert to MB
    return totalBytes / (1024 * 1024);
  }

  /// Get average embedding generation time from search history
  Future<double> _getAvgEmbeddingTime(Session session) async {
    final recentSearches = await SearchHistory.db.find(
      session,
      limit: 100,
      orderBy: (t) => t.searchedAt,
      orderDescending: true,
    );

    if (recentSearches.isEmpty) {
      return 0.0;
    }

    final totalMs = recentSearches.fold<int>(
      0,
      (sum, search) => sum + search.queryTimeMs,
    );

    return totalMs / recentSearches.length;
  }
}

/// Helper class for batch processing
class _BatchItem {
  final String path;
  final ExtractionResult extraction;
  final FileIndex? existingIndex;

  _BatchItem({
    required this.path,
    required this.extraction,
    this.existingIndex,
  });
}

/// Result of batch processing
class _BatchResult {
  final int indexedCount;
  final int failedCount;
  final int skippedCount;

  _BatchResult(this.indexedCount, this.failedCount, this.skippedCount);
}

/// Helper class for sorting search results by score
class _ScoredResult {
  final FileIndex doc;
  final double score;

  _ScoredResult({required this.doc, required this.score});
}
