import 'package:semantic_butler_client/semantic_butler_client.dart';

/// A unified wrapper for both [SearchResult] and [AISearchResult]
sealed class UnifiedSearchResult {
  final String path;
  final String fileName;
  final double relevanceScore;
  final String contentPreview;
  final List<String> tags;
  final int? fileSizeBytes;
  final String? mimeType;
  final DateTime? indexedAt;

  UnifiedSearchResult({
    required this.path,
    required this.fileName,
    required this.relevanceScore,
    required this.contentPreview,
    required this.tags,
    this.fileSizeBytes,
    this.mimeType,
    this.indexedAt,
  });

  factory UnifiedSearchResult.fromSearchResult(SearchResult result) {
    return TraditionalSearchResultWrapper(result);
  }

  factory UnifiedSearchResult.fromAISearchResult(AISearchResult result) {
    return AISearchResultWrapper(result);
  }
}

class TraditionalSearchResultWrapper extends UnifiedSearchResult {
  final SearchResult raw;

  TraditionalSearchResultWrapper(this.raw)
    : super(
        path: raw.path,
        fileName: raw.fileName,
        relevanceScore: raw.relevanceScore,
        contentPreview: raw.contentPreview ?? '',
        tags: raw.tags,
        fileSizeBytes: raw.fileSizeBytes,
        mimeType: raw.mimeType,
        indexedAt: raw.indexedAt,
      );
}

class AISearchResultWrapper extends UnifiedSearchResult {
  final AISearchResult raw;

  AISearchResultWrapper(this.raw)
    : super(
        path: raw.path,
        fileName: raw.fileName,
        relevanceScore: raw.relevanceScore ?? 0.5,
        contentPreview: raw.contentPreview ?? raw.matchReason ?? '',
        tags: raw.tags ?? [],
        fileSizeBytes: raw.fileSizeBytes,
        mimeType: raw.mimeType,
        indexedAt: raw.indexedAt,
      );
}
