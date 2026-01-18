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
import 'agent_file_command.dart' as _i3;
import 'agent_message.dart' as _i4;
import 'agent_response.dart' as _i5;
import 'agent_stream_message.dart' as _i6;
import 'ai_search_progress.dart' as _i7;
import 'ai_search_result.dart' as _i8;
import 'database_stats.dart' as _i9;
import 'document_embedding.dart' as _i10;
import 'drive_info.dart' as _i11;
import 'duplicate_file.dart' as _i12;
import 'duplicate_group.dart' as _i13;
import 'error_category_count.dart' as _i14;
import 'error_stats.dart' as _i15;
import 'file_index.dart' as _i16;
import 'file_operation_result.dart' as _i17;
import 'file_system_entry.dart' as _i18;
import 'greetings/greeting.dart' as _i19;
import 'health_check.dart' as _i20;
import 'ignore_pattern.dart' as _i21;
import 'indexing_job.dart' as _i22;
import 'indexing_job_detail.dart' as _i23;
import 'indexing_progress.dart' as _i24;
import 'indexing_status.dart' as _i25;
import 'naming_issue.dart' as _i26;
import 'organization_suggestions.dart' as _i27;
import 'saved_search_preset.dart' as _i28;
import 'search_filters.dart' as _i29;
import 'search_history.dart' as _i30;
import 'search_result.dart' as _i31;
import 'search_suggestion.dart' as _i32;
import 'similar_content_group.dart' as _i33;
import 'similar_file.dart' as _i34;
import 'tag_taxonomy.dart' as _i35;
import 'watched_folder.dart' as _i36;
import 'package:semantic_butler_server/src/generated/agent_message.dart'
    as _i37;
import 'package:semantic_butler_server/src/generated/search_result.dart'
    as _i38;
import 'package:semantic_butler_server/src/generated/search_suggestion.dart'
    as _i39;
import 'package:semantic_butler_server/src/generated/saved_search_preset.dart'
    as _i40;
import 'package:semantic_butler_server/src/generated/search_history.dart'
    as _i41;
import 'package:semantic_butler_server/src/generated/watched_folder.dart'
    as _i42;
import 'package:semantic_butler_server/src/generated/ignore_pattern.dart'
    as _i43;
import 'package:semantic_butler_server/src/generated/tag_taxonomy.dart' as _i44;
import 'package:semantic_butler_server/src/generated/file_system_entry.dart'
    as _i45;
