import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:serverpod/serverpod.dart';
import 'package:semantic_butler_server/server.dart' show getEnv;
import 'package:semantic_butler_server/src/generated/protocol.dart';
import '../services/openrouter_client.dart';
import '../services/ai_service.dart';
import '../services/cached_ai_service.dart';
import '../services/cache_service.dart';
import '../services/file_extraction_service.dart';
import '../services/auth_service.dart';
import '../services/rate_limit_service.dart';
import '../services/tag_taxonomy_service.dart';
import '../services/search_preset_service.dart';
import '../services/index_health_service.dart';
import '../services/summarization_service.dart';
import '../services/ai_search_service.dart';
import '../services/reset_service.dart';
import '../utils/validation.dart';
import '../services/suggestion_service.dart';
import '../services/indexing_service.dart';
import '../utils/query_parser.dart';
import '../services/query_correction_service.dart';
import '../config/search_config.dart';
import '../utils/client_identifier.dart';

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
  final IndexingService _indexingService = IndexingService();

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
    IndexingService.stopWatcherCleanup();

    // Dispose all tracked HTTP clients
    for (final client in _allClients) {
      client.dispose();
    }
    _allClients.clear();

    // Also dispose file watchers
    await IndexingService.disposeAllWatchers();
  }

  /// Initialize periodic cleanup of idle watchers
  static void initializeWatcherCleanup() {
    IndexingService.startWatcherCleanup();
  }

  // Indexing moved to IndexingService

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

  String _getClientIdentifier(Session session) {
    return ClientIdentifier.fromSession(session);
  }

  /// Generate a pagination cursor
  String _createCursor(double score, int id) {
    return base64.encode(utf8.encode('$score:$id'));
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
  static const int _maxSearchLimit = SearchConfig.maxSearchLimit;

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
    offset = offset.clamp(0, SearchConfig.maxPaginationOffset);

    if (query.isNotEmpty) {
      InputValidation.validateSearchQuery(query);
    }

    final stopwatch = Stopwatch()..start();
    final cacheKey = CacheService.semanticSearchKey(
      query,
      threshold,
      limit,
      filters?.cursor,
      dateFrom: filters?.dateFrom,
      dateTo: filters?.dateTo,
      fileTypes: filters?.fileTypes,
      tags: filters?.tags,
      minSize: filters?.minSize,
      maxSize: filters?.maxSize,
      locationPaths: filters?.locationPaths,
      contentTerms: filters?.contentTerms,
      minCount: filters?.minCount,
      maxCount: filters?.maxCount,
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

      final results = <_ScoredResult>[];
      // 1. Perform vector search using improved _performSemanticSearch
      final semanticResults = await _performSemanticSearch(
        session,
        query,
        threshold: threshold,
        limit: limit,
        filters: filters,
        offset: offset,
      );

      results.addAll(semanticResults);

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

        final searchResult = SearchResult(
          id: r.doc.id!,
          path: r.doc.path,
          fileName: r.doc.fileName,
          relevanceScore: r.score,
          contentPreview: r.doc.contentPreview,
          tags: tags,
          indexedAt: r.doc.indexedAt,
          fileSizeBytes: r.doc.fileSizeBytes,
          mimeType: r.doc.mimeType,
          // Generate cursor for this result
          nextCursor: _createCursor(r.score, r.doc.id!),
          matchedChunkText: r.matchedChunkText,
        );
        return searchResult;
      }).toList();

      // 7. Check for query suggestions ("Did you mean?")
      String? suggestedQuery;
      try {
        suggestedQuery = await QueryCorrectionService(client: openRouterClient)
            .getCorrectedQuery(
              session,
              query,
            );
      } catch (e) {
        session.log('Query correction failed: $e', level: LogLevel.debug);
      }

      // Attach suggested query to all results (if any)
      // Note: For empty results, the suggestion will be returned via the first
      // result in the list which acts as a metadata carrier. The UI filters
      // results with id=-1 and empty path, treating them as metadata-only.
      if (suggestedQuery != null) {
        if (searchResults.isNotEmpty) {
          // Attach to all results so any result can provide the suggestion
          for (var result in searchResults) {
            result.suggestedQuery = suggestedQuery;
          }
        } else {
          // For empty results, create a metadata-only result to carry the suggestion
          // This is clearly marked with id=-1 and empty fields
          searchResults.add(
            SearchResult(
              id: -1,
              path: '',
              fileName: '',
              relevanceScore: 0.0,
              tags: [],
              fileSizeBytes: 0,
              suggestedQuery: suggestedQuery,
              contentPreview: null,
            ),
          );
        }
      }

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

  /// Stream semantic search results for better perceived performance (Priority 2)
  Stream<SearchResult> semanticSearchStream(
    Session session,
    String query, {
    int limit = 10,
    double threshold = 0.3,
    int offset = 0,
    SearchFilters? filters,
  }) async* {
    final results = await semanticSearch(
      session,
      query,
      limit: limit,
      threshold: threshold,
      offset: offset,
      filters: filters,
    );

    for (final result in results) {
      yield result;
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
    return SearchPresetService.deletePreset(session, presetId);
  }

  /// Get faceted search counts for filtering
  Future<List<SearchFacet>> getSearchFacets(
    Session session,
    String query, {
    SearchFilters? filters,
  }) async {
    AuthService.requireAuth(session);

    final facets = <SearchFacet>[];
    if (query.trim().isEmpty) return facets;

    // Use QueryParser for consistent filtering logic
    final parsedQuery = QueryParser.parse(query);
    final parameters = <dynamic>[];
    final keywordCondition = parsedQuery.buildSqlCondition(
      columnName: 'fi."fileName"',
      parameters: parameters,
      nextParamIndex: () => parameters.length + 1,
    );

    try {
      // Combined facet query using UNION ALL for better performance
      // This reduces database round trips from 2 to 1
      final combinedFacetQuery =
          '''
        WITH filtered_files AS (
          SELECT fi."mimeType", fi."tagsJson"
          FROM file_index fi
          WHERE $keywordCondition
          AND status = 'indexed'
        ),
        type_facets AS (
          SELECT 'fileType' as facet_type, "mimeType" as value, count(*) as cnt
          FROM filtered_files
          WHERE "mimeType" IS NOT NULL
          GROUP BY "mimeType"
          ORDER BY cnt DESC
          LIMIT 10
        ),
        tag_facets AS (
          SELECT 'tag' as facet_type, tag as value, count(*) as cnt
          FROM (
            SELECT json_array_elements_text(
              CASE 
                WHEN "tagsJson" LIKE '[%' THEN "tagsJson"::json 
                ELSE '[]'::json 
              END
            ) as tag
            FROM filtered_files
            WHERE "tagsJson" IS NOT NULL
          ) t
          GROUP BY tag
          ORDER BY cnt DESC
          LIMIT 10
        )
        SELECT facet_type, value, cnt FROM type_facets
        UNION ALL
        SELECT facet_type, value, cnt FROM tag_facets
      ''';

      final rows = await session.db.unsafeQuery(
        combinedFacetQuery,
        parameters: QueryParameters.positional(parameters),
      );

      // Group results by facet type
      final typeEntries = <FacetEntry>[];
      final tagEntries = <FacetEntry>[];

      for (final row in rows) {
        final facetType = row[0] as String;
        final value = (row[1] as String?) ?? 'unknown';
        final count = row[2] as int;

        final entry = FacetEntry(label: value, value: value, count: count);
        if (facetType == 'fileType') {
          typeEntries.add(entry);
        } else if (facetType == 'tag') {
          tagEntries.add(entry);
        }
      }

      if (typeEntries.isNotEmpty) {
        facets.add(SearchFacet(facetType: 'fileType', entries: typeEntries));
      }
      if (tagEntries.isNotEmpty) {
        facets.add(SearchFacet(facetType: 'tag', entries: tagEntries));
      }
    } catch (e) {
      session.log('Facet calculation failed: $e', level: LogLevel.warning);
    }

    return facets;
  }

  // ==========================================================================
  // SEARCH HISTORY
  // ==========================================================================

  /// Get search history
  Future<List<SearchHistory>> getSearchHistory(
    Session session, {
    int? limit,
    int? offset,
  }) async {
    AuthService.requireAuth(session);
    return await SearchHistory.db.find(
      session,
      limit: limit ?? 50,
      offset: offset ?? 0,
      orderBy: (t) => t.searchedAt,
      orderDescending: true,
    );
  }

  /// Clear all search history
  Future<int> clearSearchHistory(Session session) async {
    AuthService.requireAuth(session);
    final deleted = await SearchHistory.db.deleteWhere(
      session,
      where: (t) => Constant.bool(true),
    );
    return deleted.length;
  }

  /// Delete a specific search history item
  Future<bool> deleteSearchHistoryItem(Session session, int id) async {
    AuthService.requireAuth(session);
    final deleted = await SearchHistory.db.deleteWhere(
      session,
      where: (t) => t.id.equals(id),
    );
    return deleted.isNotEmpty;
  }

  /// Record a local file search
  Future<void> recordLocalSearch(
    Session session,
    String query,
    String directory,
    int resultCount,
  ) async {
    AuthService.requireAuth(session);
    final history = SearchHistory(
      query: query,
      resultCount: resultCount,
      queryTimeMs: 0,
      searchedAt: DateTime.now(),
      searchType: 'local',
      directoryContext: directory,
    );
    await SearchHistory.db.insertRow(session, history);
  }

  // ==========================================================================
  // RESET
  // ==========================================================================

  /// Generate a reset confirmation code
  Future<String> generateResetConfirmationCode(Session session) async {
    AuthService.requireAuth(session);
    return ResetService.instance.generateConfirmationCode();
  }

  /// Preview a database reset
  Future<ResetPreview> previewReset(Session session) async {
    AuthService.requireAuth(session);
    return await ResetService.instance.getPreview(session);
  }

  /// Perform a database reset
  Future<ResetResult> resetDatabase(
    Session session, {
    required String scope,
    required String confirmationCode,
    bool dryRun = false,
  }) async {
    AuthService.requireAuth(session);
    return await ResetService.instance.resetDatabase(
      session,
      scope: scope,
      confirmationCode: confirmationCode,
      dryRun: dryRun,
    );
  }

  // ==========================================================================
  // DOCUMENT INDEXING
  // ==========================================================================

  /// Get current indexing status
  Future<IndexingStatus> getIndexingStatus(Session session) async {
    return await _indexingService.getIndexingStatus(session);
  }

  /// Get error statistics
  Future<ErrorStats> getErrorStats(Session session) async {
    return await _indexingService.getErrorStats(session);
  }

  /// Stream indexing progress
  Stream<IndexingProgress> streamIndexingProgress(
    Session session,
    int jobId,
  ) async* {
    yield* _indexingService.streamProgress(session, jobId);
  }

  /// Get details of a specific indexing job
  Future<IndexingJob?> getIndexingJob(Session session, int jobId) async {
    return await _indexingService.getIndexingJob(session, jobId);
  }

  /// Start indexing documents from specified folder path
  Future<IndexingJob> startIndexing(
    Session session,
    String folderPath,
  ) async {
    AuthService.requireAuth(session);
    return _indexingService.startIndexing(session, folderPath);
  }

  /// Cancel a running indexing job
  Future<bool> cancelIndexingJob(
    Session session,
    int jobId,
  ) async {
    AuthService.requireAuth(session);
    return _indexingService.cancelIndexingJob(session, jobId);
  }

  // ==========================================================================
  // SMART INDEXING (File Watching)
  // ==========================================================================

  /// Enable smart indexing for a folder
  Future<WatchedFolder> enableSmartIndexing(
    Session session,
    String folderPath,
  ) async {
    AuthService.requireAuth(session);
    return _indexingService.enableSmartIndexing(session, folderPath);
  }

  /// Disable smart indexing for a folder
  Future<void> disableSmartIndexing(
    Session session,
    String folderPath,
  ) async {
    AuthService.requireAuth(session);
    return _indexingService.disableSmartIndexing(session, folderPath);
  }

  /// Toggle smart indexing for a folder
  Future<WatchedFolder?> toggleSmartIndexing(
    Session session,
    String folderPath,
  ) async {
    AuthService.requireAuth(session);
    return _indexingService.toggleSmartIndexing(session, folderPath);
  }

  /// Get all watched folders
  Future<List<WatchedFolder>> getWatchedFolders(Session session) async {
    AuthService.requireAuth(session);
    return WatchedFolder.db.find(session);
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

  /// Parse tag list from JSON
  List<String> _parseTagList(String tagsJson) {
    try {
      final tags = DocumentTags.fromJson(tagsJson);
      return tags.toTagList();
    } catch (e) {
      return [];
    }
  }

  /// Estimate database size based on content
  /// This is an approximation based on indexed content
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
    final actualLimit = (limit ?? 20).clamp(1, SearchConfig.maxSearchLimit);
    final actualOffset = (offset ?? 0).clamp(
      0,
      SearchConfig.maxPaginationOffset,
    );
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
      filters?.cursor,
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
        matchedChunkText: result.matchedChunkText,
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
        // Document appears in both - combine scores, keep matchedChunkText from semantic
        combined[docId] = _ScoredResult(
          doc: existing.doc,
          score: existing.score + (normalizedScore * actualKeywordWeight),
          matchedChunkText: existing.matchedChunkText,
        );
      } else {
        // New document from keyword search only
        combined[docId] = _ScoredResult(
          doc: result.doc,
          score: normalizedScore * actualKeywordWeight,
          matchedChunkText: result.matchedChunkText,
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
        matchedChunkText: result.matchedChunkText,
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

  /// Perform semantic (vector) search with filtering and normalization
  Future<List<_ScoredResult>> _performSemanticSearch(
    Session session,
    String query, {
    required double threshold,
    required int limit,
    int offset = 0,
    SearchFilters? filters,
  }) async {
    final results = <_ScoredResult>[];

    try {
      // 1. Generate/Get embedding for the query
      final aiService = await _getAIService();
      final queryEmbedding = await aiService.generateEmbedding(query);
      final queryEmbeddingJson = jsonEncode(queryEmbedding);

      // 2. Build dynamic where conditions for filters
      final whereConditions = <String>[
        '(1 - (de.embedding <=> \$1::vector) > \$2 OR fi."fileName" % \$3)',
      ];
      final parameters = <dynamic>[queryEmbeddingJson, threshold, query];
      int paramIndex = 4;

      final sWeight = filters?.semanticWeight ?? 0.7;
      final kWeight = filters?.keywordWeight ?? 0.3;

      // Apply boolean query parsing for keyword filtering on filename
      // QueryParser logic removed to allow natural language queries to work
      // without strict filename keyword matching.
      // We rely on vector similarity (de.embedding <=> query) and trigram similarity (fi."fileName" % query)
      // for relevance instead.

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

        // Tags - use PostgreSQL JSON containment for proper escaping
        if (filters.tags != null && filters.tags!.isNotEmpty) {
          for (final tag in filters.tags!) {
            whereConditions.add(
              '''(fi."tagsJson" IS NOT NULL AND fi."tagsJson"::jsonb @> \$$paramIndex::jsonb)''',
            );
            parameters.add(
              '["${tag.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"]',
            );
            paramIndex++;
          }
        }

        // Content Terms - search in content preview
        if (filters.contentTerms != null && filters.contentTerms!.isNotEmpty) {
          final contentConditions = <String>[];
          for (final term in filters.contentTerms!) {
            contentConditions.add('fi."contentPreview" ILIKE \$$paramIndex');
            parameters.add('%$term%');
            paramIndex++;
          }
          if (contentConditions.isNotEmpty) {
            whereConditions.add('(${contentConditions.join(" AND ")})');
          }
        }

        // Location Paths - filter by directory paths
        if (filters.locationPaths != null &&
            filters.locationPaths!.isNotEmpty) {
          final pathConditions = <String>[];
          for (final locPath in filters.locationPaths!) {
            // Normalize path for consistent matching (handle both forward and back slashes)
            final normalizedPath = locPath.replaceAll('\\', '/');
            pathConditions.add(
              'REPLACE(fi."path", \'\\\\\', \'/\') ILIKE \$$paramIndex',
            );
            parameters.add('$normalizedPath%');
            paramIndex++;
          }
          if (pathConditions.isNotEmpty) {
            whereConditions.add('(${pathConditions.join(" OR ")})');
          }
        }

        // Word Count filters
        if (filters.minCount != null) {
          whereConditions.add('fi."wordCount" >= \$$paramIndex');
          parameters.add(filters.minCount);
          paramIndex++;
        }
        if (filters.maxCount != null) {
          whereConditions.add('fi."wordCount" <= \$$paramIndex');
          parameters.add(filters.maxCount);
          paramIndex++;
        }
      }

      // 3. Execute vector search with pgvector using CTE for better performance
      // Using CTE with ROW_NUMBER() instead of DISTINCT ON for efficiency
      // UNION with media files (no embeddings) that match by filename/path
      final searchQuery =
          '''
        WITH ranked_embeddings AS (
          SELECT
            de."fileIndexId",
            ((1 - (de.embedding <=> \$1::vector)) * $sWeight + (similarity(fi."fileName", \$3) * $kWeight)) as hybrid_score,
            fi.id, fi.path, fi."fileName", fi."contentPreview",
            fi."tagsJson", fi."indexedAt", fi."fileSizeBytes", fi."mimeType",
            fi."isTextContent", fi."contentHash", fi."embeddingModel", fi."documentCategory",
            fi."fileModifiedAt", fi."fileCreatedAt", fi."wordCount",
            de."chunkText" as matched_chunk_text,
            ROW_NUMBER() OVER (PARTITION BY de."fileIndexId" ORDER BY (1 - (de.embedding <=> \$1::vector)) DESC) as rn
          FROM document_embedding de
          JOIN file_index fi ON de."fileIndexId" = fi.id
          WHERE ${whereConditions.join(" AND ")}
        ),
        media_files AS (
          SELECT
            fi.id as "fileIndexId",
            (similarity(fi."fileName", \$3) * 0.9 + similarity(fi.path, \$3) * 0.1) as hybrid_score,
            fi.id, fi.path, fi."fileName", fi."contentPreview",
            fi."tagsJson", fi."indexedAt", fi."fileSizeBytes", fi."mimeType",
            fi."isTextContent", fi."contentHash", fi."embeddingModel", fi."documentCategory",
            fi."fileModifiedAt", fi."fileCreatedAt", fi."wordCount",
            NULL::text as matched_chunk_text,
            1 as rn
          FROM file_index fi
          WHERE fi."isTextContent" = false
            AND (fi."fileName" % \$3 OR fi.path ILIKE '%' || \$3 || '%')
        )
        SELECT "fileIndexId", hybrid_score, id, path, "fileName", "contentPreview",
               "tagsJson", "indexedAt", "fileSizeBytes", "mimeType",
               "isTextContent", "contentHash", "embeddingModel", "documentCategory",
               "fileModifiedAt", "fileCreatedAt", "wordCount", matched_chunk_text
        FROM (
          SELECT * FROM ranked_embeddings WHERE rn = 1
          UNION ALL
          SELECT * FROM media_files
        ) combined_results
        ORDER BY hybrid_score DESC
        LIMIT \$$paramIndex OFFSET \$${paramIndex + 1}
      ''';

      parameters.add(limit);
      parameters.add(offset);

      final rows = await session.db.unsafeQuery(
        searchQuery,
        parameters: QueryParameters.positional(parameters),
      );

      for (final row in rows) {
        final hybridScore = row[1] as double;
        final doc = FileIndex(
          id: row[2] as int,
          path: row[3] as String,
          fileName: row[4] as String,
          contentPreview: row[5] as String?,
          tagsJson: row[6] as String?,
          indexedAt: row[7] as DateTime?,
          fileSizeBytes: (row[8] as int?) ?? 0,
          mimeType: row[9] as String?,
          isTextContent: row[10] as bool,
          contentHash: row[11] as String,
          embeddingModel: row[12] as String?,
          documentCategory: row[13] as String?,
          fileModifiedAt: row[14] as DateTime?,
          fileCreatedAt: row[15] as DateTime?,
          wordCount: row[16] as int?,
          status: 'indexed',
        );
        results.add(
          _ScoredResult(
            doc: doc,
            score: hybridScore,
            matchedChunkText: row[17] as String?,
          ),
        );
      }
    } catch (e) {
      session.log('Semantic search failed: $e', level: LogLevel.warning);
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

        // Tags - use PostgreSQL JSON containment for proper escaping
        if (filters.tags != null && filters.tags!.isNotEmpty) {
          for (final tag in filters.tags!) {
            whereConditions.add(
              '''(fi."tagsJson" IS NOT NULL AND fi."tagsJson"::jsonb @> \$$paramIndex::jsonb)''',
            );
            parameters.add(
              '["${tag.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"]',
            );
            paramIndex++;
          }
        }

        // Content Terms - search in content preview
        if (filters.contentTerms != null && filters.contentTerms!.isNotEmpty) {
          final contentConditions = <String>[];
          for (final term in filters.contentTerms!) {
            contentConditions.add('fi."contentPreview" ILIKE \$$paramIndex');
            parameters.add('%$term%');
            paramIndex++;
          }
          if (contentConditions.isNotEmpty) {
            whereConditions.add('(${contentConditions.join(" AND ")})');
          }
        }

        // Location Paths - filter by directory paths
        if (filters.locationPaths != null &&
            filters.locationPaths!.isNotEmpty) {
          final pathConditions = <String>[];
          for (final locPath in filters.locationPaths!) {
            // Normalize path for consistent matching (handle both forward and back slashes)
            final normalizedPath = locPath.replaceAll('\\', '/');
            pathConditions.add(
              'REPLACE(fi."path", \'\\\\\', \'/\') ILIKE \$$paramIndex',
            );
            parameters.add('$normalizedPath%');
            paramIndex++;
          }
          if (pathConditions.isNotEmpty) {
            whereConditions.add('(${pathConditions.join(" OR ")})');
          }
        }

        // Word Count filters
        if (filters.minCount != null) {
          whereConditions.add('fi."wordCount" >= \$$paramIndex');
          parameters.add(filters.minCount);
          paramIndex++;
        }
        if (filters.maxCount != null) {
          whereConditions.add('fi."wordCount" <= \$$paramIndex');
          parameters.add(filters.maxCount);
          paramIndex++;
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
          ) as rank,
          fi."isTextContent", fi."contentHash", fi."embeddingModel", fi."documentCategory",
          fi."fileModifiedAt", fi."fileCreatedAt", fi."wordCount"
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
          isTextContent: row[9] as bool,
          contentHash: row[10] as String,
          embeddingModel: row[11] as String?,
          documentCategory: row[12] as String?,
          fileModifiedAt: row[13] as DateTime?,
          fileCreatedAt: row[14] as DateTime?,
          wordCount: row[15] as int?,
          status: 'indexed',
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

  /// Fuzzy filename search using pg_trgm similarity
  ///
  /// Handles typos and partial matches in filenames
  /// [query] - Filename or partial filename to search for
  /// [limit] - Maximum number of results (default: 10)
  /// [minSimilarity] - Minimum similarity threshold 0.0-1.0 (default: 0.3)
  Future<List<SearchResult>> fuzzyFilenameSearch(
    Session session,
    String query, {
    int limit = 10,
    double minSimilarity = 0.3,
  }) async {
    AuthService.requireAuth(session);

    final clientId = _getClientIdentifier(session);
    RateLimitService.instance.requireRateLimit(clientId, 'fuzzySearch');

    if (query.isEmpty || query.length < 2) {
      return [];
    }

    InputValidation.validateSearchQuery(query);
    limit = limit.clamp(1, _maxSearchLimit);
    minSimilarity = minSimilarity.clamp(0.0, 1.0);

    try {
      // Use pg_trgm similarity function for fuzzy matching
      final searchQuery = '''
        SELECT 
          fi.id, fi.path, fi."fileName", fi."contentPreview",
          fi."tagsJson", fi."indexedAt", fi."fileSizeBytes", fi."mimeType",
          similarity(fi."fileName", \$1) as sim_score
        FROM file_index fi
        WHERE fi.status = 'indexed'
          AND similarity(fi."fileName", \$1) >= \$2
        ORDER BY sim_score DESC
        LIMIT \$3
      ''';

      final rows = await session.db.unsafeQuery(
        searchQuery,
        parameters: QueryParameters.positional([query, minSimilarity, limit]),
      );

      return rows.map((row) {
        final tags = row[4] != null
            ? _parseTagList(row[4] as String)
            : <String>[];
        return SearchResult(
          id: row[0] as int,
          path: row[1] as String,
          fileName: row[2] as String,
          contentPreview: row[3] as String?,
          tags: tags,
          indexedAt: row[5] as DateTime?,
          fileSizeBytes: (row[6] as int?) ?? 0,
          mimeType: row[7] as String?,
          relevanceScore: row[8] as double,
        );
      }).toList();
    } catch (e) {
      session.log('Fuzzy filename search failed: $e', level: LogLevel.warning);
      return [];
    }
  }

  /// Generate index health report
  Future<IndexHealthReport> getIndexHealthReport(Session session) async {
    return await IndexHealthService.generateReport(session);
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
    SearchFilters? filters,
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

    // Yield progress from the AI search service with graceful fallback
    try {
      yield* aiSearchService.executeSearch(
        session,
        query,
        strategy: searchStrategy,
        maxResults: effectiveMaxResults,
        filters: filters,
      );
    } catch (e, stackTrace) {
      session.log(
        'AI search failed: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );

      // Graceful fallback to traditional search
      yield AISearchProgress(
        type: 'warning',
        message: 'AI search failed, falling back to traditional search...',
        progress: 0.5,
      );

      try {
        // Attempt hybrid search as fallback
        final fallbackResults = await hybridSearch(
          session,
          query,
          limit: effectiveMaxResults,
          threshold: 0.3,
          filters: filters,
        );

        // Convert SearchResult to AISearchResult
        final aiResults = fallbackResults
            .map(
              (r) => AISearchResult(
                path: r.path,
                fileName: r.fileName,
                isDirectory: false,
                source: 'fallback',
                relevanceScore: r.relevanceScore,
                contentPreview: r.contentPreview,
                foundVia: 'hybrid_fallback',
                matchReason: 'Found via fallback search',
                fileSizeBytes: r.fileSizeBytes,
                mimeType: r.mimeType,
                tags: r.tags,
                indexedAt: r.indexedAt,
                suggestedQuery: r.suggestedQuery,
              ),
            )
            .toList();

        yield AISearchProgress(
          type: 'complete',
          message: 'Search complete (fallback mode)',
          results: aiResults,
          progress: 1.0,
        );
      } catch (fallbackError) {
        session.log(
          'Fallback search also failed: $fallbackError',
          level: LogLevel.error,
        );
        yield AISearchProgress(
          type: 'error',
          message: 'Search failed',
          error: e.toString(),
        );
      }
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
}

/// Helper class for sorting search results by score
class _ScoredResult {
  final FileIndex doc;
  final double score;
  final String? matchedChunkText;

  _ScoredResult({
    required this.doc,
    required this.score,
    this.matchedChunkText,
  });
}
