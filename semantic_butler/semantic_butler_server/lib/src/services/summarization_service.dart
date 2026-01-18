import 'package:serverpod/serverpod.dart';

import 'openrouter_client.dart';

/// Service for generating hierarchical document summaries
///
/// Reduces token usage by:
/// - Creating multi-level summaries (detailed, medium, brief)
/// - Using smaller models for summarization
/// - Embedding summaries instead of full content
/// - Maintaining semantic search quality
class SummarizationService {
  static const int chunkSize = 4000; // Characters per chunk
  static const int maxChunks = 10; // Maximum chunks to process

  /// Generate hierarchical summary for a document
  static Future<DocumentSummary> generateSummary(
    Session session,
    String content,
    OpenRouterClient client, {
    String? fileName,
  }) async {
    // Skip summarization for short documents
    if (content.length < 1000) {
      return DocumentSummary(
        briefSummary: content.substring(0, content.length.clamp(0, 500)),
        mediumSummary: content.substring(0, content.length.clamp(0, 1000)),
        detailedSummary: content,
        originalLength: content.length,
        compressionRatio: 1.0,
        chunkCount: 1,
      );
    }

    try {
      // Split content into chunks
      final chunks = _splitIntoChunks(content, chunkSize);
      final processedChunks = chunks.take(maxChunks).toList();

      // Generate summaries for each chunk in parallel
      final chunkSummaries = await Future.wait(
        processedChunks.map((chunk) => _summarizeChunk(session, chunk, client)),
      );

      // Combine chunk summaries
      final combinedSummary = chunkSummaries.join('\n\n');
      final isTruncated = chunks.length > maxChunks;

      // Generate different levels of summary
      final detailed = await _generateDetailedSummary(
        session,
        combinedSummary,
        client,
        fileName: fileName,
      );

      final medium = await _generateMediumSummary(
        session,
        detailed,
        client,
      );

      final brief = await _generateBriefSummary(
        session,
        medium,
        client,
      );

      final compressionRatio = detailed.length / content.length;

      return DocumentSummary(
        briefSummary: brief,
        mediumSummary: medium,
        detailedSummary: detailed,
        originalLength: content.length,
        compressionRatio: compressionRatio,
        chunkCount: processedChunks.length,
        isTruncated: isTruncated,
      );
    } catch (e) {
      session.log(
        'Summarization failed, using truncated content: $e',
        level: LogLevel.warning,
      );

      // Fallback to truncation
      return DocumentSummary(
        briefSummary: content.substring(0, content.length.clamp(0, 500)),
        mediumSummary: content.substring(0, content.length.clamp(0, 2000)),
        detailedSummary: content.substring(0, content.length.clamp(0, 8000)),
        originalLength: content.length,
        compressionRatio: 0.5,
        chunkCount: 1,
        isTruncated: content.length > 8000,
      );
    }
  }

  /// Split content into manageable chunks
  static List<String> _splitIntoChunks(String content, int chunkSize) {
    final chunks = <String>[];
    int start = 0;

    while (start < content.length) {
      int end = start + chunkSize;

      // Try to break at paragraph or sentence boundary
      if (end < content.length) {
        final nextNewline = content.indexOf('\n\n', end - 200);
        if (nextNewline != -1 && nextNewline < end + 200) {
          end = nextNewline;
        } else {
          final nextPeriod = content.indexOf('. ', end - 100);
          if (nextPeriod != -1 && nextPeriod < end + 100) {
            end = nextPeriod + 1;
          }
        }
      } else {
        end = content.length;
      }

      chunks.add(content.substring(start, end));
      start = end;
    }

    return chunks;
  }

  /// Summarize a single chunk
  static Future<String> _summarizeChunk(
    Session session,
    String chunk,
    OpenRouterClient client,
  ) async {
    final prompt =
        '''Summarize the following text concisely while preserving key information:

$chunk

Summary:''';

    final response = await client.chatCompletion(
      messages: [
        ChatMessage.user(prompt),
      ],
      model: 'google/gemini-flash-1.5-8b', // Fast, cheap model for chunking
      maxTokens: 500,
    );

    return response.choices.first.message.content;
  }

  /// Generate detailed summary (70-80% compression)
  static Future<String> _generateDetailedSummary(
    Session session,
    String combinedSummary,
    OpenRouterClient client, {
    String? fileName,
  }) async {
    final fileContext = fileName != null ? ' from "$fileName"' : '';
    final prompt =
        '''Create a comprehensive summary of this document$fileContext. Include:
- Main topics and themes
- Key points and details
- Important facts and figures
- Structure and organization

Content:
$combinedSummary

Detailed Summary:''';

    final response = await client.chatCompletion(
      messages: [
        ChatMessage.user(prompt),
      ],
      model: 'google/gemini-flash-1.5-8b',
      maxTokens: 1000,
    );

    return response.choices.first.message.content;
  }

