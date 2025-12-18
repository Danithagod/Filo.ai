import 'dart:io';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/openrouter_client.dart';
import '../services/ai_service.dart';
import '../config/ai_models.dart';
import 'butler_endpoint.dart';

/// Agent endpoint for natural language interactions
///
/// Provides a conversational interface that can use tools to:
/// - Search documents semantically
/// - Index new folders
/// - Summarize content
/// - Find related documents
/// - Answer questions about the user's files
class AgentEndpoint extends Endpoint {
  OpenRouterClient? _client;
  AIService? _aiService;

  OpenRouterClient get client {
    _client ??= OpenRouterClient(
      apiKey: Platform.environment['OPENROUTER_API_KEY'] ?? '',
    );
    return _client!;
  }

  AIService get aiService {
    _aiService ??= AIService(client: client);
    return _aiService!;
  }

  /// System prompt for the agent
  static const String systemPrompt = '''
You are Semantic Butler, an intelligent file search and organization assistant.
You help users find, organize, and understand their documents using semantic search.

You have access to the following tools:

1. **search_files** - Search indexed documents using natural language queries
   Parameters: query (string), limit (int, optional, default 10)

2. **get_document_details** - Get full details about a specific document
   Parameters: document_id (int)

3. **summarize_document** - Generate a summary of a document's content
   Parameters: document_id (int), max_words (int, optional, default 200)

4. **find_related** - Find documents similar to a given document
   Parameters: document_id (int), limit (int, optional, default 5)

5. **get_indexing_status** - Check the current indexing status and statistics

When responding:
- Be helpful and conversational
- Explain what you're doing when using tools
- Provide relevant context from search results
- Suggest related searches or actions when appropriate
''';

