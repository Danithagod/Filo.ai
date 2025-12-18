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

abstract class AgentResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AgentResponse._({
    required this.message,
    required this.toolsUsed,
    required this.tokensUsed,
  });

  factory AgentResponse({
    required String message,
    required int toolsUsed,
    required int tokensUsed,
  }) = _AgentResponseImpl;

  factory AgentResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return AgentResponse(
      message: jsonSerialization['message'] as String,
      toolsUsed: jsonSerialization['toolsUsed'] as int,
      tokensUsed: jsonSerialization['tokensUsed'] as int,
    );
  }

  /// The agent's text response message
  String message;

  /// Number of tools used to generate response
  int toolsUsed;

  /// Total tokens used for this interaction
  int tokensUsed;

  /// Returns a shallow copy of this [AgentResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AgentResponse copyWith({
    String? message,
    int? toolsUsed,
    int? tokensUsed,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AgentResponse',
      'message': message,
      'toolsUsed': toolsUsed,
      'tokensUsed': tokensUsed,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AgentResponse',
      'message': message,
      'toolsUsed': toolsUsed,
      'tokensUsed': tokensUsed,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AgentResponseImpl extends AgentResponse {
  _AgentResponseImpl({
    required String message,
    required int toolsUsed,
    required int tokensUsed,
  }) : super._(
         message: message,
         toolsUsed: toolsUsed,
         tokensUsed: tokensUsed,
       );

  /// Returns a shallow copy of this [AgentResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AgentResponse copyWith({
    String? message,
    int? toolsUsed,
    int? tokensUsed,
  }) {
    return AgentResponse(
      message: message ?? this.message,
      toolsUsed: toolsUsed ?? this.toolsUsed,
      tokensUsed: tokensUsed ?? this.tokensUsed,
    );
  }
}
