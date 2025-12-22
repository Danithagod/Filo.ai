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
import 'package:semantic_butler_client/src/protocol/indexing_job.dart' as _i7;
import 'package:semantic_butler_client/src/protocol/indexing_status.dart'
    as _i8;
import 'package:semantic_butler_client/src/protocol/database_stats.dart' as _i9;
import 'package:semantic_butler_client/src/protocol/search_history.dart'
    as _i10;
import 'package:semantic_butler_client/src/protocol/watched_folder.dart'
    as _i11;
import 'package:semantic_butler_client/src/protocol/ignore_pattern.dart'
    as _i12;
import 'package:semantic_butler_client/src/protocol/file_system_entry.dart'
    as _i13;
import 'package:semantic_butler_client/src/protocol/drive_info.dart' as _i14;
import 'package:semantic_butler_client/src/protocol/file_operation_result.dart'
    as _i15;
import 'package:semantic_butler_client/src/protocol/greetings/greeting.dart'
    as _i16;
import 'protocol.dart' as _i17;

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

  /// Semantic search across indexed documents
  ///
  /// [query] - Natural language search query
  /// [limit] - Maximum number of results to return (default: 10)
  /// [threshold] - Minimum relevance score (0.0 to 1.0, default: 0.3)
  _i2.Future<List<_i6.SearchResult>> semanticSearch(
    String query, {
    required int limit,
    required double threshold,
  }) => caller.callServerEndpoint<List<_i6.SearchResult>>(
    'butler',
    'semanticSearch',
    {
      'query': query,
      'limit': limit,
      'threshold': threshold,
    },
  );

  /// Start indexing documents from specified folder path
  _i2.Future<_i7.IndexingJob> startIndexing(String folderPath) =>
      caller.callServerEndpoint<_i7.IndexingJob>(
        'butler',
        'startIndexing',
        {'folderPath': folderPath},
      );

  /// Get current indexing status
  _i2.Future<_i8.IndexingStatus> getIndexingStatus() =>
      caller.callServerEndpoint<_i8.IndexingStatus>(
        'butler',
        'getIndexingStatus',
        {},
      );

  /// Get database statistics
  _i2.Future<_i9.DatabaseStats> getDatabaseStats() =>
      caller.callServerEndpoint<_i9.DatabaseStats>(
        'butler',
        'getDatabaseStats',
        {},
      );

  /// Get recent search history
  _i2.Future<List<_i10.SearchHistory>> getSearchHistory({required int limit}) =>
      caller.callServerEndpoint<List<_i10.SearchHistory>>(
        'butler',
        'getSearchHistory',
        {'limit': limit},
      );

  /// Get AI usage statistics (cost tracking)
  _i2.Future<Map<String, dynamic>> getAIUsageStats() =>
      caller.callServerEndpoint<Map<String, dynamic>>(
        'butler',
        'getAIUsageStats',
        {},
      );

  /// Clear all indexed data
  _i2.Future<void> clearIndex() => caller.callServerEndpoint<void>(
    'butler',
    'clearIndex',
    {},
  );

  /// Enable smart indexing for a folder (starts file watching)
  _i2.Future<_i11.WatchedFolder> enableSmartIndexing(String folderPath) =>
      caller.callServerEndpoint<_i11.WatchedFolder>(
        'butler',
        'enableSmartIndexing',
        {'folderPath': folderPath},
      );

  /// Disable smart indexing for a folder (stops file watching)
  _i2.Future<void> disableSmartIndexing(String folderPath) =>
      caller.callServerEndpoint<void>(
        'butler',
        'disableSmartIndexing',
        {'folderPath': folderPath},
      );

  /// Get all watched folders
  _i2.Future<List<_i11.WatchedFolder>> getWatchedFolders() =>
      caller.callServerEndpoint<List<_i11.WatchedFolder>>(
        'butler',
        'getWatchedFolders',
        {},
      );

  /// Toggle smart indexing for a folder
  _i2.Future<_i11.WatchedFolder?> toggleSmartIndexing(String folderPath) =>
      caller.callServerEndpoint<_i11.WatchedFolder?>(
        'butler',
        'toggleSmartIndexing',
        {'folderPath': folderPath},
      );

  /// Add an ignore pattern
  /// [pattern] - Glob pattern like "*.log", "node_modules/**"
  /// [patternType] - Type: "file", "directory", or "both"
  _i2.Future<_i12.IgnorePattern> addIgnorePattern(
    String pattern, {
    required String patternType,
    String? description,
  }) => caller.callServerEndpoint<_i12.IgnorePattern>(
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
  _i2.Future<List<_i12.IgnorePattern>> listIgnorePatterns() =>
      caller.callServerEndpoint<List<_i12.IgnorePattern>>(
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
}

/// Endpoint for filesystem browsing and operations
/// {@category Endpoint}
class EndpointFileSystem extends _i1.EndpointRef {
  EndpointFileSystem(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'fileSystem';

  /// List contents of a directory
  _i2.Future<List<_i13.FileSystemEntry>> listDirectory(String path) =>
      caller.callServerEndpoint<List<_i13.FileSystemEntry>>(
        'fileSystem',
        'listDirectory',
        {'path': path},
      );

  /// Get available drives on the system
  _i2.Future<List<_i14.DriveInfo>> getDrives() =>
      caller.callServerEndpoint<List<_i14.DriveInfo>>(
        'fileSystem',
        'getDrives',
        {},
      );

  /// Rename a file or folder
  _i2.Future<_i15.FileOperationResult> rename(
    String path,
    String newName,
    bool isDirectory,
  ) => caller.callServerEndpoint<_i15.FileOperationResult>(
    'fileSystem',
    'rename',
    {
      'path': path,
      'newName': newName,
      'isDirectory': isDirectory,
    },
  );

  /// Move a file or folder
  _i2.Future<_i15.FileOperationResult> move(
    String sourcePath,
    String destFolder,
  ) => caller.callServerEndpoint<_i15.FileOperationResult>(
    'fileSystem',
    'move',
    {
      'sourcePath': sourcePath,
      'destFolder': destFolder,
    },
  );

  /// Delete a file or folder
  _i2.Future<_i15.FileOperationResult> delete(String path) =>
      caller.callServerEndpoint<_i15.FileOperationResult>(
        'fileSystem',
        'delete',
        {'path': path},
      );

  /// Create a new folder
  _i2.Future<_i15.FileOperationResult> createFolder(String path) =>
      caller.callServerEndpoint<_i15.FileOperationResult>(
        'fileSystem',
        'createFolder',
        {'path': path},
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
  _i2.Future<_i16.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i16.Greeting>(
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
         _i17.Protocol(),
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
    greeting = EndpointGreeting(this);
  }

  late final EndpointAgent agent;

  late final EndpointButler butler;

  late final EndpointFileSystem fileSystem;

  late final EndpointGreeting greeting;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'agent': agent,
    'butler': butler,
    'fileSystem': fileSystem,
    'greeting': greeting,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
