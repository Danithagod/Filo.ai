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

/// DocumentEmbedding model - stores vector embeddings separately for flexibility
abstract class DocumentEmbedding implements _i1.SerializableModel {
  DocumentEmbedding._({
    this.id,
    required this.fileIndexId,
    required this.chunkIndex,
    this.chunkText,
    required this.embedding,
    this.embeddingJson,
    this.dimensions,
  });

  factory DocumentEmbedding({
    int? id,
    required int fileIndexId,
    required int chunkIndex,
    String? chunkText,
    required _i1.Vector embedding,
    String? embeddingJson,
    int? dimensions,
  }) = _DocumentEmbeddingImpl;

  factory DocumentEmbedding.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocumentEmbedding(
      id: jsonSerialization['id'] as int?,
      fileIndexId: jsonSerialization['fileIndexId'] as int,
      chunkIndex: jsonSerialization['chunkIndex'] as int,
      chunkText: jsonSerialization['chunkText'] as String?,
      embedding: _i1.VectorJsonExtension.fromJson(
        jsonSerialization['embedding'],
      ),
      embeddingJson: jsonSerialization['embeddingJson'] as String?,
      dimensions: jsonSerialization['dimensions'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Reference to the file_index record
  int fileIndexId;

  /// Chunk index (0 for single-chunk docs, 1+ for multi-chunk)
  int chunkIndex;

  /// The text chunk that was embedded
  String? chunkText;

  /// Vector embedding - 768 dimensions for sentence transformers
  _i1.Vector embedding;

  /// JSON encoded embedding vector (DEPRECATED: Use native embedding field)
  String? embeddingJson;

  /// Embedding dimensions (DEPRECATED)
  int? dimensions;

  /// Returns a shallow copy of this [DocumentEmbedding]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DocumentEmbedding copyWith({
    int? id,
    int? fileIndexId,
    int? chunkIndex,
    String? chunkText,
    _i1.Vector? embedding,
    String? embeddingJson,
    int? dimensions,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocumentEmbedding',
      if (id != null) 'id': id,
      'fileIndexId': fileIndexId,
      'chunkIndex': chunkIndex,
      if (chunkText != null) 'chunkText': chunkText,
      'embedding': embedding.toJson(),
      if (embeddingJson != null) 'embeddingJson': embeddingJson,
      if (dimensions != null) 'dimensions': dimensions,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentEmbeddingImpl extends DocumentEmbedding {
  _DocumentEmbeddingImpl({
    int? id,
    required int fileIndexId,
    required int chunkIndex,
    String? chunkText,
    required _i1.Vector embedding,
    String? embeddingJson,
    int? dimensions,
  }) : super._(
         id: id,
         fileIndexId: fileIndexId,
         chunkIndex: chunkIndex,
         chunkText: chunkText,
         embedding: embedding,
         embeddingJson: embeddingJson,
         dimensions: dimensions,
       );

  /// Returns a shallow copy of this [DocumentEmbedding]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DocumentEmbedding copyWith({
    Object? id = _Undefined,
    int? fileIndexId,
    int? chunkIndex,
    Object? chunkText = _Undefined,
    _i1.Vector? embedding,
    Object? embeddingJson = _Undefined,
    Object? dimensions = _Undefined,
  }) {
    return DocumentEmbedding(
      id: id is int? ? id : this.id,
      fileIndexId: fileIndexId ?? this.fileIndexId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      chunkText: chunkText is String? ? chunkText : this.chunkText,
      embedding: embedding ?? this.embedding.clone(),
      embeddingJson: embeddingJson is String?
          ? embeddingJson
          : this.embeddingJson,
      dimensions: dimensions is int? ? dimensions : this.dimensions,
    );
  }
}