import 'package:semantic_butler_server/src/generated/drive_info.dart' as _i46;
export 'agent_file_command.dart';
export 'agent_message.dart';
export 'agent_response.dart';
export 'agent_stream_message.dart';
export 'ai_search_progress.dart';
export 'ai_search_result.dart';
export 'database_stats.dart';
export 'document_embedding.dart';
export 'drive_info.dart';
export 'duplicate_file.dart';
export 'duplicate_group.dart';
export 'error_category_count.dart';
export 'error_stats.dart';
export 'file_index.dart';
export 'file_operation_result.dart';
export 'file_system_entry.dart';
export 'greetings/greeting.dart';
export 'health_check.dart';
export 'ignore_pattern.dart';
export 'indexing_job.dart';
export 'indexing_job_detail.dart';
export 'indexing_progress.dart';
export 'indexing_status.dart';
export 'naming_issue.dart';
export 'organization_suggestions.dart';
export 'saved_search_preset.dart';
export 'search_filters.dart';
export 'search_history.dart';
export 'search_result.dart';
export 'search_suggestion.dart';
export 'similar_content_group.dart';
export 'similar_file.dart';
export 'tag_taxonomy.dart';
export 'watched_folder.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'agent_file_command',
      dartName: 'AgentFileCommand',
      schema: 'public',
      module: 'semantic_butler',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'agent_file_command_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'operation',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'sourcePath',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'destinationPath',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'newName',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'executedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'success',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'errorMessage',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'reversible',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'wasUndone',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'agent_file_command_pkey',
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
          indexName: 'idx_file_command_operation',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'operation',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'idx_file_command_executed',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'executedAt',
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
          name: 'summary',
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
          name: 'documentCategory',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'fileCreatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'fileModifiedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'wordCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'isTextContent',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
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
        _i2.IndexDefinition(
          indexName: 'file_index_category',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'documentCategory',
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
      name: 'ignore_pattern',
      dartName: 'IgnorePattern',
      schema: 'public',
      module: 'semantic_butler',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'ignore_pattern_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'pattern',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'patternType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'ignore_pattern_pkey',
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
          indexName: 'ignore_pattern_unique',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'pattern',
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
        _i2.ColumnDefinition(
          name: 'errorCategory',
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
      name: 'indexing_job_detail',
      dartName: 'IndexingJobDetail',
      schema: 'public',
      module: 'semantic_butler',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'indexing_job_detail_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'jobId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'filePath',
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
        _i2.ColumnDefinition(
          name: 'errorCategory',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'indexing_job_detail_pkey',
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
          indexName: 'idx_job_detail_job',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'jobId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'idx_job_detail_status',
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
          indexName: 'idx_job_detail_path',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'filePath',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'idx_job_detail_error_category',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'errorCategory',
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
      name: 'saved_search_preset',
      dartName: 'SavedSearchPreset',
      schema: 'public',
      module: 'semantic_butler',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'saved_search_preset_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'query',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'category',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'tags',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
        ),
        _i2.ColumnDefinition(
          name: 'fileTypes',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
        ),
        _i2.ColumnDefinition(
          name: 'dateFrom',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'dateTo',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'minSize',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'maxSize',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'usageCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'saved_search_preset_pkey',
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
        _i2.ColumnDefinition(
          name: 'searchType',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'directoryContext',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
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
        _i2.IndexDefinition(
          indexName: 'search_history_type',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'searchType',
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
      name: 'tag_taxonomy',
      dartName: 'TagTaxonomy',
      schema: 'public',
      module: 'semantic_butler',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'tag_taxonomy_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'category',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'tagValue',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'frequency',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'firstSeenAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'lastSeenAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'tag_taxonomy_pkey',
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
          indexName: 'tag_taxonomy_category_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'category',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'tag_taxonomy_value_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'tagValue',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'tag_taxonomy_frequency_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'frequency',
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
      name: 'watched_folders',
      dartName: 'WatchedFolder',
      schema: 'public',
      module: 'semantic_butler',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'watched_folders_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'path',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'isEnabled',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'lastEventAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'filesWatched',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'watched_folders_pkey',
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

    if (t == _i3.AgentFileCommand) {
      return _i3.AgentFileCommand.fromJson(data) as T;
    }
    if (t == _i4.AgentMessage) {
      return _i4.AgentMessage.fromJson(data) as T;
    }
    if (t == _i5.AgentResponse) {
      return _i5.AgentResponse.fromJson(data) as T;
    }
    if (t == _i6.AgentStreamMessage) {
      return _i6.AgentStreamMessage.fromJson(data) as T;
    }
    if (t == _i7.AISearchProgress) {
      return _i7.AISearchProgress.fromJson(data) as T;
    }
    if (t == _i8.AISearchResult) {
      return _i8.AISearchResult.fromJson(data) as T;
    }
    if (t == _i9.DatabaseStats) {
      return _i9.DatabaseStats.fromJson(data) as T;
    }
    if (t == _i10.DocumentEmbedding) {
      return _i10.DocumentEmbedding.fromJson(data) as T;
    }
    if (t == _i11.DriveInfo) {
      return _i11.DriveInfo.fromJson(data) as T;
    }
    if (t == _i12.DuplicateFile) {
      return _i12.DuplicateFile.fromJson(data) as T;
    }
    if (t == _i13.DuplicateGroup) {
      return _i13.DuplicateGroup.fromJson(data) as T;
    }
    if (t == _i14.ErrorCategoryCount) {
      return _i14.ErrorCategoryCount.fromJson(data) as T;
    }
    if (t == _i15.ErrorStats) {
      return _i15.ErrorStats.fromJson(data) as T;
    }
    if (t == _i16.FileIndex) {
      return _i16.FileIndex.fromJson(data) as T;
    }
    if (t == _i17.FileOperationResult) {
      return _i17.FileOperationResult.fromJson(data) as T;
    }
    if (t == _i18.FileSystemEntry) {
      return _i18.FileSystemEntry.fromJson(data) as T;
    }
    if (t == _i19.Greeting) {
      return _i19.Greeting.fromJson(data) as T;
    }
    if (t == _i20.HealthCheck) {
      return _i20.HealthCheck.fromJson(data) as T;
    }
    if (t == _i21.IgnorePattern) {
      return _i21.IgnorePattern.fromJson(data) as T;
    }
    if (t == _i22.IndexingJob) {
      return _i22.IndexingJob.fromJson(data) as T;
    }
    if (t == _i23.IndexingJobDetail) {
      return _i23.IndexingJobDetail.fromJson(data) as T;
    }
    if (t == _i24.IndexingProgress) {
      return _i24.IndexingProgress.fromJson(data) as T;
    }
    if (t == _i25.IndexingStatus) {
      return _i25.IndexingStatus.fromJson(data) as T;
    }
    if (t == _i26.NamingIssue) {
      return _i26.NamingIssue.fromJson(data) as T;
    }
    if (t == _i27.OrganizationSuggestions) {
      return _i27.OrganizationSuggestions.fromJson(data) as T;
    }
    if (t == _i28.SavedSearchPreset) {
      return _i28.SavedSearchPreset.fromJson(data) as T;
    }
    if (t == _i29.SearchFilters) {
      return _i29.SearchFilters.fromJson(data) as T;
    }
    if (t == _i30.SearchHistory) {
      return _i30.SearchHistory.fromJson(data) as T;
    }
    if (t == _i31.SearchResult) {
      return _i31.SearchResult.fromJson(data) as T;
    }
    if (t == _i32.SearchSuggestion) {
      return _i32.SearchSuggestion.fromJson(data) as T;
    }
    if (t == _i33.SimilarContentGroup) {
      return _i33.SimilarContentGroup.fromJson(data) as T;
    }
    if (t == _i34.SimilarFile) {
      return _i34.SimilarFile.fromJson(data) as T;
    }
    if (t == _i35.TagTaxonomy) {
      return _i35.TagTaxonomy.fromJson(data) as T;
    }
    if (t == _i36.WatchedFolder) {
      return _i36.WatchedFolder.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.AgentFileCommand?>()) {
      return (data != null ? _i3.AgentFileCommand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.AgentMessage?>()) {
      return (data != null ? _i4.AgentMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AgentResponse?>()) {
      return (data != null ? _i5.AgentResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.AgentStreamMessage?>()) {
      return (data != null ? _i6.AgentStreamMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.AISearchProgress?>()) {
      return (data != null ? _i7.AISearchProgress.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.AISearchResult?>()) {
      return (data != null ? _i8.AISearchResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.DatabaseStats?>()) {
      return (data != null ? _i9.DatabaseStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.DocumentEmbedding?>()) {
      return (data != null ? _i10.DocumentEmbedding.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.DriveInfo?>()) {
      return (data != null ? _i11.DriveInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.DuplicateFile?>()) {
      return (data != null ? _i12.DuplicateFile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.DuplicateGroup?>()) {
      return (data != null ? _i13.DuplicateGroup.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.ErrorCategoryCount?>()) {
      return (data != null ? _i14.ErrorCategoryCount.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i15.ErrorStats?>()) {
      return (data != null ? _i15.ErrorStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.FileIndex?>()) {
      return (data != null ? _i16.FileIndex.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.FileOperationResult?>()) {
      return (data != null ? _i17.FileOperationResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i18.FileSystemEntry?>()) {
      return (data != null ? _i18.FileSystemEntry.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.Greeting?>()) {
      return (data != null ? _i19.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.HealthCheck?>()) {
      return (data != null ? _i20.HealthCheck.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.IgnorePattern?>()) {
      return (data != null ? _i21.IgnorePattern.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.IndexingJob?>()) {
      return (data != null ? _i22.IndexingJob.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.IndexingJobDetail?>()) {
      return (data != null ? _i23.IndexingJobDetail.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.IndexingProgress?>()) {
      return (data != null ? _i24.IndexingProgress.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.IndexingStatus?>()) {
      return (data != null ? _i25.IndexingStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.NamingIssue?>()) {
      return (data != null ? _i26.NamingIssue.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.OrganizationSuggestions?>()) {
      return (data != null ? _i27.OrganizationSuggestions.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i28.SavedSearchPreset?>()) {
      return (data != null ? _i28.SavedSearchPreset.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.SearchFilters?>()) {
      return (data != null ? _i29.SearchFilters.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.SearchHistory?>()) {
      return (data != null ? _i30.SearchHistory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.SearchResult?>()) {
      return (data != null ? _i31.SearchResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i32.SearchSuggestion?>()) {
      return (data != null ? _i32.SearchSuggestion.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i33.SimilarContentGroup?>()) {
      return (data != null ? _i33.SimilarContentGroup.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i34.SimilarFile?>()) {
      return (data != null ? _i34.SimilarFile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i35.TagTaxonomy?>()) {
      return (data != null ? _i35.TagTaxonomy.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i36.WatchedFolder?>()) {
      return (data != null ? _i36.WatchedFolder.fromJson(data) : null) as T;
    }
    if (t == List<_i8.AISearchResult>) {
      return (data as List)
              .map((e) => deserialize<_i8.AISearchResult>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i8.AISearchResult>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i8.AISearchResult>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i12.DuplicateFile>) {
      return (data as List)
              .map((e) => deserialize<_i12.DuplicateFile>(e))
              .toList()
          as T;
    }
    if (t == List<_i14.ErrorCategoryCount>) {
      return (data as List)
              .map((e) => deserialize<_i14.ErrorCategoryCount>(e))
              .toList()
          as T;
    }
    if (t == List<_i22.IndexingJob>) {
      return (data as List)
              .map((e) => deserialize<_i22.IndexingJob>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i22.IndexingJob>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i22.IndexingJob>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i13.DuplicateGroup>) {
      return (data as List)
              .map((e) => deserialize<_i13.DuplicateGroup>(e))
              .toList()
          as T;
    }
    if (t == List<_i26.NamingIssue>) {
      return (data as List)
              .map((e) => deserialize<_i26.NamingIssue>(e))
              .toList()
          as T;
    }
    if (t == List<_i33.SimilarContentGroup>) {
      return (data as List)
              .map((e) => deserialize<_i33.SimilarContentGroup>(e))
              .toList()
          as T;
    }
    if (t == List<_i34.SimilarFile>) {
      return (data as List)
              .map((e) => deserialize<_i34.SimilarFile>(e))
              .toList()
          as T;
    }
    if (t == List<_i37.AgentMessage>) {
      return (data as List)
              .map((e) => deserialize<_i37.AgentMessage>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i37.AgentMessage>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i37.AgentMessage>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i38.SearchResult>) {
      return (data as List)
              .map((e) => deserialize<_i38.SearchResult>(e))
              .toList()
          as T;
    }
    if (t == List<_i39.SearchSuggestion>) {
      return (data as List)
              .map((e) => deserialize<_i39.SearchSuggestion>(e))
              .toList()
          as T;
    }
    if (t == List<_i40.SavedSearchPreset>) {
      return (data as List)
              .map((e) => deserialize<_i40.SavedSearchPreset>(e))
              .toList()
          as T;
    }
    if (t == List<_i41.SearchHistory>) {
      return (data as List)
              .map((e) => deserialize<_i41.SearchHistory>(e))
              .toList()
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
          )
          as T;
    }
    if (t == List<_i42.WatchedFolder>) {
      return (data as List)
              .map((e) => deserialize<_i42.WatchedFolder>(e))
              .toList()
          as T;
    }
    if (t == List<_i43.IgnorePattern>) {
      return (data as List)
              .map((e) => deserialize<_i43.IgnorePattern>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i44.TagTaxonomy>) {
      return (data as List)
              .map((e) => deserialize<_i44.TagTaxonomy>(e))
              .toList()
          as T;
    }
    if (t == List<Map<String, dynamic>>) {
      return (data as List)
              .map((e) => deserialize<Map<String, dynamic>>(e))
              .toList()
          as T;
    }
    if (t == Map<String, double>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<double>(v)),
          )
          as T;
    }
    if (t == _i1.getType<Map<String, dynamic>?>()) {
      return (data != null
              ? (data as Map).map(
                  (k, v) =>
                      MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
                )
              : null)
          as T;
    }
    if (t == List<_i45.FileSystemEntry>) {
      return (data as List)
              .map((e) => deserialize<_i45.FileSystemEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i46.DriveInfo>) {
      return (data as List).map((e) => deserialize<_i46.DriveInfo>(e)).toList()
          as T;
    }
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i3.AgentFileCommand => 'AgentFileCommand',
      _i4.AgentMessage => 'AgentMessage',
      _i5.AgentResponse => 'AgentResponse',
      _i6.AgentStreamMessage => 'AgentStreamMessage',
      _i7.AISearchProgress => 'AISearchProgress',
      _i8.AISearchResult => 'AISearchResult',
      _i9.DatabaseStats => 'DatabaseStats',
      _i10.DocumentEmbedding => 'DocumentEmbedding',
      _i11.DriveInfo => 'DriveInfo',
      _i12.DuplicateFile => 'DuplicateFile',
      _i13.DuplicateGroup => 'DuplicateGroup',
      _i14.ErrorCategoryCount => 'ErrorCategoryCount',
      _i15.ErrorStats => 'ErrorStats',
      _i16.FileIndex => 'FileIndex',
      _i17.FileOperationResult => 'FileOperationResult',
      _i18.FileSystemEntry => 'FileSystemEntry',
      _i19.Greeting => 'Greeting',
      _i20.HealthCheck => 'HealthCheck',
      _i21.IgnorePattern => 'IgnorePattern',
      _i22.IndexingJob => 'IndexingJob',
      _i23.IndexingJobDetail => 'IndexingJobDetail',
      _i24.IndexingProgress => 'IndexingProgress',
      _i25.IndexingStatus => 'IndexingStatus',
      _i26.NamingIssue => 'NamingIssue',
      _i27.OrganizationSuggestions => 'OrganizationSuggestions',
      _i28.SavedSearchPreset => 'SavedSearchPreset',
      _i29.SearchFilters => 'SearchFilters',
      _i30.SearchHistory => 'SearchHistory',
      _i31.SearchResult => 'SearchResult',
      _i32.SearchSuggestion => 'SearchSuggestion',
      _i33.SimilarContentGroup => 'SimilarContentGroup',
      _i34.SimilarFile => 'SimilarFile',
      _i35.TagTaxonomy => 'TagTaxonomy',
      _i36.WatchedFolder => 'WatchedFolder',
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
      case _i3.AgentFileCommand():
        return 'AgentFileCommand';
      case _i4.AgentMessage():
        return 'AgentMessage';
      case _i5.AgentResponse():
        return 'AgentResponse';
      case _i6.AgentStreamMessage():
        return 'AgentStreamMessage';
      case _i7.AISearchProgress():
        return 'AISearchProgress';
      case _i8.AISearchResult():
        return 'AISearchResult';
      case _i9.DatabaseStats():
        return 'DatabaseStats';
      case _i10.DocumentEmbedding():
        return 'DocumentEmbedding';
      case _i11.DriveInfo():
        return 'DriveInfo';
      case _i12.DuplicateFile():
        return 'DuplicateFile';
      case _i13.DuplicateGroup():
        return 'DuplicateGroup';
      case _i14.ErrorCategoryCount():
        return 'ErrorCategoryCount';
      case _i15.ErrorStats():
        return 'ErrorStats';
      case _i16.FileIndex():
        return 'FileIndex';
      case _i17.FileOperationResult():
        return 'FileOperationResult';
      case _i18.FileSystemEntry():
        return 'FileSystemEntry';
      case _i19.Greeting():
        return 'Greeting';
      case _i20.HealthCheck():
        return 'HealthCheck';
      case _i21.IgnorePattern():
        return 'IgnorePattern';
      case _i22.IndexingJob():
        return 'IndexingJob';
      case _i23.IndexingJobDetail():
        return 'IndexingJobDetail';
      case _i24.IndexingProgress():
        return 'IndexingProgress';
      case _i25.IndexingStatus():
        return 'IndexingStatus';
      case _i26.NamingIssue():
        return 'NamingIssue';
      case _i27.OrganizationSuggestions():
        return 'OrganizationSuggestions';
      case _i28.SavedSearchPreset():
        return 'SavedSearchPreset';
      case _i29.SearchFilters():
        return 'SearchFilters';
      case _i30.SearchHistory():
        return 'SearchHistory';
      case _i31.SearchResult():
        return 'SearchResult';
      case _i32.SearchSuggestion():
        return 'SearchSuggestion';
      case _i33.SimilarContentGroup():
        return 'SimilarContentGroup';
      case _i34.SimilarFile():
        return 'SimilarFile';
      case _i35.TagTaxonomy():
        return 'TagTaxonomy';
      case _i36.WatchedFolder():
        return 'WatchedFolder';
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
    if (dataClassName == 'AgentFileCommand') {
      return deserialize<_i3.AgentFileCommand>(data['data']);
    }
    if (dataClassName == 'AgentMessage') {
      return deserialize<_i4.AgentMessage>(data['data']);
    }
    if (dataClassName == 'AgentResponse') {
      return deserialize<_i5.AgentResponse>(data['data']);
    }
    if (dataClassName == 'AgentStreamMessage') {
      return deserialize<_i6.AgentStreamMessage>(data['data']);
    }
    if (dataClassName == 'AISearchProgress') {
      return deserialize<_i7.AISearchProgress>(data['data']);
    }
    if (dataClassName == 'AISearchResult') {
      return deserialize<_i8.AISearchResult>(data['data']);
    }
    if (dataClassName == 'DatabaseStats') {
      return deserialize<_i9.DatabaseStats>(data['data']);
    }
    if (dataClassName == 'DocumentEmbedding') {
      return deserialize<_i10.DocumentEmbedding>(data['data']);
    }
    if (dataClassName == 'DriveInfo') {
      return deserialize<_i11.DriveInfo>(data['data']);
    }
    if (dataClassName == 'DuplicateFile') {
      return deserialize<_i12.DuplicateFile>(data['data']);
    }
    if (dataClassName == 'DuplicateGroup') {
      return deserialize<_i13.DuplicateGroup>(data['data']);
    }
    if (dataClassName == 'ErrorCategoryCount') {
      return deserialize<_i14.ErrorCategoryCount>(data['data']);
    }
    if (dataClassName == 'ErrorStats') {
      return deserialize<_i15.ErrorStats>(data['data']);
    }
    if (dataClassName == 'FileIndex') {
      return deserialize<_i16.FileIndex>(data['data']);
    }
    if (dataClassName == 'FileOperationResult') {
      return deserialize<_i17.FileOperationResult>(data['data']);
    }
    if (dataClassName == 'FileSystemEntry') {
      return deserialize<_i18.FileSystemEntry>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i19.Greeting>(data['data']);
    }
    if (dataClassName == 'HealthCheck') {
      return deserialize<_i20.HealthCheck>(data['data']);
    }
    if (dataClassName == 'IgnorePattern') {
      return deserialize<_i21.IgnorePattern>(data['data']);
    }
    if (dataClassName == 'IndexingJob') {
      return deserialize<_i22.IndexingJob>(data['data']);
    }
    if (dataClassName == 'IndexingJobDetail') {
      return deserialize<_i23.IndexingJobDetail>(data['data']);
    }
    if (dataClassName == 'IndexingProgress') {
      return deserialize<_i24.IndexingProgress>(data['data']);
    }
    if (dataClassName == 'IndexingStatus') {
      return deserialize<_i25.IndexingStatus>(data['data']);
    }
    if (dataClassName == 'NamingIssue') {
      return deserialize<_i26.NamingIssue>(data['data']);
    }
    if (dataClassName == 'OrganizationSuggestions') {
      return deserialize<_i27.OrganizationSuggestions>(data['data']);
    }
    if (dataClassName == 'SavedSearchPreset') {
      return deserialize<_i28.SavedSearchPreset>(data['data']);
    }
    if (dataClassName == 'SearchFilters') {
      return deserialize<_i29.SearchFilters>(data['data']);
    }
    if (dataClassName == 'SearchHistory') {
      return deserialize<_i30.SearchHistory>(data['data']);
    }
    if (dataClassName == 'SearchResult') {
      return deserialize<_i31.SearchResult>(data['data']);
    }
    if (dataClassName == 'SearchSuggestion') {
      return deserialize<_i32.SearchSuggestion>(data['data']);
    }
    if (dataClassName == 'SimilarContentGroup') {
      return deserialize<_i33.SimilarContentGroup>(data['data']);
    }
    if (dataClassName == 'SimilarFile') {
      return deserialize<_i34.SimilarFile>(data['data']);
    }
    if (dataClassName == 'TagTaxonomy') {
      return deserialize<_i35.TagTaxonomy>(data['data']);
    }
    if (dataClassName == 'WatchedFolder') {
      return deserialize<_i36.WatchedFolder>(data['data']);
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
      case _i3.AgentFileCommand:
        return _i3.AgentFileCommand.t;
      case _i10.DocumentEmbedding:
        return _i10.DocumentEmbedding.t;
      case _i16.FileIndex:
        return _i16.FileIndex.t;
      case _i21.IgnorePattern:
        return _i21.IgnorePattern.t;
      case _i22.IndexingJob:
        return _i22.IndexingJob.t;
      case _i23.IndexingJobDetail:
        return _i23.IndexingJobDetail.t;
      case _i28.SavedSearchPreset:
        return _i28.SavedSearchPreset.t;
      case _i30.SearchHistory:
        return _i30.SearchHistory.t;
      case _i35.TagTaxonomy:
        return _i35.TagTaxonomy.t;
      case _i36.WatchedFolder:
        return _i36.WatchedFolder.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'semantic_butler';
}
