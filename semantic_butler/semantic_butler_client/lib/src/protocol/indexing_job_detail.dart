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

/// IndexingJobDetail model - tracks individual file progress within an indexing job
abstract class IndexingJobDetail implements _i1.SerializableModel {
  IndexingJobDetail._({
    this.id,
    required this.jobId,
    required this.filePath,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.errorCategory,
  });

  factory IndexingJobDetail({
    int? id,
    required int jobId,
    required String filePath,
    required String status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    String? errorCategory,
  }) = _IndexingJobDetailImpl;

  factory IndexingJobDetail.fromJson(Map<String, dynamic> jsonSerialization) {
    return IndexingJobDetail(
      id: jsonSerialization['id'] as int?,
      jobId: jsonSerialization['jobId'] as int,
      filePath: jsonSerialization['filePath'] as String,
      status: jsonSerialization['status'] as String,
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

  /// Reference to the parent indexing job
  int jobId;

  /// File path being processed
  String filePath;

  /// Current status: discovered, extracting, summarizing, embedding, complete, skipped, failed
  String status;

  /// When processing started for this file
  DateTime? startedAt;

  /// When processing completed for this file
  DateTime? completedAt;

  /// Error message if processing failed
  String? errorMessage;

  /// Error category if processing failed (e.g., APITimeout, CorruptFile, NetworkError)
  String? errorCategory;

  /// Returns a shallow copy of this [IndexingJobDetail]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IndexingJobDetail copyWith({
    int? id,
    int? jobId,
    String? filePath,
    String? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    String? errorCategory,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IndexingJobDetail',
      if (id != null) 'id': id,
      'jobId': jobId,
      'filePath': filePath,
      'status': status,
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

class _IndexingJobDetailImpl extends IndexingJobDetail {
  _IndexingJobDetailImpl({
    int? id,
    required int jobId,
    required String filePath,
    required String status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    String? errorCategory,
  }) : super._(
         id: id,
         jobId: jobId,
         filePath: filePath,
         status: status,
         startedAt: startedAt,
         completedAt: completedAt,
         errorMessage: errorMessage,
         errorCategory: errorCategory,
       );

  /// Returns a shallow copy of this [IndexingJobDetail]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IndexingJobDetail copyWith({
    Object? id = _Undefined,
    int? jobId,
    String? filePath,
    String? status,
    Object? startedAt = _Undefined,
    Object? completedAt = _Undefined,
    Object? errorMessage = _Undefined,
    Object? errorCategory = _Undefined,
  }) {
    return IndexingJobDetail(
      id: id is int? ? id : this.id,
      jobId: jobId ?? this.jobId,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      errorCategory: errorCategory is String?
          ? errorCategory
          : this.errorCategory,
    );
  }
}
