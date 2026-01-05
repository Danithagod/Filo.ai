import 'dart:convert';
import 'dart:math' as math;

import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/openrouter_client.dart';
import '../services/ai_service.dart';
import '../services/file_operations_service.dart';
import '../services/terminal_service.dart';
import '../config/ai_models.dart';
import 'butler_endpoint.dart';
import '../../server.dart' show getEnv;

/// Agent endpoint for natural language interactions
///
/// Provides a conversational interface that can use tools to:
/// - Search documents semantically
/// - Index new folders
/// - Summarize content
/// - Find related documents
/// - Answer questions about the user's files
/// - Organize files (rename, move, delete, create folders)
class AgentEndpoint extends Endpoint {
  OpenRouterClient? _client;
  AIService? _aiService;
  final FileOperationsService _fileOps = FileOperationsService();
  final TerminalService _terminal = TerminalService();

  OpenRouterClient get client {
    _client ??= OpenRouterClient(
      apiKey: getEnv('OPENROUTER_API_KEY'),
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
You can also help organize files by renaming, moving, deleting, and creating folders.
You have access to the local file system and can execute terminal commands.

You have access to the following tools:

**Search & Discovery:**
1. **search_files** - Semantic search on indexed documents
   Parameters: query (string), limit (int, optional)

2. **grep_search** - Search file contents for text patterns (like grep/findstr)
   Parameters: pattern (string), path (string), recursive (bool), ignore_case (bool)

3. **find_files** - Find files by name pattern across drives
   Parameters: pattern (string), directory (string, optional), recursive (bool)

4. **list_directory** - List contents of a directory
   Parameters: path (string)

5. **get_drives** - List all available drives on the system

**File Information:**
6. **get_document_details** - Get details about an indexed document
   Parameters: document_id (int)

7. **read_file_contents** - Read the contents of any text file
   Parameters: path (string)

8. **summarize_document** - Generate AI summary of a document
   Parameters: document_id (int), max_words (int, optional)

9. **find_related** - Find semantically similar documents
   Parameters: document_id (int), limit (int, optional)

10. **get_indexing_status** - Check indexing status and statistics

**File Organization:**
11. **rename_file** - Rename a file
    Parameters: current_path (string), new_name (string)

12. **rename_folder** - Rename a folder
    Parameters: current_path (string), new_name (string)

13. **move_file** - Move a file to a different folder
    Parameters: source_path (string), destination_folder (string)

14. **delete_file** - Delete a file or folder (CAUTION: permanent)
    Parameters: path (string)

15. **create_folder** - Create a new folder
    Parameters: path (string)

**Terminal Access:**
16. **run_command** - Execute a shell command (read-only commands only)
    Parameters: command (string), working_directory (string, optional)

When responding:
- Be helpful and conversational
- Use terminal commands to explore the file system when needed
- Explain what you're doing when using tools
- For file operations, ALWAYS confirm before destructive operations
- If an operation fails, explain why and suggest alternatives
- Use appropriate path separators for the OS (Windows: backslash, Unix: forward slash)
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
    // File organization tools
    Tool(
      function: ToolFunction(
        name: 'rename_file',
        description: 'Rename a file to a new name',
        parameters: {
          'type': 'object',
          'properties': {
            'current_path': {
              'type': 'string',
              'description': 'Full path to the file to rename',
            },
            'new_name': {
              'type': 'string',
              'description': 'New name for the file (not full path)',
            },
          },
          'required': ['current_path', 'new_name'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: 'rename_folder',
        description: 'Rename a folder to a new name',
        parameters: {
          'type': 'object',
          'properties': {
            'current_path': {
              'type': 'string',
              'description': 'Full path to the folder to rename',
            },
            'new_name': {
              'type': 'string',
              'description': 'New name for the folder (not full path)',
            },
          },
          'required': ['current_path', 'new_name'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: 'move_file',
        description: 'Move a file or folder to a different location',
        parameters: {
          'type': 'object',
          'properties': {
            'source_path': {
              'type': 'string',
              'description': 'Full path to the file or folder to move',
            },
            'destination_folder': {
              'type': 'string',
              'description': 'Full path to the destination folder',
            },
          },
          'required': ['source_path', 'destination_folder'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: 'delete_file',
        description: 'Delete a file or folder (CAUTION: this is permanent)',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Full path to the file or folder to delete',
            },
          },
          'required': ['path'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: 'create_folder',
        description:
            'Create a new folder (creates parent directories if needed)',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Full path of the folder to create',
            },
          },
          'required': ['path'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: 'list_directory',
        description: 'List the contents of a directory',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Full path to the directory to list',
            },
          },
          'required': ['path'],
        },
      ),
    ),
    // Terminal access tools
    Tool(
      function: ToolFunction(
        name: 'run_command',
        description:
            'Execute a shell command on the host system. Only read-only commands are allowed (dir, ls, find, grep, cat, type, etc.)',
        parameters: {
          'type': 'object',
          'properties': {
            'command': {
              'type': 'string',
              'description': 'The shell command to execute',
            },
            'working_directory': {
              'type': 'string',
              'description': 'Optional working directory for the command',
            },
          },
          'required': ['command'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: 'grep_search',
        description:
            'Search file contents for a text pattern (like grep on Unix or findstr on Windows)',
        parameters: {
          'type': 'object',
          'properties': {
            'pattern': {
              'type': 'string',
              'description': 'Text pattern to search for',
            },
            'path': {
              'type': 'string',
              'description': 'File or directory path to search in',
            },
            'recursive': {
              'type': 'boolean',
              'description':
                  'Search recursively in subdirectories (default: true)',
            },
            'ignore_case': {
              'type': 'boolean',
              'description': 'Case-insensitive search (default: true)',
            },
          },
          'required': ['pattern', 'path'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: 'find_files',
        description:
            'Find files matching a name pattern across drives or in a directory',
        parameters: {
          'type': 'object',
          'properties': {
            'pattern': {
              'type': 'string',
              'description':
                  'File name pattern with wildcards (e.g., *.pdf, report*.docx)',
            },
            'directory': {
              'type': 'string',
              'description':
                  'Directory to search in (optional, defaults to C:\\ or /)',
            },
            'recursive': {
              'type': 'boolean',
              'description': 'Search recursively (default: true)',
            },
          },
          'required': ['pattern'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: 'read_file_contents',
        description: 'Read the contents of a text file',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Full path to the file to read',
            },
          },
          'required': ['path'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: 'get_drives',
        description: 'List all available drives/filesystems on the system',
        parameters: {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      ),
    ),
  ];

  /// Streaming chat with real-time updates
  ///
  /// Yields [AgentStreamMessage] events for:
  /// - 'thinking' - Agent is processing
  /// - 'text' - Token-by-token text content
  /// - 'tool_start' - Starting a tool execution
  /// - 'tool_result' - Tool execution result
  /// - 'error' - Error occurred
  /// - 'complete' - Stream finished
  Stream<AgentStreamMessage> streamChat(
    Session session,
    String message, {
    List<AgentMessage>? conversationHistory,
  }) async* {
    // Emit thinking status
    yield AgentStreamMessage(
      type: 'thinking',
      content: 'Processing your request...',
    );

    final messages = <ChatMessage>[
      ChatMessage.system(systemPrompt),
    ];

    // Add conversation history if provided
    if (conversationHistory != null) {
      for (final msg in conversationHistory) {
        messages.add(ChatMessage(role: msg.role, content: msg.content));
      }
    }

    // Add the new user message
    messages.add(ChatMessage.user(message));

    int totalTokens = 0;
    int iteration = 0;
    const maxIterations = 10;

    while (iteration < maxIterations) {
      iteration++;

      // Stream the response
      final contentBuffer = StringBuffer();
      List<ToolCall>? pendingToolCalls;
      String? finishReason;

      try {
        await for (final chunk in client.streamChatCompletion(
          model: AIModels.agentDefault,
          messages: messages,
          tools: tools,
          temperature: 0.7,
          maxTokens: 4096,
        )) {
          if (chunk.isDone) {
            finishReason = 'stop';
            break;
          }

          // Emit text tokens
          if (chunk.deltaContent != null && chunk.deltaContent!.isNotEmpty) {
            contentBuffer.write(chunk.deltaContent);
            totalTokens++;
            yield AgentStreamMessage(
              type: 'text',
              content: chunk.deltaContent,
              tokenCount: totalTokens,
            );
          }

          // Check for tool calls
          if (chunk.hasToolCalls) {
            pendingToolCalls = chunk.toolCalls;
          }

          // Check finish reason
          if (chunk.finishReason != null) {
            finishReason = chunk.finishReason;
          }
        }
      } catch (e) {
        yield AgentStreamMessage(
          type: 'error',
          content: 'Streaming failed: $e',
        );
        return;
      }

      final content = contentBuffer.toString();

      // If we have tool calls, execute them
      if (finishReason == 'tool_calls' &&
          pendingToolCalls != null &&
          pendingToolCalls.isNotEmpty) {
        // Add assistant message with tool calls
        messages.add(
          ChatMessage.assistant(content, toolCalls: pendingToolCalls),
        );

        // Execute each tool
        for (final toolCall in pendingToolCalls) {
          // Emit tool start
          yield AgentStreamMessage(
            type: 'tool_start',
            tool: toolCall.function.name,
            content: 'Executing ${toolCall.function.name}...',
          );

          // Execute the tool
          final result = await _executeTool(session, toolCall);

          // Emit tool result
          yield AgentStreamMessage(
            type: 'tool_result',
            tool: toolCall.function.name,
            result: jsonEncode(result),
          );

          // Add tool result message
          messages.add(
            ChatMessage.tool(
              jsonEncode(result),
              toolCall.id,
            ),
          );
        }

        // Continue the loop to get the next response
        yield AgentStreamMessage(
          type: 'thinking',
          content: 'Processing tool results...',
        );
        continue;
      }

      // No more tool calls, we're done
      yield AgentStreamMessage(
        type: 'complete',
        content: content,
        tokenCount: totalTokens,
      );
      return;
    }

    // Max iterations reached
    yield AgentStreamMessage(
      type: 'error',
      content: 'Maximum tool iterations reached',
    );
  }

  /// Chat with the agent (non-streaming version)
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

      // File organization tools
      case 'rename_file':
        return await _toolRenameFile(
          session,
          args['current_path'] as String,
          args['new_name'] as String,
        );

      case 'rename_folder':
        return await _toolRenameFolder(
          session,
          args['current_path'] as String,
          args['new_name'] as String,
        );

      case 'move_file':
        return await _toolMoveFile(
          session,
          args['source_path'] as String,
          args['destination_folder'] as String,
        );

      case 'delete_file':
        return await _toolDeleteFile(
          session,
          args['path'] as String,
        );

      case 'create_folder':
        return await _toolCreateFolder(
          session,
          args['path'] as String,
        );

      case 'list_directory':
        return await _toolListDirectory(
          session,
          args['path'] as String,
        );

      // Terminal access tools
      case 'run_command':
        return await _toolRunCommand(
          args['command'] as String,
          workingDirectory: args['working_directory'] as String?,
        );

      case 'grep_search':
        return await _toolGrepSearch(
          args['pattern'] as String,
          args['path'] as String,
          recursive: args['recursive'] as bool? ?? true,
          ignoreCase: args['ignore_case'] as bool? ?? true,
        );

      case 'find_files':
        return await _toolFindFiles(
          args['pattern'] as String,
          directory: args['directory'] as String?,
          recursive: args['recursive'] as bool? ?? true,
        );

      case 'read_file_contents':
        return await _toolReadFileContents(
          args['path'] as String,
        );

      case 'get_drives':
        return await _toolGetDrives();

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
            (r) => <String, dynamic>{
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

    // Parse embedding from JSON
    final vectorQuery =
        (jsonDecode(embedding.embeddingJson) as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList();

    // Search using the document's embedding as query
    // This finds semantically similar documents
    final butlerEndpoint = ButlerEndpoint();
    final results = await butlerEndpoint.semanticSearch(
      session,
      sourceDoc?.contentPreview ?? '',
      limit: limit + 1, // +1 because it might include itself
      vectorQuery: vectorQuery,
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
            (r) => <String, dynamic>{
              'id': r.id,
              'fileName': r.fileName,
              'relevanceScore': r.relevanceScore,
              'preview': r.contentPreview?.substring(
                0,
                math.min(100, r.contentPreview?.length ?? 0),
              ),
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

  // ==========================================================================
  // FILE ORGANIZATION TOOLS
  // ==========================================================================

  /// Tool: Rename a file
  Future<Map<String, dynamic>> _toolRenameFile(
    Session session,
    String currentPath,
    String newName,
  ) async {
    final result = await _fileOps.renameFile(currentPath, newName);

    // Sync file index if operation succeeded
    if (result.success && result.newPath != null) {
      await _syncIndexAfterRename(session, currentPath, result.newPath!);
    }

    // Log the operation
    await _logFileOperation(
      session,
      operation: 'rename',
      sourcePath: currentPath,
      newName: newName,
      destinationPath: result.newPath,
      success: result.success,
      errorMessage: result.error,
    );

    return result.toJson();
  }

  /// Tool: Rename a folder
  Future<Map<String, dynamic>> _toolRenameFolder(
    Session session,
    String currentPath,
    String newName,
  ) async {
    final result = await _fileOps.renameFolder(currentPath, newName);

    // Log the operation
    await _logFileOperation(
      session,
      operation: 'rename',
      sourcePath: currentPath,
      newName: newName,
      destinationPath: result.newPath,
      success: result.success,
      errorMessage: result.error,
    );

    return result.toJson();
  }

  /// Tool: Move a file or folder
  Future<Map<String, dynamic>> _toolMoveFile(
    Session session,
    String sourcePath,
    String destFolder,
  ) async {
    final result = await _fileOps.moveFile(sourcePath, destFolder);

    // Sync file index if operation succeeded
    if (result.success && result.newPath != null) {
      await _syncIndexAfterRename(session, sourcePath, result.newPath!);
    }

    // Log the operation
    await _logFileOperation(
      session,
      operation: 'move',
      sourcePath: sourcePath,
      destinationPath: result.newPath ?? destFolder,
      success: result.success,
      errorMessage: result.error,
    );

    return result.toJson();
  }

  /// Tool: Delete a file or folder
  Future<Map<String, dynamic>> _toolDeleteFile(
    Session session,
    String path,
  ) async {
    final result = await _fileOps.deleteFile(path);

    // Remove from file index if operation succeeded
    if (result.success) {
      await _removeFromIndexSafe(session, path);
    }

    // Log the operation
    await _logFileOperation(
      session,
      operation: 'delete',
      sourcePath: path,
      success: result.success,
      errorMessage: result.error,
    );

    return result.toJson();
  }

  /// Tool: Create a folder
  Future<Map<String, dynamic>> _toolCreateFolder(
    Session session,
    String path,
  ) async {
    final result = await _fileOps.createFolder(path);

    // Log the operation
    await _logFileOperation(
      session,
      operation: 'create',
      sourcePath: path,
      destinationPath: result.newPath,
      success: result.success,
      errorMessage: result.error,
    );

    return result.toJson();
  }

  /// Tool: List directory contents
  Future<Map<String, dynamic>> _toolListDirectory(
    Session session,
    String path,
  ) async {
    final result = await _fileOps.listDirectory(path);

    // List operations are not logged to the audit trail
    return result.toJson();
  }

  /// Log a file operation to the database for audit purposes
  Future<void> _logFileOperation(
    Session session, {
    required String operation,
    required String sourcePath,
    String? destinationPath,
    String? newName,
    required bool success,
    String? errorMessage,
  }) async {
    try {
      await AgentFileCommand.db.insertRow(
        session,
        AgentFileCommand(
          operation: operation,
          sourcePath: sourcePath,
          destinationPath: destinationPath,
          newName: newName,
          executedAt: DateTime.now(),
          success: success,
          errorMessage: errorMessage,
          reversible: operation != 'delete', // Only delete is not reversible
          wasUndone: false,
        ),
      );
    } catch (e) {
      // Don't fail the operation if logging fails
      session.log('Failed to log file operation: $e', level: LogLevel.warning);
    }
  }

  /// Sync the file index after a rename or move operation
  /// Updates the path in the index if the old path exists
  Future<void> _syncIndexAfterRename(
    Session session,
    String oldPath,
    String newPath,
  ) async {
    try {
      // Find the file index entry for the old path
      final fileIndex = await FileIndex.db.findFirstRow(
        session,
        where: (t) => t.path.equals(oldPath),
      );

      if (fileIndex != null) {
        // Update the path and file name
        final newFileName = newPath.split(RegExp(r'[/\\]')).last;
        fileIndex.path = newPath;
        fileIndex.fileName = newFileName;
        await FileIndex.db.updateRow(session, fileIndex);
        session.log(
          'Updated index: $oldPath -> $newPath',
          level: LogLevel.info,
        );
      }
    } catch (e) {
      // Don't fail the operation if index sync fails
      session.log(
        'Failed to sync index after rename: $e',
        level: LogLevel.warning,
      );
    }
  }

  /// Safely remove a file from the index after deletion
  Future<void> _removeFromIndexSafe(Session session, String path) async {
    try {
      final butlerEndpoint = ButlerEndpoint();
      final removed = await butlerEndpoint.removeFromIndex(session, path: path);
      if (removed) {
        session.log('Removed from index: $path', level: LogLevel.info);
      }
    } catch (e) {
      // Don't fail the operation if index removal fails
      session.log(
        'Failed to remove from index: $e',
        level: LogLevel.warning,
      );
    }
  }

  // ===========================================================================
  // TERMINAL TOOL IMPLEMENTATIONS
  // ===========================================================================

  /// Tool: Run a shell command
  Future<Map<String, dynamic>> _toolRunCommand(
    String command, {
    String? workingDirectory,
  }) async {
    try {
      final result = await _terminal.execute(
        command,
        workingDirectory: workingDirectory,
      );

      return {
        'success': result.success,
        'command': result.command,
        'output': result.output,
        'exitCode': result.exitCode,
        'truncated': result.truncated,
        'timedOut': result.timedOut,
      };
    } on TerminalSecurityException catch (e) {
      return {
        'success': false,
        'error': 'Security violation: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Command execution failed: $e',
      };
    }
  }

  /// Tool: Search file contents with grep/findstr
  Future<Map<String, dynamic>> _toolGrepSearch(
    String pattern,
    String path, {
    bool recursive = true,
    bool ignoreCase = true,
  }) async {
    try {
      final result = await _terminal.grepSearch(
        pattern,
        path,
        recursive: recursive,
        ignoreCase: ignoreCase,
      );

      return {
        'success': result.success,
        'pattern': pattern,
        'path': path,
        'output': result.output,
        'matchCount': result.stdout
            .split('\n')
            .where((l) => l.isNotEmpty)
            .length,
        'truncated': result.truncated,
      };
    } on TerminalSecurityException catch (e) {
      return {
        'success': false,
        'error': 'Security violation: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Search failed: $e',
      };
    }
  }

  /// Tool: Find files by pattern
  Future<Map<String, dynamic>> _toolFindFiles(
    String pattern, {
    String? directory,
    bool recursive = true,
  }) async {
    try {
      final result = await _terminal.findFiles(
        pattern,
        directory: directory,
        recursive: recursive,
      );

      final files = result.stdout
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      return {
        'success': result.success,
        'pattern': pattern,
        'directory': directory ?? (_terminal.isWindows ? 'C:\\' : '/'),
        'files': files.take(100).toList(), // Limit to 100 results
        'totalCount': files.length,
        'truncated': files.length > 100 || result.truncated,
      };
    } on TerminalSecurityException catch (e) {
      return {
        'success': false,
        'error': 'Security violation: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Find failed: $e',
      };
    }
  }

  /// Tool: Read file contents
  Future<Map<String, dynamic>> _toolReadFileContents(String path) async {
    try {
      final result = await _terminal.readFile(path);

      return {
        'success': result.success,
        'path': path,
        'contents': result.output,
        'truncated': result.truncated,
      };
    } on TerminalSecurityException catch (e) {
      return {
        'success': false,
        'error': 'Security violation: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Read failed: $e',
      };
    }
  }

  /// Tool: Get available drives
  Future<Map<String, dynamic>> _toolGetDrives() async {
    try {
      final drives = await _terminal.listDrives();

      return {
        'success': true,
        'drives': drives.map((d) => d.toJson()).toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to list drives: $e',
      };
    }
  }
}
