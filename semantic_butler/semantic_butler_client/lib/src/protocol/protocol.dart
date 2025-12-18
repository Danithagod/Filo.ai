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
import 'agent_message.dart' as _i2;
import 'agent_response.dart' as _i3;
import 'database_stats.dart' as _i4;
import 'document_embedding.dart' as _i5;
import 'file_index.dart' as _i6;
import 'greetings/greeting.dart' as _i7;
import 'indexing_job.dart' as _i8;
import 'indexing_status.dart' as _i9;
import 'search_history.dart' as _i10;
import 'search_result.dart' as _i11;
import 'package:semantic_butler_client/src/protocol/agent_message.dart' as _i12;
import 'package:semantic_butler_client/src/protocol/search_result.dart' as _i13;
import 'package:semantic_butler_client/src/protocol/search_history.dart'
    as _i14;
export 'agent_message.dart';
export 'agent_response.dart';
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

    if (t == _i2.AgentMessage) {
      return _i2.AgentMessage.fromJson(data) as T;
    }
    if (t == _i3.AgentResponse) {
      return _i3.AgentResponse.fromJson(data) as T;
    }
    if (t == _i4.DatabaseStats) {
      return _i4.DatabaseStats.fromJson(data) as T;
    }
    if (t == _i5.DocumentEmbedding) {
      return _i5.DocumentEmbedding.fromJson(data) as T;
    }
    if (t == _i6.FileIndex) {
      return _i6.FileIndex.fromJson(data) as T;
    }
    if (t == _i7.Greeting) {
      return _i7.Greeting.fromJson(data) as T;
    }
    if (t == _i8.IndexingJob) {
      return _i8.IndexingJob.fromJson(data) as T;
    }
    if (t == _i9.IndexingStatus) {
      return _i9.IndexingStatus.fromJson(data) as T;
    }
    if (t == _i10.SearchHistory) {
      return _i10.SearchHistory.fromJson(data) as T;
    }
    if (t == _i11.SearchResult) {
      return _i11.SearchResult.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AgentMessage?>()) {
      return (data != null ? _i2.AgentMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AgentResponse?>()) {
      return (data != null ? _i3.AgentResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.DatabaseStats?>()) {
      return (data != null ? _i4.DatabaseStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.DocumentEmbedding?>()) {
      return (data != null ? _i5.DocumentEmbedding.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.FileIndex?>()) {
      return (data != null ? _i6.FileIndex.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Greeting?>()) {
      return (data != null ? _i7.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.IndexingJob?>()) {
      return (data != null ? _i8.IndexingJob.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.IndexingStatus?>()) {
      return (data != null ? _i9.IndexingStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.SearchHistory?>()) {
      return (data != null ? _i10.SearchHistory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.SearchResult?>()) {
      return (data != null ? _i11.SearchResult.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i12.AgentMessage>) {
      return (data as List)
              .map((e) => deserialize<_i12.AgentMessage>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i12.AgentMessage>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i12.AgentMessage>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i13.SearchResult>) {
      return (data as List)
              .map((e) => deserialize<_i13.SearchResult>(e))
              .toList()
          as T;
    }
    if (t == List<_i14.SearchHistory>) {
      return (data as List)
              .map((e) => deserialize<_i14.SearchHistory>(e))
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
      _i2.AgentMessage => 'AgentMessage',
      _i3.AgentResponse => 'AgentResponse',
      _i4.DatabaseStats => 'DatabaseStats',
      _i5.DocumentEmbedding => 'DocumentEmbedding',
      _i6.FileIndex => 'FileIndex',
      _i7.Greeting => 'Greeting',
      _i8.IndexingJob => 'IndexingJob',
      _i9.IndexingStatus => 'IndexingStatus',
      _i10.SearchHistory => 'SearchHistory',
      _i11.SearchResult => 'SearchResult',
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
      case _i2.AgentMessage():
        return 'AgentMessage';
      case _i3.AgentResponse():
        return 'AgentResponse';
      case _i4.DatabaseStats():
        return 'DatabaseStats';
      case _i5.DocumentEmbedding():
        return 'DocumentEmbedding';
      case _i6.FileIndex():
        return 'FileIndex';
      case _i7.Greeting():
        return 'Greeting';
      case _i8.IndexingJob():
        return 'IndexingJob';
      case _i9.IndexingStatus():
        return 'IndexingStatus';
      case _i10.SearchHistory():
        return 'SearchHistory';
      case _i11.SearchResult():
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
    if (dataClassName == 'AgentMessage') {
      return deserialize<_i2.AgentMessage>(data['data']);
    }
    if (dataClassName == 'AgentResponse') {
      return deserialize<_i3.AgentResponse>(data['data']);
    }
    if (dataClassName == 'DatabaseStats') {
      return deserialize<_i4.DatabaseStats>(data['data']);
    }
    if (dataClassName == 'DocumentEmbedding') {
      return deserialize<_i5.DocumentEmbedding>(data['data']);
    }
    if (dataClassName == 'FileIndex') {
      return deserialize<_i6.FileIndex>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i7.Greeting>(data['data']);
    }
    if (dataClassName == 'IndexingJob') {
      return deserialize<_i8.IndexingJob>(data['data']);
    }
    if (dataClassName == 'IndexingStatus') {
      return deserialize<_i9.IndexingStatus>(data['data']);
    }
    if (dataClassName == 'SearchHistory') {
      return deserialize<_i10.SearchHistory>(data['data']);
    }
    if (dataClassName == 'SearchResult') {
      return deserialize<_i11.SearchResult>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
