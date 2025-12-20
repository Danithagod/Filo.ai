import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/openrouter_client.dart';
import '../services/ai_service.dart';
import '../services/file_extraction_service.dart';
import '../config/ai_models.dart';

/// Main endpoint for Semantic Desktop Butler
/// Handles semantic search, document indexing, and status queries
///
/// Now powered by OpenRouter for multi-provider AI access
class ButlerEndpoint extends Endpoint {
  // Services - lazily initialized
  OpenRouterClient? _openRouterClient;
  AIService? _aiService;
  final FileExtractionService _extractionService = FileExtractionService();

  /// Get OpenRouter API key from environment
  String get _openRouterApiKey =>
      Platform.environment['OPENROUTER_API_KEY'] ?? '';

  /// Get OpenRouter client (lazily initialized)
  OpenRouterClient get openRouterClient {
    _openRouterClient ??= OpenRouterClient(
      apiKey: _openRouterApiKey,
      siteUrl:
          Platform.environment['OPENROUTER_SITE_URL'] ??
          'https://semantic-butler.app',
      siteName:
          Platform.environment['OPENROUTER_SITE_NAME'] ??
          'Semantic Desktop Butler',
    );
    return _openRouterClient!;
  }

  /// Get AI service (lazily initialized)
  AIService get aiService {
    _aiService ??= AIService(client: openRouterClient);
    return _aiService!;
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
        final query = '''
          SELECT
            "fileIndexId",
            1 - (embedding <=> '$queryEmbeddingJson'::vector) as similarity
          FROM document_embedding
          WHERE 1 - (embedding <=> '$queryEmbeddingJson'::vector) > $threshold
          ORDER BY embedding <=> '$queryEmbeddingJson'::vector
          LIMIT $limit
        ''';

        final rows = await session.db.query(query);

        // 3. Map results to FileIndex objects
        for (final row in rows) {
          final fileIndexId = row[0] as int;
          final similarity = row[1] as double;

          final doc = await FileIndex.db.findById(session, fileIndexId);
          if (doc != null) {
            results.add(_ScoredResult(doc: doc, score: similarity));
          }
        }
      } catch (e) {
        // Fallback to Dart-based search if pgvector fails (e.g. extension not installed)
        session.log('pgvector search failed, falling back to Dart implementation: $e', level: LogLevel.warning);

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

    // Start indexing in background
    // Note: In production, use Serverpod Future Calls for proper async handling
    unawaited(_processIndexingJob(session, insertedJob));

    return insertedJob;
  }

  /// Process an indexing job (background task)
  Future<void> _processIndexingJob(Session session, IndexingJob job) async {
    try {
      // Update job status to running
      job.status = 'running';
      job.startedAt = DateTime.now();
      await IndexingJob.db.updateRow(session, job);

      // Scan directory for files
      final files = await _extractionService.scanDirectory(job.folderPath);
      job.totalFiles = files.length;
      await IndexingJob.db.updateRow(session, job);

      // Process files in batches
      const batchSize = 10;
      for (var i = 0; i < files.length; i += batchSize) {
        final batch = files.sublist(
          i,
          i + batchSize > files.length ? files.length : i + batchSize,
        );

        final results = await _processBatch(session, batch);

        job.processedFiles += results.indexedCount;
        job.failedFiles += results.failedCount;
        job.skippedFiles += results.skippedCount;

        // Update progress
        await IndexingJob.db.updateRow(session, job);
      }

      // Mark job as completed
      job.status = 'completed';
      job.completedAt = DateTime.now();
      await IndexingJob.db.updateRow(session, job);
    } catch (e) {
      job.status = 'failed';
      job.errorMessage = e.toString();
      job.completedAt = DateTime.now();
      await IndexingJob.db.updateRow(session, job);
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
        if (existing != null && existing.contentHash == extraction.contentHash) {
          skipped++;
          continue;
        }

        itemsToProcess.add(_BatchItem(path: path, extraction: extraction, existingIndex: existing));
      } catch (e) {
        failed++;
        session.log('Failed to extract $path: $e', level: LogLevel.warning);
        await _recordIndexingError(session, path, 'Extraction failed: $e');
      }
    }

    if (itemsToProcess.isEmpty) {
      return _BatchResult(indexed, failed, skipped);
    }

    // 2. Generate embeddings in batch (optimization)
    List<List<double>> embeddings;
    try {
      embeddings = await _retry(
        () => aiService.generateEmbeddings(
          itemsToProcess.map((item) => item.extraction.content).toList(),
        ),
        maxAttempts: 3,
      );
    } catch (e) {
      session.log('Failed to generate embeddings for batch: $e', level: LogLevel.error);
      return _BatchResult(indexed, failed + itemsToProcess.length, skipped);
    }

    // 3. Process each file with its embedding
    for (var i = 0; i < itemsToProcess.length; i++) {
      final item = itemsToProcess[i];
      final embedding = embeddings[i];

      try {
        // Generate tags
        final tags = await _retry(
          () => aiService.generateTags(
            item.extraction.content,
            fileName: item.extraction.fileName,
          ),
          maxAttempts: 2,
        );

        // Create/Update FileIndex record
        final fileIndex = FileIndex(
          id: item.existingIndex?.id,
          path: item.path,
          fileName: item.extraction.fileName,
          contentHash: item.extraction.contentHash,
          fileSizeBytes: item.extraction.fileSizeBytes,
          mimeType: item.extraction.mimeType,
          contentPreview: item.extraction.preview,
          tagsJson: tags.toJson(),
          status: 'indexed',
          embeddingModel: AIModels.embeddingDefault,
          indexedAt: DateTime.now(),
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
          savedIndex = await FileIndex.db.insertRow(session, fileIndex);
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

        // Update vector column directly
        try {
          await session.db.query(
            'UPDATE document_embedding SET embedding = \'${jsonEncode(embedding)}\'::vector WHERE id = ${embeddingRecord.id}',
          );
        } catch (e) {
          session.log('Failed to update vector column: $e', level: LogLevel.error);
        }

        indexed++;
      } catch (e) {
        failed++;
        session.log('Failed to index ${item.path}: $e', level: LogLevel.warning);
        await _recordIndexingError(session, item.path, 'Indexing failed: $e');
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
          ),
        );
      }
    } catch (e) {
      session.log('Failed to record indexing error for $path: $e', level: LogLevel.error);
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
}

/// Helper for batch processing
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

    return IndexingStatus(
      totalDocuments: totalDocs,
      indexedDocuments: indexedDocs,
      pendingDocuments: pendingDocs,
      failedDocuments: failedDocs,
      activeJobs: activeJobs,
      databaseSizeMb: await _estimateDatabaseSize(session),
      lastActivity: lastIndexed?.indexedAt,
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

/// Helper class for sorting search results by score
class _ScoredResult {
  final FileIndex doc;
  final double score;

  _ScoredResult({required this.doc, required this.score});
}
