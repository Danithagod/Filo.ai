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

/// IgnorePattern model - stores patterns to exclude from indexing
abstract class IgnorePattern implements _i1.SerializableModel {
  IgnorePattern._({
    this.id,
    required this.pattern,
    required this.patternType,
    this.description,
    required this.createdAt,
  });

  factory IgnorePattern({
    int? id,
    required String pattern,
    required String patternType,
    String? description,
    required DateTime createdAt,
  }) = _IgnorePatternImpl;

  factory IgnorePattern.fromJson(Map<String, dynamic> jsonSerialization) {
    return IgnorePattern(
      id: jsonSerialization['id'] as int?,
      pattern: jsonSerialization['pattern'] as String,
      patternType: jsonSerialization['patternType'] as String,
      description: jsonSerialization['description'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Glob pattern like "*.log", "node_modules/**", or specific paths
  String pattern;

  /// Pattern type: file, directory, or both
  String patternType;

  /// Optional description for the pattern
  String? description;

  /// When the pattern was created
  DateTime createdAt;

  /// Returns a shallow copy of this [IgnorePattern]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IgnorePattern copyWith({
    int? id,
    String? pattern,
    String? patternType,
    String? description,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IgnorePattern',
      if (id != null) 'id': id,
      'pattern': pattern,
      'patternType': patternType,
      if (description != null) 'description': description,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IgnorePatternImpl extends IgnorePattern {
  _IgnorePatternImpl({
    int? id,
    required String pattern,
    required String patternType,
    String? description,
    required DateTime createdAt,
  }) : super._(
         id: id,
         pattern: pattern,
         patternType: patternType,
         description: description,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [IgnorePattern]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IgnorePattern copyWith({
    Object? id = _Undefined,
    String? pattern,
    String? patternType,
    Object? description = _Undefined,
    DateTime? createdAt,
  }) {
    return IgnorePattern(
      id: id is int? ? id : this.id,
      pattern: pattern ?? this.pattern,
      patternType: patternType ?? this.patternType,
      description: description is String? ? description : this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
