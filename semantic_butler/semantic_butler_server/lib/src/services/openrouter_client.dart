import 'dart:convert';
import 'package:http/http.dart' as http;

/// OpenRouter API client for unified access to multiple AI providers
///
/// Supports:
/// - Chat completions (GPT-4, Claude, Gemini, Llama, etc.)
/// - Embeddings (text-embedding-3-small/large)
/// - Tool/Function calling
/// - Streaming responses
class OpenRouterClient {
  static const String baseUrl = 'https://openrouter.ai/api/v1';

  final String apiKey;
  final String siteUrl;
  final String siteName;
  final http.Client _httpClient;

  OpenRouterClient({
    required this.apiKey,
    this.siteUrl = 'https://semantic-butler.app',
    this.siteName = 'Semantic Desktop Butler',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
    'HTTP-Referer': siteUrl,
    'X-Title': siteName,
  };

  /// Chat completion with any supported model
  ///
  /// [model] - OpenRouter model ID (e.g., 'anthropic/claude-3.5-sonnet')
  /// [messages] - List of conversation messages
  /// [tools] - Optional list of tools for function calling
  /// [temperature] - Sampling temperature (0.0 to 2.0)
  /// [maxTokens] - Maximum tokens in response
  Future<ChatCompletionResponse> chatCompletion({
    required String model,
    required List<ChatMessage> messages,
    List<Tool>? tools,
    double? temperature,
    int? maxTokens,
    bool? stream,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
    };

    if (tools != null && tools.isNotEmpty) {
      body['tools'] = tools.map((t) => t.toJson()).toList();
    }
    if (temperature != null) body['temperature'] = temperature;
    if (maxTokens != null) body['max_tokens'] = maxTokens;
    if (stream != null) body['stream'] = stream;

    final response = await _httpClient
        .post(
          Uri.parse('$baseUrl/chat/completions'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw OpenRouterException(
            'Chat completion timed out after 60 seconds',
            statusCode: 408,
          ),
        );

    if (response.statusCode != 200) {
      throw OpenRouterException(
        'Chat completion failed',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return ChatCompletionResponse.fromJson(jsonDecode(response.body));
  }

  /// Streaming chat completion with token-by-token responses
  ///
  /// Yields [StreamChatChunk] events as they arrive from the API.
  /// Uses Server-Sent Events (SSE) format.
  Stream<StreamChatChunk> streamChatCompletion({
    required String model,
    required List<ChatMessage> messages,
    List<Tool>? tools,
    double? temperature,
    int? maxTokens,
  }) async* {
    final body = <String, dynamic>{
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': true,
    };

    if (tools != null && tools.isNotEmpty) {
      body['tools'] = tools.map((t) => t.toJson()).toList();
    }
    if (temperature != null) body['temperature'] = temperature;
    if (maxTokens != null) body['max_tokens'] = maxTokens;

    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/chat/completions'),
    );
    request.headers.addAll(_headers);
    request.body = jsonEncode(body);

    final streamedResponse = await _httpClient
        .send(request)
        .timeout(
          const Duration(seconds: 120),
          onTimeout: () => throw OpenRouterException(
            'Streaming chat timed out after 120 seconds',
            statusCode: 408,
          ),
        );

    if (streamedResponse.statusCode != 200) {
      final body = await streamedResponse.stream.bytesToString();
      throw OpenRouterException(
        'Streaming chat failed',
        statusCode: streamedResponse.statusCode,
        body: body,
      );
    }

    // Buffer for incomplete SSE lines
    String buffer = '';

    await for (final bytes in streamedResponse.stream) {
      buffer += utf8.decode(bytes);

      // Process complete lines
      while (buffer.contains('\n')) {
        final newlineIndex = buffer.indexOf('\n');
        final line = buffer.substring(0, newlineIndex).trim();
        buffer = buffer.substring(newlineIndex + 1);

        if (line.isEmpty) continue;
        if (!line.startsWith('data: ')) continue;

        final data = line.substring(6); // Remove 'data: ' prefix
        if (data == '[DONE]') {
          yield StreamChatChunk.done();
          return;
        }

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final chunk = StreamChatChunk.fromJson(json);
          yield chunk;
        } catch (e) {
          // Skip malformed chunks
          continue;
        }
      }
    }
  }

  /// Generate text embeddings
  ///
  /// [model] - Embedding model (e.g., 'openai/text-embedding-3-small')
  /// [input] - List of texts to embed
  Future<EmbeddingResponse> createEmbeddings({
    required String model,
    required List<String> input,
  }) async {
    final response = await _httpClient
        .post(
          Uri.parse('$baseUrl/embeddings'),
          headers: _headers,
          body: jsonEncode({
            'model': model,
            'input': input,
          }),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw OpenRouterException(
            'Embeddings timed out after 30 seconds',
            statusCode: 408,
          ),
        );

    if (response.statusCode != 200) {
      throw OpenRouterException(
        'Embeddings failed',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return EmbeddingResponse.fromJson(jsonDecode(response.body));
  }

  /// Get list of available models
  Future<List<ModelInfo>> getModels() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/models'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw OpenRouterException(
        'Get models failed',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final json = jsonDecode(response.body);
    final data = json['data'] as List<dynamic>;
    return data.map((m) => ModelInfo.fromJson(m)).toList();
  }

  /// Get available embedding models
  Future<List<ModelInfo>> getEmbeddingModels() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/embeddings/models'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw OpenRouterException(
        'Get embedding models failed',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final json = jsonDecode(response.body);
    final data = json['data'] as List<dynamic>;
    return data.map((m) => ModelInfo.fromJson(m)).toList();
  }

  void dispose() {
    _httpClient.close();
  }
}

// =============================================================================
// DATA MODELS
// =============================================================================

/// Chat message for conversation
class ChatMessage {
  final String role; // 'system', 'user', 'assistant', 'tool'
  final String content;
  final String? name;
  final List<ToolCall>? toolCalls;
  final String? toolCallId;

  ChatMessage({
    required this.role,
    required this.content,
    this.name,
    this.toolCalls,
    this.toolCallId,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'role': role,
      'content': content,
    };
    if (name != null) json['name'] = name;
    if (toolCalls != null) {
      json['tool_calls'] = toolCalls!.map((t) => t.toJson()).toList();
    }
    if (toolCallId != null) json['tool_call_id'] = toolCallId;
    return json;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String? ?? '',
      name: json['name'] as String?,
      toolCalls: json['tool_calls'] != null
          ? (json['tool_calls'] as List)
                .map((t) => ToolCall.fromJson(t))
                .toList()
          : null,
      toolCallId: json['tool_call_id'] as String?,
    );
  }

  // Convenience constructors
  factory ChatMessage.system(String content) =>
      ChatMessage(role: 'system', content: content);

  factory ChatMessage.user(String content) =>
      ChatMessage(role: 'user', content: content);

  factory ChatMessage.assistant(String content, {List<ToolCall>? toolCalls}) =>
      ChatMessage(role: 'assistant', content: content, toolCalls: toolCalls);

  factory ChatMessage.tool(String content, String toolCallId) =>
      ChatMessage(role: 'tool', content: content, toolCallId: toolCallId);
}

/// Tool definition for function calling
class Tool {
  final String type;
  final ToolFunction function;

