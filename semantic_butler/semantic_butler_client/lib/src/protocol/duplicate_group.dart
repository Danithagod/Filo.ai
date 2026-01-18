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
import 'duplicate_file.dart' as _i2;
import 'package:semantic_butler_client/src/protocol/protocol.dart' as _i3;

/// DuplicateGroup - represents a group of files with identical content
abstract class DuplicateGroup implements _i1.SerializableModel {
  DuplicateGroup._({
    required this.contentHash,
    required this.files,
    required this.totalSizeBytes,
    required this.potentialSavingsBytes,
    required this.fileCount,
  });

  factory DuplicateGroup({
    required String contentHash,
    required List<_i2.DuplicateFile> files,
    required int totalSizeBytes,
    required int potentialSavingsBytes,
    required int fileCount,
  }) = _DuplicateGroupImpl;

  factory DuplicateGroup.fromJson(Map<String, dynamic> jsonSerialization) {
    return DuplicateGroup(
      contentHash: jsonSerialization['contentHash'] as String,
      files: _i3.Protocol().deserialize<List<_i2.DuplicateFile>>(
        jsonSerialization['files'],
      ),
      totalSizeBytes: jsonSerialization['totalSizeBytes'] as int,
      potentialSavingsBytes: jsonSerialization['potentialSavingsBytes'] as int,
      fileCount: jsonSerialization['fileCount'] as int,
    );
  }

  /// SHA-256 content hash shared by all files in this group
  String contentHash;

  /// List of file paths in this duplicate group
  List<_i2.DuplicateFile> files;

  /// Total size of all duplicates combined (in bytes)
  int totalSizeBytes;

  /// Potential storage savings if duplicates are removed (keeps one file)
  int potentialSavingsBytes;

  /// Number of duplicate files in this group
  int fileCount;

  /// Returns a shallow copy of this [DuplicateGroup]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DuplicateGroup copyWith({
    String? contentHash,
    List<_i2.DuplicateFile>? files,
    int? totalSizeBytes,
    int? potentialSavingsBytes,
    int? fileCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DuplicateGroup',
      'contentHash': contentHash,
      'files': files.toJson(valueToJson: (v) => v.toJson()),
      'totalSizeBytes': totalSizeBytes,
      'potentialSavingsBytes': potentialSavingsBytes,
      'fileCount': fileCount,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DuplicateGroupImpl extends DuplicateGroup {
  _DuplicateGroupImpl({
    required String contentHash,
    required List<_i2.DuplicateFile> files,
    required int totalSizeBytes,
    required int potentialSavingsBytes,
    required int fileCount,
  }) : super._(
         contentHash: contentHash,
         files: files,
         totalSizeBytes: totalSizeBytes,
         potentialSavingsBytes: potentialSavingsBytes,
         fileCount: fileCount,
       );

  /// Returns a shallow copy of this [DuplicateGroup]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DuplicateGroup copyWith({
    String? contentHash,
    List<_i2.DuplicateFile>? files,
    int? totalSizeBytes,
    int? potentialSavingsBytes,
    int? fileCount,
  }) {
    return DuplicateGroup(
      contentHash: contentHash ?? this.contentHash,
      files: files ?? this.files.map((e0) => e0.copyWith()).toList(),
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      potentialSavingsBytes:
          potentialSavingsBytes ?? this.potentialSavingsBytes,
      fileCount: fileCount ?? this.fileCount,
    );
  }
}
