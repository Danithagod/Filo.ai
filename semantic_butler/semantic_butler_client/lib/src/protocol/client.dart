/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:semantic_butler_client/src/protocol/agent_stream_message.dart'
    as _i3;
import 'package:semantic_butler_client/src/protocol/agent_message.dart' as _i4;
import 'package:semantic_butler_client/src/protocol/agent_response.dart' as _i5;
import 'package:semantic_butler_client/src/protocol/search_result.dart' as _i6;
import 'package:semantic_butler_client/src/protocol/search_filters.dart' as _i7;
import 'package:semantic_butler_client/src/protocol/search_suggestion.dart'
    as _i8;
import 'package:semantic_butler_client/src/protocol/saved_search_preset.dart'
    as _i9;
import 'package:semantic_butler_client/src/protocol/search_facet.dart' as _i10;
import 'package:semantic_butler_client/src/protocol/search_history.dart'
    as _i11;
import 'package:semantic_butler_client/src/protocol/reset_preview.dart' as _i12;
import 'package:semantic_butler_client/src/protocol/reset_result.dart' as _i13;
import 'package:semantic_butler_client/src/protocol/indexing_status.dart'
    as _i14;
import 'package:semantic_butler_client/src/protocol/error_stats.dart' as _i15;
import 'package:semantic_butler_client/src/protocol/indexing_progress.dart'
    as _i16;
import 'package:semantic_butler_client/src/protocol/indexing_job.dart' as _i17;
import 'package:semantic_butler_client/src/protocol/watched_folder.dart'
    as _i18;
import 'package:semantic_butler_client/src/protocol/ignore_pattern.dart'
    as _i19;
import 'package:semantic_butler_client/src/protocol/tag_taxonomy.dart' as _i20;
import 'package:semantic_butler_client/src/protocol/index_health_report.dart'
    as _i21;
import 'package:semantic_butler_client/src/protocol/ai_search_progress.dart'
    as _i22;
import 'package:semantic_butler_client/src/protocol/file_system_entry.dart'
    as _i23;
import 'package:semantic_butler_client/src/protocol/drive_info.dart' as _i24;
import 'package:semantic_butler_client/src/protocol/file_operation_result.dart'
    as _i25;
import 'package:semantic_butler_client/src/protocol/health_check.dart' as _i26;
import 'package:semantic_butler_client/src/protocol/file_index.dart' as _i27;
import 'package:semantic_butler_client/src/protocol/document_embedding.dart'
    as _i28;
import 'package:semantic_butler_client/src/protocol/indexing_job_detail.dart'
    as _i29;
import 'package:semantic_butler_client/src/protocol/greetings/greeting.dart'
    as _i30;
import 'protocol.dart' as _i31;

