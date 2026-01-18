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

/// SimilarFile - info about a file within a similar content group
abstract class SimilarFile implements _i1.SerializableModel {
  SimilarFile._({
    required this.path,
    required this.fileName,
    this.contentPreview,
    this.category,
  });

  factory SimilarFile({
    required String path,
    required String fileName,
    String? contentPreview,
    String? category,
  }) = _SimilarFileImpl;

  factory SimilarFile.fromJson(Map<String, dynamic> jsonSerialization) {
    return SimilarFile(
      path: jsonSerialization['path'] as String,
      fileName: jsonSerialization['fileName'] as String,
      contentPreview: jsonSerialization['contentPreview'] as String?,
      category: jsonSerialization['category'] as String?,
    );
  }

  /// Full file path
  String path;

  /// File name without path
  String fileName;

  /// Content preview (first 200 chars)
  String? contentPreview;

  /// Document category
  String? category;

  /// Returns a shallow copy of this [SimilarFile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SimilarFile copyWith({
    String? path,
    String? fileName,
    String? contentPreview,
    String? category,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SimilarFile',
      'path': path,
      'fileName': fileName,
      if (contentPreview != null) 'contentPreview': contentPreview,
      if (category != null) 'category': category,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SimilarFileImpl extends SimilarFile {
  _SimilarFileImpl({
    required String path,
    required String fileName,
    String? contentPreview,
    String? category,
  }) : super._(
         path: path,
         fileName: fileName,
         contentPreview: contentPreview,
         category: category,
       );

  /// Returns a shallow copy of this [SimilarFile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SimilarFile copyWith({
    String? path,
    String? fileName,
    Object? contentPreview = _Undefined,
    Object? category = _Undefined,
  }) {
    return SimilarFile(
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      contentPreview: contentPreview is String?
          ? contentPreview
          : this.contentPreview,
      category: category is String? ? category : this.category,
    );
  }
}