  /// Generate medium summary (50-60% compression)
  static Future<String> _generateMediumSummary(
    Session session,
    String detailedSummary,
    OpenRouterClient client,
  ) async {
    final prompt =
        '''Create a medium-length summary focusing on the most important points:

$detailedSummary

Medium Summary:''';

    final response = await client.chatCompletion(
      messages: [
        ChatMessage.user(prompt),
      ],
      model: 'google/gemini-flash-1.5-8b',
      maxTokens: 500,
    );

    return response.choices.first.message.content;
  }

  /// Generate brief summary (20-30% compression)
  static Future<String> _generateBriefSummary(
    Session session,
    String mediumSummary,
    OpenRouterClient client,
  ) async {
    final prompt =
        '''Create a brief 2-3 sentence summary of the main idea:

$mediumSummary

Brief Summary:''';

    final response = await client.chatCompletion(
      messages: [
        ChatMessage.user(prompt),
      ],
      model: 'google/gemini-flash-1.5-8b',
      maxTokens: 200,
    );

    return response.choices.first.message.content;
  }

  /// Determine which summary level to use for embedding
  static String getEmbeddingSummary(
    DocumentSummary summary, {
    int targetTokens = 8000,
  }) {
    // Estimate tokens (rough: 1 token ≈ 4 characters)
    final detailedTokens = summary.detailedSummary.length ~/ 4;
    final mediumTokens = summary.mediumSummary.length ~/ 4;
    // final briefTokens = summary.briefSummary.length ~/ 4;

    if (detailedTokens <= targetTokens) {
      return summary.detailedSummary;
    } else if (mediumTokens <= targetTokens) {
      return summary.mediumSummary;
    } else {
      return summary.briefSummary;
    }
  }

  /// Calculate token savings
  static TokenSavings calculateSavings(
    int originalLength,
    int summaryLength,
  ) {
    final originalTokens = originalLength ~/ 4; // Rough estimate
    final summaryTokens = summaryLength ~/ 4;
    final savedTokens = originalTokens - summaryTokens;
    final savingsPercentage = (savedTokens / originalTokens) * 100;

    // Estimate cost savings (using average embedding cost)
    const costPerMToken = 0.02; // text-embedding-3-small
    final savedCost = (savedTokens / 1000000) * costPerMToken;

    return TokenSavings(
      originalTokens: originalTokens,
      summaryTokens: summaryTokens,
      savedTokens: savedTokens,
      savingsPercentage: savingsPercentage,
      estimatedCostSavings: savedCost,
    );
  }
}

class DocumentSummary {
  final String briefSummary;
  final String mediumSummary;
  final String detailedSummary;
  final int originalLength;
  final double compressionRatio;
  final int chunkCount;
  final bool isTruncated;

  DocumentSummary({
    required this.briefSummary,
    required this.mediumSummary,
    required this.detailedSummary,
    required this.originalLength,
    required this.compressionRatio,
    required this.chunkCount,
    this.isTruncated = false,
  });

  Map<String, dynamic> toJson() => {
    'briefSummary': briefSummary,
    'mediumSummary': mediumSummary,
    'detailedSummary': detailedSummary,
    'originalLength': originalLength,
    'compressionRatio': compressionRatio,
    'chunkCount': chunkCount,
    'isTruncated': isTruncated,
  };

  factory DocumentSummary.fromJson(Map<String, dynamic> json) {
    return DocumentSummary(
      briefSummary: json['briefSummary'] as String,
      mediumSummary: json['mediumSummary'] as String,
      detailedSummary: json['detailedSummary'] as String,
      originalLength: json['originalLength'] as int,
      compressionRatio: (json['compressionRatio'] as num).toDouble(),
      chunkCount: json['chunkCount'] as int,
      isTruncated: json['isTruncated'] as bool? ?? false,
    );
  }
}

/// Token savings information
class TokenSavings {
  final int originalTokens;
  final int summaryTokens;
  final int savedTokens;
  final double savingsPercentage;
  final double estimatedCostSavings;

  TokenSavings({
    required this.originalTokens,
    required this.summaryTokens,
    required this.savedTokens,
    required this.savingsPercentage,
    required this.estimatedCostSavings,
  });

  Map<String, dynamic> toJson() => {
    'originalTokens': originalTokens,
    'summaryTokens': summaryTokens,
    'savedTokens': savedTokens,
    'savingsPercentage': savingsPercentage,
    'estimatedCostSavings': estimatedCostSavings,
  };
}
