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
import 'agent_file_command.dart' as _i2;
import 'agent_message.dart' as _i3;
import 'agent_response.dart' as _i4;
import 'agent_stream_message.dart' as _i5;
import 'database_stats.dart' as _i6;
import 'document_embedding.dart' as _i7;
import 'drive_info.dart' as _i8;
import 'file_index.dart' as _i9;
import 'file_operation_result.dart' as _i10;
import 'file_system_entry.dart' as _i11;
import 'greetings/greeting.dart' as _i12;
import 'ignore_pattern.dart' as _i13;
import 'indexing_job.dart' as _i14;
import 'indexing_job_detail.dart' as _i15;
import 'indexing_status.dart' as _i16;
import 'search_history.dart' as _i17;
import 'search_result.dart' as _i18;
import 'watched_folder.dart' as _i19;
import 'package:semantic_butler_client/src/protocol/agent_message.dart' as _i20;
import 'package:semantic_butler_client/src/protocol/search_result.dart' as _i21;
import 'package:semantic_butler_client/src/protocol/search_history.dart'
    as _i22;
import 'package:semantic_butler_client/src/protocol/watched_folder.dart'
    as _i23;
import 'package:semantic_butler_client/src/protocol/ignore_pattern.dart'
    as _i24;
import 'package:semantic_butler_client/src/protocol/file_system_entry.dart'
    as _i25;
