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
import 'ai_search_result.dart' as _i2;
import 'package:semantic_butler_client/src/protocol/protocol.dart' as _i3;

/// AISearchProgress DTO - streaming progress updates for AI search
/// Used for real-time feedback during AI-powered file search
abstract class AISearchProgress implements _i1.SerializableModel {
  AISearchProgress._({
    required this.type,
    this.message,
    this.source,
    this.drive,
    this.results,
    this.progress,
    this.error,
    this.toolResultJson,
  });

  factory AISearchProgress({
    required String type,
    String? message,
    String? source,
    String? drive,
    List<_i2.AISearchResult>? results,
    double? progress,
    String? error,
    String? toolResultJson,
  }) = _AISearchProgressImpl;

  factory AISearchProgress.fromJson(Map<String, dynamic> jsonSerialization) {
    return AISearchProgress(
      type: jsonSerialization['type'] as String,
      message: jsonSerialization['message'] as String?,
      source: jsonSerialization['source'] as String?,
      drive: jsonSerialization['drive'] as String?,
      results: jsonSerialization['results'] == null
          ? null
          : _i3.Protocol().deserialize<List<_i2.AISearchResult>>(
              jsonSerialization['results'],
            ),
      progress: (jsonSerialization['progress'] as num?)?.toDouble(),
      error: jsonSerialization['error'] as String?,
      toolResultJson: jsonSerialization['toolResultJson'] as String?,
    );
  }

  /// Progress type: 'thinking', 'searching', 'found', 'result', 'complete', 'error'
  String type;

  /// Human-readable progress message
  String? message;

  /// Search source: 'semantic', 'terminal', 'combined'
  String? source;

  /// Current drive being searched (for terminal search)
  String? drive;

  /// Optional partial or final results
  List<_i2.AISearchResult>? results;

  /// Progress percentage (0.0 to 1.0)
  double? progress;

  /// Error message if type is 'error'
  String? error;

  /// Optional tool result JSON for debugging/tracking
  String? toolResultJson;

  /// Returns a shallow copy of this [AISearchProgress]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AISearchProgress copyWith({
    String? type,
    String? message,
    String? source,
    String? drive,
    List<_i2.AISearchResult>? results,
    double? progress,
    String? error,
    String? toolResultJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AISearchProgress',
      'type': type,
      if (message != null) 'message': message,
      if (source != null) 'source': source,
      if (drive != null) 'drive': drive,
      if (results != null)
        'results': results?.toJson(valueToJson: (v) => v.toJson()),
      if (progress != null) 'progress': progress,
      if (error != null) 'error': error,
      if (toolResultJson != null) 'toolResultJson': toolResultJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AISearchProgressImpl extends AISearchProgress {
  _AISearchProgressImpl({
    required String type,
    String? message,
    String? source,
    String? drive,
    List<_i2.AISearchResult>? results,
    double? progress,
    String? error,
    String? toolResultJson,
  }) : super._(
         type: type,
         message: message,
         source: source,
         drive: drive,
         results: results,
         progress: progress,
         error: error,
         toolResultJson: toolResultJson,
       );

  /// Returns a shallow copy of this [AISearchProgress]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AISearchProgress copyWith({
    String? type,
    Object? message = _Undefined,
    Object? source = _Undefined,
    Object? drive = _Undefined,
    Object? results = _Undefined,
    Object? progress = _Undefined,
    Object? error = _Undefined,
    Object? toolResultJson = _Undefined,
  }) {
    return AISearchProgress(
      type: type ?? this.type,
      message: message is String? ? message : this.message,
      source: source is String? ? source : this.source,
      drive: drive is String? ? drive : this.drive,
      results: results is List<_i2.AISearchResult>?
          ? results
          : this.results?.map((e0) => e0.copyWith()).toList(),
      progress: progress is double? ? progress : this.progress,
      error: error is String? ? error : this.error,
      toolResultJson: toolResultJson is String?
          ? toolResultJson
          : this.toolResultJson,
    );
  }
}
