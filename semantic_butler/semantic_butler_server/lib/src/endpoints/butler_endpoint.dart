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
      // 1. Generate embedding for the query using OpenRouter
      final queryEmbedding = await aiService.generateEmbedding(query);

      // 2. Get all indexed documents with embeddings
      final allDocs = await FileIndex.db.find(
        session,
        where: (t) => t.status.equals('indexed'),
      );

      // 3. Calculate similarity scores
      final results = <_ScoredResult>[];

      for (final doc in allDocs) {
        // Get embeddings for this document
        final embeddings = await DocumentEmbedding.db.find(
          session,
          where: (t) => t.fileIndexId.equals(doc.id!),
        );

        if (embeddings.isEmpty) continue;

        // Calculate max similarity across all chunks
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

      // 4. Sort by score and limit results
      results.sort((a, b) => b.score.compareTo(a.score));
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

      // Process each file
      for (final filePath in files) {
        try {
          await _indexFile(session, filePath);
          job.processedFiles++;
        } catch (e) {
          job.failedFiles++;
          session.log('Failed to index $filePath: $e', level: LogLevel.warning);
        }

        // Update progress periodically
        if (job.processedFiles % 10 == 0) {
          await IndexingJob.db.updateRow(session, job);
        }
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

  /// Index a single file
  Future<void> _indexFile(Session session, String filePath) async {
    // Check if file already indexed with same hash
    final existing = await FileIndex.db.findFirstRow(
      session,
      where: (t) => t.path.equals(filePath),
    );

    // Extract file content
    final extraction = await _extractionService.extractText(filePath);

    // Skip if content hash matches (file unchanged)
    if (existing != null && existing.contentHash == extraction.contentHash) {
      return;
    }

    // Generate embedding using OpenRouter
    final embedding = await aiService.generateEmbedding(extraction.content);

    // Generate tags using OpenRouter
    final tags = await aiService.generateTags(
      extraction.content,
      fileName: extraction.fileName,
    );

    // Create or update FileIndex record
    final fileIndex = FileIndex(
      id: existing?.id,
      path: filePath,
      fileName: extraction.fileName,
      contentHash: extraction.contentHash,
      fileSizeBytes: extraction.fileSizeBytes,
      mimeType: extraction.mimeType,
      contentPreview: extraction.preview,
      tagsJson: tags.toJson(),
      status: 'indexed',
      embeddingModel: AIModels.embeddingDefault,
      indexedAt: DateTime.now(),
    );

    FileIndex savedIndex;
    if (existing != null) {
      savedIndex = await FileIndex.db.updateRow(session, fileIndex);

      // Delete old embeddings
      await DocumentEmbedding.db.deleteWhere(
        session,
        where: (t) => t.fileIndexId.equals(existing.id!),
      );
    } else {
      savedIndex = await FileIndex.db.insertRow(session, fileIndex);
    }

    // Store embedding
    await DocumentEmbedding.db.insertRow(
      session,
      DocumentEmbedding(
        fileIndexId: savedIndex.id!,
        chunkIndex: 0,
        chunkText: extraction.preview,
        embeddingJson: jsonEncode(embedding),
        dimensions: aiService.getEmbeddingDimensions(),
      ),
    );
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
