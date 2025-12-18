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
import 'database_stats.dart' as _i2;
import 'document_embedding.dart' as _i3;
import 'file_index.dart' as _i4;
import 'greetings/greeting.dart' as _i5;
import 'indexing_job.dart' as _i6;
import 'indexing_status.dart' as _i7;
import 'search_history.dart' as _i8;
import 'search_result.dart' as _i9;
import 'package:semantic_butler_client/src/endpoints/agent_endpoint.dart'
    as _i10;
import 'package:semantic_butler_client/src/protocol/search_result.dart' as _i11;
import 'package:semantic_butler_client/src/protocol/search_history.dart'
    as _i12;
export 'database_stats.dart';
export 'document_embedding.dart';
export 'file_index.dart';
export 'greetings/greeting.dart';
export 'indexing_job.dart';
export 'indexing_status.dart';
export 'search_history.dart';
export 'search_result.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.DatabaseStats) {
      return _i2.DatabaseStats.fromJson(data) as T;
    }
    if (t == _i3.DocumentEmbedding) {
      return _i3.DocumentEmbedding.fromJson(data) as T;
    }
    if (t == _i4.FileIndex) {
      return _i4.FileIndex.fromJson(data) as T;
    }
    if (t == _i5.Greeting) {
      return _i5.Greeting.fromJson(data) as T;
    }
    if (t == _i6.IndexingJob) {
      return _i6.IndexingJob.fromJson(data) as T;
    }
    if (t == _i7.IndexingStatus) {
      return _i7.IndexingStatus.fromJson(data) as T;
    }
    if (t == _i8.SearchHistory) {
      return _i8.SearchHistory.fromJson(data) as T;
    }
    if (t == _i9.SearchResult) {
      return _i9.SearchResult.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.DatabaseStats?>()) {
      return (data != null ? _i2.DatabaseStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.DocumentEmbedding?>()) {
      return (data != null ? _i3.DocumentEmbedding.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.FileIndex?>()) {
      return (data != null ? _i4.FileIndex.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.Greeting?>()) {
      return (data != null ? _i5.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.IndexingJob?>()) {
      return (data != null ? _i6.IndexingJob.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.IndexingStatus?>()) {
      return (data != null ? _i7.IndexingStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.SearchHistory?>()) {
      return (data != null ? _i8.SearchHistory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.SearchResult?>()) {
      return (data != null ? _i9.SearchResult.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i10.AgentMessage>) {
      return (data as List)
              .map((e) => deserialize<_i10.AgentMessage>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i10.AgentMessage>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i10.AgentMessage>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i11.SearchResult>) {
      return (data as List)
              .map((e) => deserialize<_i11.SearchResult>(e))
              .toList()
          as T;
    }
    if (t == List<_i12.SearchHistory>) {
      return (data as List)
              .map((e) => deserialize<_i12.SearchHistory>(e))
              .toList()
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
          )
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.DatabaseStats => 'DatabaseStats',
      _i3.DocumentEmbedding => 'DocumentEmbedding',
      _i4.FileIndex => 'FileIndex',
      _i5.Greeting => 'Greeting',
      _i6.IndexingJob => 'IndexingJob',
      _i7.IndexingStatus => 'IndexingStatus',
      _i8.SearchHistory => 'SearchHistory',
      _i9.SearchResult => 'SearchResult',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst(
        'semantic_butler.',
        '',
      );
    }

    switch (data) {
      case _i2.DatabaseStats():
        return 'DatabaseStats';
      case _i3.DocumentEmbedding():
        return 'DocumentEmbedding';
      case _i4.FileIndex():
        return 'FileIndex';
      case _i5.Greeting():
        return 'Greeting';
      case _i6.IndexingJob():
        return 'IndexingJob';
      case _i7.IndexingStatus():
        return 'IndexingStatus';
      case _i8.SearchHistory():
        return 'SearchHistory';
      case _i9.SearchResult():
        return 'SearchResult';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'DatabaseStats') {
      return deserialize<_i2.DatabaseStats>(data['data']);
    }
    if (dataClassName == 'DocumentEmbedding') {
      return deserialize<_i3.DocumentEmbedding>(data['data']);
    }
    if (dataClassName == 'FileIndex') {
      return deserialize<_i4.FileIndex>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i5.Greeting>(data['data']);
    }
    if (dataClassName == 'IndexingJob') {
      return deserialize<_i6.IndexingJob>(data['data']);
    }
    if (dataClassName == 'IndexingStatus') {
      return deserialize<_i7.IndexingStatus>(data['data']);
    }
    if (dataClassName == 'SearchHistory') {
      return deserialize<_i8.SearchHistory>(data['data']);
    }
    if (dataClassName == 'SearchResult') {
      return deserialize<_i9.SearchResult>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
