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
import 'indexing_job.dart' as _i2;
import 'package:semantic_butler_client/src/protocol/protocol.dart' as _i3;

/// IndexingStatus DTO - current indexing status
abstract class IndexingStatus implements _i1.SerializableModel {
  IndexingStatus._({
    required this.totalDocuments,
    required this.indexedDocuments,
    required this.pendingDocuments,
    required this.failedDocuments,
    required this.activeJobs,
    required this.databaseSizeMb,
    this.lastActivity,
    this.recentJobs,
    this.estimatedTimeRemainingSeconds,
    this.cacheHitRate,
  });

  factory IndexingStatus({
    required int totalDocuments,
    required int indexedDocuments,
    required int pendingDocuments,
    required int failedDocuments,
    required int activeJobs,
    required double databaseSizeMb,
    DateTime? lastActivity,
    List<_i2.IndexingJob>? recentJobs,
    int? estimatedTimeRemainingSeconds,
    double? cacheHitRate,
  }) = _IndexingStatusImpl;

  factory IndexingStatus.fromJson(Map<String, dynamic> jsonSerialization) {
    return IndexingStatus(
      totalDocuments: jsonSerialization['totalDocuments'] as int,
      indexedDocuments: jsonSerialization['indexedDocuments'] as int,
      pendingDocuments: jsonSerialization['pendingDocuments'] as int,
      failedDocuments: jsonSerialization['failedDocuments'] as int,
      activeJobs: jsonSerialization['activeJobs'] as int,
      databaseSizeMb: (jsonSerialization['databaseSizeMb'] as num).toDouble(),
      lastActivity: jsonSerialization['lastActivity'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastActivity'],
            ),
      recentJobs: jsonSerialization['recentJobs'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.IndexingJob>>(
              jsonSerialization['recentJobs'],
            ),
      estimatedTimeRemainingSeconds:
          jsonSerialization['estimatedTimeRemainingSeconds'] as int?,
      cacheHitRate: (jsonSerialization['cacheHitRate'] as num?)?.toDouble(),
    );
  }

  /// Total documents in database
  int totalDocuments;

  /// Successfully indexed documents
  int indexedDocuments;

  /// Documents pending indexing
  int pendingDocuments;

  /// Failed documents
  int failedDocuments;

  /// Currently running jobs
  int activeJobs;

  /// Database size in megabytes
  double databaseSizeMb;

  /// Last indexing activity timestamp
  DateTime? lastActivity;

  List<_i2.IndexingJob>? recentJobs;

  /// Estimated time remaining for current indexing in seconds
  int? estimatedTimeRemainingSeconds;

  /// Cache hit rate (0.0 to 1.0)
  double? cacheHitRate;

  /// Returns a shallow copy of this [IndexingStatus]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IndexingStatus copyWith({
    int? totalDocuments,
    int? indexedDocuments,
    int? pendingDocuments,
    int? failedDocuments,
    int? activeJobs,
    double? databaseSizeMb,
    DateTime? lastActivity,
    List<_i2.IndexingJob>? recentJobs,
    int? estimatedTimeRemainingSeconds,
    double? cacheHitRate,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IndexingStatus',
      'totalDocuments': totalDocuments,
      'indexedDocuments': indexedDocuments,
      'pendingDocuments': pendingDocuments,
      'failedDocuments': failedDocuments,
      'activeJobs': activeJobs,
      'databaseSizeMb': databaseSizeMb,
      if (lastActivity != null) 'lastActivity': lastActivity?.toJson(),
      if (recentJobs != null)
        'recentJobs': recentJobs?.toJson(valueToJson: (v) => v.toJson()),
      if (estimatedTimeRemainingSeconds != null)
        'estimatedTimeRemainingSeconds': estimatedTimeRemainingSeconds,
      if (cacheHitRate != null) 'cacheHitRate': cacheHitRate,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IndexingStatusImpl extends IndexingStatus {
  _IndexingStatusImpl({
    required int totalDocuments,
    required int indexedDocuments,
    required int pendingDocuments,
    required int failedDocuments,
    required int activeJobs,
    required double databaseSizeMb,
    DateTime? lastActivity,
    List<_i2.IndexingJob>? recentJobs,
    int? estimatedTimeRemainingSeconds,
    double? cacheHitRate,
  }) : super._(
         totalDocuments: totalDocuments,
         indexedDocuments: indexedDocuments,
         pendingDocuments: pendingDocuments,
         failedDocuments: failedDocuments,
         activeJobs: activeJobs,
         databaseSizeMb: databaseSizeMb,
         lastActivity: lastActivity,
         recentJobs: recentJobs,
         estimatedTimeRemainingSeconds: estimatedTimeRemainingSeconds,
         cacheHitRate: cacheHitRate,
       );

  /// Returns a shallow copy of this [IndexingStatus]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IndexingStatus copyWith({
    int? totalDocuments,
    int? indexedDocuments,
    int? pendingDocuments,
    int? failedDocuments,
    int? activeJobs,
    double? databaseSizeMb,
    Object? lastActivity = _Undefined,
    Object? recentJobs = _Undefined,
    Object? estimatedTimeRemainingSeconds = _Undefined,
    Object? cacheHitRate = _Undefined,
  }) {
    return IndexingStatus(
      totalDocuments: totalDocuments ?? this.totalDocuments,
      indexedDocuments: indexedDocuments ?? this.indexedDocuments,
      pendingDocuments: pendingDocuments ?? this.pendingDocuments,
      failedDocuments: failedDocuments ?? this.failedDocuments,
      activeJobs: activeJobs ?? this.activeJobs,
      databaseSizeMb: databaseSizeMb ?? this.databaseSizeMb,
      lastActivity: lastActivity is DateTime?
          ? lastActivity
          : this.lastActivity,
      recentJobs: recentJobs is List<_i2.IndexingJob>?
          ? recentJobs
          : this.recentJobs?.map((e0) => e0.copyWith()).toList(),
      estimatedTimeRemainingSeconds: estimatedTimeRemainingSeconds is int?
          ? estimatedTimeRemainingSeconds
          : this.estimatedTimeRemainingSeconds,
      cacheHitRate: cacheHitRate is double? ? cacheHitRate : this.cacheHitRate,
    );
  }
}
