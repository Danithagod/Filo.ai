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
import 'organization_action_result.dart' as _i2;
import 'package:semantic_butler_client/src/protocol/protocol.dart' as _i3;

/// Result of a batch organization operation
abstract class BatchOrganizationResult implements _i1.SerializableModel {
  BatchOrganizationResult._({
    required this.success,
    required this.totalActions,
    required this.successCount,
    required this.failureCount,
    required this.results,
    this.error,
    this.wasRolledBack,
  });

  factory BatchOrganizationResult({
    required bool success,
    required int totalActions,
    required int successCount,
    required int failureCount,
    required List<_i2.OrganizationActionResult> results,
    String? error,
    bool? wasRolledBack,
  }) = _BatchOrganizationResultImpl;

  factory BatchOrganizationResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BatchOrganizationResult(
      success: jsonSerialization['success'] as bool,
      totalActions: jsonSerialization['totalActions'] as int,
      successCount: jsonSerialization['successCount'] as int,
      failureCount: jsonSerialization['failureCount'] as int,
      results: _i3.Protocol().deserialize<List<_i2.OrganizationActionResult>>(
        jsonSerialization['results'],
      ),
      error: jsonSerialization['error'] as String?,
      wasRolledBack: jsonSerialization['wasRolledBack'] as bool?,
    );
  }

  /// Whether the entire batch succeeded
  bool success;

  /// Total number of actions
  int totalActions;

  /// Number of actions that succeeded
  int successCount;

  /// Number of actions that failed
  int failureCount;

  /// Individual action results
  List<_i2.OrganizationActionResult> results;

  /// Overall error message
  String? error;

  /// Whether operations were rolled back
  bool? wasRolledBack;

  /// Returns a shallow copy of this [BatchOrganizationResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BatchOrganizationResult copyWith({
    bool? success,
    int? totalActions,
    int? successCount,
    int? failureCount,
    List<_i2.OrganizationActionResult>? results,
    String? error,
    bool? wasRolledBack,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BatchOrganizationResult',
      'success': success,
      'totalActions': totalActions,
      'successCount': successCount,
      'failureCount': failureCount,
      'results': results.toJson(valueToJson: (v) => v.toJson()),
      if (error != null) 'error': error,
      if (wasRolledBack != null) 'wasRolledBack': wasRolledBack,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BatchOrganizationResultImpl extends BatchOrganizationResult {
  _BatchOrganizationResultImpl({
    required bool success,
    required int totalActions,
    required int successCount,
    required int failureCount,
    required List<_i2.OrganizationActionResult> results,
    String? error,
    bool? wasRolledBack,
  }) : super._(
         success: success,
         totalActions: totalActions,
         successCount: successCount,
         failureCount: failureCount,
         results: results,
         error: error,
         wasRolledBack: wasRolledBack,
       );

  /// Returns a shallow copy of this [BatchOrganizationResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BatchOrganizationResult copyWith({
    bool? success,
    int? totalActions,
    int? successCount,
    int? failureCount,
    List<_i2.OrganizationActionResult>? results,
    Object? error = _Undefined,
    Object? wasRolledBack = _Undefined,
  }) {
    return BatchOrganizationResult(
      success: success ?? this.success,
      totalActions: totalActions ?? this.totalActions,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      results: results ?? this.results.map((e0) => e0.copyWith()).toList(),
      error: error is String? ? error : this.error,
      wasRolledBack: wasRolledBack is bool?
          ? wasRolledBack
          : this.wasRolledBack,
    );
  }
}
