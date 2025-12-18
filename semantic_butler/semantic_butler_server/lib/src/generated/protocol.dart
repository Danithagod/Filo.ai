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
import 'package:serverpod/protocol.dart' as _i2;
import 'agent_message.dart' as _i3;
import 'agent_response.dart' as _i4;
import 'database_stats.dart' as _i5;
import 'document_embedding.dart' as _i6;
import 'file_index.dart' as _i7;
import 'greetings/greeting.dart' as _i8;
import 'indexing_job.dart' as _i9;
import 'indexing_status.dart' as _i10;
import 'search_history.dart' as _i11;
import 'search_result.dart' as _i12;
import 'package:semantic_butler_server/src/generated/agent_message.dart'
    as _i13;
import 'package:semantic_butler_server/src/generated/search_result.dart'
    as _i14;
import 'package:semantic_butler_server/src/generated/search_history.dart'
    as _i15;
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

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'document_embedding',
      dartName: 'DocumentEmbedding',
      schema: 'public',
      module: 'semantic_butler',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'document_embedding_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'fileIndexId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'chunkIndex',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'chunkText',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'embeddingJson',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'dimensions',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'document_embedding_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'document_embedding_file_index',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'fileIndexId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'document_embedding_file_chunk',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'fileIndexId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'chunkIndex',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'file_index',
      dartName: 'FileIndex',
      schema: 'public',
      module: 'semantic_butler',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'file_index_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'path',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'fileName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'contentHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'fileSizeBytes',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'mimeType',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'contentPreview',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'tagsJson',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'errorMessage',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'embeddingModel',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'indexedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'file_index_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'file_index_path_unique',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'path',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'file_index_content_hash',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'contentHash',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'file_index_status',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'indexing_job',
      dartName: 'IndexingJob',
      schema: 'public',
      module: 'semantic_butler',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'indexing_job_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'folderPath',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'totalFiles',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'processedFiles',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'failedFiles',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'skippedFiles',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'startedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'completedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'errorMessage',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'indexing_job_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'indexing_job_status',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'indexing_job_folder',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'folderPath',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'search_history',
      dartName: 'SearchHistory',
      schema: 'public',
      module: 'semantic_butler',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'search_history_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'query',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'resultCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'topResultId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'queryTimeMs',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'searchedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'search_history_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'search_history_queried_at',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'searchedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i2.Protocol.targetTableDefinitions,
  ];

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

    if (t == _i3.AgentMessage) {
      return _i3.AgentMessage.fromJson(data) as T;
    }
    if (t == _i4.AgentResponse) {
      return _i4.AgentResponse.fromJson(data) as T;
    }
    if (t == _i5.DatabaseStats) {
      return _i5.DatabaseStats.fromJson(data) as T;
    }
    if (t == _i6.DocumentEmbedding) {
      return _i6.DocumentEmbedding.fromJson(data) as T;
    }
    if (t == _i7.FileIndex) {
      return _i7.FileIndex.fromJson(data) as T;
    }
    if (t == _i8.Greeting) {
      return _i8.Greeting.fromJson(data) as T;
    }
    if (t == _i9.IndexingJob) {
      return _i9.IndexingJob.fromJson(data) as T;
    }
    if (t == _i10.IndexingStatus) {
      return _i10.IndexingStatus.fromJson(data) as T;
    }
    if (t == _i11.SearchHistory) {
      return _i11.SearchHistory.fromJson(data) as T;
    }
    if (t == _i12.SearchResult) {
      return _i12.SearchResult.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.AgentMessage?>()) {
      return (data != null ? _i3.AgentMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.AgentResponse?>()) {
      return (data != null ? _i4.AgentResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.DatabaseStats?>()) {
      return (data != null ? _i5.DatabaseStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.DocumentEmbedding?>()) {
      return (data != null ? _i6.DocumentEmbedding.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.FileIndex?>()) {
      return (data != null ? _i7.FileIndex.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.Greeting?>()) {
      return (data != null ? _i8.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.IndexingJob?>()) {
      return (data != null ? _i9.IndexingJob.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.IndexingStatus?>()) {
      return (data != null ? _i10.IndexingStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.SearchHistory?>()) {
      return (data != null ? _i11.SearchHistory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.SearchResult?>()) {
      return (data != null ? _i12.SearchResult.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i13.AgentMessage>) {
      return (data as List)
              .map((e) => deserialize<_i13.AgentMessage>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i13.AgentMessage>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i13.AgentMessage>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i14.SearchResult>) {
      return (data as List)
              .map((e) => deserialize<_i14.SearchResult>(e))
              .toList()
          as T;
    }
    if (t == List<_i15.SearchHistory>) {
      return (data as List)
              .map((e) => deserialize<_i15.SearchHistory>(e))
              .toList()
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
          )
          as T;
    }
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i3.AgentMessage => 'AgentMessage',
      _i4.AgentResponse => 'AgentResponse',
      _i5.DatabaseStats => 'DatabaseStats',
      _i6.DocumentEmbedding => 'DocumentEmbedding',
      _i7.FileIndex => 'FileIndex',
      _i8.Greeting => 'Greeting',
      _i9.IndexingJob => 'IndexingJob',
      _i10.IndexingStatus => 'IndexingStatus',
      _i11.SearchHistory => 'SearchHistory',
      _i12.SearchResult => 'SearchResult',
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
      case _i3.AgentMessage():
        return 'AgentMessage';
      case _i4.AgentResponse():
        return 'AgentResponse';
      case _i5.DatabaseStats():
        return 'DatabaseStats';
      case _i6.DocumentEmbedding():
        return 'DocumentEmbedding';
      case _i7.FileIndex():
        return 'FileIndex';
      case _i8.Greeting():
        return 'Greeting';
      case _i9.IndexingJob():
        return 'IndexingJob';
      case _i10.IndexingStatus():
        return 'IndexingStatus';
      case _i11.SearchHistory():
        return 'SearchHistory';
      case _i12.SearchResult():
        return 'SearchResult';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
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
      return deserialize<_i3.AgentMessage>(data['data']);
    }
    if (dataClassName == 'AgentResponse') {
      return deserialize<_i4.AgentResponse>(data['data']);
    }
    if (dataClassName == 'DatabaseStats') {
      return deserialize<_i5.DatabaseStats>(data['data']);
    }
    if (dataClassName == 'DocumentEmbedding') {
      return deserialize<_i6.DocumentEmbedding>(data['data']);
    }
    if (dataClassName == 'FileIndex') {
      return deserialize<_i7.FileIndex>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i8.Greeting>(data['data']);
    }
    if (dataClassName == 'IndexingJob') {
      return deserialize<_i9.IndexingJob>(data['data']);
    }
    if (dataClassName == 'IndexingStatus') {
      return deserialize<_i10.IndexingStatus>(data['data']);
    }
    if (dataClassName == 'SearchHistory') {
      return deserialize<_i11.SearchHistory>(data['data']);
    }
    if (dataClassName == 'SearchResult') {
      return deserialize<_i12.SearchResult>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i6.DocumentEmbedding:
        return _i6.DocumentEmbedding.t;
      case _i7.FileIndex:
        return _i7.FileIndex.t;
      case _i9.IndexingJob:
        return _i9.IndexingJob.t;
      case _i11.SearchHistory:
        return _i11.SearchHistory.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'semantic_butler';
}