  Tool({
    this.type = 'function',
    required this.function,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'function': function.toJson(),
  };
}

/// Function definition within a tool
class ToolFunction {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  ToolFunction({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'parameters': parameters,
  };
}

/// Tool call made by the model
class ToolCall {
  final String id;
  final String type;
  final ToolCallFunction function;

  ToolCall({
    required this.id,
    this.type = 'function',
    required this.function,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'function': function.toJson(),
  };

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'function',
      function: ToolCallFunction.fromJson(json['function']),
    );
  }
}

/// Function call details
class ToolCallFunction {
  final String name;
  final String arguments;

  ToolCallFunction({
    required this.name,
    required this.arguments,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'arguments': arguments,
  };

  factory ToolCallFunction.fromJson(Map<String, dynamic> json) {
    return ToolCallFunction(
      name: json['name'] as String,
      arguments: json['arguments'] as String,
    );
  }

  /// Parse arguments as JSON
  Map<String, dynamic> get parsedArguments => jsonDecode(arguments);
}

/// Chat completion response
class ChatCompletionResponse {
  final String id;
  final String model;
  final List<Choice> choices;
  final Usage? usage;

  ChatCompletionResponse({
    required this.id,
    required this.model,
    required this.choices,
    this.usage,
  });

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    return ChatCompletionResponse(
      id: json['id'] as String,
      model: json['model'] as String,
      choices: (json['choices'] as List)
          .map((c) => Choice.fromJson(c))
          .toList(),
      usage: json['usage'] != null ? Usage.fromJson(json['usage']) : null,
    );
  }

  /// Get the first choice's message content
  String get content => choices.first.message.content;

  /// Check if the model wants to call tools
  bool get hasToolCalls =>
      choices.isNotEmpty &&
      choices.first.message.toolCalls != null &&
      choices.first.message.toolCalls!.isNotEmpty;

  /// Get tool calls from the first choice
  List<ToolCall> get toolCalls => choices.first.message.toolCalls ?? [];
}

/// Choice in completion response
class Choice {
  final int index;
  final ChatMessage message;
  final String? finishReason;

  Choice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      index: json['index'] as int,
      message: ChatMessage.fromJson(json['message']),
      finishReason: json['finish_reason'] as String?,
    );
  }
}