/// Agent endpoint for natural language interactions
///
/// Provides a conversational interface that can use tools to:
/// - Search documents semantically
/// - Index new folders
/// - Summarize content
/// - Find related documents
/// - Answer questions about the user's files
/// - Organize files (rename, move, delete, create folders)
/// {@category Endpoint}
class EndpointAgent extends _i1.EndpointRef {
  EndpointAgent(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'agent';

  /// Streaming chat with real-time updates
  ///
  /// Yields [AgentStreamMessage] events for:
  /// - 'thinking' - Agent is processing
  /// - 'text' - Token-by-token text content
  /// - 'tool_start' - Starting a tool execution
  /// - 'tool_result' - Tool execution result
  /// - 'error' - Error occurred
  /// - 'complete' - Stream finished
  _i2.Stream<_i3.AgentStreamMessage> streamChat(
    String message, {
    List<_i4.AgentMessage>? conversationHistory,
  }) =>
      caller.callStreamingServerEndpoint<
        _i2.Stream<_i3.AgentStreamMessage>,
        _i3.AgentStreamMessage
      >(
        'agent',
        'streamChat',
        {
          'message': message,
          'conversationHistory': conversationHistory,
        },
        {},
      );

  /// Chat with the agent (non-streaming version)
  ///
  /// [message] - User's natural language message
  /// [conversationHistory] - Optional previous messages for context
  _i2.Future<_i5.AgentResponse> chat(
    String message, {
    List<_i4.AgentMessage>? conversationHistory,
  }) => caller.callServerEndpoint<_i5.AgentResponse>(
    'agent',
    'chat',
    {
      'message': message,
      'conversationHistory': conversationHistory,
    },
  );
}

/// Main endpoint for Semantic Desktop Butler
/// Handles semantic search, document indexing, and status queries
///
/// Now powered by OpenRouter for multi-provider AI access
/// {@category Endpoint}
class EndpointButler extends _i1.EndpointRef {
  EndpointButler(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'butler';

  _i2.Future<List<_i6.SearchResult>> semanticSearch(
    String query, {
    required int limit,
    required double threshold,
    required int offset,
    _i7.SearchFilters? filters,
  }) => caller.callServerEndpoint<List<_i6.SearchResult>>(
    'butler',
    'semanticSearch',
    {
      'query': query,
      'limit': limit,
      'threshold': threshold,
      'offset': offset,
      'filters': filters,
    },
  );

  /// Stream semantic search results for better perceived performance (Priority 2)
  _i2.Stream<_i6.SearchResult> semanticSearchStream(
    String query, {
    required int limit,
    required double threshold,
    required int offset,
    _i7.SearchFilters? filters,
  }) =>
      caller.callStreamingServerEndpoint<
        _i2.Stream<_i6.SearchResult>,
        _i6.SearchResult
      >(
        'butler',
        'semanticSearchStream',
        {
          'query': query,
          'limit': limit,
          'threshold': threshold,
          'offset': offset,
          'filters': filters,
        },
        {},
      );

  /// Get search suggestions based on query
  _i2.Future<List<_i8.SearchSuggestion>> getSearchSuggestions(
    String query, {
    required int limit,
  }) => caller.callServerEndpoint<List<_i8.SearchSuggestion>>(
    'butler',
    'getSearchSuggestions',
    {
      'query': query,
      'limit': limit,
    },
  );

  /// Save a search preset
  _i2.Future<_i9.SavedSearchPreset> savePreset(_i9.SavedSearchPreset preset) =>
      caller.callServerEndpoint<_i9.SavedSearchPreset>(
        'butler',
        'savePreset',
        {'preset': preset},
      );

  /// Get saved search presets
  _i2.Future<List<_i9.SavedSearchPreset>> getSavedPresets() =>
      caller.callServerEndpoint<List<_i9.SavedSearchPreset>>(
        'butler',
        'getSavedPresets',
        {},
      );

  /// Delete a saved search preset
  _i2.Future<bool> deletePreset(int presetId) =>
      caller.callServerEndpoint<bool>(
        'butler',
        'deletePreset',
        {'presetId': presetId},
      );

  /// Get faceted search counts for filtering
  _i2.Future<List<_i10.SearchFacet>> getSearchFacets(
    String query, {
    _i7.SearchFilters? filters,
  }) => caller.callServerEndpoint<List<_i10.SearchFacet>>(
    'butler',
    'getSearchFacets',
    {
      'query': query,
      'filters': filters,
    },
  );

  /// Get search history
  _i2.Future<List<_i11.SearchHistory>> getSearchHistory({
    int? limit,
    int? offset,
  }) => caller.callServerEndpoint<List<_i11.SearchHistory>>(
    'butler',
    'getSearchHistory',
    {
      'limit': limit,
      'offset': offset,
    },
  );

  /// Clear all search history
  _i2.Future<int> clearSearchHistory() => caller.callServerEndpoint<int>(
    'butler',
    'clearSearchHistory',
    {},
  );

  /// Delete a specific search history item
  _i2.Future<bool> deleteSearchHistoryItem(int id) =>
      caller.callServerEndpoint<bool>(
        'butler',
        'deleteSearchHistoryItem',
        {'id': id},
      );

  /// Record a local file search
  _i2.Future<void> recordLocalSearch(
    String query,
    String directory,
    int resultCount,
  ) => caller.callServerEndpoint<void>(
    'butler',
    'recordLocalSearch',
    {
      'query': query,
      'directory': directory,
      'resultCount': resultCount,
    },
  );

  /// Generate a reset confirmation code
  _i2.Future<String> generateResetConfirmationCode() =>
      caller.callServerEndpoint<String>(
        'butler',
        'generateResetConfirmationCode',
        {},
      );

  /// Preview a database reset
  _i2.Future<_i12.ResetPreview> previewReset() =>
      caller.callServerEndpoint<_i12.ResetPreview>(
        'butler',
        'previewReset',
        {},
      );

  /// Perform a database reset
  _i2.Future<_i13.ResetResult> resetDatabase({
    required String scope,
    required String confirmationCode,
    required bool dryRun,
  }) => caller.callServerEndpoint<_i13.ResetResult>(
    'butler',
    'resetDatabase',
    {
      'scope': scope,
      'confirmationCode': confirmationCode,
      'dryRun': dryRun,
    },
  );

  /// Get current indexing status
  _i2.Future<_i14.IndexingStatus> getIndexingStatus() =>
      caller.callServerEndpoint<_i14.IndexingStatus>(
        'butler',
        'getIndexingStatus',
        {},
      );

  /// Get error statistics
  _i2.Future<_i15.ErrorStats> getErrorStats() =>
      caller.callServerEndpoint<_i15.ErrorStats>(
        'butler',
        'getErrorStats',
        {},
      );

  /// Stream indexing progress
  _i2.Stream<_i16.IndexingProgress> streamIndexingProgress(int jobId) =>
      caller.callStreamingServerEndpoint<
        _i2.Stream<_i16.IndexingProgress>,
        _i16.IndexingProgress
      >(
        'butler',
        'streamIndexingProgress',
        {'jobId': jobId},
        {},
      );

  /// Get details of a specific indexing job
  _i2.Future<_i17.IndexingJob?> getIndexingJob(int jobId) =>
      caller.callServerEndpoint<_i17.IndexingJob?>(
        'butler',
        'getIndexingJob',
        {'jobId': jobId},
      );

  /// Start indexing documents from specified folder path
  _i2.Future<_i17.IndexingJob> startIndexing(String folderPath) =>
      caller.callServerEndpoint<_i17.IndexingJob>(
        'butler',
        'startIndexing',
        {'folderPath': folderPath},
      );

  /// Cancel a running indexing job
  _i2.Future<bool> cancelIndexingJob(int jobId) =>
      caller.callServerEndpoint<bool>(
        'butler',
        'cancelIndexingJob',
        {'jobId': jobId},
      );

  /// Enable smart indexing for a folder
  _i2.Future<_i18.WatchedFolder> enableSmartIndexing(String folderPath) =>
      caller.callServerEndpoint<_i18.WatchedFolder>(
        'butler',
        'enableSmartIndexing',
        {'folderPath': folderPath},
      );

  /// Disable smart indexing for a folder
  _i2.Future<void> disableSmartIndexing(String folderPath) =>
      caller.callServerEndpoint<void>(
        'butler',
        'disableSmartIndexing',
        {'folderPath': folderPath},
      );

  /// Toggle smart indexing for a folder
  _i2.Future<_i18.WatchedFolder?> toggleSmartIndexing(String folderPath) =>
      caller.callServerEndpoint<_i18.WatchedFolder?>(
        'butler',
        'toggleSmartIndexing',
        {'folderPath': folderPath},
      );

  /// Get all watched folders
  _i2.Future<List<_i18.WatchedFolder>> getWatchedFolders() =>
      caller.callServerEndpoint<List<_i18.WatchedFolder>>(
        'butler',
        'getWatchedFolders',
        {},
      );

  /// Add an ignore pattern
  /// [pattern] - Glob pattern like "*.log", "node_modules/**"
  /// [patternType] - Type: "file", "directory", or "both"
  _i2.Future<_i19.IgnorePattern> addIgnorePattern(
    String pattern, {
    required String patternType,
    String? description,
  }) => caller.callServerEndpoint<_i19.IgnorePattern>(
    'butler',
    'addIgnorePattern',
    {
      'pattern': pattern,
      'patternType': patternType,
      'description': description,
    },
  );

  /// Remove an ignore pattern by ID
  _i2.Future<int> removeIgnorePattern(int patternId) =>
      caller.callServerEndpoint<int>(
        'butler',
        'removeIgnorePattern',
        {'patternId': patternId},
      );

  /// List all ignore patterns
  _i2.Future<List<_i19.IgnorePattern>> listIgnorePatterns() =>
      caller.callServerEndpoint<List<_i19.IgnorePattern>>(
        'butler',
        'listIgnorePatterns',
        {},
      );

  /// Get ignore patterns as list of strings for filtering
  /// Used by the indexing process to filter out ignored files
  _i2.Future<List<String>> getIgnorePatternStrings() =>
      caller.callServerEndpoint<List<String>>(
        'butler',
        'getIgnorePatternStrings',
        {},
      );

  /// Remove a file from the index by path or ID
  /// Returns true if the file was removed, false if not found
  _i2.Future<bool> removeFromIndex({
    String? path,
    int? id,
  }) => caller.callServerEndpoint<bool>(
    'butler',
    'removeFromIndex',
    {
      'path': path,
      'id': id,
    },
  );

  /// Remove multiple files from the index by paths
  _i2.Future<int> removeMultipleFromIndex(List<String> paths) =>
      caller.callServerEndpoint<int>(
        'butler',
        'removeMultipleFromIndex',
        {'paths': paths},
      );

  /// Estimate database size based on content
  /// This is an approximation based on indexed content
  /// Get top tags by frequency
  _i2.Future<List<_i20.TagTaxonomy>> getTopTags({
    String? category,
    int? limit,
  }) => caller.callServerEndpoint<List<_i20.TagTaxonomy>>(
    'butler',
    'getTopTags',
    {
      'category': category,
      'limit': limit,
    },
  );

  /// Search tags for autocomplete
  _i2.Future<List<_i20.TagTaxonomy>> searchTags(
    String query, {
    String? category,
    int? limit,
  }) => caller.callServerEndpoint<List<_i20.TagTaxonomy>>(
    'butler',
    'searchTags',
    {
      'query': query,
      'category': category,
      'limit': limit,
    },
  );

  /// Merge multiple tags into a single target tag
  _i2.Future<int> mergeTags({
    required List<String> sourceTags,
    required String targetTag,
    String? category,
  }) => caller.callServerEndpoint<int>(
    'butler',
    'mergeTags',
    {
      'sourceTags': sourceTags,
      'targetTag': targetTag,
      'category': category,
    },
  );

  /// Rename a tag across all files and taxonomy
  _i2.Future<int> renameTag({
    required String oldTag,
    required String newTag,
    String? category,
  }) => caller.callServerEndpoint<int>(
    'butler',
    'renameTag',
    {
      'oldTag': oldTag,
      'newTag': newTag,
      'category': category,
    },
  );

  /// Get related tags based on co-occurrence
  _i2.Future<List<Map<String, dynamic>>> getRelatedTags({
    required String tagValue,
    int? limit,
  }) => caller.callServerEndpoint<List<Map<String, dynamic>>>(
    'butler',
    'getRelatedTags',
    {
      'tagValue': tagValue,
      'limit': limit,
    },
  );

  /// Get tag category statistics
  _i2.Future<Map<String, dynamic>> getTagCategoryStats() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'butler',
        'getTagCategoryStats',
        {},
      );

