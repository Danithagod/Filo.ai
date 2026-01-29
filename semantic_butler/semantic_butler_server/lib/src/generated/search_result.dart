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
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:semantic_butler_server/src/generated/protocol.dart' as _i2;

/// SearchResult DTO - returned from semantic search
abstract class SearchResult
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SearchResult._({
    required this.id,
    required this.path,
    required this.fileName,
    required this.relevanceScore,
    this.contentPreview,
    required this.tags,
    this.indexedAt,
    required this.fileSizeBytes,
    this.mimeType,
    this.suggestedQuery,
    this.nextCursor,
    this.matchedChunkText,
  });

  factory SearchResult({
    required int id,
    required String path,
    required String fileName,
    required double relevanceScore,
    String? contentPreview,
    required List<String> tags,
    DateTime? indexedAt,
    required int fileSizeBytes,
    String? mimeType,
    String? suggestedQuery,
    String? nextCursor,
    String? matchedChunkText,
  }) = _SearchResultImpl;

  factory SearchResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return SearchResult(
      id: jsonSerialization['id'] as int,
      path: jsonSerialization['path'] as String,
      fileName: jsonSerialization['fileName'] as String,
      relevanceScore: (jsonSerialization['relevanceScore'] as num).toDouble(),
      contentPreview: jsonSerialization['contentPreview'] as String?,
      tags: _i2.Protocol().deserialize<List<String>>(jsonSerialization['tags']),
      indexedAt: jsonSerialization['indexedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['indexedAt']),
      fileSizeBytes: jsonSerialization['fileSizeBytes'] as int,
      mimeType: jsonSerialization['mimeType'] as String?,
      suggestedQuery: jsonSerialization['suggestedQuery'] as String?,
      nextCursor: jsonSerialization['nextCursor'] as String?,
      matchedChunkText: jsonSerialization['matchedChunkText'] as String?,
    );
  }

  /// Document ID from file_index
  int id;

  /// File path
  String path;

  /// File name
  String fileName;

  /// Relevance score (0.0 to 1.0)
  double relevanceScore;

  /// Content preview snippet
  String? contentPreview;

  /// Parsed tags as list of strings
  List<String> tags;

  /// When the file was indexed
  DateTime? indexedAt;

  /// File size in bytes
  int fileSizeBytes;

  /// MIME type
  String? mimeType;

  /// Suggested query if typos were detected
  String? suggestedQuery;

  /// Pagination cursor for the next result set
  String? nextCursor;

  /// The specific text chunk that matched the search query
  String? matchedChunkText;

  /// Returns a shallow copy of this [SearchResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SearchResult copyWith({
    int? id,
    String? path,
    String? fileName,
    double? relevanceScore,
    String? contentPreview,
    List<String>? tags,
    DateTime? indexedAt,
    int? fileSizeBytes,
    String? mimeType,
    String? suggestedQuery,
    String? nextCursor,
    String? matchedChunkText,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SearchResult',
      'id': id,
      'path': path,
      'fileName': fileName,
      'relevanceScore': relevanceScore,
      if (contentPreview != null) 'contentPreview': contentPreview,
      'tags': tags.toJson(),
      if (indexedAt != null) 'indexedAt': indexedAt?.toJson(),
      'fileSizeBytes': fileSizeBytes,
      if (mimeType != null) 'mimeType': mimeType,
      if (suggestedQuery != null) 'suggestedQuery': suggestedQuery,
      if (nextCursor != null) 'nextCursor': nextCursor,
      if (matchedChunkText != null) 'matchedChunkText': matchedChunkText,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SearchResult',
      'id': id,
      'path': path,
      'fileName': fileName,
      'relevanceScore': relevanceScore,
      if (contentPreview != null) 'contentPreview': contentPreview,
      'tags': tags.toJson(),
      if (indexedAt != null) 'indexedAt': indexedAt?.toJson(),
      'fileSizeBytes': fileSizeBytes,
      if (mimeType != null) 'mimeType': mimeType,
      if (suggestedQuery != null) 'suggestedQuery': suggestedQuery,
      if (nextCursor != null) 'nextCursor': nextCursor,
      if (matchedChunkText != null) 'matchedChunkText': matchedChunkText,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SearchResultImpl extends SearchResult {
  _SearchResultImpl({
    required int id,
    required String path,
    required String fileName,
    required double relevanceScore,
    String? contentPreview,
    required List<String> tags,
    DateTime? indexedAt,
    required int fileSizeBytes,
    String? mimeType,
    String? suggestedQuery,
    String? nextCursor,
    String? matchedChunkText,
  }) : super._(
         id: id,
         path: path,
         fileName: fileName,
         relevanceScore: relevanceScore,
         contentPreview: contentPreview,
         tags: tags,
         indexedAt: indexedAt,
         fileSizeBytes: fileSizeBytes,
         mimeType: mimeType,
         suggestedQuery: suggestedQuery,
         nextCursor: nextCursor,
         matchedChunkText: matchedChunkText,
       );

  /// Returns a shallow copy of this [SearchResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SearchResult copyWith({
    int? id,
    String? path,
    String? fileName,
    double? relevanceScore,
    Object? contentPreview = _Undefined,
    List<String>? tags,
    Object? indexedAt = _Undefined,
    int? fileSizeBytes,
    Object? mimeType = _Undefined,
    Object? suggestedQuery = _Undefined,
    Object? nextCursor = _Undefined,
    Object? matchedChunkText = _Undefined,
  }) {
    return SearchResult(
      id: id ?? this.id,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      contentPreview: contentPreview is String?
          ? contentPreview
          : this.contentPreview,
      tags: tags ?? this.tags.map((e0) => e0).toList(),
      indexedAt: indexedAt is DateTime? ? indexedAt : this.indexedAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType is String? ? mimeType : this.mimeType,
      suggestedQuery: suggestedQuery is String?
          ? suggestedQuery
          : this.suggestedQuery,
      nextCursor: nextCursor is String? ? nextCursor : this.nextCursor,
      matchedChunkText: matchedChunkText is String?
          ? matchedChunkText
          : this.matchedChunkText,
    );
  }
}
