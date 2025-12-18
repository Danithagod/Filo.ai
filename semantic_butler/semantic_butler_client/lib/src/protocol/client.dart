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
import 'package:semantic_butler_client/src/endpoints/agent_endpoint.dart'
    as _i3;
import 'package:semantic_butler_client/src/protocol/search_result.dart' as _i4;
import 'package:semantic_butler_client/src/protocol/indexing_job.dart' as _i5;
import 'package:semantic_butler_client/src/protocol/indexing_status.dart'
    as _i6;
import 'package:semantic_butler_client/src/protocol/database_stats.dart' as _i7;
import 'package:semantic_butler_client/src/protocol/search_history.dart' as _i8;
import 'package:semantic_butler_client/src/protocol/greetings/greeting.dart'
    as _i9;
import 'protocol.dart' as _i10;

/// Agent endpoint for natural language interactions
///
/// Provides a conversational interface that can use tools to:
/// - Search documents semantically
/// - Index new folders
/// - Summarize content
/// - Find related documents
/// - Answer questions about the user's files
/// {@category Endpoint}
class EndpointAgent extends _i1.EndpointRef {
  EndpointAgent(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'agent';

  /// Chat with the agent
  ///
  /// [message] - User's natural language message
  /// [conversationHistory] - Optional previous messages for context
  _i2.Future<_i3.AgentResponse> chat(
    String message, {
    List<_i3.AgentMessage>? conversationHistory,
  }) => caller.callServerEndpoint<_i3.AgentResponse>(
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
  _i2.Future<List<_i4.SearchResult>> semanticSearch(
    String query, {
    required int limit,
    required double threshold,
  }) => caller.callServerEndpoint<List<_i4.SearchResult>>(
    'butler',
    'semanticSearch',
    {
      'query': query,
      'limit': limit,
      'threshold': threshold,
    },
  );

  /// Start indexing documents from specified folder path
  _i2.Future<_i5.IndexingJob> startIndexing(String folderPath) =>
      caller.callServerEndpoint<_i5.IndexingJob>(
        'butler',
        'startIndexing',
        {'folderPath': folderPath},
      );

  /// Get current indexing status
  _i2.Future<_i6.IndexingStatus> getIndexingStatus() =>
      caller.callServerEndpoint<_i6.IndexingStatus>(
        'butler',
        'getIndexingStatus',
        {},
      );

  /// Get database statistics
  _i2.Future<_i7.DatabaseStats> getDatabaseStats() =>
      caller.callServerEndpoint<_i7.DatabaseStats>(
        'butler',
        'getDatabaseStats',
        {},
      );

  /// Get recent search history
  _i2.Future<List<_i8.SearchHistory>> getSearchHistory({required int limit}) =>
      caller.callServerEndpoint<List<_i8.SearchHistory>>(
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
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i9.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i9.Greeting>(
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
         _i10.Protocol(),
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
    greeting = EndpointGreeting(this);
  }

  late final EndpointAgent agent;

  late final EndpointButler butler;

  late final EndpointGreeting greeting;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'agent': agent,
    'butler': butler,
    'greeting': greeting,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
