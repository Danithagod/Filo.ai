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

abstract class IndexingProgress
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  IndexingProgress._({
    required this.jobId,
    required this.status,
    required this.totalFiles,
    required this.processedFiles,
    required this.failedFiles,
    required this.skippedFiles,
    required this.progressPercent,
    this.estimatedSecondsRemaining,
    this.currentFile,
    required this.timestamp,
  });

  factory IndexingProgress({
    required int jobId,
    required String status,
    required int totalFiles,
    required int processedFiles,
    required int failedFiles,
    required int skippedFiles,
    required double progressPercent,
    int? estimatedSecondsRemaining,
    String? currentFile,
    required DateTime timestamp,
  }) = _IndexingProgressImpl;

  factory IndexingProgress.fromJson(Map<String, dynamic> jsonSerialization) {
    return IndexingProgress(
      jobId: jsonSerialization['jobId'] as int,
      status: jsonSerialization['status'] as String,
      totalFiles: jsonSerialization['totalFiles'] as int,
      processedFiles: jsonSerialization['processedFiles'] as int,
      failedFiles: jsonSerialization['failedFiles'] as int,
      skippedFiles: jsonSerialization['skippedFiles'] as int,
      progressPercent: (jsonSerialization['progressPercent'] as num).toDouble(),
      estimatedSecondsRemaining:
          jsonSerialization['estimatedSecondsRemaining'] as int?,
      currentFile: jsonSerialization['currentFile'] as String?,
      timestamp: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['timestamp'],
      ),
    );
  }

  /// Job ID being tracked
  int jobId;

  /// Current status (running, completed, failed)
  String status;

  /// Total files to process
  int totalFiles;

  /// Files processed successfully
  int processedFiles;

  /// Files that failed processing
  int failedFiles;

  /// Files skipped (unchanged/cached)
  int skippedFiles;

  /// Progress percentage (0-100)
  double progressPercent;

  /// Estimated seconds remaining
  int? estimatedSecondsRemaining;

  /// Current file being processed (if any)
  String? currentFile;

  /// Timestamp of this update
  DateTime timestamp;

  /// Returns a shallow copy of this [IndexingProgress]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IndexingProgress copyWith({
    int? jobId,
    String? status,
    int? totalFiles,
    int? processedFiles,
    int? failedFiles,
    int? skippedFiles,
    double? progressPercent,
    int? estimatedSecondsRemaining,
    String? currentFile,
    DateTime? timestamp,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IndexingProgress',
      'jobId': jobId,
      'status': status,
      'totalFiles': totalFiles,
      'processedFiles': processedFiles,
      'failedFiles': failedFiles,
      'skippedFiles': skippedFiles,
      'progressPercent': progressPercent,
      if (estimatedSecondsRemaining != null)
        'estimatedSecondsRemaining': estimatedSecondsRemaining,
      if (currentFile != null) 'currentFile': currentFile,
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IndexingProgress',
      'jobId': jobId,
      'status': status,
      'totalFiles': totalFiles,
      'processedFiles': processedFiles,
      'failedFiles': failedFiles,
      'skippedFiles': skippedFiles,
      'progressPercent': progressPercent,
      if (estimatedSecondsRemaining != null)
        'estimatedSecondsRemaining': estimatedSecondsRemaining,
      if (currentFile != null) 'currentFile': currentFile,
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IndexingProgressImpl extends IndexingProgress {
  _IndexingProgressImpl({
    required int jobId,
    required String status,
    required int totalFiles,
    required int processedFiles,
    required int failedFiles,
    required int skippedFiles,
    required double progressPercent,
    int? estimatedSecondsRemaining,
    String? currentFile,
    required DateTime timestamp,
  }) : super._(
         jobId: jobId,
         status: status,
         totalFiles: totalFiles,
         processedFiles: processedFiles,
         failedFiles: failedFiles,
         skippedFiles: skippedFiles,
         progressPercent: progressPercent,
         estimatedSecondsRemaining: estimatedSecondsRemaining,
         currentFile: currentFile,
         timestamp: timestamp,
       );

  /// Returns a shallow copy of this [IndexingProgress]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IndexingProgress copyWith({
    int? jobId,
    String? status,
    int? totalFiles,
    int? processedFiles,
    int? failedFiles,
    int? skippedFiles,
    double? progressPercent,
    Object? estimatedSecondsRemaining = _Undefined,
    Object? currentFile = _Undefined,
    DateTime? timestamp,
  }) {
    return IndexingProgress(
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      totalFiles: totalFiles ?? this.totalFiles,
      processedFiles: processedFiles ?? this.processedFiles,
      failedFiles: failedFiles ?? this.failedFiles,
      skippedFiles: skippedFiles ?? this.skippedFiles,
      progressPercent: progressPercent ?? this.progressPercent,
      estimatedSecondsRemaining: estimatedSecondsRemaining is int?
          ? estimatedSecondsRemaining
          : this.estimatedSecondsRemaining,
      currentFile: currentFile is String? ? currentFile : this.currentFile,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
