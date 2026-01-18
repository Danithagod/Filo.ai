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

abstract class SearchFilters implements _i1.SerializableModel {
  SearchFilters._({
    this.dateFrom,
    this.dateTo,
    this.fileTypes,
    this.tags,
    this.minSize,
    this.maxSize,
  });

  factory SearchFilters({
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? fileTypes,
    List<String>? tags,
    int? minSize,
    int? maxSize,
  }) = _SearchFiltersImpl;

  factory SearchFilters.fromJson(Map<String, dynamic> jsonSerialization) {
    return SearchFilters(
      dateFrom: jsonSerialization['dateFrom'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dateFrom']),
      dateTo: jsonSerialization['dateTo'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dateTo']),
      fileTypes: jsonSerialization['fileTypes'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['fileTypes'],
            ),
      tags: jsonSerialization['tags'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(jsonSerialization['tags']),
      minSize: jsonSerialization['minSize'] as int?,
      maxSize: jsonSerialization['maxSize'] as int?,
    );
  }

  DateTime? dateFrom;

  DateTime? dateTo;

  List<String>? fileTypes;

  List<String>? tags;

  int? minSize;

  int? maxSize;

  /// Returns a shallow copy of this [SearchFilters]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SearchFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? fileTypes,
    List<String>? tags,
    int? minSize,
    int? maxSize,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SearchFilters',
      if (dateFrom != null) 'dateFrom': dateFrom?.toJson(),
      if (dateTo != null) 'dateTo': dateTo?.toJson(),
      if (fileTypes != null) 'fileTypes': fileTypes?.toJson(),
      if (tags != null) 'tags': tags?.toJson(),
      if (minSize != null) 'minSize': minSize,
      if (maxSize != null) 'maxSize': maxSize,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SearchFiltersImpl extends SearchFilters {
  _SearchFiltersImpl({
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? fileTypes,
    List<String>? tags,
    int? minSize,
    int? maxSize,
  }) : super._(
         dateFrom: dateFrom,
         dateTo: dateTo,
         fileTypes: fileTypes,
         tags: tags,
         minSize: minSize,
         maxSize: maxSize,
       );

  /// Returns a shallow copy of this [SearchFilters]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SearchFilters copyWith({
    Object? dateFrom = _Undefined,
    Object? dateTo = _Undefined,
    Object? fileTypes = _Undefined,
    Object? tags = _Undefined,
    Object? minSize = _Undefined,
    Object? maxSize = _Undefined,
  }) {
    return SearchFilters(
      dateFrom: dateFrom is DateTime? ? dateFrom : this.dateFrom,
      dateTo: dateTo is DateTime? ? dateTo : this.dateTo,
      fileTypes: fileTypes is List<String>?
          ? fileTypes
          : this.fileTypes?.map((e0) => e0).toList(),
      tags: tags is List<String>? ? tags : this.tags?.map((e0) => e0).toList(),
      minSize: minSize is int? ? minSize : this.minSize,
      maxSize: maxSize is int? ? maxSize : this.maxSize,
    );
  }
}
