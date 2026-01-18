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
import 'error_category_count.dart' as _i2;
import 'package:semantic_butler_client/src/protocol/protocol.dart' as _i3;

/// ErrorStats model - aggregated error statistics
abstract class ErrorStats implements _i1.SerializableModel {
  ErrorStats._({
    required this.totalErrors,
    required this.byCategory,
    this.timeRange,
    this.jobId,
    required this.generatedAt,
  });

  factory ErrorStats({
    required int totalErrors,
    required List<_i2.ErrorCategoryCount> byCategory,
    String? timeRange,
    int? jobId,
    required DateTime generatedAt,
  }) = _ErrorStatsImpl;

  factory ErrorStats.fromJson(Map<String, dynamic> jsonSerialization) {
    return ErrorStats(
      totalErrors: jsonSerialization['totalErrors'] as int,
      byCategory: _i3.Protocol().deserialize<List<_i2.ErrorCategoryCount>>(
        jsonSerialization['byCategory'],
      ),
      timeRange: jsonSerialization['timeRange'] as String?,
      jobId: jsonSerialization['jobId'] as int?,
      generatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['generatedAt'],
      ),
    );
  }

  /// Total number of errors
  int totalErrors;

  /// Breakdown by error category
  List<_i2.ErrorCategoryCount> byCategory;

  /// Time range filter applied (e.g., "24h", "7d", "30d", "all")
  String? timeRange;

  /// Optional job ID filter applied
  int? jobId;

  /// When these stats were generated
  DateTime generatedAt;

  /// Returns a shallow copy of this [ErrorStats]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ErrorStats copyWith({
    int? totalErrors,
    List<_i2.ErrorCategoryCount>? byCategory,
    String? timeRange,
    int? jobId,
    DateTime? generatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ErrorStats',
      'totalErrors': totalErrors,
      'byCategory': byCategory.toJson(valueToJson: (v) => v.toJson()),
      if (timeRange != null) 'timeRange': timeRange,
      if (jobId != null) 'jobId': jobId,
      'generatedAt': generatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ErrorStatsImpl extends ErrorStats {
  _ErrorStatsImpl({
    required int totalErrors,
    required List<_i2.ErrorCategoryCount> byCategory,
    String? timeRange,
    int? jobId,
    required DateTime generatedAt,
  }) : super._(
         totalErrors: totalErrors,
         byCategory: byCategory,
         timeRange: timeRange,
         jobId: jobId,
         generatedAt: generatedAt,
       );

  /// Returns a shallow copy of this [ErrorStats]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ErrorStats copyWith({
    int? totalErrors,
    List<_i2.ErrorCategoryCount>? byCategory,
    Object? timeRange = _Undefined,
    Object? jobId = _Undefined,
    DateTime? generatedAt,
  }) {
    return ErrorStats(
      totalErrors: totalErrors ?? this.totalErrors,
      byCategory:
          byCategory ?? this.byCategory.map((e0) => e0.copyWith()).toList(),
      timeRange: timeRange is String? ? timeRange : this.timeRange,
      jobId: jobId is int? ? jobId : this.jobId,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
