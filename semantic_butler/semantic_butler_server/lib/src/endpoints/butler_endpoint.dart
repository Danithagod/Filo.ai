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
import '../services/search_preset_service.dart';
import '../services/ai_cost_service.dart';
import '../services/index_health_service.dart';
import '../services/summarization_service.dart';
import '../services/lock_service.dart';
import '../services/ai_search_service.dart';
import '../utils/validation.dart';
import '../config/ai_models.dart';
import '../constants/error_categories.dart';
import '../services/duplicate_detector.dart';
import '../services/naming_analyzer.dart';
import '../services/similarity_analyzer.dart';
import '../services/suggestion_service.dart';

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
    // Stop the watcher cleanup timer
    stopWatcherCleanup();

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

  /// Maximum number of concurrent file watchers to prevent memory exhaustion
  static const int _maxFileWatchers = 100;

  /// Paths currently being processed (Issue #4: Race condition prevention)
  /// Uses _processingPathsLock to ensure atomic check-and-add operations
  static final Set<String> _processingPaths = {};

  /// Lock for synchronizing access to _processingPaths
  /// In Dart's single-threaded async model, we use a simple Completer-based lock
  static Completer<void>? _processingPathsLock;

  /// Atomically check if paths are being processed and mark them if not
  /// Returns the list of paths that were successfully claimed (not already processing)
  static Future<List<String>> _claimPathsForProcessing(
    List<String> paths,
  ) async {
    // Wait for any existing lock
    while (_processingPathsLock != null) {
      await _processingPathsLock!.future;
    }

    // Create lock for this operation
    _processingPathsLock = Completer<void>();

    try {
      // Atomically filter and claim paths
      final claimedPaths = paths
          .where((p) => !_processingPaths.contains(p))
          .toList();
      _processingPaths.addAll(claimedPaths);
      return claimedPaths;
    } finally {
      // Release lock
      final lock = _processingPathsLock;
      _processingPathsLock = null;
      lock?.complete();
    }
  }

  /// Release claimed paths after processing
  static void _releaseProcessingPaths(List<String> paths) {
    _processingPaths.removeAll(paths);
  }

  /// Flag to log pgvector warning only once (Issue #12)
  static bool _pgvectorWarningLogged = false;

  /// Maximum age for idle file watchers before cleanup (30 minutes)
  static const Duration _watcherMaxIdleTime = Duration(minutes: 30);

  /// Timer for periodic cleanup of idle file watchers
  static Timer? _watcherCleanupTimer;

  /// Initialize periodic cleanup of file watchers
  /// Call this once during server startup
  static void initializeWatcherCleanup() {
    _watcherCleanupTimer?.cancel();
    // Run cleanup every 10 minutes
    _watcherCleanupTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => cleanupIdleWatchers(),
    );
  }

  /// Stop the watcher cleanup timer (call on server shutdown)
  static void stopWatcherCleanup() {
    _watcherCleanupTimer?.cancel();
    _watcherCleanupTimer = null;
  }

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
  /// [offset] - Number of results to skip for pagination (default: 0)
  /// Maximum allowed limit for search results to prevent DoS
  static const int _maxSearchLimit = 100;

  Future<List<SearchResult>> semanticSearch(
    Session session,
    String query, {
    int limit = 10,
    double threshold = 0.3,
    int offset = 0,
    SearchFilters? filters,
  }) async {
    // Security: Validate authentication
    AuthService.requireAuth(session);

    // Security: Rate limiting (60 requests per minute)
    // Use composite key of IP + session ID to prevent bypass via session recreation
    final clientId = _getClientIdentifier(session);
    RateLimitService.instance.requireRateLimit(clientId, 'semanticSearch');

    // Security: Input validation with max limit enforcement
    InputValidation.validateLimit(limit);
    InputValidation.validateThreshold(threshold);

    // Enforce maximum limit to prevent DoS
    if (limit > _maxSearchLimit) {
      limit = _maxSearchLimit;
      session.log(
        'Search limit capped to $_maxSearchLimit',
        level: LogLevel.debug,
      );
    }

    // Ensure non-negative offset with reasonable max
    offset = offset.clamp(0, 10000);

    if (query.isNotEmpty) {
      InputValidation.validateSearchQuery(query);
    }

    final stopwatch = Stopwatch()..start();
    final cacheKey = CacheService.semanticSearchKey(
      query,
      threshold,
      limit,
      offset,
    );

    try {
      // Check cache first for non-empty queries (empty ones have their own cache handler below)
      if (query.trim().isNotEmpty) {
        final cached = CacheService.instance.get<List<SearchResult>>(cacheKey);
        if (cached != null) {
          session.log(
            'Semantic search cache hit for query: $query',
            level: LogLevel.debug,
          );
          stopwatch.stop();
          _logSearchAnalytics(
            session,
            query: query,
            searchType: 'semantic_cached',
            resultCount: cached.length,
            queryTimeMs: stopwatch.elapsedMilliseconds,
          );
          return cached;
        }
      }
      // 0. Handle empty query: Return recently indexed documents
      if (query.trim().isEmpty) {
        // Check cache for recent documents
        final recentCacheKey = CacheService.recentDocsKey(limit, offset);
        final cachedRecent = CacheService.instance.get<List<SearchResult>>(
          recentCacheKey,
        );
        if (cachedRecent != null) {
          session.log(
            'Recent docs cache hit (limit: $limit, offset: $offset)',
            level: LogLevel.debug,
          );
          return cachedRecent;
        }

        final recentDocs = await FileIndex.db.find(
          session,
          where: (t) => t.status.equals('indexed'),
          orderBy: (t) => t.indexedAt,
          orderDescending: true,
          limit: limit,
          offset: offset,
        );

        final results = recentDocs.map((doc) {
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

        // Cache recent docs with short TTL (1 minute)
        CacheService.instance.set(
          recentCacheKey,
          results,
          ttl: CacheService.recentDocsTtl,
        );

        return results;
      }

      // 1. Generate embedding for the query using OpenRouter with caching
      final queryEmbedding = await cachedAiService.generateEmbedding(query);

      // 2. Perform vector search using pgvector
      final queryEmbeddingJson = jsonEncode(queryEmbedding);
      final results = <_ScoredResult>[];

      try {
        // Use vector cosine similarity operator (<=>)
        // 1 - (a <=> b) gives cosine similarity
        // SECURITY: Using parameterized queries to prevent SQL injection
        // PERFORMANCE: Using JOIN to avoid N+1 query problem
        // Build dynamic WHERE clause for filters
        final whereConditions = <String>[
          '1 - (de.embedding <=> \$1::vector) > \$2',
        ];
        final parameters = <dynamic>[queryEmbeddingJson, threshold];
        // Start parameter index at 3 (since 1 and 2 are used above)
        int paramIndex = 3;

        if (filters != null) {
          // Date Range
          if (filters.dateFrom != null) {
            whereConditions.add('fi."indexedAt" >= \$$paramIndex');
            parameters.add(filters.dateFrom);
            paramIndex++;
          }
          if (filters.dateTo != null) {
            whereConditions.add('fi."indexedAt" <= \$$paramIndex');
            parameters.add(filters.dateTo);
            paramIndex++;
          }

          // File Size
          if (filters.minSize != null) {
            whereConditions.add('fi."fileSizeBytes" >= \$$paramIndex');
            parameters.add(filters.minSize);
            paramIndex++;
          }
          if (filters.maxSize != null) {
            whereConditions.add('fi."fileSizeBytes" <= \$$paramIndex');
            parameters.add(filters.maxSize);
            paramIndex++;
          }

          // File Types (using OR condition for multiple types)
          if (filters.fileTypes != null && filters.fileTypes!.isNotEmpty) {
            final typeConditions = <String>[];
            for (final type in filters.fileTypes!) {
              // Simple mapping from UI types to mime/extensions
              // In reality, this should be more robust
              if (type == 'pdf') {
                typeConditions.add('fi."mimeType" ILIKE \$$paramIndex');
                parameters.add('%pdf%');
                paramIndex++;
              } else if (type == 'image') {
                typeConditions.add('fi."mimeType" ILIKE \$$paramIndex');
                parameters.add('image/%');
                paramIndex++;
              } else if (type == 'doc') {
                typeConditions.add(
                  '(fi."mimeType" ILIKE \$$paramIndex OR fi."fileName" ILIKE \$$paramIndex)',
                );
                parameters.add('%word%'); // rudimentary check
                paramIndex++; // Reuse or increment? Need separate params
                // Actually let's just use simpler Extension check for now if MIME is unreliable
                // But let's stick to MIME pattern matching for simplicity of this block
              } else {
                // Generic fallback
                typeConditions.add('fi."fileName" ILIKE \$$paramIndex');
                parameters.add('%.$type%');
                paramIndex++;
              }
            }
            if (typeConditions.isNotEmpty) {
              whereConditions.add('(${typeConditions.join(" OR ")})');
            }
          }

          // Tags (JSON containment)
          if (filters.tags != null && filters.tags!.isNotEmpty) {
            for (final tag in filters.tags!) {
              // Postgres JSONB containment: tagsJson @> '["tag"]'
              // But tagsJson is String in Serverpod model, likely text in PG
              // If it's text, we use ILIKE. If JSONB, we use operator.
              // Assuming text for compatibility:
              whereConditions.add('fi."tagsJson" ILIKE \$$paramIndex');
              parameters.add('%"$tag"%');
              paramIndex++;
            }
          }
        }

        // Add LIMIT and OFFSET parameters
        final limitParamIndex = paramIndex;
        final offsetParamIndex = paramIndex + 1;
        parameters.add(limit);
        parameters.add(offset);

        final searchQuery =
            '''
          SELECT
            de."fileIndexId",
            1 - (de.embedding <=> \$1::vector) as similarity,
            fi.id, fi.path, fi."fileName", fi."contentPreview",
            fi."tagsJson", fi."indexedAt", fi."fileSizeBytes", fi."mimeType"
          FROM document_embedding de
          JOIN file_index fi ON de."fileIndexId" = fi.id
          WHERE ${whereConditions.join(" AND ")}
          ORDER BY de.embedding <=> \$1::vector
          LIMIT \$$limitParamIndex OFFSET \$$offsetParamIndex
        ''';

        final rows = await session.db.unsafeQuery(
          searchQuery,
          parameters: QueryParameters.positional(parameters),
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
          searchType: 'semantic',
          directoryContext:
              null, // Semantic searches are not directory-specific
        ),
      );

      // 6. Map to SearchResult DTOs and cache
      final searchResults = topResults.map((r) {
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

      // Cache the results for future queries (5 minute TTL)
      CacheService.instance.set(
        cacheKey,
        searchResults,
        ttl: CacheService.searchResultTtl,
      );

      // Log search analytics
      _logSearchAnalytics(
        session,
        query: query,
        searchType: 'semantic',
        resultCount: searchResults.length,
        queryTimeMs: stopwatch.elapsedMilliseconds,
      );

      return searchResults;
    } catch (e) {
      session.log('Semantic search error: $e', level: LogLevel.error);
      rethrow;
    }
  }

  // ==========================================================================
  // ADVANCED SEARCH
  // ==========================================================================

  /// Get search suggestions based on query
  Future<List<SearchSuggestion>> getSearchSuggestions(
    Session session,
    String query, {
    int limit = 10,
  }) async {
    AuthService.requireAuth(session);
    return SuggestionService().getSuggestions(
      session,
      query,
      limit: limit,
    );
  }

  /// Save a search preset
  Future<SavedSearchPreset> savePreset(
    Session session,
    SavedSearchPreset preset,
  ) async {
    AuthService.requireAuth(session);
    return SearchPresetService.savePreset(session, preset);
  }

  /// Get saved search presets
  Future<List<SavedSearchPreset>> getSavedPresets(
    Session session,
  ) async {
    AuthService.requireAuth(session);
    return SearchPresetService.getSavedPresets(session);
  }

  /// Delete a saved search preset
  Future<bool> deletePreset(
    Session session,
    int presetId,
  ) async {
    AuthService.requireAuth(session);
    return SearchPresetService.deletePreset(session, presetId);
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
        job.errorCategory = _categorizeError(e);
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
        job.errorCategory = _categorizeError(e);
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
      // Try to acquire lock for this file
      final locked = await LockService.tryAcquireLock(session, path);

      if (!locked) {
        // Another thread is processing this file, skip it
        session.log(
          'File already being processed, skipping: $path',
          level: LogLevel.info,
        );
        skipped++;
        continue;
      }

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
          session.log(
            'Content unchanged, skipping: $path',
            level: LogLevel.debug,
          );
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
        final errorCategory = _categorizeError(e);
        session.log(
          'Failed to extract $path [$errorCategory]: $e',
          level: LogLevel.warning,
        );
        await _recordIndexingError(
          session,
          path,
          'Extraction failed: $e',
          errorCategory: errorCategory,
        );
      } finally {
        // Always release lock
        await LockService.releaseLock(session, path);
      }
    }

    if (itemsToProcess.isEmpty) {
      return _BatchResult(indexed, failed, skipped);
    }

    // 2. Generate summaries for large documents in parallel
    // 2. Generate summaries for large documents in parallel
    final summaryResults = await Future.wait(
      itemsToProcess.map((item) async {
        try {
          if (item.extraction.wordCount > 500) {
            final docSummary = await SummarizationService.generateSummary(
              session,
              item.extraction.content,
              openRouterClient,
              fileName: item.extraction.fileName,
            );
            return (
              summaryForDb: jsonEncode(docSummary.toJson()),
              textForEmbedding: SummarizationService.getEmbeddingSummary(
                docSummary,
              ),
            );
          } else {
            return (
              summaryForDb: null as String?, // No summary for short docs
              textForEmbedding: item.extraction.content,
            );
          }
        } catch (e) {
          session.log(
            'Summary generation failed for ${item.path}, using preview: $e',
            level: LogLevel.warning,
          );
          return (
            summaryForDb: null as String?,
            textForEmbedding: item.extraction.preview,
          );
        }
      }),
    );

    // 3. Generate embeddings from summaries/content
    final embeddingTexts = summaryResults
        .map((e) => e.textForEmbedding)
        .toList();
    List<List<double>> embeddings;
    try {
      embeddings = await _retry(
        () => aiService.generateEmbeddings(embeddingTexts),
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
      final summary = summaryResults[i].summaryForDb;

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

        // TRANSACTION: Wrap all database operations atomically
        await session.db.transaction((transaction) async {
          // Create/Update FileIndex record
          final fileIndex = FileIndex(
            id: item.existingIndex?.id,
            path: item.path,
            fileName: item.extraction.fileName,
            contentHash: item.extraction.contentHash,
            fileSizeBytes: item.extraction.fileSizeBytes,
            mimeType: item.extraction.mimeType,
            contentPreview: item.extraction.preview,
            summary: summary,
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
            savedIndex = await FileIndex.db.updateRow(
              session,
              fileIndex,
              transaction: transaction,
            );

            // Delete old embeddings
            await DocumentEmbedding.db.deleteWhere(
              session,
              where: (t) => t.fileIndexId.equals(item.existingIndex!.id!),
              transaction: transaction,
            );
          } else {
            // Try insert, fall back to update if duplicate key
            try {
              savedIndex = await FileIndex.db.insertRow(
                session,
                fileIndex,
                transaction: transaction,
              );
            } catch (e) {
              // Likely duplicate key - find existing and update instead
              final existing = await FileIndex.db.findFirstRow(
                session,
                where: (t) => t.path.equals(item.path),
                transaction: transaction,
              );
              if (existing != null) {
                fileIndex.id = existing.id;
                savedIndex = await FileIndex.db.updateRow(
                  session,
                  fileIndex,
                  transaction: transaction,
                );
                // Delete old embeddings
                await DocumentEmbedding.db.deleteWhere(
                  session,
                  where: (t) => t.fileIndexId.equals(existing.id!),
                  transaction: transaction,
                );
              } else {
                rethrow; // Not a duplicate key issue
              }
            }
          }

          // Issue #13: Store embeddings - use chunking for long documents
          if (item.extraction.wordCount > 1000) {
            // Long document - split into chunks and generate embeddings for each
            final chunks = _chunkText(item.extraction.content);
            session.log(
              'Long document (${item.extraction.wordCount} words), creating ${chunks.length} chunks: ${item.path}',
              level: LogLevel.debug,
            );

            for (var i = 0; i < chunks.length; i++) {
              try {
                // Generate embedding for this chunk
                final chunkEmbedding = await aiService.generateEmbedding(
                  chunks[i],
                );
                final chunkPreview = chunks[i].length > 500
                    ? '${chunks[i].substring(0, 500)}...'
                    : chunks[i];

                final chunkRecord = await DocumentEmbedding.db.insertRow(
                  session,
                  DocumentEmbedding(
                    fileIndexId: savedIndex.id!,
                    chunkIndex: i,
                    chunkText: chunkPreview,
                    embeddingJson: jsonEncode(chunkEmbedding),
                    dimensions: aiService.getEmbeddingDimensions(),
                  ),
                  transaction: transaction,
                );

                // Update vector column
                try {
                  await session.db.unsafeQuery(
                    'UPDATE document_embedding SET embedding = \$1::vector WHERE id = \$2',
                    parameters: QueryParameters.positional([
                      jsonEncode(chunkEmbedding),
                      chunkRecord.id,
                    ]),
                  );
                } catch (e) {
                  if (!_pgvectorWarningLogged) {
                    session.log(
                      'pgvector extension not available, using Dart fallback: $e',
                      level: LogLevel.warning,
                    );
                    _pgvectorWarningLogged = true;
                  }
                }
              } catch (e) {
                session.log(
                  'Failed to create chunk $i for ${item.path}: $e',
                  level: LogLevel.warning,
                );
              }
            }
          } else {
            // Short document - single embedding (original behavior)
            final embeddingRecord = await DocumentEmbedding.db.insertRow(
              session,
              DocumentEmbedding(
                fileIndexId: savedIndex.id!,
                chunkIndex: 0,
                chunkText: item.extraction.preview,
                embeddingJson: jsonEncode(embedding),
                dimensions: aiService.getEmbeddingDimensions(),
              ),
              transaction: transaction,
            );

            // Update vector column directly (optional - Dart fallback works without it)
            try {
              await session.db.unsafeQuery(
                'UPDATE document_embedding SET embedding = \$1::vector WHERE id = \$2',
                parameters: QueryParameters.positional([
                  jsonEncode(embedding),
                  embeddingRecord.id,
                ]),
              );
            } catch (e) {
              // Issue #12: Log pgvector failure once per session
              if (!_pgvectorWarningLogged) {
                session.log(
                  'pgvector extension not available, using Dart fallback for vector search: $e',
                  level: LogLevel.warning,
                );
                _pgvectorWarningLogged = true;
              }
            }
          }
        }); // End transaction

        return true; // Success
      } catch (e) {
        final errorCategory = _categorizeError(e);
        session.log(
          'Failed to index ${item.path} [$errorCategory]: $e',
          level: LogLevel.warning,
        );
        await _recordIndexingError(
          session,
          item.path,
          'Indexing failed: $e',
          errorCategory: errorCategory,
        );
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

  /// Record indexing error to database with categorization
  Future<void> _recordIndexingError(
    Session session,
    String path,
    String errorMessage, {
    String? errorCategory,
  }) async {
    try {
      final existing = await FileIndex.db.findFirstRow(
        session,
        where: (t) => t.path.equals(path),
      );

      if (existing != null) {
        existing.status = 'failed';
        existing.errorMessage = errorMessage;
        // Note: FileIndex doesn't have errorCategory, only IndexingJob does
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

  /// Categorize error based on error message/exception
  String _categorizeError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Check for specific error patterns
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return ErrorCategory.apiTimeout;
    }
    if (errorStr.contains('permission') || errorStr.contains('access denied')) {
      return ErrorCategory.permissionDenied;
    }
    if (errorStr.contains('corrupt') ||
        errorStr.contains('invalid format') ||
        errorStr.contains('malformed')) {
      return ErrorCategory.corruptFile;
    }
    if (errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('socket')) {
      return ErrorCategory.networkError;
    }
    if (errorStr.contains('unsupported') ||
        errorStr.contains('not supported')) {
      return ErrorCategory.unsupportedFormat;
    }
    if (errorStr.contains('disk') ||
        errorStr.contains('space') ||
        errorStr.contains('quota')) {
      return ErrorCategory.insufficientDiskSpace;
    }

    return ErrorCategory.unknown;
  }

  // ==========================================================================
  // STATUS & STATISTICS
  // ==========================================================================

  /// Get current indexing status
  Future<IndexingStatus> getIndexingStatus(Session session) async {
    final activeJobsList = await IndexingJob.db.find(
      session,
      where: (t) => t.status.equals('running'),
    );
    final activeJobs = activeJobsList.length;

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

    // Calculate dynamic total: include files in jobs that aren't yet in FileIndex
    var totalDocs = await FileIndex.db.count(session);
    for (final job in activeJobsList) {
      // If job is discovering files, its totalFiles might be higher than what's in DB
      final pendingInJob = job.totalFiles - job.processedFiles;
      if (pendingInJob > 0) {
        totalDocs += pendingInJob;
      }
    }

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

  /// Get error statistics aggregated by category
  ///
  /// [timeRange] - Filter by time: "24h", "7d", "30d", or "all" (default: "all")
  /// [category] - Filter by specific error category (optional)
  /// [jobId] - Filter by specific indexing job (optional)
  Future<ErrorStats> getErrorStats(
    Session session, {
    String? timeRange,
    String? category,
    int? jobId,
  }) async {
    // Security: Validate authentication
    AuthService.requireAuth(session);

    // Build date filter based on timeRange
    DateTime? cutoffDate;
    final now = DateTime.now();
    switch (timeRange) {
      case '24h':
        cutoffDate = now.subtract(const Duration(hours: 24));
        break;
      case '7d':
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case '30d':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      default:
        cutoffDate = null; // No time filter
    }

    // Query failed job details with basic filters
    var failedDetails = await IndexingJobDetail.db.find(
      session,
      where: (t) {
        var condition = t.status.equals('failed');

        if (jobId != null) {
          condition = condition & t.jobId.equals(jobId);
        }

        if (category != null) {
          condition = condition & t.errorCategory.equals(category);
        }

        return condition;
      },
    );

    // Apply date filter in-memory (Serverpod 3.1.0 doesn't have date comparison operators)
    if (cutoffDate != null) {
      failedDetails = failedDetails.where((d) {
        final completedAt = d.completedAt;
        return completedAt != null && completedAt.isAfter(cutoffDate!);
      }).toList();
    }

    // Aggregate by category
    final categoryCounts = <String, int>{};
    for (final detail in failedDetails) {
      final cat = detail.errorCategory ?? ErrorCategory.unknown;
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    // Calculate total and percentages
    final totalErrors = failedDetails.length;
    final byCategory = categoryCounts.entries.map((entry) {
      return ErrorCategoryCount(
        category: entry.key,
        count: entry.value,
        percentage: totalErrors > 0 ? (entry.value / totalErrors) * 100 : 0.0,
      );
    }).toList();

    // Sort by count descending
    byCategory.sort((a, b) => b.count.compareTo(a.count));

    return ErrorStats(
      totalErrors: totalErrors,
      byCategory: byCategory,
      timeRange: timeRange,
      jobId: jobId,
      generatedAt: DateTime.now(),
    );
  }

  /// Get recent search history with pagination support
  Future<List<SearchHistory>> getSearchHistory(
    Session session, {
    int limit = 20,
    int offset = 0,
    String? searchType, // Filter by 'semantic', 'local', or 'hybrid'
  }) async {
    if (searchType != null) {
      return await SearchHistory.db.find(
        session,
        orderBy: (t) => t.searchedAt,
        orderDescending: true,
        limit: limit,
        offset: offset,
        where: (t) => t.searchType.equals(searchType),
      );
    }
    return await SearchHistory.db.find(
      session,
      orderBy: (t) => t.searchedAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );
  }

  /// Delete a specific search history item by ID
  Future<bool> deleteSearchHistoryItem(Session session, int searchId) async {
    try {
      final item = await SearchHistory.db.findById(session, searchId);
      if (item == null) {
        return false;
      }
      await SearchHistory.db.deleteRow(session, item);
      return true;
    } catch (e) {
      session.log(
        'Failed to delete search history item: $e',
        level: LogLevel.error,
      );
      return false;
    }
  }

  /// Clear all search history
  Future<int> clearSearchHistory(Session session) async {
    try {
      final deleted = await SearchHistory.db.deleteWhere(
        session,
        where: (t) => t.id > 0,
      );
      return deleted.length;
    } catch (e) {
      session.log('Failed to clear search history: $e', level: LogLevel.error);
      return 0;
    }
  }

  /// Record a local file search to history
  ///
  /// [query] - Search query string
  /// [directoryPath] - Directory where search was performed
  /// [resultCount] - Number of results found
  Future<void> recordLocalSearch(
    Session session,
    String query,
    String directoryPath,
    int resultCount,
  ) async {
    try {
      await SearchHistory.db.insertRow(
        session,
        SearchHistory(
          query: query,
          resultCount: resultCount,
          queryTimeMs: 0, // Local search timing not tracked
          searchedAt: DateTime.now(),
          searchType: 'local',
          directoryContext: directoryPath,
        ),
      );
    } catch (e) {
      session.log('Failed to record local search: $e', level: LogLevel.warning);
      // Don't throw - search history failure shouldn't break the UI
    }
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
      // Check if we've hit the max watchers limit
      if (_fileWatchers.length >= _maxFileWatchers) {
        // Clean up idle watchers first
        cleanupIdleWatchers();

        // If still at limit, remove the oldest watcher
        if (_fileWatchers.length >= _maxFileWatchers) {
          String? oldestSessionId;
          DateTime? oldestAccess;
          for (final entry in _fileWatcherLastAccess.entries) {
            if (oldestAccess == null || entry.value.isBefore(oldestAccess)) {
              oldestAccess = entry.value;
              oldestSessionId = entry.key;
            }
          }
          if (oldestSessionId != null) {
            session.log(
              'Max file watchers reached, removing oldest: $oldestSessionId',
              level: LogLevel.warning,
            );
            _cleanupWatcherForSession(oldestSessionId);
          }
        }
      }

      _fileWatchers[sessionId] = FileWatcherService(
        session,
        onFilesChanged: (paths) async {
          // Issue #4: Atomically claim paths for processing (race condition prevention)
          // This prevents multiple watchers from processing the same paths
          final pathsToProcess = await _claimPathsForProcessing(paths);
          if (pathsToProcess.isEmpty) {
            session.log(
              'Smart indexing: All ${paths.length} files already being processed, skipping',
              level: LogLevel.debug,
            );
            return;
          }

          // Issue #18: Rate limit auto-index operations
          final clientId = sessionId;
          final allowed = RateLimitService.instance.checkAndConsume(
            clientId,
            'auto-index',
            limit: 30, // 30 files per minute for auto-index
          );
          if (!allowed) {
            session.log(
              'Auto-index rate limited, deferring ${pathsToProcess.length} files',
              level: LogLevel.warning,
            );
            // Release claimed paths since we're not processing them
            _releaseProcessingPaths(pathsToProcess);
            return;
          }

          // Use background session for processing to prevent blocking the main session
          // and to ensure locks are managed independently
          final bgSession = await session.serverpod.createSession();
          try {
            session.log(
              'Smart indexing: Re-indexing ${pathsToProcess.length} changed files',
              level: LogLevel.info,
            );
            await _handleFilesChanged(bgSession, pathsToProcess);
          } catch (e, stackTrace) {
            session.log(
              'Error in background indexing: $e',
              level: LogLevel.error,
              stackTrace: stackTrace,
            );
          } finally {
            _releaseProcessingPaths(pathsToProcess);
            await bgSession.close();
          }
        },
        onFileRemoved: (path) async {
          // Use background session with locking for removal
          final bgSession = await session.serverpod.createSession();
          try {
            await LockService.withLock(bgSession, path, () async {
              // Issue #1: Properly remove file from index when deleted
              await _removeFileFromIndex(bgSession, path);
            });
          } catch (e) {
            session.log(
              'Error removing file $path: $e',
              level: LogLevel.error,
            );
          } finally {
            await bgSession.close();
          }
        },
      );

      // Load and set ignore patterns for the watcher
      _loadIgnorePatternsForWatcher(session, sessionId);
    }
    // Update last access time to prevent cleanup while session is active
    _fileWatcherLastAccess[sessionId] = DateTime.now();
    return _fileWatchers[sessionId]!;
  }

  /// Load ignore patterns and set them on the file watcher
  Future<void> _loadIgnorePatternsForWatcher(
    Session session,
    String sessionId,
  ) async {
    try {
      final patterns = await getIgnorePatternStrings(session);
      final watcher = _fileWatchers[sessionId];
      if (watcher != null && patterns.isNotEmpty) {
        watcher.setIgnorePatterns(patterns);
        session.log(
          'Loaded ${patterns.length} ignore patterns for file watcher',
          level: LogLevel.debug,
        );
      }
    } catch (e) {
      session.log(
        'Failed to load ignore patterns for file watcher: $e',
        level: LogLevel.warning,
      );
    }
  }

  /// Internal method to remove a file from the index (Issue #1: File removal implementation)
  ///
  /// Deletes the FileIndex record and associated DocumentEmbedding records
  /// for a file that has been deleted from the filesystem.
  /// This is called by the file watcher when a file is deleted.
  Future<void> _removeFileFromIndex(Session session, String filePath) async {
    try {
      final existing = await FileIndex.db.findFirstRow(
        session,
        where: (t) => t.path.equals(filePath),
      );

      if (existing == null) {
        session.log(
          'File not in index, nothing to remove: $filePath',
          level: LogLevel.debug,
        );
        return;
      }

      // TRANSACTION: Delete embeddings and file index atomically
      await session.db.transaction((transaction) async {
        // Delete embeddings first (foreign key dependency)
        final deletedEmbeddings = await DocumentEmbedding.db.deleteWhere(
          session,
          where: (t) => t.fileIndexId.equals(existing.id!),
          transaction: transaction,
        );

        // Delete file index record
        await FileIndex.db.deleteRow(
          session,
          existing,
          transaction: transaction,
        );

        session.log(
          'Removed from index: $filePath (${deletedEmbeddings.length} embeddings)',
          level: LogLevel.info,
        );
      });
    } catch (e) {
      session.log(
        'Failed to remove from index: $filePath - $e',
        level: LogLevel.error,
      );
      rethrow;
    }
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

    return await session.db.transaction((transaction) async {
      // 1. Handle deletion by ID (specific file)
      if (id != null) {
        final fileIndex = await FileIndex.db.findById(
          session,
          id,
          transaction: transaction,
        );
        if (fileIndex == null) return false;

        await DocumentEmbedding.db.deleteWhere(
          session,
          where: (t) => t.fileIndexId.equals(fileIndex.id!),
          transaction: transaction,
        );
        await FileIndex.db.deleteRow(
          session,
          fileIndex,
          transaction: transaction,
        );
        return true;
      }

      // 2. Handle deletion by path (could be a file or a folder)
      if (path != null) {
        session.log(
          'removeFromIndex called with path: "$path"',
          level: LogLevel.info,
        );

        // Robust normalization for file matching
        final normalizedPath = path
            .replaceAll('\\', '/') // Standardize separators
            .replaceAll(RegExp(r'/+$'), ''); // Remove trailing slashes

        // First, try to find an exact file match (case-insensitive for robustness)
        final exactMatch = await FileIndex.db.findFirstRow(
          session,
          where: (t) => t.path.ilike(path),
          transaction: transaction,
        );

        if (exactMatch != null) {
          final deletedEmbeddings = await DocumentEmbedding.db.deleteWhere(
            session,
            where: (t) => t.fileIndexId.equals(exactMatch.id!),
            transaction: transaction,
          );
          await FileIndex.db.deleteRow(
            session,
            exactMatch,
            transaction: transaction,
          );
          session.log(
            'Deleted exact file match: $path (${deletedEmbeddings.length} embeddings removed)',
          );
        }

        // Second, handle folder-level removal
        // Matching "path/..." using normalized forward slashes
        final folderSearchPattern = '$normalizedPath/%';

        final children = await FileIndex.db.find(
          session,
          where: (t) => t.path.ilike(folderSearchPattern),
          transaction: transaction,
        );

        if (children.isNotEmpty) {
          session.log(
            'Removing ${children.length} child files for directory: $path',
          );
          for (final child in children) {
            await DocumentEmbedding.db.deleteWhere(
              session,
              where: (t) => t.fileIndexId.equals(child.id!),
              transaction: transaction,
            );
            await FileIndex.db.deleteRow(
              session,
              child,
              transaction: transaction,
            );
          }
        }

        // 3. Clean up associated indexing jobs
        // Use .equals() for exact matching (ILIKE has issues with backslash escaping)
        final deletedJobsOriginal = await IndexingJob.db.deleteWhere(
          session,
          where: (t) => t.folderPath.equals(path),
          transaction: transaction,
        );

        // Also try normalized path (forward slashes) if different
        int deletedJobsNormalized = 0;
        if (normalizedPath != path) {
          final deleted = await IndexingJob.db.deleteWhere(
            session,
            where: (t) => t.folderPath.equals(normalizedPath),
            transaction: transaction,
          );
          deletedJobsNormalized = deleted.length;
        }

        final totalDeletedJobs =
            deletedJobsOriginal.length + deletedJobsNormalized;

        session.log(
          'Index cleanup complete for "$path". Deleted jobs: $totalDeletedJobs (original: ${deletedJobsOriginal.length}, normalized: $deletedJobsNormalized)',
          level: LogLevel.info,
        );

        return true;
      }

      return false;
    });
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

  /// Split text into overlapping chunks for better embedding coverage (Issue #13)
  ///
  /// Long documents are split into chunks of [chunkSize] words with [overlap]
  /// words of overlap between consecutive chunks for context continuity.
  List<String> _chunkText(
    String text, {
    int chunkSize = 1000,
    int overlap = 100,
  }) {
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= chunkSize) return [text];

    final chunks = <String>[];
    int start = 0;
    while (start < words.length) {
      final end = (start + chunkSize).clamp(0, words.length);
      chunks.add(words.sublist(start, end).join(' '));
      start += chunkSize - overlap;
      if (start >= words.length) break;
    }
    return chunks;
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

  /// Handle file changes from file watcher (with locking)
  Future<void> _handleFilesChanged(
    Session session,
    List<String> filePaths,
  ) async {
    session.log(
      'Processing ${filePaths.length} changed files',
      level: LogLevel.info,
    );

    // Process files in batches of 10
    const batchSize = 10;
    for (int i = 0; i < filePaths.length; i += batchSize) {
      final end = (i + batchSize < filePaths.length)
          ? i + batchSize
          : filePaths.length;
      final batch = filePaths.sublist(i, end);
      await _processBatch(session, batch);
    }

    session.log(
      'Completed processing ${filePaths.length} files',
      level: LogLevel.info,
    );
  }

  /// Get top tags by frequency
  Future<List<TagTaxonomy>> getTopTags(
    Session session, {
    String? category,
    int? limit,
  }) async {
    return await TagTaxonomyService.getTopTags(
      session,
      category: category,
      limit: limit ?? 20,
    );
  }

  /// Search tags for autocomplete
  Future<List<TagTaxonomy>> searchTags(
    Session session,
    String query, {
    String? category,
    int? limit,
  }) async {
    return await TagTaxonomyService.searchTags(
      session,
      query,
      category: category,
      limit: limit ?? 10,
    );
  }

  /// Merge multiple tags into a single target tag
  Future<int> mergeTags(
    Session session, {
    required List<String> sourceTags,
    required String targetTag,
    String? category,
  }) async {
    return await TagTaxonomyService.mergeTags(
      session,
      sourceTags,
      targetTag,
      category: category,
    );
  }

  /// Rename a tag across all files and taxonomy
  Future<int> renameTag(
    Session session, {
    required String oldTag,
    required String newTag,
    String? category,
  }) async {
    return await TagTaxonomyService.renameTag(
      session,
      oldTag,
      newTag,
      category: category,
    );
  }

  /// Get related tags based on co-occurrence
  Future<List<Map<String, dynamic>>> getRelatedTags(
    Session session, {
    required String tagValue,
    int? limit,
  }) async {
    final relatedTags = await TagTaxonomyService.getRelatedTags(
      session,
      tagValue,
      limit: limit ?? 10,
    );

    // Convert to JSON-serializable format
    return relatedTags.map((tag) => tag.toJson()).toList();
  }

  /// Get tag category statistics
  Future<Map<String, dynamic>> getTagCategoryStats(
    Session session,
  ) async {
    final stats = await TagTaxonomyService.getCategoryStats(session);

    // Convert to JSON-serializable format
    return stats.map((key, value) => MapEntry(key, value.toJson()));
  }

  /// Get AI cost summary
  Future<Map<String, dynamic>> getAICostSummary(
    Session session, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final summary = await AICostService.getCostSummary(
      session,
      startDate: startDate,
      endDate: endDate,
    );

    return summary.toJson();
  }

  /// Check budget status
  Future<Map<String, dynamic>> checkBudget(
    Session session, {
    required double budgetLimit,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final status = await AICostService.checkBudget(
      session,
      budgetLimit,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );

    return status.toJson();
  }

  /// Get projected costs
  Future<Map<String, dynamic>> getProjectedCosts(
    Session session, {
    int? lookbackDays,
    int? forecastDays,
  }) async {
    final projection = await AICostService.getProjectedCosts(
      session,
      lookbackDays: lookbackDays ?? 30,
      forecastDays: forecastDays ?? 30,
    );

    return projection.toJson();
  }

  /// Get daily costs
  Future<List<Map<String, dynamic>>> getDailyCosts(
    Session session, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dailyCosts = await AICostService.getDailyCosts(
      session,
      startDate: startDate,
      endDate: endDate,
    );

    return dailyCosts.map((d) => d.toJson()).toList();
  }

  /// Get cost breakdown by feature
  Future<Map<String, double>> getCostByFeature(
    Session session, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await AICostService.getCostByFeature(
      session,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get cost breakdown by model
  Future<Map<String, double>> getCostByModel(
    Session session, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await AICostService.getCostByModel(
      session,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Record AI API call cost
  Future<void> recordAICost(
    Session session, {
    required String feature,
    required String model,
    required int inputTokens,
    required int outputTokens,
    required double cost,
    Map<String, dynamic>? metadata,
  }) async {
    await AICostService.recordCost(
      session,
      feature: feature,
      model: model,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      cost: cost,
      metadata: metadata,
    );
  }

  /// Hybrid search combining semantic and keyword search
  Future<List<SearchResult>> hybridSearch(
    Session session,
    String query, {
    double? threshold,
    int? limit,
    int? offset,
    double? semanticWeight,
    double? keywordWeight,
    SearchFilters? filters,
  }) async {
    // Security: Validate authentication
    AuthService.requireAuth(session);

    // Security: Rate limiting
    final clientId = _getClientIdentifier(session);
    RateLimitService.instance.requireRateLimit(clientId, 'hybridSearch');

    // Validate and sanitize parameters
    final actualThreshold = (threshold ?? 0.3).clamp(0.0, 1.0);
    final actualLimit = (limit ?? 20).clamp(1, 100); // Enforce max limit
    final actualOffset = (offset ?? 0).clamp(0, 10000);
    final actualSemanticWeight = (semanticWeight ?? 0.7).clamp(0.0, 1.0);
    final actualKeywordWeight = (keywordWeight ?? 0.3).clamp(0.0, 1.0);

    // Validate query
    if (query.isNotEmpty) {
      InputValidation.validateSearchQuery(query);
    }

    // Start timing for analytics
    final stopwatch = Stopwatch()..start();

    // Check cache first for hybrid search results
    final cacheKey = CacheService.hybridSearchKey(
      query,
      actualThreshold,
      actualLimit,
      actualOffset,
      actualSemanticWeight,
      actualKeywordWeight,
    );
    final cachedResults = CacheService.instance.get<List<SearchResult>>(
      cacheKey,
    );
    if (cachedResults != null) {
      session.log(
        'Hybrid search cache hit for query: $query',
        level: LogLevel.debug,
      );
      // Still log cache hits for analytics (faster response)
      stopwatch.stop();
      _logSearchAnalytics(
        session,
        query: query,
        searchType: 'hybrid_cached',
        resultCount: cachedResults.length,
        queryTimeMs: stopwatch.elapsedMilliseconds,
      );
      return cachedResults;
    }

    // Run semantic and keyword searches in parallel with error capture
    List<_ScoredResult>? semanticResults;
    List<_ScoredResult>? keywordResults;
    String? semanticError;
    String? keywordError;

    final searchFutures = await Future.wait([
      _performSemanticSearch(
            session,
            query,
            threshold: actualThreshold,
            limit: actualLimit * 2, // Get more results for merging
          )
          .then((r) {
            semanticResults = r;
            return r;
          })
          .catchError((e) {
            semanticError = e.toString();
            session.log(
              'Semantic search failed in hybrid: $e',
              level: LogLevel.warning,
            );
            return <_ScoredResult>[];
          }),
      _performKeywordSearch(
            session,
            query,
            limit: actualLimit * 2,
            filters: filters,
          )
          .then((r) {
            keywordResults = r;
            return r;
          })
          .catchError((e) {
            keywordError = e.toString();
            session.log(
              'Keyword search failed in hybrid: $e',
              level: LogLevel.warning,
            );
            return <_ScoredResult>[];
          }),
    ]);

    // Use captured results (could be null if errors occurred before assignment)
    semanticResults ??= searchFutures[0];
    keywordResults ??= searchFutures[1];

    // If both searches failed completely, throw error
    if (semanticResults!.isEmpty &&
        keywordResults!.isEmpty &&
        semanticError != null &&
        keywordError != null) {
      throw Exception(
        'Both semantic and keyword searches failed. '
        'Semantic: $semanticError, Keyword: $keywordError',
      );
    }

    // Combine results with weighted scores
    final combined = <int, _ScoredResult>{};

    // Normalize scores to 0-1 range before combining
    // This prevents keyword search (ts_rank_cd can be > 1) from dominating
    final maxSemanticScore = semanticResults!.isEmpty
        ? 1.0
        : semanticResults!.map((r) => r.score).reduce((a, b) => a > b ? a : b);
    final maxKeywordScore = keywordResults!.isEmpty
        ? 1.0
        : keywordResults!.map((r) => r.score).reduce((a, b) => a > b ? a : b);

    // Add normalized semantic results
    for (final result in semanticResults!) {
      final normalizedScore = maxSemanticScore > 0
          ? (result.score / maxSemanticScore).clamp(0.0, 1.0)
          : 0.0;
      combined[result.doc.id!] = _ScoredResult(
        doc: result.doc,
        score: normalizedScore * actualSemanticWeight,
      );
    }

    // Add or merge normalized keyword results
    for (final result in keywordResults!) {
      final normalizedScore = maxKeywordScore > 0
          ? (result.score / maxKeywordScore).clamp(0.0, 1.0)
          : 0.0;
      final docId = result.doc.id!;
      final existing = combined[docId];
      if (existing != null) {
        // Document appears in both - combine scores
        combined[docId] = _ScoredResult(
          doc: existing.doc,
          score: existing.score + (normalizedScore * actualKeywordWeight),
        );
      } else {
        // New document from keyword search only
        combined[docId] = _ScoredResult(
          doc: result.doc,
          score: normalizedScore * actualKeywordWeight,
        );
      }
    }

    // Sort by combined score
    final sortedResults = combined.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // Apply offset and limit
    final pagedResults = sortedResults
        .skip(actualOffset)
        .take(actualLimit)
        .toList();

    // Convert to SearchResult objects
    final results = pagedResults.map((result) {
      final tags = result.doc.tagsJson != null
          ? _parseTagList(result.doc.tagsJson!)
          : <String>[];

      return SearchResult(
        id: result.doc.id!,
        path: result.doc.path,
        fileName: result.doc.fileName,
        relevanceScore: result.score,
        contentPreview: result.doc.contentPreview,
        tags: tags,
        indexedAt: result.doc.indexedAt,
        fileSizeBytes: result.doc.fileSizeBytes,
        mimeType: result.doc.mimeType,
      );
    }).toList();

    // Cache the results for future queries (5 minute TTL)
    CacheService.instance.set(
      cacheKey,
      results,
      ttl: CacheService.searchResultTtl,
    );

    // Log search analytics
    stopwatch.stop();
    _logSearchAnalytics(
      session,
      query: query,
      searchType: 'hybrid',
      resultCount: results.length,
      queryTimeMs: stopwatch.elapsedMilliseconds,
    );

    return results;
  }

  /// Log search analytics for monitoring and performance tracking
  void _logSearchAnalytics(
    Session session, {
    required String query,
    required String searchType,
    required int resultCount,
    required int queryTimeMs,
    String? error,
  }) {
    // Log to Serverpod's structured logging
    session.log(
      'SearchAnalytics: type=$searchType, results=$resultCount, '
      'timeMs=$queryTimeMs, queryLen=${query.length}${error != null ? ', error=$error' : ''}',
      level: queryTimeMs > 2000 ? LogLevel.warning : LogLevel.info,
    );

    // Track slow queries for monitoring
    if (queryTimeMs > 2000) {
      session.log(
        'Slow search detected: $searchType took ${queryTimeMs}ms for query: '
        '${query.length > 50 ? '${query.substring(0, 50)}...' : query}',
        level: LogLevel.warning,
      );
    }
  }

  /// Get or initialize AI Service
  Future<AIService> _getAIService() async {
    if (_aiService != null) return _aiService!;
    final client = await _getOpenRouterClient();
    _aiService = AIService(client: client);
    return _aiService!;
  }

  Future<OpenRouterClient> _getOpenRouterClient() async {
    if (_openRouterClient != null) return _openRouterClient!;

    // Retrieve API key from environment or default to empty (will fail gracefully usually)
    // Fixed: getEnv is usually synchronous or returns String? depending on implementation.
    // If it's returning String? directly, remove await.
    final apiKey = getEnv('OPENROUTER_API_KEY');

    _openRouterClient = OpenRouterClient(apiKey: apiKey);
    _allClients.add(_openRouterClient!);
    return _openRouterClient!;
  }

  /// Perform semantic (vector) search
  Future<List<_ScoredResult>> _performSemanticSearch(
    Session session,
    String query, {
    required double threshold,
    required int limit,
  }) async {
    final aiService = await _getAIService();
    final queryEmbedding = await aiService.generateEmbedding(query);
    final queryEmbeddingJson = jsonEncode(queryEmbedding);
    final results = <_ScoredResult>[];

    try {
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
          contentHash: '',
          status: 'indexed',
          embeddingModel: '',
          isTextContent: true,
        );
        results.add(_ScoredResult(doc: doc, score: similarity));
      }
    } catch (e) {
      session.log(
        'Semantic search failed: $e',
        level: LogLevel.warning,
      );
    }

    return results;
  }

  /// Perform keyword (full-text) search using PostgreSQL
  Future<List<_ScoredResult>> _performKeywordSearch(
    Session session,
    String query, {
    required int limit,
    SearchFilters? filters,
  }) async {
    final results = <_ScoredResult>[];

    // Input validation and sanitization
    if (query.isEmpty || query.length > 1000) {
      session.log(
        'Keyword search: Invalid query length (${query.length})',
        level: LogLevel.warning,
      );
      return results;
    }

    // Sanitize query for PostgreSQL full-text search
    // Remove special characters, keeping alphanumeric, spaces, and basic punctuation
    final sanitizedQuery = query
        .replaceAll(RegExp('[^a-zA-Z0-9\\s\\-.,]'), ' ')
        .replaceAll(RegExp('\\s+'), ' ')
        .trim();

    if (sanitizedQuery.isEmpty) {
      session.log(
        'Keyword search: Query empty after sanitization',
        level: LogLevel.debug,
      );
      return results;
    }

    try {
      // Use PostgreSQL full-text search
      // Build dynamic WHERE clause
      final whereConditions = <String>[
        '''to_tsvector('english', COALESCE(fi."contentPreview", '') || ' ' ||
                                      COALESCE(fi."fileName", '') || ' ' ||
                                      COALESCE(fi."tagsJson", ''))
              @@ plainto_tsquery('english', \$1)''',
      ];
      final parameters = <dynamic>[sanitizedQuery];
      // Start param index at 2 (since 1 is query)
      int paramIndex = 2;

      if (filters != null) {
        // Date Range
        if (filters.dateFrom != null) {
          whereConditions.add('fi."indexedAt" >= \$$paramIndex');
          parameters.add(filters.dateFrom);
          paramIndex++;
        }
        if (filters.dateTo != null) {
          whereConditions.add('fi."indexedAt" <= \$$paramIndex');
          parameters.add(filters.dateTo);
          paramIndex++;
        }

        // File Size
        if (filters.minSize != null) {
          whereConditions.add('fi."fileSizeBytes" >= \$$paramIndex');
          parameters.add(filters.minSize);
          paramIndex++;
        }
        if (filters.maxSize != null) {
          whereConditions.add('fi."fileSizeBytes" <= \$$paramIndex');
          parameters.add(filters.maxSize);
          paramIndex++;
        }

        // File Types
        if (filters.fileTypes != null && filters.fileTypes!.isNotEmpty) {
          final typeConditions = <String>[];
          for (final type in filters.fileTypes!) {
            if (type == 'pdf') {
              typeConditions.add('fi."mimeType" ILIKE \$$paramIndex');
              parameters.add('%pdf%');
              paramIndex++;
            } else if (type == 'image') {
              typeConditions.add('fi."mimeType" ILIKE \$$paramIndex');
              parameters.add('image/%');
              paramIndex++;
            } else if (type == 'doc') {
              typeConditions.add(
                '(fi."mimeType" ILIKE \$$paramIndex OR fi."fileName" ILIKE \$$paramIndex)',
              );
              parameters.add('%word%');
              paramIndex++;
            } else {
              typeConditions.add('fi."fileName" ILIKE \$$paramIndex');
              parameters.add('%.$type%');
              paramIndex++;
            }
          }
          if (typeConditions.isNotEmpty) {
            whereConditions.add('(${typeConditions.join(" OR ")})');
          }
        }

        // Tags
        if (filters.tags != null && filters.tags!.isNotEmpty) {
          for (final tag in filters.tags!) {
            whereConditions.add('fi."tagsJson" ILIKE \$$paramIndex');
            parameters.add('%"$tag"%');
            paramIndex++;
          }
        }
      }

      // Add LIMIT
      final limitParamIndex = paramIndex;
      parameters.add(limit);

      final searchQuery =
          '''
        SELECT
          fi.id,
          fi.path,
          fi."fileName",
          fi."contentPreview",
          fi."tagsJson",
          fi."indexedAt",
          fi."fileSizeBytes",
          fi."mimeType",
          ts_rank_cd(
            to_tsvector('english', COALESCE(fi."contentPreview", '') || ' ' ||
                                    COALESCE(fi."fileName", '') || ' ' ||
                                    COALESCE(fi."tagsJson", '')),
            plainto_tsquery('english', \$1)
          ) as rank
        FROM file_index fi
        WHERE ${whereConditions.join(" AND ")}
        ORDER BY rank DESC
        LIMIT \$$limitParamIndex
      ''';

      final rows = await session.db.unsafeQuery(
        searchQuery,
        parameters: QueryParameters.positional(parameters),
      );

      for (final row in rows) {
        final rank = row[8] as double;
        final doc = FileIndex(
          id: row[0] as int,
          path: row[1] as String,
          fileName: row[2] as String,
          contentPreview: row[3] as String?,
          tagsJson: row[4] as String?,
          indexedAt: row[5] as DateTime?,
          fileSizeBytes: (row[6] as int?) ?? 0,
          mimeType: row[7] as String?,
          contentHash: '',
          status: 'indexed',
          embeddingModel: '',
          isTextContent: true,
        );
        // Normalize rank to 0-1 range (ts_rank_cd typically returns 0-1 but can be higher)
        final normalizedScore = (rank / 1.0).clamp(0.0, 1.0);
        results.add(_ScoredResult(doc: doc, score: normalizedScore));
      }
    } catch (e) {
      session.log(
        'Keyword search failed: $e',
        level: LogLevel.warning,
      );
    }

    return results;
  }

  /// Generate index health report
  Future<Map<String, dynamic>> getIndexHealthReport(Session session) async {
    final report = await IndexHealthService.generateReport(session);
    return report.toJson();
  }

  /// Clean up orphaned files from index
  Future<int> cleanupOrphanedFiles(Session session) async {
    return await IndexHealthService.cleanupOrphanedFiles(session);
  }

  /// Refresh stale index entries
  Future<int> refreshStaleEntries(
    Session session, {
    int? staleThresholdDays,
  }) async {
    return await IndexHealthService.refreshStaleEntries(
      session,
      staleThresholdDays: staleThresholdDays ?? 180,
    );
  }

  /// Remove duplicate files from index
  Future<int> removeDuplicates(
    Session session, {
    bool? keepNewest,
  }) async {
    return await IndexHealthService.removeDuplicates(
      session,
      keepNewest: keepNewest ?? true,
    );
  }

  /// Fix files with missing embeddings
  Future<int> fixMissingEmbeddings(Session session) async {
    return await IndexHealthService.fixMissingEmbeddings(session);
  }

  // ==========================================================================
  // AI-POWERED SEARCH
  // ==========================================================================

  /// AI-powered search with streaming progress
  ///
  /// Combines semantic index search with AI agent terminal commands
  /// to find files that may not be indexed yet.
  ///
  /// [query] - Natural language search query
  /// [strategy] - Search strategy: 'semantic_first', 'ai_only', 'hybrid'
  /// [maxResults] - Maximum number of results to return
  ///
  /// Returns a stream of [AISearchProgress] events for real-time feedback
  Stream<AISearchProgress> aiSearch(
    Session session,
    String query, {
    String? strategy,
    int? maxResults,
  }) async* {
    // Security: Validate authentication
    AuthService.requireAuth(session);

    // Security: Rate limiting (30 requests per minute for AI search)
    final clientId = _getClientIdentifier(session);
    RateLimitService.instance.requireRateLimit(
      clientId,
      'aiSearch',
      limit: 30,
    );

    // Validate parameters
    final effectiveMaxResults = (maxResults ?? 20).clamp(1, 100);
    final effectiveStrategy = strategy ?? 'hybrid';

    if (query.isNotEmpty) {
      InputValidation.validateSearchQuery(query);
    }

    // Import and use the AISearchService
    final aiSearchService = AISearchService(
      client: openRouterClient,
    );

    // Map strategy string to enum
    SearchStrategy searchStrategy;
    switch (effectiveStrategy) {
      case 'semantic_first':
        searchStrategy = SearchStrategy.semanticFirst;
        break;
      case 'ai_only':
        searchStrategy = SearchStrategy.aiOnly;
        break;
      case 'hybrid':
      default:
        searchStrategy = SearchStrategy.hybrid;
    }

    // Yield progress from the AI search service
    try {
      yield* aiSearchService.executeSearch(
        session,
        query,
        strategy: searchStrategy,
        maxResults: effectiveMaxResults,
      );
    } catch (e, stackTrace) {
      session.log(
        'AI search failed: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
      yield AISearchProgress(
        type: 'error',
        message: 'Search failed',
        error: e.toString(),
      );
    }
  }

  /// Summarize a file's content using AI
  ///
  /// Extracts text from the file and generates a hierarchical summary
  /// with brief, medium, and detailed levels.
  ///
  /// [filePath] - Full path to the file to summarize
  ///
  /// Returns a JSON string containing the summary levels and metadata
  Future<String> summarizeFile(
    Session session,
    String filePath,
  ) async {
    // Security: Validate authentication
    AuthService.requireAuth(session);

    // Security: Rate limiting (20 requests per minute for summarization)
    final clientId = _getClientIdentifier(session);
    RateLimitService.instance.requireRateLimit(
      clientId,
      'summarizeFile',
      limit: 20,
    );

    // Validate file path
    InputValidation.validateFilePath(filePath);

    // Check file exists
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    // Check file is supported
    if (!FileExtractionService.isSupported(filePath)) {
      throw Exception('Unsupported file type for summarization');
    }

    try {
      // Extract file content
      final extraction = await _extractionService.extractText(filePath);

      // Check content is not empty
      if (extraction.content.trim().isEmpty) {
        return jsonEncode({
          'briefSummary': 'Empty file',
          'mediumSummary': 'This file appears to be empty.',
          'detailedSummary': 'No content could be extracted from this file.',
          'originalLength': 0,
          'compressionRatio': 1.0,
          'chunkCount': 0,
          'fileName': extraction.fileName,
        });
      }

      // Generate summary using SummarizationService
      final summary = await SummarizationService.generateSummary(
        session,
        extraction.content,
        openRouterClient,
        fileName: extraction.fileName,
      );

      // Return JSON with summary and file metadata
      final result = summary.toJson();
      result['fileName'] = extraction.fileName;
      result['mimeType'] = extraction.mimeType;
      result['wordCount'] = extraction.wordCount;

      return jsonEncode(result);
    } catch (e, stackTrace) {
      session.log(
        'File summarization failed: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ==========================================================================
  // FILE ORGANIZATION ANALYSIS
  // ==========================================================================

  /// Get file organization suggestions including duplicates, naming issues,
  /// and semantically similar documents
  ///
  /// [rootPath] - Optional root path to limit analysis to a specific folder
  Future<OrganizationSuggestions> getOrganizationSuggestions(
    Session session, {
    String? rootPath,
  }) async {
    // Security: Validate authentication
    AuthService.requireAuth(session);

    session.log(
      'Starting organization analysis${rootPath != null ? " for $rootPath" : ""}',
      level: LogLevel.info,
    );

    // Run all analyses in parallel for performance
    final duplicateDetector = DuplicateDetector();
    final namingAnalyzer = NamingAnalyzer();
    final similarityAnalyzer = SimilarityAnalyzer();

    final results = await Future.wait([
      duplicateDetector.findDuplicates(session, rootPath: rootPath),
      namingAnalyzer.detectIssues(session, rootPath: rootPath),
      similarityAnalyzer.findSimilar(session),
    ]);

    final duplicates = results[0] as List<DuplicateGroup>;
    final namingIssues = results[1] as List<NamingIssue>;
    final similarContent = results[2] as List<SimilarContentGroup>;

    // Calculate total potential savings
    final potentialSavings = duplicates.fold<int>(
      0,
      (sum, g) => sum + g.potentialSavingsBytes,
    );

    // Get total files analyzed
    final totalFiles = await FileIndex.db.count(
      session,
      where: (t) => t.status.equals('indexed'),
    );

    session.log(
      'Organization analysis complete: ${duplicates.length} duplicate groups, '
      '${namingIssues.length} naming issues, ${similarContent.length} similar groups',
      level: LogLevel.info,
    );

    return OrganizationSuggestions(
      duplicates: duplicates,
      namingIssues: namingIssues,
      similarContent: similarContent,
      analyzedAt: DateTime.now(),
      totalFilesAnalyzed: totalFiles,
      potentialSavingsBytes: potentialSavings,
    );
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