  /// Tool definitions for function calling
  List<Tool> get tools => [
    Tool(
      function: ToolFunction(
        name: 'search_files',
        description: 'Search indexed documents using semantic similarity',
        parameters: {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'Natural language search query',
            },
            'limit': {
              'type': 'integer',
              'description': 'Maximum number of results (default: 10)',
            },
          },
          'required': ['query'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: 'get_document_details',
        description: 'Get full details about a specific indexed document',
        parameters: {
          'type': 'object',
          'properties': {
            'document_id': {
              'type': 'integer',
              'description': 'ID of the document',
            },
          },
          'required': ['document_id'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: 'summarize_document',
        description: 'Generate a summary of a document content',
        parameters: {
          'type': 'object',
          'properties': {
            'document_id': {
              'type': 'integer',
              'description': 'ID of the document to summarize',
            },
            'max_words': {
              'type': 'integer',
              'description': 'Maximum summary length in words (default: 200)',
            },
          },
          'required': ['document_id'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: 'find_related',
        description: 'Find documents related to a given document',
        parameters: {
          'type': 'object',
          'properties': {
            'document_id': {
              'type': 'integer',
              'description': 'ID of the reference document',
            },
            'limit': {
              'type': 'integer',
              'description': 'Maximum related documents (default: 5)',
            },
          },
          'required': ['document_id'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: 'get_indexing_status',
        description: 'Get current indexing status and database statistics',
        parameters: {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      ),
    ),
  ];

  /// Chat with the agent
  ///
  /// [message] - User's natural language message
  /// [conversationHistory] - Optional previous messages for context
  Future<AgentResponse> chat(
    Session session,
    String message, {
    List<AgentMessage>? conversationHistory,
  }) async {
    final messages = <ChatMessage>[
      ChatMessage.system(systemPrompt),
    ];

    // Add conversation history if provided
    if (conversationHistory != null) {
      for (final msg in conversationHistory) {
        messages.add(
          ChatMessage(
            role: msg.role,
            content: msg.content,
          ),
        );
      }
    }

    // Add the new user message
    messages.add(ChatMessage.user(message));

    // Get response with potential tool calls
    var response = await client.chatCompletion(
      model: AIModels.agentDefault,
      messages: messages,
      tools: tools,
    );

    // Handle tool calls in a loop (agent may need multiple steps)
    int maxIterations = 10;
    int iteration = 0;

    while (response.hasToolCalls && iteration < maxIterations) {
      iteration++;

      // Add assistant's response with tool calls
      messages.add(response.choices.first.message);

      // Execute each tool call
      for (final toolCall in response.toolCalls) {
        final result = await _executeTool(session, toolCall);

        // Add tool result to messages
        messages.add(
          ChatMessage.tool(
            jsonEncode(result),
            toolCall.id,
          ),
        );
      }

      // Get next response
      response = await client.chatCompletion(
        model: AIModels.agentDefault,
        messages: messages,
        tools: tools,
      );
    }

    // Return final response
    return AgentResponse(
      message: response.content,
      toolsUsed: iteration > 0
          ? messages.where((m) => m.role == 'tool').length
          : 0,
      tokensUsed: response.usage?.totalTokens ?? 0,
    );
  }

  /// Execute a tool call
  Future<Map<String, dynamic>> _executeTool(
    Session session,
    ToolCall toolCall,
  ) async {
    final args = toolCall.function.parsedArguments;

    switch (toolCall.function.name) {
      case 'search_files':
        return await _toolSearchFiles(
          session,
          args['query'] as String,
          limit: args['limit'] as int? ?? 10,
        );

      case 'get_document_details':
        return await _toolGetDocumentDetails(
          session,
          args['document_id'] as int,
        );

      case 'summarize_document':
        return await _toolSummarizeDocument(
          session,
          args['document_id'] as int,
          maxWords: args['max_words'] as int? ?? 200,
        );

      case 'find_related':
        return await _toolFindRelated(
          session,
          args['document_id'] as int,
          limit: args['limit'] as int? ?? 5,
        );

      case 'get_indexing_status':
        return await _toolGetIndexingStatus(session);

      default:
        return {'error': 'Unknown tool: ${toolCall.function.name}'};
    }
  }

  /// Tool: Search files
  Future<Map<String, dynamic>> _toolSearchFiles(
    Session session,
    String query, {
    int limit = 10,
  }) async {
    // Use the ButlerEndpoint's search
    final butlerEndpoint = ButlerEndpoint();
    final results = await butlerEndpoint.semanticSearch(
      session,
      query,
      limit: limit,
    );

    return {
      'results': results
          .map(
            (r) => {
              'id': r.id,
              'fileName': r.fileName,
              'path': r.path,
              'relevanceScore': r.relevanceScore,
              'preview': r.contentPreview,
              'tags': r.tags,
            },
          )
          .toList(),
      'count': results.length,
    };
  }

  /// Tool: Get document details
  Future<Map<String, dynamic>> _toolGetDocumentDetails(
    Session session,
    int documentId,
  ) async {
    final doc = await FileIndex.db.findById(session, documentId);

    if (doc == null) {
      return {'error': 'Document not found'};
    }

    return {
      'id': doc.id,
      'fileName': doc.fileName,
      'path': doc.path,
      'mimeType': doc.mimeType,
      'fileSize': doc.fileSizeBytes,
      'status': doc.status,
      'indexedAt': doc.indexedAt?.toIso8601String(),
      'contentPreview': doc.contentPreview,
      'tags': doc.tagsJson,
    };
  }

  /// Tool: Summarize document
  Future<Map<String, dynamic>> _toolSummarizeDocument(
    Session session,
    int documentId, {
    int maxWords = 200,
  }) async {
    final doc = await FileIndex.db.findById(session, documentId);

    if (doc == null) {
      return {'error': 'Document not found'};
    }

    if (doc.contentPreview == null || doc.contentPreview!.isEmpty) {
      return {'error': 'Document has no content to summarize'};
    }

    final summary = await aiService.summarize(
      doc.contentPreview!,
      maxWords: maxWords,
    );

    return {
      'documentId': documentId,
      'fileName': doc.fileName,
      'summary': summary,
    };
  }

  /// Tool: Find related documents
  Future<Map<String, dynamic>> _toolFindRelated(
    Session session,
    int documentId, {
    int limit = 5,
  }) async {
    // Get the source document's embedding
    final embedding = await DocumentEmbedding.db.findFirstRow(
      session,
      where: (t) => t.fileIndexId.equals(documentId),
    );

    if (embedding == null) {
      return {'error': 'Document embedding not found'};
    }

    // Get source document info
    final sourceDoc = await FileIndex.db.findById(session, documentId);

    // Search using the document's embedding as query
    // This finds semantically similar documents
    final butlerEndpoint = ButlerEndpoint();
    final results = await butlerEndpoint.semanticSearch(
      session,
      sourceDoc?.contentPreview ?? '',
      limit: limit + 1, // +1 because it might include itself
    );

    // Filter out the source document
    final related = results
        .where((r) => r.id != documentId)
        .take(limit)
        .toList();

    return {
      'sourceDocument': sourceDoc?.fileName,
      'relatedDocuments': related
          .map(
            (r) => {
              'id': r.id,
              'fileName': r.fileName,
              'relevanceScore': r.relevanceScore,
              'preview': r.contentPreview?.substring(0, 100),
            },
          )
          .toList(),
    };
  }

  /// Tool: Get indexing status
  Future<Map<String, dynamic>> _toolGetIndexingStatus(Session session) async {
    final butlerEndpoint = ButlerEndpoint();
    final status = await butlerEndpoint.getIndexingStatus(session);

    return {
      'totalDocuments': status.totalDocuments,
      'indexedDocuments': status.indexedDocuments,
      'pendingDocuments': status.pendingDocuments,
      'failedDocuments': status.failedDocuments,
      'activeJobs': status.activeJobs,
      'lastActivity': status.lastActivity?.toIso8601String(),
    };
  }
}
