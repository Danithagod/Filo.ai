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

/// IndexingJob model - tracks indexing jobs/tasks
abstract class IndexingJob implements _i1.SerializableModel {
  IndexingJob._({
    this.id,
    required this.folderPath,
    required this.status,
    required this.totalFiles,
    required this.processedFiles,
    required this.failedFiles,
    required this.skippedFiles,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.errorCategory,
  });

  factory IndexingJob({
    int? id,
    required String folderPath,
    required String status,
    required int totalFiles,
    required int processedFiles,
    required int failedFiles,
    required int skippedFiles,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    String? errorCategory,
  }) = _IndexingJobImpl;

  factory IndexingJob.fromJson(Map<String, dynamic> jsonSerialization) {
    return IndexingJob(
      id: jsonSerialization['id'] as int?,
      folderPath: jsonSerialization['folderPath'] as String,
      status: jsonSerialization['status'] as String,
      totalFiles: jsonSerialization['totalFiles'] as int,
      processedFiles: jsonSerialization['processedFiles'] as int,
      failedFiles: jsonSerialization['failedFiles'] as int,
      skippedFiles: jsonSerialization['skippedFiles'] as int,
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      errorMessage: jsonSerialization['errorMessage'] as String?,
      errorCategory: jsonSerialization['errorCategory'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Folder path being indexed
  String folderPath;

  /// Job status: queued, running, completed, failed, cancelled
  String status;

  /// Total files found in folder
  int totalFiles;

  /// Number of files processed
  int processedFiles;

  /// Number of files that failed
  int failedFiles;

  /// Number of files skipped (unsupported format)
  int skippedFiles;

  /// When the job started
  DateTime? startedAt;

  /// When the job completed
  DateTime? completedAt;

  /// Error message if job failed
  String? errorMessage;

  /// Error category for failed files
  String? errorCategory;

  /// Returns a shallow copy of this [IndexingJob]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IndexingJob copyWith({
    int? id,
    String? folderPath,
    String? status,
    int? totalFiles,
    int? processedFiles,
    int? failedFiles,
    int? skippedFiles,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    String? errorCategory,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IndexingJob',
      if (id != null) 'id': id,
      'folderPath': folderPath,
      'status': status,
      'totalFiles': totalFiles,
      'processedFiles': processedFiles,
      'failedFiles': failedFiles,
      'skippedFiles': skippedFiles,
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (errorCategory != null) 'errorCategory': errorCategory,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IndexingJobImpl extends IndexingJob {
  _IndexingJobImpl({
    int? id,
    required String folderPath,
    required String status,
    required int totalFiles,
    required int processedFiles,
    required int failedFiles,
    required int skippedFiles,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    String? errorCategory,
  }) : super._(
         id: id,
         folderPath: folderPath,
         status: status,
         totalFiles: totalFiles,
         processedFiles: processedFiles,
         failedFiles: failedFiles,
         skippedFiles: skippedFiles,
         startedAt: startedAt,
         completedAt: completedAt,
         errorMessage: errorMessage,
         errorCategory: errorCategory,
       );

  /// Returns a shallow copy of this [IndexingJob]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IndexingJob copyWith({
    Object? id = _Undefined,
    String? folderPath,
    String? status,
    int? totalFiles,
    int? processedFiles,
    int? failedFiles,
    int? skippedFiles,
    Object? startedAt = _Undefined,
    Object? completedAt = _Undefined,
    Object? errorMessage = _Undefined,
    Object? errorCategory = _Undefined,
  }) {
    return IndexingJob(
      id: id is int? ? id : this.id,
      folderPath: folderPath ?? this.folderPath,
      status: status ?? this.status,
      totalFiles: totalFiles ?? this.totalFiles,
      processedFiles: processedFiles ?? this.processedFiles,
      failedFiles: failedFiles ?? this.failedFiles,
      skippedFiles: skippedFiles ?? this.skippedFiles,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      errorCategory: errorCategory is String?
          ? errorCategory
          : this.errorCategory,
    );
  }
}
