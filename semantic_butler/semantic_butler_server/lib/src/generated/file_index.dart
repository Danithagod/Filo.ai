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

/// FileIndex model - stores indexed documents with embeddings
abstract class FileIndex
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  FileIndex._({
    this.id,
    required this.path,
    required this.fileName,
    required this.contentHash,
    required this.fileSizeBytes,
    this.mimeType,
    this.contentPreview,
    this.tagsJson,
    required this.status,
    this.errorMessage,
    this.embeddingModel,
    this.indexedAt,
  });

  factory FileIndex({
    int? id,
    required String path,
    required String fileName,
    required String contentHash,
    required int fileSizeBytes,
    String? mimeType,
    String? contentPreview,
    String? tagsJson,
    required String status,
    String? errorMessage,
    String? embeddingModel,
    DateTime? indexedAt,
  }) = _FileIndexImpl;

  factory FileIndex.fromJson(Map<String, dynamic> jsonSerialization) {
    return FileIndex(
      id: jsonSerialization['id'] as int?,
      path: jsonSerialization['path'] as String,
      fileName: jsonSerialization['fileName'] as String,
      contentHash: jsonSerialization['contentHash'] as String,
      fileSizeBytes: jsonSerialization['fileSizeBytes'] as int,
      mimeType: jsonSerialization['mimeType'] as String?,
      contentPreview: jsonSerialization['contentPreview'] as String?,
      tagsJson: jsonSerialization['tagsJson'] as String?,
      status: jsonSerialization['status'] as String,
      errorMessage: jsonSerialization['errorMessage'] as String?,
      embeddingModel: jsonSerialization['embeddingModel'] as String?,
      indexedAt: jsonSerialization['indexedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['indexedAt']),
    );
  }

  static final t = FileIndexTable();

  static const db = FileIndexRepository._();

  @override
  int? id;

  /// File path on the file system
  String path;

  /// File name without path
  String fileName;

  /// SHA-256 hash of file content for change detection
  String contentHash;

  /// File size in bytes
  int fileSizeBytes;

  /// MIME type of the file
  String? mimeType;

  /// Preview of the document content (first 500 chars)
  String? contentPreview;

  /// JSON encoded auto-generated tags
  String? tagsJson;

  /// Status: pending, indexing, indexed, failed, skipped
  String status;

  /// Error message if status is failed
  String? errorMessage;

  /// Name of the embedding model used
  String? embeddingModel;

  /// When the file was indexed
  DateTime? indexedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [FileIndex]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FileIndex copyWith({
    int? id,
    String? path,
    String? fileName,
    String? contentHash,
    int? fileSizeBytes,
    String? mimeType,
    String? contentPreview,
    String? tagsJson,
    String? status,
    String? errorMessage,
    String? embeddingModel,
    DateTime? indexedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FileIndex',
      if (id != null) 'id': id,
      'path': path,
      'fileName': fileName,
      'contentHash': contentHash,
      'fileSizeBytes': fileSizeBytes,
      if (mimeType != null) 'mimeType': mimeType,
      if (contentPreview != null) 'contentPreview': contentPreview,
      if (tagsJson != null) 'tagsJson': tagsJson,
      'status': status,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (embeddingModel != null) 'embeddingModel': embeddingModel,
      if (indexedAt != null) 'indexedAt': indexedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FileIndex',
      if (id != null) 'id': id,
      'path': path,
      'fileName': fileName,
      'contentHash': contentHash,
      'fileSizeBytes': fileSizeBytes,
      if (mimeType != null) 'mimeType': mimeType,
      if (contentPreview != null) 'contentPreview': contentPreview,
      if (tagsJson != null) 'tagsJson': tagsJson,
      'status': status,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (embeddingModel != null) 'embeddingModel': embeddingModel,
      if (indexedAt != null) 'indexedAt': indexedAt?.toJson(),
    };
  }

  static FileIndexInclude include() {
    return FileIndexInclude._();
  }

  static FileIndexIncludeList includeList({
    _i1.WhereExpressionBuilder<FileIndexTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FileIndexTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FileIndexTable>? orderByList,
    FileIndexInclude? include,
  }) {
    return FileIndexIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FileIndex.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(FileIndex.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FileIndexImpl extends FileIndex {
  _FileIndexImpl({
    int? id,
    required String path,
    required String fileName,
    required String contentHash,
    required int fileSizeBytes,
    String? mimeType,
    String? contentPreview,
    String? tagsJson,
    required String status,
    String? errorMessage,
    String? embeddingModel,
    DateTime? indexedAt,
  }) : super._(
         id: id,
         path: path,
         fileName: fileName,
         contentHash: contentHash,
         fileSizeBytes: fileSizeBytes,
         mimeType: mimeType,
         contentPreview: contentPreview,
         tagsJson: tagsJson,
         status: status,
         errorMessage: errorMessage,
         embeddingModel: embeddingModel,
         indexedAt: indexedAt,
       );

  /// Returns a shallow copy of this [FileIndex]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FileIndex copyWith({
    Object? id = _Undefined,
    String? path,
    String? fileName,
    String? contentHash,
    int? fileSizeBytes,
    Object? mimeType = _Undefined,
    Object? contentPreview = _Undefined,
    Object? tagsJson = _Undefined,
    String? status,
    Object? errorMessage = _Undefined,
    Object? embeddingModel = _Undefined,
    Object? indexedAt = _Undefined,
  }) {
    return FileIndex(
      id: id is int? ? id : this.id,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      contentHash: contentHash ?? this.contentHash,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType is String? ? mimeType : this.mimeType,
      contentPreview: contentPreview is String?
          ? contentPreview
          : this.contentPreview,
      tagsJson: tagsJson is String? ? tagsJson : this.tagsJson,
      status: status ?? this.status,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      embeddingModel: embeddingModel is String?
          ? embeddingModel
          : this.embeddingModel,
      indexedAt: indexedAt is DateTime? ? indexedAt : this.indexedAt,
    );
  }
}

class FileIndexUpdateTable extends _i1.UpdateTable<FileIndexTable> {
  FileIndexUpdateTable(super.table);

  _i1.ColumnValue<String, String> path(String value) => _i1.ColumnValue(
    table.path,
    value,
  );

  _i1.ColumnValue<String, String> fileName(String value) => _i1.ColumnValue(
    table.fileName,
    value,
  );

  _i1.ColumnValue<String, String> contentHash(String value) => _i1.ColumnValue(
    table.contentHash,
    value,
  );

  _i1.ColumnValue<int, int> fileSizeBytes(int value) => _i1.ColumnValue(
    table.fileSizeBytes,
    value,
  );

  _i1.ColumnValue<String, String> mimeType(String? value) => _i1.ColumnValue(
    table.mimeType,
    value,
  );

  _i1.ColumnValue<String, String> contentPreview(String? value) =>
      _i1.ColumnValue(
        table.contentPreview,
        value,
      );

  _i1.ColumnValue<String, String> tagsJson(String? value) => _i1.ColumnValue(
    table.tagsJson,
    value,
  );

  _i1.ColumnValue<String, String> status(String value) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<String, String> errorMessage(String? value) =>
      _i1.ColumnValue(
        table.errorMessage,
        value,
      );

  _i1.ColumnValue<String, String> embeddingModel(String? value) =>
      _i1.ColumnValue(
        table.embeddingModel,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> indexedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.indexedAt,
        value,
      );
}

class FileIndexTable extends _i1.Table<int?> {
  FileIndexTable({super.tableRelation}) : super(tableName: 'file_index') {
    updateTable = FileIndexUpdateTable(this);
    path = _i1.ColumnString(
      'path',
      this,
    );
    fileName = _i1.ColumnString(
      'fileName',
      this,
    );
    contentHash = _i1.ColumnString(
      'contentHash',
      this,
    );
    fileSizeBytes = _i1.ColumnInt(
      'fileSizeBytes',
      this,
    );
    mimeType = _i1.ColumnString(
      'mimeType',
      this,
    );
    contentPreview = _i1.ColumnString(
      'contentPreview',
      this,
    );
    tagsJson = _i1.ColumnString(
      'tagsJson',
      this,
    );
    status = _i1.ColumnString(
      'status',
      this,
    );
    errorMessage = _i1.ColumnString(
      'errorMessage',
      this,
    );
    embeddingModel = _i1.ColumnString(
      'embeddingModel',
      this,
    );
    indexedAt = _i1.ColumnDateTime(
      'indexedAt',
      this,
    );
  }

  late final FileIndexUpdateTable updateTable;

  /// File path on the file system
  late final _i1.ColumnString path;

  /// File name without path
  late final _i1.ColumnString fileName;

  /// SHA-256 hash of file content for change detection
  late final _i1.ColumnString contentHash;

  /// File size in bytes
  late final _i1.ColumnInt fileSizeBytes;

  /// MIME type of the file
  late final _i1.ColumnString mimeType;

  /// Preview of the document content (first 500 chars)
  late final _i1.ColumnString contentPreview;

  /// JSON encoded auto-generated tags
  late final _i1.ColumnString tagsJson;

  /// Status: pending, indexing, indexed, failed, skipped
  late final _i1.ColumnString status;

  /// Error message if status is failed
  late final _i1.ColumnString errorMessage;

  /// Name of the embedding model used
  late final _i1.ColumnString embeddingModel;

  /// When the file was indexed
  late final _i1.ColumnDateTime indexedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    path,
    fileName,
    contentHash,
    fileSizeBytes,
    mimeType,
    contentPreview,
    tagsJson,
    status,
    errorMessage,
    embeddingModel,
    indexedAt,
  ];
}

