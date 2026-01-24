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
import 'file_operation_result.dart' as _i2;
import 'package:semantic_butler_server/src/generated/protocol.dart' as _i3;

/// Result of an organization action
abstract class OrganizationActionResult
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  OrganizationActionResult._({
    required this.success,
    required this.actionType,
    required this.filesProcessed,
    required this.successCount,
    required this.failureCount,
    required this.spaceSavedBytes,
    required this.results,
    this.error,
    this.isDryRun,
  });

  factory OrganizationActionResult({
    required bool success,
    required String actionType,
    required int filesProcessed,
    required int successCount,
    required int failureCount,
    required int spaceSavedBytes,
    required List<_i2.FileOperationResult> results,
    String? error,
    bool? isDryRun,
  }) = _OrganizationActionResultImpl;

  factory OrganizationActionResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return OrganizationActionResult(
      success: jsonSerialization['success'] as bool,
      actionType: jsonSerialization['actionType'] as String,
      filesProcessed: jsonSerialization['filesProcessed'] as int,
      successCount: jsonSerialization['successCount'] as int,
      failureCount: jsonSerialization['failureCount'] as int,
      spaceSavedBytes: jsonSerialization['spaceSavedBytes'] as int,
      results: _i3.Protocol().deserialize<List<_i2.FileOperationResult>>(
        jsonSerialization['results'],
      ),
      error: jsonSerialization['error'] as String?,
      isDryRun: jsonSerialization['isDryRun'] as bool?,
    );
  }

  /// Whether the action succeeded
  bool success;

  /// Type of action that was performed
  String actionType;

  /// Number of files processed
  int filesProcessed;

  /// Number of files that succeeded
  int successCount;

  /// Number of files that failed
  int failureCount;

  /// Space saved in bytes (for duplicate removal)
  int spaceSavedBytes;

  /// Individual file operation results
  List<_i2.FileOperationResult> results;

  /// Error message if the overall action failed
  String? error;

  /// Whether this was a dry-run preview
  bool? isDryRun;

  /// Returns a shallow copy of this [OrganizationActionResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OrganizationActionResult copyWith({
    bool? success,
    String? actionType,
    int? filesProcessed,
    int? successCount,
    int? failureCount,
    int? spaceSavedBytes,
    List<_i2.FileOperationResult>? results,
    String? error,
    bool? isDryRun,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OrganizationActionResult',
      'success': success,
      'actionType': actionType,
      'filesProcessed': filesProcessed,
      'successCount': successCount,
      'failureCount': failureCount,
      'spaceSavedBytes': spaceSavedBytes,
      'results': results.toJson(valueToJson: (v) => v.toJson()),
      if (error != null) 'error': error,
      if (isDryRun != null) 'isDryRun': isDryRun,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OrganizationActionResult',
      'success': success,
      'actionType': actionType,
      'filesProcessed': filesProcessed,
      'successCount': successCount,
      'failureCount': failureCount,
      'spaceSavedBytes': spaceSavedBytes,
      'results': results.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (error != null) 'error': error,
      if (isDryRun != null) 'isDryRun': isDryRun,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OrganizationActionResultImpl extends OrganizationActionResult {
  _OrganizationActionResultImpl({
    required bool success,
    required String actionType,
    required int filesProcessed,
    required int successCount,
    required int failureCount,
    required int spaceSavedBytes,
    required List<_i2.FileOperationResult> results,
    String? error,
    bool? isDryRun,
  }) : super._(
         success: success,
         actionType: actionType,
         filesProcessed: filesProcessed,
         successCount: successCount,
         failureCount: failureCount,
         spaceSavedBytes: spaceSavedBytes,
         results: results,
         error: error,
         isDryRun: isDryRun,
       );

  /// Returns a shallow copy of this [OrganizationActionResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OrganizationActionResult copyWith({
    bool? success,
    String? actionType,
    int? filesProcessed,
    int? successCount,
    int? failureCount,
    int? spaceSavedBytes,
    List<_i2.FileOperationResult>? results,
    Object? error = _Undefined,
    Object? isDryRun = _Undefined,
  }) {
    return OrganizationActionResult(
      success: success ?? this.success,
      actionType: actionType ?? this.actionType,
      filesProcessed: filesProcessed ?? this.filesProcessed,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      spaceSavedBytes: spaceSavedBytes ?? this.spaceSavedBytes,
      results: results ?? this.results.map((e0) => e0.copyWith()).toList(),
      error: error is String? ? error : this.error,
      isDryRun: isDryRun is bool? ? isDryRun : this.isDryRun,
    );
  }
}
