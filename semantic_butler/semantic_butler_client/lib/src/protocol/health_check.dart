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

/// Health check response model
abstract class HealthCheck implements _i1.SerializableModel {
  HealthCheck._({
    required this.status,
    required this.databaseHealthy,
    required this.pgvectorHealthy,
    required this.watcherHealthy,
    required this.activeWatcherCount,
    this.cacheHitRate,
    this.apiResponseTimeMs,
    required this.checkedAt,
    this.watcherDetails,
  });

  factory HealthCheck({
    required String status,
    required bool databaseHealthy,
    required bool pgvectorHealthy,
    required bool watcherHealthy,
    required int activeWatcherCount,
    double? cacheHitRate,
    double? apiResponseTimeMs,
    required DateTime checkedAt,
    String? watcherDetails,
  }) = _HealthCheckImpl;

  factory HealthCheck.fromJson(Map<String, dynamic> jsonSerialization) {
    return HealthCheck(
      status: jsonSerialization['status'] as String,
      databaseHealthy: jsonSerialization['databaseHealthy'] as bool,
      pgvectorHealthy: jsonSerialization['pgvectorHealthy'] as bool,
      watcherHealthy: jsonSerialization['watcherHealthy'] as bool,
      activeWatcherCount: jsonSerialization['activeWatcherCount'] as int,
      cacheHitRate: (jsonSerialization['cacheHitRate'] as num?)?.toDouble(),
      apiResponseTimeMs: (jsonSerialization['apiResponseTimeMs'] as num?)
          ?.toDouble(),
      checkedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['checkedAt'],
      ),
      watcherDetails: jsonSerialization['watcherDetails'] as String?,
    );
  }

  /// Overall system status: healthy, degraded, unhealthy
  String status;

  /// Database connectivity status
  bool databaseHealthy;

  /// pgvector extension availability
  bool pgvectorHealthy;

  /// File watcher service status
  bool watcherHealthy;

  /// Number of active file watchers
  int activeWatcherCount;

  /// Cache hit rate percentage (0-100)
  double? cacheHitRate;

  /// Average API response time in milliseconds
  double? apiResponseTimeMs;

  /// Timestamp of health check
  DateTime checkedAt;

  /// Additional details about watcher health
  String? watcherDetails;

  /// Returns a shallow copy of this [HealthCheck]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  HealthCheck copyWith({
    String? status,
    bool? databaseHealthy,
    bool? pgvectorHealthy,
    bool? watcherHealthy,
    int? activeWatcherCount,
    double? cacheHitRate,
    double? apiResponseTimeMs,
    DateTime? checkedAt,
    String? watcherDetails,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'HealthCheck',
      'status': status,
      'databaseHealthy': databaseHealthy,
      'pgvectorHealthy': pgvectorHealthy,
      'watcherHealthy': watcherHealthy,
      'activeWatcherCount': activeWatcherCount,
      if (cacheHitRate != null) 'cacheHitRate': cacheHitRate,
      if (apiResponseTimeMs != null) 'apiResponseTimeMs': apiResponseTimeMs,
      'checkedAt': checkedAt.toJson(),
      if (watcherDetails != null) 'watcherDetails': watcherDetails,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _HealthCheckImpl extends HealthCheck {
  _HealthCheckImpl({
    required String status,
    required bool databaseHealthy,
    required bool pgvectorHealthy,
    required bool watcherHealthy,
    required int activeWatcherCount,
    double? cacheHitRate,
    double? apiResponseTimeMs,
    required DateTime checkedAt,
    String? watcherDetails,
  }) : super._(
         status: status,
         databaseHealthy: databaseHealthy,
         pgvectorHealthy: pgvectorHealthy,
         watcherHealthy: watcherHealthy,
         activeWatcherCount: activeWatcherCount,
         cacheHitRate: cacheHitRate,
         apiResponseTimeMs: apiResponseTimeMs,
         checkedAt: checkedAt,
         watcherDetails: watcherDetails,
       );

  /// Returns a shallow copy of this [HealthCheck]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  HealthCheck copyWith({
    String? status,
    bool? databaseHealthy,
    bool? pgvectorHealthy,
    bool? watcherHealthy,
    int? activeWatcherCount,
    Object? cacheHitRate = _Undefined,
    Object? apiResponseTimeMs = _Undefined,
    DateTime? checkedAt,
    Object? watcherDetails = _Undefined,
  }) {
    return HealthCheck(
      status: status ?? this.status,
      databaseHealthy: databaseHealthy ?? this.databaseHealthy,
      pgvectorHealthy: pgvectorHealthy ?? this.pgvectorHealthy,
      watcherHealthy: watcherHealthy ?? this.watcherHealthy,
      activeWatcherCount: activeWatcherCount ?? this.activeWatcherCount,
      cacheHitRate: cacheHitRate is double? ? cacheHitRate : this.cacheHitRate,
      apiResponseTimeMs: apiResponseTimeMs is double?
          ? apiResponseTimeMs
          : this.apiResponseTimeMs,
      checkedAt: checkedAt ?? this.checkedAt,
      watcherDetails: watcherDetails is String?
          ? watcherDetails
          : this.watcherDetails,
    );
  }
}
