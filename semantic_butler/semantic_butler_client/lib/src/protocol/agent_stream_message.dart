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

abstract class AgentStreamMessage implements _i1.SerializableModel {
  AgentStreamMessage._({
    required this.type,
    this.content,
    this.tool,
    this.result,
    this.tokenCount,
  });

  factory AgentStreamMessage({
    required String type,
    String? content,
    String? tool,
    String? result,
    int? tokenCount,
  }) = _AgentStreamMessageImpl;

  factory AgentStreamMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return AgentStreamMessage(
      type: jsonSerialization['type'] as String,
      content: jsonSerialization['content'] as String?,
      tool: jsonSerialization['tool'] as String?,
      result: jsonSerialization['result'] as String?,
      tokenCount: jsonSerialization['tokenCount'] as int?,
    );
  }

  String type;

  String? content;

  String? tool;

  String? result;

  int? tokenCount;

  /// Returns a shallow copy of this [AgentStreamMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AgentStreamMessage copyWith({
    String? type,
    String? content,
    String? tool,
    String? result,
    int? tokenCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AgentStreamMessage',
      'type': type,
      if (content != null) 'content': content,
      if (tool != null) 'tool': tool,
      if (result != null) 'result': result,
      if (tokenCount != null) 'tokenCount': tokenCount,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AgentStreamMessageImpl extends AgentStreamMessage {
  _AgentStreamMessageImpl({
    required String type,
    String? content,
    String? tool,
    String? result,
    int? tokenCount,
  }) : super._(
         type: type,
         content: content,
         tool: tool,
         result: result,
         tokenCount: tokenCount,
       );

  /// Returns a shallow copy of this [AgentStreamMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AgentStreamMessage copyWith({
    String? type,
    Object? content = _Undefined,
    Object? tool = _Undefined,
    Object? result = _Undefined,
    Object? tokenCount = _Undefined,
  }) {
    return AgentStreamMessage(
      type: type ?? this.type,
      content: content is String? ? content : this.content,
      tool: tool is String? ? tool : this.tool,
      result: result is String? ? result : this.result,
      tokenCount: tokenCount is int? ? tokenCount : this.tokenCount,
    );
  }
}
