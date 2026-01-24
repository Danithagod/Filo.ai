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
import 'package:semantic_butler_client/src/protocol/protocol.dart' as _i2;

/// Represents the result of a database reset operation.
/// This is a non-persisted DTO (no table) used for API responses.
abstract class ResetResult implements _i1.SerializableModel {
  ResetResult._({
    required this.success,
    required this.affectedRows,
    required this.durationMs,
    required this.scope,
    this.errorMessage,
  });

  factory ResetResult({
    required bool success,
    required Map<String, int> affectedRows,
    required int durationMs,
    required String scope,
    String? errorMessage,
  }) = _ResetResultImpl;

  factory ResetResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return ResetResult(
      success: jsonSerialization['success'] as bool,
      affectedRows: _i2.Protocol().deserialize<Map<String, int>>(
        jsonSerialization['affectedRows'],
      ),
      durationMs: jsonSerialization['durationMs'] as int,
      scope: jsonSerialization['scope'] as String,
      errorMessage: jsonSerialization['errorMessage'] as String?,
    );
  }

  /// Whether the reset completed successfully
  bool success;

  /// Map of table name to rows deleted
  Map<String, int> affectedRows;

  /// Duration of the reset operation in milliseconds
  int durationMs;

  /// Scope of reset: 'dataOnly' or 'full'
  String scope;

  /// Error message if the reset failed
  String? errorMessage;

  /// Returns a shallow copy of this [ResetResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ResetResult copyWith({
    bool? success,
    Map<String, int>? affectedRows,
    int? durationMs,
    String? scope,
    String? errorMessage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ResetResult',
      'success': success,
      'affectedRows': affectedRows.toJson(),
      'durationMs': durationMs,
      'scope': scope,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ResetResultImpl extends ResetResult {
  _ResetResultImpl({
    required bool success,
    required Map<String, int> affectedRows,
    required int durationMs,
    required String scope,
    String? errorMessage,
  }) : super._(
         success: success,
         affectedRows: affectedRows,
         durationMs: durationMs,
         scope: scope,
         errorMessage: errorMessage,
       );

  /// Returns a shallow copy of this [ResetResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ResetResult copyWith({
    bool? success,
    Map<String, int>? affectedRows,
    int? durationMs,
    String? scope,
    Object? errorMessage = _Undefined,
  }) {
    return ResetResult(
      success: success ?? this.success,
      affectedRows:
          affectedRows ??
          this.affectedRows.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      durationMs: durationMs ?? this.durationMs,
      scope: scope ?? this.scope,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
    );
  }
}
