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

abstract class SavedSearchPreset implements _i1.SerializableModel {
  SavedSearchPreset._({
    this.id,
    required this.name,
    required this.query,
    this.category,
    this.tags,
    this.fileTypes,
    this.dateFrom,
    this.dateTo,
    this.minSize,
    this.maxSize,
    required this.createdAt,
    required this.usageCount,
  });

  factory SavedSearchPreset({
    int? id,
    required String name,
    required String query,
    String? category,
    List<String>? tags,
    List<String>? fileTypes,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? minSize,
    int? maxSize,
    required DateTime createdAt,
    required int usageCount,
  }) = _SavedSearchPresetImpl;

  factory SavedSearchPreset.fromJson(Map<String, dynamic> jsonSerialization) {
    return SavedSearchPreset(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      query: jsonSerialization['query'] as String,
      category: jsonSerialization['category'] as String?,
      tags: jsonSerialization['tags'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(jsonSerialization['tags']),
      fileTypes: jsonSerialization['fileTypes'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['fileTypes'],
            ),
      dateFrom: jsonSerialization['dateFrom'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dateFrom']),
      dateTo: jsonSerialization['dateTo'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dateTo']),
      minSize: jsonSerialization['minSize'] as int?,
      maxSize: jsonSerialization['maxSize'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      usageCount: jsonSerialization['usageCount'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String name;

  String query;

  String? category;

  List<String>? tags;

  List<String>? fileTypes;

  DateTime? dateFrom;

  DateTime? dateTo;

  int? minSize;

  int? maxSize;

  DateTime createdAt;

  int usageCount;

  /// Returns a shallow copy of this [SavedSearchPreset]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SavedSearchPreset copyWith({
    int? id,
    String? name,
    String? query,
    String? category,
    List<String>? tags,
    List<String>? fileTypes,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? minSize,
    int? maxSize,
    DateTime? createdAt,
    int? usageCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SavedSearchPreset',
      if (id != null) 'id': id,
      'name': name,
      'query': query,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags?.toJson(),
      if (fileTypes != null) 'fileTypes': fileTypes?.toJson(),
      if (dateFrom != null) 'dateFrom': dateFrom?.toJson(),
      if (dateTo != null) 'dateTo': dateTo?.toJson(),
      if (minSize != null) 'minSize': minSize,
      if (maxSize != null) 'maxSize': maxSize,
      'createdAt': createdAt.toJson(),
      'usageCount': usageCount,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SavedSearchPresetImpl extends SavedSearchPreset {
  _SavedSearchPresetImpl({
    int? id,
    required String name,
    required String query,
    String? category,
    List<String>? tags,
    List<String>? fileTypes,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? minSize,
    int? maxSize,
    required DateTime createdAt,
    required int usageCount,
  }) : super._(
         id: id,
         name: name,
         query: query,
         category: category,
         tags: tags,
         fileTypes: fileTypes,
         dateFrom: dateFrom,
         dateTo: dateTo,
         minSize: minSize,
         maxSize: maxSize,
         createdAt: createdAt,
         usageCount: usageCount,
       );

  /// Returns a shallow copy of this [SavedSearchPreset]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SavedSearchPreset copyWith({
    Object? id = _Undefined,
    String? name,
    String? query,
    Object? category = _Undefined,
    Object? tags = _Undefined,
    Object? fileTypes = _Undefined,
    Object? dateFrom = _Undefined,
    Object? dateTo = _Undefined,
    Object? minSize = _Undefined,
    Object? maxSize = _Undefined,
    DateTime? createdAt,
    int? usageCount,
  }) {
    return SavedSearchPreset(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      query: query ?? this.query,
      category: category is String? ? category : this.category,
      tags: tags is List<String>? ? tags : this.tags?.map((e0) => e0).toList(),
      fileTypes: fileTypes is List<String>?
          ? fileTypes
          : this.fileTypes?.map((e0) => e0).toList(),
      dateFrom: dateFrom is DateTime? ? dateFrom : this.dateFrom,
      dateTo: dateTo is DateTime? ? dateTo : this.dateTo,
      minSize: minSize is int? ? minSize : this.minSize,
      maxSize: maxSize is int? ? maxSize : this.maxSize,
      createdAt: createdAt ?? this.createdAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}