import 'package:semantic_butler_client/src/protocol/drive_info.dart' as _i26;
export 'agent_file_command.dart';
export 'agent_message.dart';
export 'agent_response.dart';
export 'agent_stream_message.dart';
export 'database_stats.dart';
export 'document_embedding.dart';
export 'drive_info.dart';
export 'file_index.dart';
export 'file_operation_result.dart';
export 'file_system_entry.dart';
export 'greetings/greeting.dart';
export 'ignore_pattern.dart';
export 'indexing_job.dart';
export 'indexing_job_detail.dart';
export 'indexing_status.dart';
export 'search_history.dart';
export 'search_result.dart';
export 'watched_folder.dart';
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

    if (t == _i2.AgentFileCommand) {
      return _i2.AgentFileCommand.fromJson(data) as T;
    }
    if (t == _i3.AgentMessage) {
      return _i3.AgentMessage.fromJson(data) as T;
    }
    if (t == _i4.AgentResponse) {
      return _i4.AgentResponse.fromJson(data) as T;
    }
    if (t == _i5.AgentStreamMessage) {
      return _i5.AgentStreamMessage.fromJson(data) as T;
    }
    if (t == _i6.DatabaseStats) {
      return _i6.DatabaseStats.fromJson(data) as T;
    }
    if (t == _i7.DocumentEmbedding) {
      return _i7.DocumentEmbedding.fromJson(data) as T;
    }
    if (t == _i8.DriveInfo) {
      return _i8.DriveInfo.fromJson(data) as T;
    }
    if (t == _i9.FileIndex) {
      return _i9.FileIndex.fromJson(data) as T;
    }
    if (t == _i10.FileOperationResult) {
      return _i10.FileOperationResult.fromJson(data) as T;
    }
    if (t == _i11.FileSystemEntry) {
      return _i11.FileSystemEntry.fromJson(data) as T;
    }
    if (t == _i12.Greeting) {
      return _i12.Greeting.fromJson(data) as T;
    }
    if (t == _i13.IgnorePattern) {
      return _i13.IgnorePattern.fromJson(data) as T;
    }
    if (t == _i14.IndexingJob) {
      return _i14.IndexingJob.fromJson(data) as T;
    }
    if (t == _i15.IndexingJobDetail) {
      return _i15.IndexingJobDetail.fromJson(data) as T;
    }
    if (t == _i16.IndexingStatus) {
      return _i16.IndexingStatus.fromJson(data) as T;
    }
    if (t == _i17.SearchHistory) {
      return _i17.SearchHistory.fromJson(data) as T;
    }
    if (t == _i18.SearchResult) {
      return _i18.SearchResult.fromJson(data) as T;
    }
    if (t == _i19.WatchedFolder) {
      return _i19.WatchedFolder.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AgentFileCommand?>()) {
      return (data != null ? _i2.AgentFileCommand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AgentMessage?>()) {
      return (data != null ? _i3.AgentMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.AgentResponse?>()) {
      return (data != null ? _i4.AgentResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AgentStreamMessage?>()) {
      return (data != null ? _i5.AgentStreamMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.DatabaseStats?>()) {
      return (data != null ? _i6.DatabaseStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.DocumentEmbedding?>()) {
      return (data != null ? _i7.DocumentEmbedding.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.DriveInfo?>()) {
      return (data != null ? _i8.DriveInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.FileIndex?>()) {
      return (data != null ? _i9.FileIndex.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.FileOperationResult?>()) {
      return (data != null ? _i10.FileOperationResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.FileSystemEntry?>()) {
      return (data != null ? _i11.FileSystemEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.Greeting?>()) {
      return (data != null ? _i12.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.IgnorePattern?>()) {
      return (data != null ? _i13.IgnorePattern.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.IndexingJob?>()) {
      return (data != null ? _i14.IndexingJob.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.IndexingJobDetail?>()) {
      return (data != null ? _i15.IndexingJobDetail.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.IndexingStatus?>()) {
      return (data != null ? _i16.IndexingStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.SearchHistory?>()) {
      return (data != null ? _i17.SearchHistory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.SearchResult?>()) {
      return (data != null ? _i18.SearchResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.WatchedFolder?>()) {
      return (data != null ? _i19.WatchedFolder.fromJson(data) : null) as T;
    }
    if (t == List<_i14.IndexingJob>) {
      return (data as List)
              .map((e) => deserialize<_i14.IndexingJob>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i14.IndexingJob>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i14.IndexingJob>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i20.AgentMessage>) {
      return (data as List)
              .map((e) => deserialize<_i20.AgentMessage>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i20.AgentMessage>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i20.AgentMessage>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i21.SearchResult>) {
      return (data as List)
              .map((e) => deserialize<_i21.SearchResult>(e))
              .toList()
          as T;
    }
    if (t == List<_i22.SearchHistory>) {
      return (data as List)
              .map((e) => deserialize<_i22.SearchHistory>(e))
              .toList()
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
          )
          as T;
    }
    if (t == List<_i23.WatchedFolder>) {
      return (data as List)
              .map((e) => deserialize<_i23.WatchedFolder>(e))
              .toList()
          as T;
    }
    if (t == List<_i24.IgnorePattern>) {
      return (data as List)
              .map((e) => deserialize<_i24.IgnorePattern>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i25.FileSystemEntry>) {
      return (data as List)
              .map((e) => deserialize<_i25.FileSystemEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i26.DriveInfo>) {
      return (data as List).map((e) => deserialize<_i26.DriveInfo>(e)).toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AgentFileCommand => 'AgentFileCommand',
      _i3.AgentMessage => 'AgentMessage',
      _i4.AgentResponse => 'AgentResponse',
      _i5.AgentStreamMessage => 'AgentStreamMessage',
      _i6.DatabaseStats => 'DatabaseStats',
      _i7.DocumentEmbedding => 'DocumentEmbedding',
      _i8.DriveInfo => 'DriveInfo',
      _i9.FileIndex => 'FileIndex',
      _i10.FileOperationResult => 'FileOperationResult',
      _i11.FileSystemEntry => 'FileSystemEntry',
      _i12.Greeting => 'Greeting',
      _i13.IgnorePattern => 'IgnorePattern',
      _i14.IndexingJob => 'IndexingJob',
      _i15.IndexingJobDetail => 'IndexingJobDetail',
      _i16.IndexingStatus => 'IndexingStatus',
      _i17.SearchHistory => 'SearchHistory',
      _i18.SearchResult => 'SearchResult',
      _i19.WatchedFolder => 'WatchedFolder',
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
      case _i2.AgentFileCommand():
        return 'AgentFileCommand';
      case _i3.AgentMessage():
        return 'AgentMessage';
      case _i4.AgentResponse():
        return 'AgentResponse';
      case _i5.AgentStreamMessage():
        return 'AgentStreamMessage';
      case _i6.DatabaseStats():
        return 'DatabaseStats';
      case _i7.DocumentEmbedding():
        return 'DocumentEmbedding';
      case _i8.DriveInfo():
        return 'DriveInfo';
      case _i9.FileIndex():
        return 'FileIndex';
      case _i10.FileOperationResult():
        return 'FileOperationResult';
      case _i11.FileSystemEntry():
        return 'FileSystemEntry';
      case _i12.Greeting():
        return 'Greeting';
      case _i13.IgnorePattern():
        return 'IgnorePattern';
      case _i14.IndexingJob():
        return 'IndexingJob';
      case _i15.IndexingJobDetail():
        return 'IndexingJobDetail';
      case _i16.IndexingStatus():
        return 'IndexingStatus';
      case _i17.SearchHistory():
        return 'SearchHistory';
      case _i18.SearchResult():
        return 'SearchResult';
      case _i19.WatchedFolder():
        return 'WatchedFolder';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AgentFileCommand') {
      return deserialize<_i2.AgentFileCommand>(data['data']);
    }
    if (dataClassName == 'AgentMessage') {
      return deserialize<_i3.AgentMessage>(data['data']);
    }
    if (dataClassName == 'AgentResponse') {
      return deserialize<_i4.AgentResponse>(data['data']);
    }
    if (dataClassName == 'AgentStreamMessage') {
      return deserialize<_i5.AgentStreamMessage>(data['data']);
    }
    if (dataClassName == 'DatabaseStats') {
      return deserialize<_i6.DatabaseStats>(data['data']);
    }
    if (dataClassName == 'DocumentEmbedding') {
      return deserialize<_i7.DocumentEmbedding>(data['data']);
    }
    if (dataClassName == 'DriveInfo') {
      return deserialize<_i8.DriveInfo>(data['data']);
    }
    if (dataClassName == 'FileIndex') {
      return deserialize<_i9.FileIndex>(data['data']);
    }
    if (dataClassName == 'FileOperationResult') {
      return deserialize<_i10.FileOperationResult>(data['data']);
    }
    if (dataClassName == 'FileSystemEntry') {
      return deserialize<_i11.FileSystemEntry>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i12.Greeting>(data['data']);
    }
    if (dataClassName == 'IgnorePattern') {
      return deserialize<_i13.IgnorePattern>(data['data']);
    }
    if (dataClassName == 'IndexingJob') {
      return deserialize<_i14.IndexingJob>(data['data']);
    }
    if (dataClassName == 'IndexingJobDetail') {
      return deserialize<_i15.IndexingJobDetail>(data['data']);
    }
    if (dataClassName == 'IndexingStatus') {
      return deserialize<_i16.IndexingStatus>(data['data']);
    }
    if (dataClassName == 'SearchHistory') {
      return deserialize<_i17.SearchHistory>(data['data']);
    }
    if (dataClassName == 'SearchResult') {
      return deserialize<_i18.SearchResult>(data['data']);
    }
    if (dataClassName == 'WatchedFolder') {
      return deserialize<_i19.WatchedFolder>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
