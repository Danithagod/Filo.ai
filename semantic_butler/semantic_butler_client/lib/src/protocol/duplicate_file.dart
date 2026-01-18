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

/// DuplicateFile - info about a file within a duplicate group
abstract class DuplicateFile implements _i1.SerializableModel {
  DuplicateFile._({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
    this.modifiedAt,
    required this.isIndexed,
  });

  factory DuplicateFile({
    required String path,
    required String fileName,
    required int sizeBytes,
    DateTime? modifiedAt,
    required bool isIndexed,
  }) = _DuplicateFileImpl;

  factory DuplicateFile.fromJson(Map<String, dynamic> jsonSerialization) {
    return DuplicateFile(
      path: jsonSerialization['path'] as String,
      fileName: jsonSerialization['fileName'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
      modifiedAt: jsonSerialization['modifiedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['modifiedAt']),
      isIndexed: jsonSerialization['isIndexed'] as bool,
    );
  }

  /// Full file path
  String path;

  /// File name without path
  String fileName;

  /// File size in bytes
  int sizeBytes;

  /// When the file was last modified
  DateTime? modifiedAt;

  /// Whether this file is currently indexed
  bool isIndexed;

  /// Returns a shallow copy of this [DuplicateFile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DuplicateFile copyWith({
    String? path,
    String? fileName,
    int? sizeBytes,
    DateTime? modifiedAt,
    bool? isIndexed,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DuplicateFile',
      'path': path,
      'fileName': fileName,
      'sizeBytes': sizeBytes,
      if (modifiedAt != null) 'modifiedAt': modifiedAt?.toJson(),
      'isIndexed': isIndexed,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DuplicateFileImpl extends DuplicateFile {
  _DuplicateFileImpl({
    required String path,
    required String fileName,
    required int sizeBytes,
    DateTime? modifiedAt,
    required bool isIndexed,
  }) : super._(
         path: path,
         fileName: fileName,
         sizeBytes: sizeBytes,
         modifiedAt: modifiedAt,
         isIndexed: isIndexed,
       );

  /// Returns a shallow copy of this [DuplicateFile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DuplicateFile copyWith({
    String? path,
    String? fileName,
    int? sizeBytes,
    Object? modifiedAt = _Undefined,
    bool? isIndexed,
  }) {
    return DuplicateFile(
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modifiedAt: modifiedAt is DateTime? ? modifiedAt : this.modifiedAt,
      isIndexed: isIndexed ?? this.isIndexed,
    );
  }
}
