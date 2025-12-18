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

abstract class AgentMessage implements _i1.SerializableModel {
  AgentMessage._({
    required this.role,
    required this.content,
  });

  factory AgentMessage({
    required String role,
    required String content,
  }) = _AgentMessageImpl;

  factory AgentMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return AgentMessage(
      role: jsonSerialization['role'] as String,
      content: jsonSerialization['content'] as String,
    );
  }

  /// Role of the message sender - 'user' or 'assistant'
  String role;

  /// Content of the message
  String content;

  /// Returns a shallow copy of this [AgentMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AgentMessage copyWith({
    String? role,
    String? content,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AgentMessage',
      'role': role,
      'content': content,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AgentMessageImpl extends AgentMessage {
  _AgentMessageImpl({
    required String role,
    required String content,
  }) : super._(
         role: role,
         content: content,
       );

  /// Returns a shallow copy of this [AgentMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AgentMessage copyWith({
    String? role,
    String? content,
  }) {
    return AgentMessage(
      role: role ?? this.role,
      content: content ?? this.content,
    );
  }
}
