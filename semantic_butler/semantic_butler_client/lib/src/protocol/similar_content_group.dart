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
import 'similar_file.dart' as _i2;
import 'package:semantic_butler_client/src/protocol/protocol.dart' as _i3;

/// SimilarContentGroup - represents a group of semantically similar documents
abstract class SimilarContentGroup implements _i1.SerializableModel {
  SimilarContentGroup._({
    required this.similarityScore,
    required this.files,
    required this.fileCount,
    this.similarityReason,
  });

  factory SimilarContentGroup({
    required double similarityScore,
    required List<_i2.SimilarFile> files,
    required int fileCount,
    String? similarityReason,
  }) = _SimilarContentGroupImpl;

  factory SimilarContentGroup.fromJson(Map<String, dynamic> jsonSerialization) {
    return SimilarContentGroup(
      similarityScore: (jsonSerialization['similarityScore'] as num).toDouble(),
      files: _i3.Protocol().deserialize<List<_i2.SimilarFile>>(
        jsonSerialization['files'],
      ),
      fileCount: jsonSerialization['fileCount'] as int,
      similarityReason: jsonSerialization['similarityReason'] as String?,
    );
  }

  /// Similarity score (0.0-1.0) for this group
  double similarityScore;

  /// List of similar files in this group
  List<_i2.SimilarFile> files;

  /// Number of files in this group
  int fileCount;

  /// Brief description of what makes these files similar
  String? similarityReason;

  /// Returns a shallow copy of this [SimilarContentGroup]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SimilarContentGroup copyWith({
    double? similarityScore,
    List<_i2.SimilarFile>? files,
    int? fileCount,
    String? similarityReason,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SimilarContentGroup',
      'similarityScore': similarityScore,
      'files': files.toJson(valueToJson: (v) => v.toJson()),
      'fileCount': fileCount,
      if (similarityReason != null) 'similarityReason': similarityReason,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SimilarContentGroupImpl extends SimilarContentGroup {
  _SimilarContentGroupImpl({
    required double similarityScore,
    required List<_i2.SimilarFile> files,
    required int fileCount,
    String? similarityReason,
  }) : super._(
         similarityScore: similarityScore,
         files: files,
         fileCount: fileCount,
         similarityReason: similarityReason,
       );

  /// Returns a shallow copy of this [SimilarContentGroup]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SimilarContentGroup copyWith({
    double? similarityScore,
    List<_i2.SimilarFile>? files,
    int? fileCount,
    Object? similarityReason = _Undefined,
  }) {
    return SimilarContentGroup(
      similarityScore: similarityScore ?? this.similarityScore,
      files: files ?? this.files.map((e0) => e0.copyWith()).toList(),
      fileCount: fileCount ?? this.fileCount,
      similarityReason: similarityReason is String?
          ? similarityReason
          : this.similarityReason,
    );
  }
}