  /// Hybrid search combining semantic and keyword search
  _i2.Future<List<_i6.SearchResult>> hybridSearch(
    String query, {
    double? threshold,
    int? limit,
    int? offset,
    double? semanticWeight,
    double? keywordWeight,
    _i7.SearchFilters? filters,
  }) => caller.callServerEndpoint<List<_i6.SearchResult>>(
    'butler',
    'hybridSearch',
    {
      'query': query,
      'threshold': threshold,
      'limit': limit,
      'offset': offset,
      'semanticWeight': semanticWeight,
      'keywordWeight': keywordWeight,
      'filters': filters,
    },
  );

  /// Fuzzy filename search using pg_trgm similarity
  ///
  /// Handles typos and partial matches in filenames
  /// [query] - Filename or partial filename to search for
  /// [limit] - Maximum number of results (default: 10)
  /// [minSimilarity] - Minimum similarity threshold 0.0-1.0 (default: 0.3)
  _i2.Future<List<_i6.SearchResult>> fuzzyFilenameSearch(
    String query, {
    required int limit,
    required double minSimilarity,
  }) => caller.callServerEndpoint<List<_i6.SearchResult>>(
    'butler',
    'fuzzyFilenameSearch',
    {
      'query': query,
      'limit': limit,
      'minSimilarity': minSimilarity,
    },
  );

