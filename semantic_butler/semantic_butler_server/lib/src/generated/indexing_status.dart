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

/// IndexingStatus DTO - current indexing status
abstract class IndexingStatus
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  IndexingStatus._({
    required this.totalDocuments,
    required this.indexedDocuments,
    required this.pendingDocuments,
    required this.failedDocuments,
    required this.activeJobs,
    required this.databaseSizeMb,
    this.lastActivity,
  });

  factory IndexingStatus({
    required int totalDocuments,
    required int indexedDocuments,
    required int pendingDocuments,
    required int failedDocuments,
    required int activeJobs,
    required double databaseSizeMb,
    DateTime? lastActivity,
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
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IndexingStatus',
      'totalDocuments': totalDocuments,
      'indexedDocuments': indexedDocuments,
      'pendingDocuments': pendingDocuments,
      'failedDocuments': failedDocuments,
      'activeJobs': activeJobs,
      'databaseSizeMb': databaseSizeMb,
      if (lastActivity != null) 'lastActivity': lastActivity?.toJson(),
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
  }) : super._(
         totalDocuments: totalDocuments,
         indexedDocuments: indexedDocuments,
         pendingDocuments: pendingDocuments,
         failedDocuments: failedDocuments,
         activeJobs: activeJobs,
         databaseSizeMb: databaseSizeMb,
         lastActivity: lastActivity,
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
    );
  }
}