/// Token usage statistics
class Usage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  Usage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      promptTokens: (json['prompt_tokens'] as int?) ?? 0,
      completionTokens: (json['completion_tokens'] as int?) ?? 0,
      totalTokens: (json['total_tokens'] as int?) ?? 0,
    );
  }
}

/// Embedding response
class EmbeddingResponse {
  final String model;
  final List<EmbeddingData> data;
  final Usage? usage;

  EmbeddingResponse({
    required this.model,
    required this.data,
    this.usage,
  });

  factory EmbeddingResponse.fromJson(Map<String, dynamic> json) {
    return EmbeddingResponse(
      model: json['model'] as String,
      data: (json['data'] as List)
          .map((d) => EmbeddingData.fromJson(d))
          .toList(),
      usage: json['usage'] != null ? Usage.fromJson(json['usage']) : null,
    );
  }

  /// Get the first embedding vector
  List<double> get firstEmbedding => data.first.embedding;

  /// Get all embedding vectors
  List<List<double>> get embeddings => data.map((d) => d.embedding).toList();
}

/// Single embedding result
class EmbeddingData {
  final int index;
  final List<double> embedding;

  EmbeddingData({
    required this.index,
    required this.embedding,
  });

  factory EmbeddingData.fromJson(Map<String, dynamic> json) {
    return EmbeddingData(
      index: (json['index'] as int?) ?? 0,
      embedding: (json['embedding'] as List)
          .cast<num>()
          .map((n) => n.toDouble())
          .toList(),
    );
  }
}

/// Model information
class ModelInfo {
  final String id;
  final String name;
  final String? description;
  final int? contextLength;
  final ModelPricing? pricing;

  ModelInfo({
    required this.id,
    required this.name,
    this.description,
    this.contextLength,
    this.pricing,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      description: json['description'] as String?,
      contextLength: json['context_length'] as int?,
      pricing: json['pricing'] != null
          ? ModelPricing.fromJson(json['pricing'])
          : null,
    );
  }
}

/// Model pricing information
class ModelPricing {
  final double prompt;
  final double completion;

  ModelPricing({
    required this.prompt,
    required this.completion,
  });

  factory ModelPricing.fromJson(Map<String, dynamic> json) {
    return ModelPricing(
      prompt: double.tryParse(json['prompt'].toString()) ?? 0.0,
      completion: double.tryParse(json['completion'].toString()) ?? 0.0,
    );
  }
}

/// OpenRouter API exception
class OpenRouterException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  OpenRouterException(this.message, {this.statusCode, this.body});

  @override
  String toString() {
    final parts = ['OpenRouterException: $message'];
    if (statusCode != null) parts.add('Status: $statusCode');
    if (body != null) parts.add('Body: $body');
    return parts.join('\n');
  }
}

/// Streaming chat chunk from SSE response
class StreamChatChunk {
  final String? id;
  final String? model;
  final List<StreamChoice>? choices;
  final bool isDone;

  StreamChatChunk({
    this.id,
    this.model,
    this.choices,
    this.isDone = false,
  });

  factory StreamChatChunk.done() => StreamChatChunk(isDone: true);

  factory StreamChatChunk.fromJson(Map<String, dynamic> json) {
    return StreamChatChunk(
      id: json['id'] as String?,
      model: json['model'] as String?,
      choices: (json['choices'] as List<dynamic>?)
          ?.map((c) => StreamChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get delta content from first choice
  String? get deltaContent => choices?.firstOrNull?.delta?.content;

  /// Get tool calls from first choice
  List<ToolCall>? get toolCalls => choices?.firstOrNull?.delta?.toolCalls;

  /// Check if this chunk has tool calls
  bool get hasToolCalls => toolCalls != null && toolCalls!.isNotEmpty;

  /// Get finish reason
  String? get finishReason => choices?.firstOrNull?.finishReason;
}

/// Choice in streaming response
class StreamChoice {
  final int? index;
  final StreamDelta? delta;
  final String? finishReason;

  StreamChoice({
    this.index,
    this.delta,
    this.finishReason,
  });

  factory StreamChoice.fromJson(Map<String, dynamic> json) {
    return StreamChoice(
      index: json['index'] as int?,
      delta: json['delta'] != null
          ? StreamDelta.fromJson(json['delta'] as Map<String, dynamic>)
          : null,
      finishReason: json['finish_reason'] as String?,
    );
  }
}

/// Delta content in streaming response
class StreamDelta {
  final String? role;
  final String? content;
  final List<ToolCall>? toolCalls;

  StreamDelta({
    this.role,
    this.content,
    this.toolCalls,
  });

  factory StreamDelta.fromJson(Map<String, dynamic> json) {
    return StreamDelta(
      role: json['role'] as String?,
      content: json['content'] as String?,
      toolCalls: json['tool_calls'] != null
          ? (json['tool_calls'] as List<dynamic>)
                .map((t) => ToolCall.fromJson(t as Map<String, dynamic>))
                .toList()
          : null,
    );
  }
}