  /// Generate index health report
  _i2.Future<_i21.IndexHealthReport> getIndexHealthReport() =>
      caller.callServerEndpoint<_i21.IndexHealthReport>(
        'butler',
        'getIndexHealthReport',
        {},
      );

  /// Clean up orphaned files from index
  _i2.Future<int> cleanupOrphanedFiles() => caller.callServerEndpoint<int>(
    'butler',
    'cleanupOrphanedFiles',
    {},
  );

  /// Refresh stale index entries
  _i2.Future<int> refreshStaleEntries({int? staleThresholdDays}) =>
      caller.callServerEndpoint<int>(
        'butler',
        'refreshStaleEntries',
        {'staleThresholdDays': staleThresholdDays},
      );

  /// Remove duplicate files from index
  _i2.Future<int> removeDuplicates({bool? keepNewest}) =>
      caller.callServerEndpoint<int>(
        'butler',
        'removeDuplicates',
        {'keepNewest': keepNewest},
      );

  /// Fix files with missing embeddings
  _i2.Future<int> fixMissingEmbeddings() => caller.callServerEndpoint<int>(
    'butler',
    'fixMissingEmbeddings',
    {},
  );

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
  _i2.Stream<_i22.AISearchProgress> aiSearch(
    String query, {
    String? strategy,
    int? maxResults,
    _i7.SearchFilters? filters,
  }) =>
      caller.callStreamingServerEndpoint<
        _i2.Stream<_i22.AISearchProgress>,
        _i22.AISearchProgress
      >(
        'butler',
        'aiSearch',
        {
          'query': query,
          'strategy': strategy,
          'maxResults': maxResults,
          'filters': filters,
        },
        {},
      );

