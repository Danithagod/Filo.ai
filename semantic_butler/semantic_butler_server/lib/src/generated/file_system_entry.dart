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

abstract class FileSystemEntry
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  FileSystemEntry._({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modifiedAt,
    this.fileExtension,
    required this.isIndexed,
  });

  factory FileSystemEntry({
    required String name,
    required String path,
    required bool isDirectory,
    required int size,
    required DateTime modifiedAt,
    String? fileExtension,
    required bool isIndexed,
  }) = _FileSystemEntryImpl;

  factory FileSystemEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return FileSystemEntry(
      name: jsonSerialization['name'] as String,
      path: jsonSerialization['path'] as String,
      isDirectory: jsonSerialization['isDirectory'] as bool,
      size: jsonSerialization['size'] as int,
      modifiedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['modifiedAt'],
      ),
      fileExtension: jsonSerialization['fileExtension'] as String?,
      isIndexed: jsonSerialization['isIndexed'] as bool,
    );
  }

  String name;

  String path;

  bool isDirectory;

  int size;

  DateTime modifiedAt;

  String? fileExtension;

  bool isIndexed;

  /// Returns a shallow copy of this [FileSystemEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FileSystemEntry copyWith({
    String? name,
    String? path,
    bool? isDirectory,
    int? size,
    DateTime? modifiedAt,
    String? fileExtension,
    bool? isIndexed,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FileSystemEntry',
      'name': name,
      'path': path,
      'isDirectory': isDirectory,
      'size': size,
      'modifiedAt': modifiedAt.toJson(),
      if (fileExtension != null) 'fileExtension': fileExtension,
      'isIndexed': isIndexed,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FileSystemEntry',
      'name': name,
      'path': path,
      'isDirectory': isDirectory,
      'size': size,
      'modifiedAt': modifiedAt.toJson(),
      if (fileExtension != null) 'fileExtension': fileExtension,
      'isIndexed': isIndexed,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FileSystemEntryImpl extends FileSystemEntry {
  _FileSystemEntryImpl({
    required String name,
    required String path,
    required bool isDirectory,
    required int size,
    required DateTime modifiedAt,
    String? fileExtension,
    required bool isIndexed,
  }) : super._(
         name: name,
         path: path,
         isDirectory: isDirectory,
         size: size,
         modifiedAt: modifiedAt,
         fileExtension: fileExtension,
         isIndexed: isIndexed,
       );

  /// Returns a shallow copy of this [FileSystemEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FileSystemEntry copyWith({
    String? name,
    String? path,
    bool? isDirectory,
    int? size,
    DateTime? modifiedAt,
    Object? fileExtension = _Undefined,
    bool? isIndexed,
  }) {
    return FileSystemEntry(
      name: name ?? this.name,
      path: path ?? this.path,
      isDirectory: isDirectory ?? this.isDirectory,
      size: size ?? this.size,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      fileExtension: fileExtension is String?
          ? fileExtension
          : this.fileExtension,
      isIndexed: isIndexed ?? this.isIndexed,
    );
  }
}
