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
import 'package:semantic_butler_server/src/generated/protocol.dart' as _i2;

/// IndexHealthReport - comprehensive health report for the file index
abstract class IndexHealthReport
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  IndexHealthReport._({
    required this.generatedAt,
    required this.healthScore,
    required this.orphanedFiles,
    required this.staleEntryCount,
    required this.duplicateGroupCount,
    required this.duplicateFileCount,
    required this.totalIndexed,
    required this.totalPending,
    required this.totalFailed,
    required this.totalEmbeddings,
    required this.averageFileSizeBytes,
    required this.missingEmbeddingsCount,
    required this.corruptedDataCount,
  });

  factory IndexHealthReport({
    required DateTime generatedAt,
    required double healthScore,
    required List<String> orphanedFiles,
    required int staleEntryCount,
    required int duplicateGroupCount,
    required int duplicateFileCount,
    required int totalIndexed,
    required int totalPending,
    required int totalFailed,
    required int totalEmbeddings,
    required int averageFileSizeBytes,
    required int missingEmbeddingsCount,
    required int corruptedDataCount,
  }) = _IndexHealthReportImpl;

  factory IndexHealthReport.fromJson(Map<String, dynamic> jsonSerialization) {
    return IndexHealthReport(
      generatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['generatedAt'],
      ),
      healthScore: (jsonSerialization['healthScore'] as num).toDouble(),
      orphanedFiles: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['orphanedFiles'],
      ),
      staleEntryCount: jsonSerialization['staleEntryCount'] as int,
      duplicateGroupCount: jsonSerialization['duplicateGroupCount'] as int,
      duplicateFileCount: jsonSerialization['duplicateFileCount'] as int,
      totalIndexed: jsonSerialization['totalIndexed'] as int,
      totalPending: jsonSerialization['totalPending'] as int,
      totalFailed: jsonSerialization['totalFailed'] as int,
      totalEmbeddings: jsonSerialization['totalEmbeddings'] as int,
      averageFileSizeBytes: jsonSerialization['averageFileSizeBytes'] as int,
      missingEmbeddingsCount:
          jsonSerialization['missingEmbeddingsCount'] as int,
      corruptedDataCount: jsonSerialization['corruptedDataCount'] as int,
    );
  }

  /// When the report was generated
  DateTime generatedAt;

  /// Overall health score (0-100)
  double healthScore;

  /// List of file paths that are indexed but no longer exist on disk
  List<String> orphanedFiles;

  /// Number of stale entries (files not updated in over 6 months)
  int staleEntryCount;

  /// Number of duplicate file groups found
  int duplicateGroupCount;

  /// Total number of duplicate files
  int duplicateFileCount;

  /// Number of indexed files
  int totalIndexed;

  /// Number of files pending indexing
  int totalPending;

  /// Number of failed indexing attempts
  int totalFailed;

  /// Number of embeddings stored
  int totalEmbeddings;

  /// Average file size in bytes
  int averageFileSizeBytes;

  /// Number of files missing embeddings
  int missingEmbeddingsCount;

  /// Number of potentially corrupted data entries
  int corruptedDataCount;

  /// Returns a shallow copy of this [IndexHealthReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IndexHealthReport copyWith({
    DateTime? generatedAt,
    double? healthScore,
    List<String>? orphanedFiles,
    int? staleEntryCount,
    int? duplicateGroupCount,
    int? duplicateFileCount,
    int? totalIndexed,
    int? totalPending,
    int? totalFailed,
    int? totalEmbeddings,
    int? averageFileSizeBytes,
    int? missingEmbeddingsCount,
    int? corruptedDataCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IndexHealthReport',
      'generatedAt': generatedAt.toJson(),
      'healthScore': healthScore,
      'orphanedFiles': orphanedFiles.toJson(),
      'staleEntryCount': staleEntryCount,
      'duplicateGroupCount': duplicateGroupCount,
      'duplicateFileCount': duplicateFileCount,
      'totalIndexed': totalIndexed,
      'totalPending': totalPending,
      'totalFailed': totalFailed,
      'totalEmbeddings': totalEmbeddings,
      'averageFileSizeBytes': averageFileSizeBytes,
      'missingEmbeddingsCount': missingEmbeddingsCount,
      'corruptedDataCount': corruptedDataCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IndexHealthReport',
      'generatedAt': generatedAt.toJson(),
      'healthScore': healthScore,
      'orphanedFiles': orphanedFiles.toJson(),
      'staleEntryCount': staleEntryCount,
      'duplicateGroupCount': duplicateGroupCount,
      'duplicateFileCount': duplicateFileCount,
      'totalIndexed': totalIndexed,
      'totalPending': totalPending,
      'totalFailed': totalFailed,
      'totalEmbeddings': totalEmbeddings,
      'averageFileSizeBytes': averageFileSizeBytes,
      'missingEmbeddingsCount': missingEmbeddingsCount,
      'corruptedDataCount': corruptedDataCount,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _IndexHealthReportImpl extends IndexHealthReport {
  _IndexHealthReportImpl({
    required DateTime generatedAt,
    required double healthScore,
    required List<String> orphanedFiles,
    required int staleEntryCount,
    required int duplicateGroupCount,
    required int duplicateFileCount,
    required int totalIndexed,
    required int totalPending,
    required int totalFailed,
    required int totalEmbeddings,
    required int averageFileSizeBytes,
    required int missingEmbeddingsCount,
    required int corruptedDataCount,
  }) : super._(
         generatedAt: generatedAt,
         healthScore: healthScore,
         orphanedFiles: orphanedFiles,
         staleEntryCount: staleEntryCount,
         duplicateGroupCount: duplicateGroupCount,
         duplicateFileCount: duplicateFileCount,
         totalIndexed: totalIndexed,
         totalPending: totalPending,
         totalFailed: totalFailed,
         totalEmbeddings: totalEmbeddings,
         averageFileSizeBytes: averageFileSizeBytes,
         missingEmbeddingsCount: missingEmbeddingsCount,
         corruptedDataCount: corruptedDataCount,
       );

  /// Returns a shallow copy of this [IndexHealthReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IndexHealthReport copyWith({
    DateTime? generatedAt,
    double? healthScore,
    List<String>? orphanedFiles,
    int? staleEntryCount,
    int? duplicateGroupCount,
    int? duplicateFileCount,
    int? totalIndexed,
    int? totalPending,
    int? totalFailed,
    int? totalEmbeddings,
    int? averageFileSizeBytes,
    int? missingEmbeddingsCount,
    int? corruptedDataCount,
  }) {
    return IndexHealthReport(
      generatedAt: generatedAt ?? this.generatedAt,
      healthScore: healthScore ?? this.healthScore,
      orphanedFiles:
          orphanedFiles ?? this.orphanedFiles.map((e0) => e0).toList(),
      staleEntryCount: staleEntryCount ?? this.staleEntryCount,
      duplicateGroupCount: duplicateGroupCount ?? this.duplicateGroupCount,
      duplicateFileCount: duplicateFileCount ?? this.duplicateFileCount,
      totalIndexed: totalIndexed ?? this.totalIndexed,
      totalPending: totalPending ?? this.totalPending,
      totalFailed: totalFailed ?? this.totalFailed,
      totalEmbeddings: totalEmbeddings ?? this.totalEmbeddings,
      averageFileSizeBytes: averageFileSizeBytes ?? this.averageFileSizeBytes,
      missingEmbeddingsCount:
          missingEmbeddingsCount ?? this.missingEmbeddingsCount,
      corruptedDataCount: corruptedDataCount ?? this.corruptedDataCount,
    );
  }
}