  /// Summarize a file's content using AI
  ///
  /// Extracts text from the file and generates a hierarchical summary
  /// with brief, medium, and detailed levels.
  ///
  /// [filePath] - Full path to the file to summarize
  ///
  /// Returns a JSON string containing the summary levels and metadata
  _i2.Future<String> summarizeFile(String filePath) =>
      caller.callServerEndpoint<String>(
        'butler',
        'summarizeFile',
        {'filePath': filePath},
      );
}

/// Endpoint for filesystem browsing and operations
/// {@category Endpoint}
class EndpointFileSystem extends _i1.EndpointRef {
  EndpointFileSystem(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'fileSystem';

  /// List contents of a directory
  _i2.Future<List<_i23.FileSystemEntry>> listDirectory(String path) =>
      caller.callServerEndpoint<List<_i23.FileSystemEntry>>(
        'fileSystem',
        'listDirectory',
        {'path': path},
      );

  /// Get available drives on the system
  _i2.Future<List<_i24.DriveInfo>> getDrives() =>
      caller.callServerEndpoint<List<_i24.DriveInfo>>(
        'fileSystem',
        'getDrives',
        {},
      );

  /// Rename a file or folder
  _i2.Future<_i25.FileOperationResult> rename(
    String path,
    String newName,
    bool isDirectory,
  ) => caller.callServerEndpoint<_i25.FileOperationResult>(
    'fileSystem',
    'rename',
    {
      'path': path,
      'newName': newName,
      'isDirectory': isDirectory,
    },
  );

  /// Move a file or folder
  _i2.Future<_i25.FileOperationResult> move(
    String sourcePath,
    String destFolder,
  ) => caller.callServerEndpoint<_i25.FileOperationResult>(
    'fileSystem',
    'move',
    {
      'sourcePath': sourcePath,
      'destFolder': destFolder,
    },
  );

  /// Delete a file or folder
  _i2.Future<_i25.FileOperationResult> delete(String path) =>
      caller.callServerEndpoint<_i25.FileOperationResult>(
        'fileSystem',
        'delete',
        {'path': path},
      );

  /// Create a new folder
  _i2.Future<_i25.FileOperationResult> createFolder(String path) =>
      caller.callServerEndpoint<_i25.FileOperationResult>(
        'fileSystem',
        'createFolder',
        {'path': path},
      );
}

/// Health check endpoint for monitoring system health
/// Public endpoint - no authentication required
/// {@category Endpoint}
class EndpointHealth extends _i1.EndpointRef {
  EndpointHealth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'health';

