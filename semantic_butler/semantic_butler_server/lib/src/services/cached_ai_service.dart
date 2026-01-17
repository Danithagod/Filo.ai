// Cached AI service wrapper
import '../config/ai_models.dart';
import 'ai_service.dart';
import 'cache_service.dart';
import 'metrics_service.dart';
import 'circuit_breaker.dart';
import 'openrouter_client.dart';

/// Cached AI service that wraps AIService with caching, metrics, and circuit breaker
///
/// Reduces API calls by caching:
/// - Embeddings (keyed by text hash)
/// - Summaries (keyed by content hash + max words)
/// - Tags (keyed by content hash)
///
/// Uses circuit breaker to prevent cascading failures when AI API is down.
class CachedAIService {
  final AIService _aiService;
  final CacheService _cache = CacheService.instance;
  final MetricsService _metrics = MetricsService.instance;
  final CircuitBreaker _circuitBreaker;

  CachedAIService({required OpenRouterClient client})
    : _aiService = AIService(client: client),
      _circuitBreaker = CircuitBreakerRegistry.instance.getBreaker(
        'openrouter_ai',
        failureThreshold: 5,
        resetTimeout: const Duration(minutes: 2),
      );

  /// Get underlying AI service for non-cached operations
  AIService get aiService => _aiService;

  /// Get usage statistics
  UsageStats get usageStats => _aiService.usageStats;

  // ==========================================================================
  // CACHED EMBEDDINGS
  // ==========================================================================

  /// Generate embedding with caching and circuit breaker
  Future<List<double>> generateEmbedding(
    String text, {
    EmbeddingQuality quality = EmbeddingQuality.fast,
  }) async {
    final cacheKey = CacheService.embeddingKey(text);

    // Check cache first
    final cached = _cache.get<List<double>>(cacheKey);
    if (cached != null) {
      _metrics.incrementCacheHit();
      return cached;
    }

    _metrics.incrementCacheMiss();

    // Generate embedding with circuit breaker protection
    final stopwatch = Stopwatch()..start();
    final embedding = await _circuitBreaker.execute(
      () => _aiService.generateEmbedding(
        text,
        quality: quality,
      ),
    );
    stopwatch.stop();

    _metrics.recordEmbeddingLatency(stopwatch.elapsed);

    // Cache the result
    _cache.set(cacheKey, embedding);

    return embedding;
  }

  /// Generate embeddings with caching (checks individual entries)
  Future<List<List<double>>> generateEmbeddings(
    List<String> texts, {
    EmbeddingQuality quality = EmbeddingQuality.fast,
  }) async {
    final results = <List<double>>[];
    final uncachedTexts = <String>[];
    final uncachedIndices = <int>[];

    // Check cache for each text
    for (var i = 0; i < texts.length; i++) {
      final cacheKey = CacheService.embeddingKey(texts[i]);
      final cached = _cache.get<List<double>>(cacheKey);

      if (cached != null) {
        _metrics.incrementCacheHit();
        results.add(cached);
      } else {
        _metrics.incrementCacheMiss();
        uncachedTexts.add(texts[i]);
        uncachedIndices.add(i);
        results.add([]); // Placeholder
      }
    }

    // Generate uncached embeddings in batch
    if (uncachedTexts.isNotEmpty) {
      final stopwatch = Stopwatch()..start();
      final newEmbeddings = await _aiService.generateEmbeddings(
        uncachedTexts,
        quality: quality,
      );
      stopwatch.stop();

      _metrics.recordEmbeddingLatency(stopwatch.elapsed);

      // Fill in results and cache
      for (var i = 0; i < uncachedIndices.length; i++) {
        final originalIndex = uncachedIndices[i];
        results[originalIndex] = newEmbeddings[i];

        // Cache each individually
        final cacheKey = CacheService.embeddingKey(uncachedTexts[i]);
        _cache.set(cacheKey, newEmbeddings[i]);
      }
    }

    return results;
  }

  /// Get embedding dimensions (no caching needed - static)
  int getEmbeddingDimensions({
    EmbeddingQuality quality = EmbeddingQuality.fast,
  }) {
    return _aiService.getEmbeddingDimensions(quality: quality);
  }

  // ==========================================================================
  // CACHED SUMMARIES
  // ==========================================================================

  /// Generate summary with caching
  Future<String> summarize(
    String content, {
    int maxWords = 200,
    String? focusArea,
    String? contentHash,
  }) async {
    // Use content hash if provided, otherwise compute from content
    final hash = contentHash ?? content.hashCode.toString();
    final cacheKey = CacheService.summaryKey(hash, maxWords);

    // Check cache first
    final cached = _cache.get<String>(cacheKey);
    if (cached != null) {
      _metrics.incrementCacheHit();
      return cached;
    }

    _metrics.incrementCacheMiss();

    // Generate summary
    final summary = await _aiService.summarize(
      content,
      maxWords: maxWords,
      focusArea: focusArea,
    );

    // Cache the result
    _cache.set(cacheKey, summary);

    return summary;
  }

  // ==========================================================================
  // CACHED TAGS
  // ==========================================================================

  /// Generate tags with caching
  Future<DocumentTags> generateTags(
    String content, {
    String? fileName,
    String? contentHash,
  }) async {
    // Use content hash if provided, otherwise compute from content
    final hash = contentHash ?? content.hashCode.toString();
    final cacheKey = CacheService.tagsKey(hash);

    // Check cache first
    final cached = _cache.get<String>(cacheKey);
    if (cached != null) {
      _metrics.incrementCacheHit();
      return DocumentTags.fromJson(cached);
    }

    _metrics.incrementCacheMiss();

    // Generate tags
    final tags = await _aiService.generateTags(content, fileName: fileName);

    // Cache the result (as JSON string for serialization)
    _cache.set(cacheKey, tags.toJson());

    return tags;
  }

  // ==========================================================================
  // NON-CACHED OPERATIONS (pass-through)
  // ==========================================================================

  /// Chat completion (not cached - unique responses)
  Future<String> chat({
    required String prompt,
    String? systemPrompt,
    TaskComplexity complexity = TaskComplexity.simple,
    String? forceModel,
    double? temperature,
    int? maxTokens,
  }) async {
    return _aiService.chat(
      prompt: prompt,
      systemPrompt: systemPrompt,
      complexity: complexity,
      forceModel: forceModel,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  /// Structured JSON generation (not cached)
  Future<Map<String, dynamic>> generateStructured({
    required String prompt,
    required String systemPrompt,
    TaskComplexity complexity = TaskComplexity.moderate,
    String? forceModel,
  }) async {
    return _aiService.generateStructured(
      prompt: prompt,
      systemPrompt: systemPrompt,
      complexity: complexity,
      forceModel: forceModel,
    );
  }

  /// Chat with tools (not cached)
  Future<ChatCompletionResponse> chatWithTools({
    required List<ChatMessage> messages,
    required List<Tool> tools,
    TaskComplexity complexity = TaskComplexity.complex,
    String? forceModel,
  }) async {
    return _aiService.chatWithTools(
      messages: messages,
      tools: tools,
      complexity: complexity,
      forceModel: forceModel,
    );
  }

  /// Reset usage statistics
  void resetUsageStats() {
    _aiService.resetUsageStats();
  }

  /// Get cache statistics
  CacheStats get cacheStats => _cache.stats;

  /// Clear the cache
  void clearCache() {
    _cache.clear();
  }
}
