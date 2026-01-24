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
import 'organization_action_request.dart' as _i2;
import 'package:semantic_butler_client/src/protocol/protocol.dart' as _i3;

/// Request for multiple organization actions at once
abstract class BatchOrganizationRequest implements _i1.SerializableModel {
  BatchOrganizationRequest._({
    required this.actions,
    this.rollbackOnError,
    this.dryRun,
  });

  factory BatchOrganizationRequest({
    required List<_i2.OrganizationActionRequest> actions,
    bool? rollbackOnError,
    bool? dryRun,
  }) = _BatchOrganizationRequestImpl;

  factory BatchOrganizationRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BatchOrganizationRequest(
      actions: _i3.Protocol().deserialize<List<_i2.OrganizationActionRequest>>(
        jsonSerialization['actions'],
      ),
      rollbackOnError: jsonSerialization['rollbackOnError'] as bool?,
      dryRun: jsonSerialization['dryRun'] as bool?,
    );
  }

  /// List of actions to perform
  List<_i2.OrganizationActionRequest> actions;

  /// If true, stop on first error and rollback
  bool? rollbackOnError;

  /// If true, preview all changes without executing
  bool? dryRun;

  /// Returns a shallow copy of this [BatchOrganizationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BatchOrganizationRequest copyWith({
    List<_i2.OrganizationActionRequest>? actions,
    bool? rollbackOnError,
    bool? dryRun,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BatchOrganizationRequest',
      'actions': actions.toJson(valueToJson: (v) => v.toJson()),
      if (rollbackOnError != null) 'rollbackOnError': rollbackOnError,
      if (dryRun != null) 'dryRun': dryRun,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BatchOrganizationRequestImpl extends BatchOrganizationRequest {
  _BatchOrganizationRequestImpl({
    required List<_i2.OrganizationActionRequest> actions,
    bool? rollbackOnError,
    bool? dryRun,
  }) : super._(
         actions: actions,
         rollbackOnError: rollbackOnError,
         dryRun: dryRun,
       );

  /// Returns a shallow copy of this [BatchOrganizationRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BatchOrganizationRequest copyWith({
    List<_i2.OrganizationActionRequest>? actions,
    Object? rollbackOnError = _Undefined,
    Object? dryRun = _Undefined,
  }) {
    return BatchOrganizationRequest(
      actions: actions ?? this.actions.map((e0) => e0.copyWith()).toList(),
      rollbackOnError: rollbackOnError is bool?
          ? rollbackOnError
          : this.rollbackOnError,
      dryRun: dryRun is bool? ? dryRun : this.dryRun,
    );
  }
}
