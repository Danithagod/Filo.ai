/// AI model configurations for different tasks
///
/// OpenRouter provides access to 200+ models. This configuration
/// defines defaults and routing strategies for optimal cost/quality.
class AIModels {
  // ==========================================================================
  // EMBEDDING MODELS
  // ==========================================================================

  /// Fast, cost-effective embedding model (1536 dimensions)
  /// Cost: ~$0.02 per 1M tokens
  static const String embeddingFast = 'openai/text-embedding-3-small';

  /// High-quality embedding model (3072 dimensions)
  /// Cost: ~$0.13 per 1M tokens
  static const String embeddingQuality = 'openai/text-embedding-3-large';

  /// Default embedding model
  static const String embeddingDefault = embeddingFast;

  /// Embedding dimensions by model
  static const Map<String, int> embeddingDimensions = {
    'openai/text-embedding-3-small': 1536,
    'openai/text-embedding-3-large': 3072,
    'openai/text-embedding-ada-002': 1536,
  };

  // ==========================================================================
  // CHAT MODELS - Fast (Simple Tasks)
  // ==========================================================================

  /// Google Gemini 2.5 Flash - Very fast, very cheap
  /// Best for: Tag generation, simple classification
  /// Cost: ~$0.15 per 1M input tokens
  static const String chatGeminiFlash = 'google/gemini-2.5-flash';

  /// GPT-4o Mini - Fast and capable
  /// Best for: Structured output, simple reasoning
  /// Cost: ~$0.15 per 1M input tokens
  static const String chatGpt4oMini = 'openai/gpt-4o-mini';

  /// Claude 3 Haiku - Fast, good quality
  /// Best for: Quick responses, balanced tasks
  /// Cost: ~$0.25 per 1M input tokens
  static const String chatClaudeHaiku = 'anthropic/claude-3-haiku';

  // ==========================================================================
  // CHAT MODELS - Quality (Complex Tasks)
  // ==========================================================================

  /// Claude 3.5 Sonnet - Best overall quality/cost balance
  /// Best for: Complex reasoning, long context, coding
  /// Cost: ~$3.00 per 1M input tokens
  static const String chatClaudeSonnet = 'anthropic/claude-3.5-sonnet';

  /// GPT-4o - Premium OpenAI model
  /// Best for: Highest quality, complex analysis
  /// Cost: ~$2.50 per 1M input tokens
  static const String chatGpt4o = 'openai/gpt-4o';

  /// Claude 3 Opus - Most capable Claude
  /// Best for: Critical tasks, nuanced reasoning
  /// Cost: ~$15.00 per 1M input tokens
  static const String chatClaudeOpus = 'anthropic/claude-3-opus';

  // ==========================================================================
  // AGENT MODELS (Tool Use Optimized)
  // ==========================================================================

  /// Default agent model - Claude 3.5 Sonnet
  /// Excellent tool use, reasoning, and instruction following
  static const String agentDefault = chatClaudeSonnet;

  /// Alternative agent model
  static const String agentAlternative = chatGpt4o;

  // ==========================================================================
  // OPEN SOURCE MODELS (Lower Cost)
  // ==========================================================================

  /// Llama 3.1 70B - Strong open source
  /// Cost: ~$0.59 per 1M input tokens
  static const String chatLlama70b = 'meta-llama/llama-3.1-70b-instruct';

  /// Mixtral 8x7B - Fast open source
  /// Cost: ~$0.24 per 1M input tokens
  static const String chatMixtral = 'mistralai/mixtral-8x7b-instruct';

  /// Qwen 72B - Strong multilingual
  /// Cost: ~$0.35 per 1M input tokens
  static const String chatQwen72b = 'qwen/qwen-2-72b-instruct';

  // ==========================================================================
  // MODEL ROUTING
  // ==========================================================================

  /// Get recommended model based on task complexity
  static String getModelForTask(TaskComplexity complexity) {
    switch (complexity) {
      case TaskComplexity.trivial:
        return chatGeminiFlash;
      case TaskComplexity.simple:
        return chatGpt4oMini;
      case TaskComplexity.moderate:
        return chatClaudeHaiku;
      case TaskComplexity.complex:
        return chatClaudeSonnet;
      case TaskComplexity.critical:
        return chatGpt4o;
    }
  }