class FileIndexInclude extends _i1.IncludeObject {
  FileIndexInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => FileIndex.t;
}

class FileIndexIncludeList extends _i1.IncludeList {
  FileIndexIncludeList._({
    _i1.WhereExpressionBuilder<FileIndexTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(FileIndex.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => FileIndex.t;
}

class FileIndexRepository {
  const FileIndexRepository._();

  /// Returns a list of [FileIndex]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<FileIndex>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<FileIndexTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FileIndexTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FileIndexTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<FileIndex>(
      where: where?.call(FileIndex.t),
      orderBy: orderBy?.call(FileIndex.t),
      orderByList: orderByList?.call(FileIndex.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [FileIndex] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<FileIndex?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<FileIndexTable>? where,
    int? offset,
    _i1.OrderByBuilder<FileIndexTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FileIndexTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<FileIndex>(
      where: where?.call(FileIndex.t),
      orderBy: orderBy?.call(FileIndex.t),
      orderByList: orderByList?.call(FileIndex.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [FileIndex] by its [id] or null if no such row exists.
  Future<FileIndex?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<FileIndex>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [FileIndex]s in the list and returns the inserted rows.
  ///
  /// The returned [FileIndex]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<FileIndex>> insert(
    _i1.Session session,
    List<FileIndex> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<FileIndex>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [FileIndex] and returns the inserted row.
  ///
  /// The returned [FileIndex] will have its `id` field set.
  Future<FileIndex> insertRow(
    _i1.Session session,
    FileIndex row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<FileIndex>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [FileIndex]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<FileIndex>> update(
    _i1.Session session,
    List<FileIndex> rows, {
    _i1.ColumnSelections<FileIndexTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<FileIndex>(
      rows,
      columns: columns?.call(FileIndex.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FileIndex]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<FileIndex> updateRow(
    _i1.Session session,
    FileIndex row, {
    _i1.ColumnSelections<FileIndexTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<FileIndex>(
      row,
      columns: columns?.call(FileIndex.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FileIndex] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<FileIndex?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<FileIndexUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<FileIndex>(
      id,
      columnValues: columnValues(FileIndex.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [FileIndex]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<FileIndex>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<FileIndexUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<FileIndexTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FileIndexTable>? orderBy,
    _i1.OrderByListBuilder<FileIndexTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<FileIndex>(
      columnValues: columnValues(FileIndex.t.updateTable),
      where: where(FileIndex.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FileIndex.t),
      orderByList: orderByList?.call(FileIndex.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [FileIndex]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<FileIndex>> delete(
    _i1.Session session,
    List<FileIndex> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<FileIndex>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [FileIndex].
  Future<FileIndex> deleteRow(
    _i1.Session session,
    FileIndex row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<FileIndex>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<FileIndex>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<FileIndexTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<FileIndex>(
      where: where(FileIndex.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<FileIndexTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<FileIndex>(
      where: where?.call(FileIndex.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
