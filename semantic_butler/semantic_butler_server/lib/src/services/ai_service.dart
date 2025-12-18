import 'dart:convert';
import '../config/ai_models.dart';
import 'openrouter_client.dart';

/// Unified AI service that provides a simple interface for all AI operations
///
/// Features:
/// - Automatic model selection based on task
/// - Fallback handling
/// - Cost tracking
/// - Structured output support
class AIService {
  final OpenRouterClient _client;

  // Optional: Track usage for cost monitoring
  int _totalInputTokens = 0;
  int _totalOutputTokens = 0;
  double _totalCost = 0.0;

  AIService({required OpenRouterClient client}) : _client = client;

  /// Get usage statistics
  UsageStats get usageStats => UsageStats(
    totalInputTokens: _totalInputTokens,
    totalOutputTokens: _totalOutputTokens,
    totalCost: _totalCost,
  );

  // ==========================================================================
  // EMBEDDINGS
  // ==========================================================================

  /// Generate embedding for a single text
  Future<List<double>> generateEmbedding(
    String text, {
    EmbeddingQuality quality = EmbeddingQuality.fast,
  }) async {
    final model = quality == EmbeddingQuality.fast
        ? AIModels.embeddingGemini
        : AIModels.embeddingOpenAILarge;

    final response = await _client.createEmbeddings(
      model: model,
      input: [_preprocessText(text)],
    );

    _trackUsage(model, response.usage);
    return response.firstEmbedding;
  }

  /// Generate embeddings for multiple texts
  Future<List<List<double>>> generateEmbeddings(
    List<String> texts, {
    EmbeddingQuality quality = EmbeddingQuality.fast,
  }) async {
    final model = quality == EmbeddingQuality.fast
        ? AIModels.embeddingGemini
        : AIModels.embeddingOpenAILarge;

    // Process in batches to avoid rate limits
    final allEmbeddings = <List<double>>[];
    const batchSize = 20;

    for (var i = 0; i < texts.length; i += batchSize) {
      final batch = texts.sublist(
        i,
        i + batchSize > texts.length ? texts.length : i + batchSize,
      );

      final response = await _client.createEmbeddings(
        model: model,
        input: batch.map(_preprocessText).toList(),
      );

      _trackUsage(model, response.usage);
      allEmbeddings.addAll(response.embeddings);
    }

    return allEmbeddings;
  }

  /// Get embedding dimensions for the current model
  int getEmbeddingDimensions({
    EmbeddingQuality quality = EmbeddingQuality.fast,
  }) {
    final model = quality == EmbeddingQuality.fast
        ? AIModels.embeddingGemini
        : AIModels.embeddingOpenAILarge;
    return AIModels.embeddingDimensions[model] ?? 768;
  }

  // ==========================================================================
  // CHAT COMPLETIONS
  // ==========================================================================