  /// Get model for specific task type
  static String getModelForTaskType(TaskType type) {
    switch (type) {
      case TaskType.tagGeneration:
        return chatGeminiFlash; // Fast, cheap, good at classification
      case TaskType.summarization:
        return chatClaudeHaiku; // Good at synthesis
      case TaskType.structuredOutput:
        return chatGpt4oMini; // Reliable JSON output
      case TaskType.agentReasoning:
        return chatClaudeSonnet; // Best tool use
      case TaskType.codeAnalysis:
        return chatClaudeSonnet; // Strong at code
      case TaskType.longContext:
        return chatClaudeSonnet; // 200K context
    }
  }

  // ==========================================================================
  // COST INFORMATION
  // ==========================================================================

  /// Cost per 1M tokens (input, output) in USD
  static const Map<String, ModelCost> costs = {
    chatGeminiFlash: ModelCost(input: 0.075, output: 0.30),
    chatGpt4oMini: ModelCost(input: 0.15, output: 0.60),
    chatClaudeHaiku: ModelCost(input: 0.25, output: 1.25),
    chatClaudeSonnet: ModelCost(input: 3.00, output: 15.00),
    chatGpt4o: ModelCost(input: 2.50, output: 10.00),
    chatClaudeOpus: ModelCost(input: 15.00, output: 75.00),
    chatLlama70b: ModelCost(input: 0.59, output: 0.79),
    chatMixtral: ModelCost(input: 0.24, output: 0.24),
    embeddingFast: ModelCost(input: 0.02, output: 0.0),
    embeddingQuality: ModelCost(input: 0.13, output: 0.0),
  };

  /// Estimate cost for a request
  static double estimateCost(String model, int inputTokens, int outputTokens) {
    final cost = costs[model];
    if (cost == null) return 0.0;

    return (inputTokens / 1000000 * cost.input) +
        (outputTokens / 1000000 * cost.output);
  }
}

/// Task complexity levels for model routing
enum TaskComplexity {
  /// Very simple, pattern matching (use cheapest)
  trivial,

  /// Simple classification, short output
  simple,

  /// Moderate reasoning required
  moderate,

  /// Complex multi-step reasoning
  complex,

  /// Mission-critical, needs best model
  critical,
}

/// Task types for specialized model selection
enum TaskType {
  /// Generating tags/labels for documents
  tagGeneration,

  /// Summarizing document content
  summarization,

  /// Generating structured JSON output
  structuredOutput,

  /// Multi-step agent reasoning with tools
  agentReasoning,

  /// Analyzing code files
  codeAnalysis,

  /// Processing very long documents
  longContext,
}

/// Model cost per 1M tokens
class ModelCost {
  final double input;
  final double output;

  const ModelCost({required this.input, required this.output});

  /// Calculate cost for given token counts
  double calculate(int inputTokens, int outputTokens) {
    return (inputTokens / 1000000 * input) + (outputTokens / 1000000 * output);
  }
}

/// Model capabilities information
class ModelCapabilities {
  final bool supportsTools;
  final bool supportsVision;
  final bool supportsStreaming;
  final int maxContextLength;
  final int maxOutputTokens;

  const ModelCapabilities({
    required this.supportsTools,
    required this.supportsVision,
    required this.supportsStreaming,
    required this.maxContextLength,
    required this.maxOutputTokens,
  });

  static const Map<String, ModelCapabilities> capabilities = {
    AIModels.chatClaudeSonnet: ModelCapabilities(
      supportsTools: true,
      supportsVision: true,
      supportsStreaming: true,
      maxContextLength: 200000,
      maxOutputTokens: 8192,
    ),
    AIModels.chatGpt4o: ModelCapabilities(
      supportsTools: true,
      supportsVision: true,
      supportsStreaming: true,
      maxContextLength: 128000,
      maxOutputTokens: 16384,
    ),
    AIModels.chatGeminiFlash: ModelCapabilities(
      supportsTools: true,
      supportsVision: true,
      supportsStreaming: true,
      maxContextLength: 1000000,
      maxOutputTokens: 8192,
    ),
  };
}
