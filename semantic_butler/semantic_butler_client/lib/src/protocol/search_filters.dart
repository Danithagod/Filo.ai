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
    this.minCount,
    this.maxCount,
    this.countUnit,
    this.locationPaths,
    this.cursor,
    this.semanticWeight,
    this.keywordWeight,
    this.sessionId,
    this.contentTerms,
  });

  factory SearchFilters({
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? fileTypes,
    List<String>? tags,
    int? minSize,
    int? maxSize,
    int? minCount,
    int? maxCount,
    String? countUnit,
    List<String>? locationPaths,
    String? cursor,
    double? semanticWeight,
    double? keywordWeight,
    String? sessionId,
    List<String>? contentTerms,
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
      minCount: jsonSerialization['minCount'] as int?,
      maxCount: jsonSerialization['maxCount'] as int?,
      countUnit: jsonSerialization['countUnit'] as String?,
      locationPaths: jsonSerialization['locationPaths'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['locationPaths'],
            ),
      cursor: jsonSerialization['cursor'] as String?,
      semanticWeight: (jsonSerialization['semanticWeight'] as num?)?.toDouble(),
      keywordWeight: (jsonSerialization['keywordWeight'] as num?)?.toDouble(),
      sessionId: jsonSerialization['sessionId'] as String?,
      contentTerms: jsonSerialization['contentTerms'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['contentTerms'],
            ),
    );
  }

  DateTime? dateFrom;

  DateTime? dateTo;

  List<String>? fileTypes;

  List<String>? tags;

  int? minSize;

  int? maxSize;

  int? minCount;

  int? maxCount;

  String? countUnit;

  List<String>? locationPaths;

  String? cursor;

  double? semanticWeight;

  double? keywordWeight;

  String? sessionId;

  List<String>? contentTerms;

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
    int? minCount,
    int? maxCount,
    String? countUnit,
    List<String>? locationPaths,
    String? cursor,
    double? semanticWeight,
    double? keywordWeight,
    String? sessionId,
    List<String>? contentTerms,
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
      if (minCount != null) 'minCount': minCount,
      if (maxCount != null) 'maxCount': maxCount,
      if (countUnit != null) 'countUnit': countUnit,
      if (locationPaths != null) 'locationPaths': locationPaths?.toJson(),
      if (cursor != null) 'cursor': cursor,
      if (semanticWeight != null) 'semanticWeight': semanticWeight,
      if (keywordWeight != null) 'keywordWeight': keywordWeight,
      if (sessionId != null) 'sessionId': sessionId,
      if (contentTerms != null) 'contentTerms': contentTerms?.toJson(),
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
    int? minCount,
    int? maxCount,
    String? countUnit,
    List<String>? locationPaths,
    String? cursor,
    double? semanticWeight,
    double? keywordWeight,
    String? sessionId,
    List<String>? contentTerms,
  }) : super._(
         dateFrom: dateFrom,
         dateTo: dateTo,
         fileTypes: fileTypes,
         tags: tags,
         minSize: minSize,
         maxSize: maxSize,
         minCount: minCount,
         maxCount: maxCount,
         countUnit: countUnit,
         locationPaths: locationPaths,
         cursor: cursor,
         semanticWeight: semanticWeight,
         keywordWeight: keywordWeight,
         sessionId: sessionId,
         contentTerms: contentTerms,
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
    Object? minCount = _Undefined,
    Object? maxCount = _Undefined,
    Object? countUnit = _Undefined,
    Object? locationPaths = _Undefined,
    Object? cursor = _Undefined,
    Object? semanticWeight = _Undefined,
    Object? keywordWeight = _Undefined,
    Object? sessionId = _Undefined,
    Object? contentTerms = _Undefined,
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
      minCount: minCount is int? ? minCount : this.minCount,
      maxCount: maxCount is int? ? maxCount : this.maxCount,
      countUnit: countUnit is String? ? countUnit : this.countUnit,
      locationPaths: locationPaths is List<String>?
          ? locationPaths
          : this.locationPaths?.map((e0) => e0).toList(),
      cursor: cursor is String? ? cursor : this.cursor,
      semanticWeight: semanticWeight is double?
          ? semanticWeight
          : this.semanticWeight,
      keywordWeight: keywordWeight is double?
          ? keywordWeight
          : this.keywordWeight,
      sessionId: sessionId is String? ? sessionId : this.sessionId,
      contentTerms: contentTerms is List<String>?
          ? contentTerms
          : this.contentTerms?.map((e0) => e0).toList(),
    );
  }
}