  /// Simple chat completion
  Future<String> chat({
    required String prompt,
    String? systemPrompt,
    TaskComplexity complexity = TaskComplexity.simple,
    String? forceModel,
    double? temperature,
    int? maxTokens,
  }) async {
    final model = forceModel ?? AIModels.getModelForTask(complexity);

    final messages = <ChatMessage>[
      if (systemPrompt != null) ChatMessage.system(systemPrompt),
      ChatMessage.user(prompt),
    ];

    final response = await _client.chatCompletion(
      model: model,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    _trackUsage(model, response.usage);
    return response.content;
  }

  /// Generate structured JSON output
  Future<Map<String, dynamic>> generateStructured({
    required String prompt,
    required String systemPrompt,
    TaskComplexity complexity = TaskComplexity.moderate,
    String? forceModel,
  }) async {
    final model = forceModel ?? AIModels.getModelForTask(complexity);

    final messages = <ChatMessage>[
      ChatMessage.system(
        '$systemPrompt\n\nIMPORTANT: Respond with valid JSON only. No markdown, no explanation.',
      ),
      ChatMessage.user(prompt),
    ];

    final response = await _client.chatCompletion(
      model: model,
      messages: messages,
      temperature: 0.3, // Lower temperature for structured output
    );

    _trackUsage(model, response.usage);

    // Parse JSON, handling potential markdown wrapping
    String jsonStr = response.content.trim();

    // Remove markdown code blocks if present
    if (jsonStr.startsWith('```')) {
      final start = jsonStr.indexOf('{');
      final end = jsonStr.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        jsonStr = jsonStr.substring(start, end + 1);
      }
    }

    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  /// Chat with tool/function calling support
  Future<ChatCompletionResponse> chatWithTools({
    required List<ChatMessage> messages,
    required List<Tool> tools,
    TaskComplexity complexity = TaskComplexity.complex,
    String? forceModel,
  }) async {
    final model = forceModel ?? AIModels.agentDefault;

    final response = await _client.chatCompletion(
      model: model,
      messages: messages,
      tools: tools,
    );

    _trackUsage(model, response.usage);
    return response;
  }

  // ==========================================================================
  // SPECIALIZED TASKS
  // ==========================================================================

  /// Generate tags for a document
  Future<DocumentTags> generateTags(String content, {String? fileName}) async {
    final systemPrompt = '''
You are a document analyzer. Extract structured metadata from documents.
Always respond with valid JSON matching this exact schema:
{
  "primary_topic": "string (1-3 words describing main subject)",
  "document_type": "string (one of: Code, Documentation, Notes, Report, Config, Script, Other)",
  "keywords": ["keyword1", "keyword2", "keyword3"],
  "entities": ["named entities like people, companies, projects, technologies"],
  "language": "programming language if code, or 'natural' for text documents",
  "confidence": 0.0 to 1.0
}
''';

    final prompt =
        '''
Analyze this document and extract metadata tags:
${fileName != null ? 'Filename: $fileName\n' : ''}

Content:
${content.length > 6000 ? content.substring(0, 6000) : content}
''';

    try {
      final result = await generateStructured(
        prompt: prompt,
        systemPrompt: systemPrompt,
        complexity: TaskComplexity.trivial, // Use fast model for tagging
      );

      return DocumentTags.fromMap(result);
    } catch (e) {
      return DocumentTags.unknown();
    }
  }

  /// Generate a summary of document content
  Future<String> summarize(
    String content, {
    int maxWords = 200,
    String? focusArea,
  }) async {
    final prompt =
        '''
Summarize the following document in approximately $maxWords words.
${focusArea != null ? 'Focus on: $focusArea\n' : ''}
Be concise and capture the key points.

Document:
${content.length > 10000 ? content.substring(0, 10000) : content}
''';

    return await chat(
      prompt: prompt,
      complexity: TaskComplexity.moderate,
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  /// Preprocess text before embedding
  String _preprocessText(String text) {
    // Remove excessive whitespace
    var processed = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Truncate if too long (8191 tokens ≈ 32000 chars for safety)
    const maxChars = 30000;
    if (processed.length > maxChars) {
      processed = processed.substring(0, maxChars);
    }

    return processed;
  }

  /// Track usage for cost monitoring
  void _trackUsage(String model, Usage? usage) {
    if (usage == null) return;

    _totalInputTokens += usage.promptTokens;
    _totalOutputTokens += usage.completionTokens;
    _totalCost += AIModels.estimateCost(
      model,
      usage.promptTokens,
      usage.completionTokens,
    );
  }

  /// Reset usage tracking
  void resetUsageStats() {
    _totalInputTokens = 0;
    _totalOutputTokens = 0;
    _totalCost = 0.0;
  }
}

/// Embedding quality levels
enum EmbeddingQuality {
  /// Fast model (1536 dimensions, cheaper)
  fast,

  /// High quality model (3072 dimensions, more expensive)
  quality,
}

/// Usage statistics for cost monitoring
class UsageStats {
  final int totalInputTokens;
  final int totalOutputTokens;
  final double totalCost;

  UsageStats({
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalCost,
  });

  int get totalTokens => totalInputTokens + totalOutputTokens;
}

/// Structured document tags
class DocumentTags {
  final String primaryTopic;
  final String documentType;
  final List<String> keywords;
  final List<String> entities;
  final String? language;
  final double confidence;

  DocumentTags({
    required this.primaryTopic,
    required this.documentType,
    required this.keywords,
    required this.entities,
    this.language,
    required this.confidence,
  });

  factory DocumentTags.fromMap(Map<String, dynamic> map) {
    return DocumentTags(
      primaryTopic: map['primary_topic'] as String? ?? 'Unknown',
      documentType: map['document_type'] as String? ?? 'Document',
      keywords: _parseStringList(map['keywords']),
      entities: _parseStringList(map['entities']),
      language: map['language'] as String?,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.5,
    );
  }

  factory DocumentTags.unknown() {
    return DocumentTags(
      primaryTopic: 'Unknown',
      documentType: 'Document',
      keywords: [],
      entities: [],
      confidence: 0.0,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  /// Convert to a flat list of tag strings for display
  List<String> toTagList() {
    final tags = <String>[primaryTopic, documentType];
    tags.addAll(keywords.take(3));
    tags.addAll(entities.take(2));
    if (language != null && language != 'natural') {
      tags.add(language!);
    }
    return tags.where((t) => t.isNotEmpty).toSet().toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'primary_topic': primaryTopic,
      'document_type': documentType,
      'keywords': keywords,
      'entities': entities,
      'language': language,
      'confidence': confidence,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory DocumentTags.fromJson(String json) {
    return DocumentTags.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }
}
