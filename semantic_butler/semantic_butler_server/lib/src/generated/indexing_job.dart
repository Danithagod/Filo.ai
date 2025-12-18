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

/// IndexingJob model - tracks indexing jobs/tasks
abstract class IndexingJob
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  IndexingJob._({
    this.id,
    required this.folderPath,
    required this.status,
    required this.totalFiles,
    required this.processedFiles,
    required this.failedFiles,
    required this.skippedFiles,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
  });

  factory IndexingJob({
    int? id,
    required String folderPath,
    required String status,
    required int totalFiles,
    required int processedFiles,
    required int failedFiles,
    required int skippedFiles,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
  }) = _IndexingJobImpl;

  factory IndexingJob.fromJson(Map<String, dynamic> jsonSerialization) {
    return IndexingJob(
      id: jsonSerialization['id'] as int?,
      folderPath: jsonSerialization['folderPath'] as String,
      status: jsonSerialization['status'] as String,
      totalFiles: jsonSerialization['totalFiles'] as int,
      processedFiles: jsonSerialization['processedFiles'] as int,
      failedFiles: jsonSerialization['failedFiles'] as int,
      skippedFiles: jsonSerialization['skippedFiles'] as int,
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      errorMessage: jsonSerialization['errorMessage'] as String?,
    );
  }

  static final t = IndexingJobTable();

  static const db = IndexingJobRepository._();

  @override
  int? id;

  /// Folder path being indexed
  String folderPath;

  /// Job status: queued, running, completed, failed, cancelled
  String status;

  /// Total files found in folder
  int totalFiles;

  /// Number of files processed
  int processedFiles;

  /// Number of files that failed
  int failedFiles;

  /// Number of files skipped (unsupported format)
  int skippedFiles;

  /// When the job started
  DateTime? startedAt;

  /// When the job completed
  DateTime? completedAt;

  /// Error message if job failed
  String? errorMessage;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [IndexingJob]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IndexingJob copyWith({
    int? id,
    String? folderPath,
    String? status,
    int? totalFiles,
    int? processedFiles,
    int? failedFiles,
    int? skippedFiles,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IndexingJob',
      if (id != null) 'id': id,
      'folderPath': folderPath,
      'status': status,
      'totalFiles': totalFiles,
      'processedFiles': processedFiles,
      'failedFiles': failedFiles,
      'skippedFiles': skippedFiles,
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IndexingJob',
      if (id != null) 'id': id,
      'folderPath': folderPath,
      'status': status,
      'totalFiles': totalFiles,
      'processedFiles': processedFiles,
      'failedFiles': failedFiles,
      'skippedFiles': skippedFiles,
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  static IndexingJobInclude include() {
    return IndexingJobInclude._();
  }

  static IndexingJobIncludeList includeList({
    _i1.WhereExpressionBuilder<IndexingJobTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<IndexingJobTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<IndexingJobTable>? orderByList,
    IndexingJobInclude? include,
  }) {
    return IndexingJobIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(IndexingJob.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(IndexingJob.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IndexingJobImpl extends IndexingJob {
  _IndexingJobImpl({
    int? id,
    required String folderPath,
    required String status,
    required int totalFiles,
    required int processedFiles,
    required int failedFiles,
    required int skippedFiles,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
  }) : super._(
         id: id,
         folderPath: folderPath,
         status: status,
         totalFiles: totalFiles,
         processedFiles: processedFiles,
         failedFiles: failedFiles,
         skippedFiles: skippedFiles,
         startedAt: startedAt,
         completedAt: completedAt,
         errorMessage: errorMessage,
       );

  /// Returns a shallow copy of this [IndexingJob]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IndexingJob copyWith({
    Object? id = _Undefined,
    String? folderPath,
    String? status,
    int? totalFiles,
    int? processedFiles,
    int? failedFiles,
    int? skippedFiles,
    Object? startedAt = _Undefined,
    Object? completedAt = _Undefined,
    Object? errorMessage = _Undefined,
  }) {
    return IndexingJob(
      id: id is int? ? id : this.id,
      folderPath: folderPath ?? this.folderPath,
      status: status ?? this.status,
      totalFiles: totalFiles ?? this.totalFiles,
      processedFiles: processedFiles ?? this.processedFiles,
      failedFiles: failedFiles ?? this.failedFiles,
      skippedFiles: skippedFiles ?? this.skippedFiles,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
    );
  }
}

class IndexingJobUpdateTable extends _i1.UpdateTable<IndexingJobTable> {
  IndexingJobUpdateTable(super.table);

  _i1.ColumnValue<String, String> folderPath(String value) => _i1.ColumnValue(
    table.folderPath,
    value,
  );

  _i1.ColumnValue<String, String> status(String value) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<int, int> totalFiles(int value) => _i1.ColumnValue(
    table.totalFiles,
    value,
  );

  _i1.ColumnValue<int, int> processedFiles(int value) => _i1.ColumnValue(
    table.processedFiles,
    value,
  );

  _i1.ColumnValue<int, int> failedFiles(int value) => _i1.ColumnValue(
    table.failedFiles,
    value,
  );

  _i1.ColumnValue<int, int> skippedFiles(int value) => _i1.ColumnValue(
    table.skippedFiles,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> startedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.startedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> completedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.completedAt,
        value,
      );

  _i1.ColumnValue<String, String> errorMessage(String? value) =>
      _i1.ColumnValue(
        table.errorMessage,
        value,
      );
}

class IndexingJobTable extends _i1.Table<int?> {
  IndexingJobTable({super.tableRelation}) : super(tableName: 'indexing_job') {
    updateTable = IndexingJobUpdateTable(this);
    folderPath = _i1.ColumnString(
      'folderPath',
      this,
    );
    status = _i1.ColumnString(
      'status',
      this,
    );
    totalFiles = _i1.ColumnInt(
      'totalFiles',
      this,
    );
    processedFiles = _i1.ColumnInt(
      'processedFiles',
      this,
    );
    failedFiles = _i1.ColumnInt(
      'failedFiles',
      this,
    );
    skippedFiles = _i1.ColumnInt(
      'skippedFiles',
      this,
    );
    startedAt = _i1.ColumnDateTime(
      'startedAt',
      this,
    );
    completedAt = _i1.ColumnDateTime(
      'completedAt',
      this,
    );
    errorMessage = _i1.ColumnString(
      'errorMessage',
      this,
    );
  }

  late final IndexingJobUpdateTable updateTable;

  /// Folder path being indexed
  late final _i1.ColumnString folderPath;

  /// Job status: queued, running, completed, failed, cancelled
  late final _i1.ColumnString status;

  /// Total files found in folder
  late final _i1.ColumnInt totalFiles;

  /// Number of files processed
  late final _i1.ColumnInt processedFiles;

  /// Number of files that failed
  late final _i1.ColumnInt failedFiles;

  /// Number of files skipped (unsupported format)
  late final _i1.ColumnInt skippedFiles;

  /// When the job started
  late final _i1.ColumnDateTime startedAt;

  /// When the job completed
  late final _i1.ColumnDateTime completedAt;

  /// Error message if job failed
  late final _i1.ColumnString errorMessage;

  @override
  List<_i1.Column> get columns => [
    id,
    folderPath,
    status,
    totalFiles,
    processedFiles,
    failedFiles,
    skippedFiles,
    startedAt,
    completedAt,
    errorMessage,
  ];
}

class IndexingJobInclude extends _i1.IncludeObject {
  IndexingJobInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => IndexingJob.t;
}

class IndexingJobIncludeList extends _i1.IncludeList {
  IndexingJobIncludeList._({
    _i1.WhereExpressionBuilder<IndexingJobTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(IndexingJob.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => IndexingJob.t;
}

class IndexingJobRepository {
  const IndexingJobRepository._();

  /// Returns a list of [IndexingJob]s matching the given query parameters.
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
  Future<List<IndexingJob>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<IndexingJobTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<IndexingJobTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<IndexingJobTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<IndexingJob>(
      where: where?.call(IndexingJob.t),
      orderBy: orderBy?.call(IndexingJob.t),
      orderByList: orderByList?.call(IndexingJob.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [IndexingJob] matching the given query parameters.
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
  Future<IndexingJob?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<IndexingJobTable>? where,
    int? offset,
    _i1.OrderByBuilder<IndexingJobTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<IndexingJobTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<IndexingJob>(
      where: where?.call(IndexingJob.t),
      orderBy: orderBy?.call(IndexingJob.t),
      orderByList: orderByList?.call(IndexingJob.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [IndexingJob] by its [id] or null if no such row exists.
  Future<IndexingJob?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<IndexingJob>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [IndexingJob]s in the list and returns the inserted rows.
  ///
  /// The returned [IndexingJob]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<IndexingJob>> insert(
    _i1.Session session,
    List<IndexingJob> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<IndexingJob>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [IndexingJob] and returns the inserted row.
  ///
  /// The returned [IndexingJob] will have its `id` field set.
  Future<IndexingJob> insertRow(
    _i1.Session session,
    IndexingJob row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<IndexingJob>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [IndexingJob]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<IndexingJob>> update(
    _i1.Session session,
    List<IndexingJob> rows, {
    _i1.ColumnSelections<IndexingJobTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<IndexingJob>(
      rows,
      columns: columns?.call(IndexingJob.t),
      transaction: transaction,
    );
  }

  /// Updates a single [IndexingJob]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<IndexingJob> updateRow(
    _i1.Session session,
    IndexingJob row, {
    _i1.ColumnSelections<IndexingJobTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<IndexingJob>(
      row,
      columns: columns?.call(IndexingJob.t),
      transaction: transaction,
    );
  }

  /// Updates a single [IndexingJob] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<IndexingJob?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<IndexingJobUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<IndexingJob>(
      id,
      columnValues: columnValues(IndexingJob.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [IndexingJob]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<IndexingJob>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<IndexingJobUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<IndexingJobTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<IndexingJobTable>? orderBy,
    _i1.OrderByListBuilder<IndexingJobTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<IndexingJob>(
      columnValues: columnValues(IndexingJob.t.updateTable),
      where: where(IndexingJob.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(IndexingJob.t),
      orderByList: orderByList?.call(IndexingJob.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [IndexingJob]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<IndexingJob>> delete(
    _i1.Session session,
    List<IndexingJob> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<IndexingJob>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [IndexingJob].
  Future<IndexingJob> deleteRow(
    _i1.Session session,
    IndexingJob row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<IndexingJob>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<IndexingJob>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<IndexingJobTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<IndexingJob>(
      where: where(IndexingJob.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<IndexingJobTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<IndexingJob>(
      where: where?.call(IndexingJob.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
