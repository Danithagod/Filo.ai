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
import 'package:semantic_butler_client/src/protocol/protocol.dart' as _i2;

/// AISearchResult DTO - returned from AI-powered search
/// Combines results from semantic index and terminal-based file discovery
abstract class AISearchResult implements _i1.SerializableModel {
  AISearchResult._({
    required this.path,
    required this.fileName,
    required this.isDirectory,
    required this.source,
    this.relevanceScore,
    this.contentPreview,
    this.foundVia,
    this.matchReason,
    this.fileSizeBytes,
    this.mimeType,
    this.tags,
  });

  factory AISearchResult({
    required String path,
    required String fileName,
    required bool isDirectory,
    required String source,
    double? relevanceScore,
    String? contentPreview,
    String? foundVia,
    String? matchReason,
    int? fileSizeBytes,
    String? mimeType,
    List<String>? tags,
  }) = _AISearchResultImpl;

  factory AISearchResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return AISearchResult(
      path: jsonSerialization['path'] as String,
      fileName: jsonSerialization['fileName'] as String,
      isDirectory: jsonSerialization['isDirectory'] as bool,
      source: jsonSerialization['source'] as String,
      relevanceScore: (jsonSerialization['relevanceScore'] as num?)?.toDouble(),
      contentPreview: jsonSerialization['contentPreview'] as String?,
      foundVia: jsonSerialization['foundVia'] as String?,
      matchReason: jsonSerialization['matchReason'] as String?,
      fileSizeBytes: jsonSerialization['fileSizeBytes'] as int?,
      mimeType: jsonSerialization['mimeType'] as String?,
      tags: jsonSerialization['tags'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(jsonSerialization['tags']),
    );
  }

  /// Full file path
  String path;

  /// File name
  String fileName;

  /// Whether this is a directory
  bool isDirectory;

  /// Source of the result: 'index', 'terminal', 'both'
  String source;

  /// Relevance score (0.0 to 1.0) - may be null for terminal results
  double? relevanceScore;

  /// Content preview snippet
  String? contentPreview;

  /// How the file was found: 'semantic', 'deep_search', 'find_files', 'grep_search'
  String? foundVia;

  /// Human-readable explanation of why this matched
  String? matchReason;

  /// File size in bytes (if available)
  int? fileSizeBytes;

  /// MIME type (if available)
  String? mimeType;

  /// Tags from index (if available)
  List<String>? tags;

  /// Returns a shallow copy of this [AISearchResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AISearchResult copyWith({
    String? path,
    String? fileName,
    bool? isDirectory,
    String? source,
    double? relevanceScore,
    String? contentPreview,
    String? foundVia,
    String? matchReason,
    int? fileSizeBytes,
    String? mimeType,
    List<String>? tags,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AISearchResult',
      'path': path,
      'fileName': fileName,
      'isDirectory': isDirectory,
      'source': source,
      if (relevanceScore != null) 'relevanceScore': relevanceScore,
      if (contentPreview != null) 'contentPreview': contentPreview,
      if (foundVia != null) 'foundVia': foundVia,
      if (matchReason != null) 'matchReason': matchReason,
      if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
      if (mimeType != null) 'mimeType': mimeType,
      if (tags != null) 'tags': tags?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AISearchResultImpl extends AISearchResult {
  _AISearchResultImpl({
    required String path,
    required String fileName,
    required bool isDirectory,
    required String source,
    double? relevanceScore,
    String? contentPreview,
    String? foundVia,
    String? matchReason,
    int? fileSizeBytes,
    String? mimeType,
    List<String>? tags,
  }) : super._(
         path: path,
         fileName: fileName,
         isDirectory: isDirectory,
         source: source,
         relevanceScore: relevanceScore,
         contentPreview: contentPreview,
         foundVia: foundVia,
         matchReason: matchReason,
         fileSizeBytes: fileSizeBytes,
         mimeType: mimeType,
         tags: tags,
       );

  /// Returns a shallow copy of this [AISearchResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AISearchResult copyWith({
    String? path,
    String? fileName,
    bool? isDirectory,
    String? source,
    Object? relevanceScore = _Undefined,
    Object? contentPreview = _Undefined,
    Object? foundVia = _Undefined,
    Object? matchReason = _Undefined,
    Object? fileSizeBytes = _Undefined,
    Object? mimeType = _Undefined,
    Object? tags = _Undefined,
  }) {
    return AISearchResult(
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      isDirectory: isDirectory ?? this.isDirectory,
      source: source ?? this.source,
      relevanceScore: relevanceScore is double?
          ? relevanceScore
          : this.relevanceScore,
      contentPreview: contentPreview is String?
          ? contentPreview
          : this.contentPreview,
      foundVia: foundVia is String? ? foundVia : this.foundVia,
      matchReason: matchReason is String? ? matchReason : this.matchReason,
      fileSizeBytes: fileSizeBytes is int? ? fileSizeBytes : this.fileSizeBytes,
      mimeType: mimeType is String? ? mimeType : this.mimeType,
      tags: tags is List<String>? ? tags : this.tags?.map((e0) => e0).toList(),
    );
  }
}