  /// Check system health
  /// Returns overall status and component-level health metrics
  _i2.Future<_i26.HealthCheck> check() =>
      caller.callServerEndpoint<_i26.HealthCheck>(
        'health',
        'check',
        {},
      );
}

/// Endpoint for handling hybrid indexing (Client-side indexing, Cloud storage)
/// {@category Endpoint}
class EndpointIndexing extends _i1.EndpointRef {
  EndpointIndexing(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'indexing';

  /// Upload a file index and its embeddings from the client
  /// This allows the client to do local processing (text extraction, embedding generation)
  /// and upload the result to the cloud database.
  _i2.Future<void> uploadIndex({
    required _i27.FileIndex fileIndex,
    required List<_i28.DocumentEmbedding> embeddings,
  }) => caller.callServerEndpoint<void>(
    'indexing',
    'uploadIndex',
    {
      'fileIndex': fileIndex,
      'embeddings': embeddings,
    },
  );

  /// Batch upload (DEPRECATED: Use uploadIndex for multi-chunk support)
  _i2.Future<void> uploadIndexBatch(
    List<_i27.FileIndex> files,
    List<_i28.DocumentEmbedding> embeddings,
  ) => caller.callServerEndpoint<void>(
    'indexing',
    'uploadIndexBatch',
    {
      'files': files,
      'embeddings': embeddings,
    },
  );

  /// Create a indexing job record for client-managed indexing
  _i2.Future<_i17.IndexingJob?> createClientJob(
    String folderPath,
    int totalFiles,
  ) => caller.callServerEndpoint<_i17.IndexingJob?>(
    'indexing',
    'createClientJob',
    {
      'folderPath': folderPath,
      'totalFiles': totalFiles,
    },
  );

  /// Update the status/progress of a client-managed indexing job
  _i2.Future<_i17.IndexingJob?> updateJobStatus({
    required int jobId,
    required String status,
    required int processedFiles,
    required int failedFiles,
    required int skippedFiles,
    String? errorMessage,
  }) => caller.callServerEndpoint<_i17.IndexingJob?>(
    'indexing',
    'updateJobStatus',
    {
      'jobId': jobId,
      'status': status,
      'processedFiles': processedFiles,
      'failedFiles': failedFiles,
      'skippedFiles': skippedFiles,
      'errorMessage': errorMessage,
    },
  );

  /// Update detailed status for a specific file in a job
  _i2.Future<_i29.IndexingJobDetail> updateJobDetail({
    required int jobId,
    required String filePath,
    required String status,
    String? errorMessage,
    String? errorCategory,
  }) => caller.callServerEndpoint<_i29.IndexingJobDetail>(
    'indexing',
    'updateJobDetail',
    {
      'jobId': jobId,
      'filePath': filePath,
      'status': status,
      'errorMessage': errorMessage,
      'errorCategory': errorCategory,
    },
  );

  /// Get all detailed file statuses for a specific job
  _i2.Future<List<_i29.IndexingJobDetail>> getJobDetails(int jobId) =>
      caller.callServerEndpoint<List<_i29.IndexingJobDetail>>(
        'indexing',
        'getJobDetails',
        {'jobId': jobId},
      );

  /// Check if a file with the given path and hash already exists in the index
  _i2.Future<_i27.FileIndex?> checkHash({
    required String path,
    required String contentHash,
  }) => caller.callServerEndpoint<_i27.FileIndex?>(
    'indexing',
    'checkHash',
    {
      'path': path,
      'contentHash': contentHash,
    },
  );

  /// Cancel an active indexing job
  _i2.Future<bool> cancelJob(int jobId) => caller.callServerEndpoint<bool>(
    'indexing',
    'cancelJob',
    {'jobId': jobId},
  );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i30.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i30.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i31.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    agent = EndpointAgent(this);
    butler = EndpointButler(this);
    fileSystem = EndpointFileSystem(this);
    health = EndpointHealth(this);
    indexing = EndpointIndexing(this);
    greeting = EndpointGreeting(this);
  }

  late final EndpointAgent agent;

  late final EndpointButler butler;

  late final EndpointFileSystem fileSystem;

  late final EndpointHealth health;

  late final EndpointIndexing indexing;

  late final EndpointGreeting greeting;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'agent': agent,
    'butler': butler,
    'fileSystem': fileSystem,
    'health': health,
    'indexing': indexing,
    'greeting': greeting,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
