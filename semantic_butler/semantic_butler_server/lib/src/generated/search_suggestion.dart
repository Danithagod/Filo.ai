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

abstract class SearchSuggestion
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SearchSuggestion._({
    required this.text,
    required this.type,
    required this.score,
    this.metadata,
  });

  factory SearchSuggestion({
    required String text,
    required String type,
    required double score,
    String? metadata,
  }) = _SearchSuggestionImpl;

  factory SearchSuggestion.fromJson(Map<String, dynamic> jsonSerialization) {
    return SearchSuggestion(
      text: jsonSerialization['text'] as String,
      type: jsonSerialization['type'] as String,
      score: (jsonSerialization['score'] as num).toDouble(),
      metadata: jsonSerialization['metadata'] as String?,
    );
  }

  String text;

  String type;

  double score;

  String? metadata;

  /// Returns a shallow copy of this [SearchSuggestion]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SearchSuggestion copyWith({
    String? text,
    String? type,
    double? score,
    String? metadata,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SearchSuggestion',
      'text': text,
      'type': type,
      'score': score,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SearchSuggestion',
      'text': text,
      'type': type,
      'score': score,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SearchSuggestionImpl extends SearchSuggestion {
  _SearchSuggestionImpl({
    required String text,
    required String type,
    required double score,
    String? metadata,
  }) : super._(
         text: text,
         type: type,
         score: score,
         metadata: metadata,
       );

  /// Returns a shallow copy of this [SearchSuggestion]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SearchSuggestion copyWith({
    String? text,
    String? type,
    double? score,
    Object? metadata = _Undefined,
  }) {
    return SearchSuggestion(
      text: text ?? this.text,
      type: type ?? this.type,
      score: score ?? this.score,
      metadata: metadata is String? ? metadata : this.metadata,
    );
  }
}
