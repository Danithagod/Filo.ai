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

/// DatabaseStats DTO - database statistics
abstract class DatabaseStats
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DatabaseStats._({
    required this.totalSizeMb,
    required this.fileCount,
    required this.embeddingCount,
    required this.avgEmbeddingTimeMs,
    required this.lastUpdated,
  });

  factory DatabaseStats({
    required double totalSizeMb,
    required int fileCount,
    required int embeddingCount,
    required double avgEmbeddingTimeMs,
    required DateTime lastUpdated,
  }) = _DatabaseStatsImpl;

  factory DatabaseStats.fromJson(Map<String, dynamic> jsonSerialization) {
    return DatabaseStats(
      totalSizeMb: (jsonSerialization['totalSizeMb'] as num).toDouble(),
      fileCount: jsonSerialization['fileCount'] as int,
      embeddingCount: jsonSerialization['embeddingCount'] as int,
      avgEmbeddingTimeMs: (jsonSerialization['avgEmbeddingTimeMs'] as num)
          .toDouble(),
      lastUpdated: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastUpdated'],
      ),
    );
  }

  /// Total size in megabytes
  double totalSizeMb;

  /// Number of indexed files
  int fileCount;

  /// Number of embeddings stored
  int embeddingCount;

  /// Average embedding generation time in milliseconds
  double avgEmbeddingTimeMs;

  /// Last updated timestamp
  DateTime lastUpdated;

  /// Returns a shallow copy of this [DatabaseStats]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DatabaseStats copyWith({
    double? totalSizeMb,
    int? fileCount,
    int? embeddingCount,
    double? avgEmbeddingTimeMs,
    DateTime? lastUpdated,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DatabaseStats',
      'totalSizeMb': totalSizeMb,
      'fileCount': fileCount,
      'embeddingCount': embeddingCount,
      'avgEmbeddingTimeMs': avgEmbeddingTimeMs,
      'lastUpdated': lastUpdated.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DatabaseStats',
      'totalSizeMb': totalSizeMb,
      'fileCount': fileCount,
      'embeddingCount': embeddingCount,
      'avgEmbeddingTimeMs': avgEmbeddingTimeMs,
      'lastUpdated': lastUpdated.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DatabaseStatsImpl extends DatabaseStats {
  _DatabaseStatsImpl({
    required double totalSizeMb,
    required int fileCount,
    required int embeddingCount,
    required double avgEmbeddingTimeMs,
    required DateTime lastUpdated,
  }) : super._(
         totalSizeMb: totalSizeMb,
         fileCount: fileCount,
         embeddingCount: embeddingCount,
         avgEmbeddingTimeMs: avgEmbeddingTimeMs,
         lastUpdated: lastUpdated,
       );

  /// Returns a shallow copy of this [DatabaseStats]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DatabaseStats copyWith({
    double? totalSizeMb,
    int? fileCount,
    int? embeddingCount,
    double? avgEmbeddingTimeMs,
    DateTime? lastUpdated,
  }) {
    return DatabaseStats(
      totalSizeMb: totalSizeMb ?? this.totalSizeMb,
      fileCount: fileCount ?? this.fileCount,
      embeddingCount: embeddingCount ?? this.embeddingCount,
      avgEmbeddingTimeMs: avgEmbeddingTimeMs ?? this.avgEmbeddingTimeMs,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
