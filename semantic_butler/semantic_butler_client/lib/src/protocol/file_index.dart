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

/// FileIndex model - stores indexed documents with embeddings
abstract class FileIndex implements _i1.SerializableModel {
  FileIndex._({
    this.id,
    required this.path,
    required this.fileName,
    required this.contentHash,
    required this.fileSizeBytes,
    this.mimeType,
    this.contentPreview,
    this.summary,
    this.tagsJson,
    this.documentCategory,
    this.fileCreatedAt,
    this.fileModifiedAt,
    this.wordCount,
    this.pageCount,
    required this.isTextContent,
    required this.status,
    this.errorMessage,
    this.embeddingModel,
    this.indexedAt,
  });

  factory FileIndex({
    int? id,
    required String path,
    required String fileName,
    required String contentHash,
    required int fileSizeBytes,
    String? mimeType,
    String? contentPreview,
    String? summary,
    String? tagsJson,
    String? documentCategory,
    DateTime? fileCreatedAt,
    DateTime? fileModifiedAt,
    int? wordCount,
    int? pageCount,
    required bool isTextContent,
    required String status,
    String? errorMessage,
    String? embeddingModel,
    DateTime? indexedAt,
  }) = _FileIndexImpl;

  factory FileIndex.fromJson(Map<String, dynamic> jsonSerialization) {
    return FileIndex(
      id: jsonSerialization['id'] as int?,
      path: jsonSerialization['path'] as String,
      fileName: jsonSerialization['fileName'] as String,
      contentHash: jsonSerialization['contentHash'] as String,
      fileSizeBytes: jsonSerialization['fileSizeBytes'] as int,
      mimeType: jsonSerialization['mimeType'] as String?,
      contentPreview: jsonSerialization['contentPreview'] as String?,
      summary: jsonSerialization['summary'] as String?,
      tagsJson: jsonSerialization['tagsJson'] as String?,
      documentCategory: jsonSerialization['documentCategory'] as String?,
      fileCreatedAt: jsonSerialization['fileCreatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['fileCreatedAt'],
            ),
      fileModifiedAt: jsonSerialization['fileModifiedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['fileModifiedAt'],
            ),
      wordCount: jsonSerialization['wordCount'] as int?,
      pageCount: jsonSerialization['pageCount'] as int?,
      isTextContent: jsonSerialization['isTextContent'] as bool,
      status: jsonSerialization['status'] as String,
      errorMessage: jsonSerialization['errorMessage'] as String?,
      embeddingModel: jsonSerialization['embeddingModel'] as String?,
      indexedAt: jsonSerialization['indexedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['indexedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// File path on the file system
  String path;

  /// File name without path
  String fileName;

  /// SHA-256 hash of file content for change detection
  String contentHash;

  /// File size in bytes
  int fileSizeBytes;

  /// MIME type of the file
  String? mimeType;

  /// Preview of the document content (first 500 chars)
  String? contentPreview;

  /// AI-generated summary for embedding (200-300 words)
  String? summary;

  /// JSON encoded auto-generated tags
  String? tagsJson;

  /// Document category: code, document, config, data, media_metadata
  String? documentCategory;

  /// Original file creation date from file system
  DateTime? fileCreatedAt;

  /// Original file modification date from file system
  DateTime? fileModifiedAt;

  /// Number of words in the document
  int? wordCount;

  /// Number of pages in the document (for PDFs/DOCX)
  int? pageCount;

  /// Whether this file contains readable text content
  bool isTextContent;

  /// Status: pending, indexing, indexed, failed, skipped
  String status;

  /// Error message if status is failed
  String? errorMessage;

  /// Name of the embedding model used
  String? embeddingModel;

  /// When the file was indexed
  DateTime? indexedAt;

  /// Returns a shallow copy of this [FileIndex]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FileIndex copyWith({
    int? id,
    String? path,
    String? fileName,
    String? contentHash,
    int? fileSizeBytes,
    String? mimeType,
    String? contentPreview,
    String? summary,
    String? tagsJson,
    String? documentCategory,
    DateTime? fileCreatedAt,
    DateTime? fileModifiedAt,
    int? wordCount,
    int? pageCount,
    bool? isTextContent,
    String? status,
    String? errorMessage,
    String? embeddingModel,
    DateTime? indexedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FileIndex',
      if (id != null) 'id': id,
      'path': path,
      'fileName': fileName,
      'contentHash': contentHash,
      'fileSizeBytes': fileSizeBytes,
      if (mimeType != null) 'mimeType': mimeType,
      if (contentPreview != null) 'contentPreview': contentPreview,
      if (summary != null) 'summary': summary,
      if (tagsJson != null) 'tagsJson': tagsJson,
      if (documentCategory != null) 'documentCategory': documentCategory,
      if (fileCreatedAt != null) 'fileCreatedAt': fileCreatedAt?.toJson(),
      if (fileModifiedAt != null) 'fileModifiedAt': fileModifiedAt?.toJson(),
      if (wordCount != null) 'wordCount': wordCount,
      if (pageCount != null) 'pageCount': pageCount,
      'isTextContent': isTextContent,
      'status': status,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (embeddingModel != null) 'embeddingModel': embeddingModel,
      if (indexedAt != null) 'indexedAt': indexedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FileIndexImpl extends FileIndex {
  _FileIndexImpl({
    int? id,
    required String path,
    required String fileName,
    required String contentHash,
    required int fileSizeBytes,
    String? mimeType,
    String? contentPreview,
    String? summary,
    String? tagsJson,
    String? documentCategory,
    DateTime? fileCreatedAt,
    DateTime? fileModifiedAt,
    int? wordCount,
    int? pageCount,
    required bool isTextContent,
    required String status,
    String? errorMessage,
    String? embeddingModel,
    DateTime? indexedAt,
  }) : super._(
         id: id,
         path: path,
         fileName: fileName,
         contentHash: contentHash,
         fileSizeBytes: fileSizeBytes,
         mimeType: mimeType,
         contentPreview: contentPreview,
         summary: summary,
         tagsJson: tagsJson,
         documentCategory: documentCategory,
         fileCreatedAt: fileCreatedAt,
         fileModifiedAt: fileModifiedAt,
         wordCount: wordCount,
         pageCount: pageCount,
         isTextContent: isTextContent,
         status: status,
         errorMessage: errorMessage,
         embeddingModel: embeddingModel,
         indexedAt: indexedAt,
       );

  /// Returns a shallow copy of this [FileIndex]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FileIndex copyWith({
    Object? id = _Undefined,
    String? path,
    String? fileName,
    String? contentHash,
    int? fileSizeBytes,
    Object? mimeType = _Undefined,
    Object? contentPreview = _Undefined,
    Object? summary = _Undefined,
    Object? tagsJson = _Undefined,
    Object? documentCategory = _Undefined,
    Object? fileCreatedAt = _Undefined,
    Object? fileModifiedAt = _Undefined,
    Object? wordCount = _Undefined,
    Object? pageCount = _Undefined,
    bool? isTextContent,
    String? status,
    Object? errorMessage = _Undefined,
    Object? embeddingModel = _Undefined,
    Object? indexedAt = _Undefined,
  }) {
    return FileIndex(
      id: id is int? ? id : this.id,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      contentHash: contentHash ?? this.contentHash,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType is String? ? mimeType : this.mimeType,
      contentPreview: contentPreview is String?
          ? contentPreview
          : this.contentPreview,
      summary: summary is String? ? summary : this.summary,
      tagsJson: tagsJson is String? ? tagsJson : this.tagsJson,
      documentCategory: documentCategory is String?
          ? documentCategory
          : this.documentCategory,
      fileCreatedAt: fileCreatedAt is DateTime?
          ? fileCreatedAt
          : this.fileCreatedAt,
      fileModifiedAt: fileModifiedAt is DateTime?
          ? fileModifiedAt
          : this.fileModifiedAt,
      wordCount: wordCount is int? ? wordCount : this.wordCount,
      pageCount: pageCount is int? ? pageCount : this.pageCount,
      isTextContent: isTextContent ?? this.isTextContent,
      status: status ?? this.status,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      embeddingModel: embeddingModel is String?
          ? embeddingModel
          : this.embeddingModel,
      indexedAt: indexedAt is DateTime? ? indexedAt : this.indexedAt,
    );
  }
}
