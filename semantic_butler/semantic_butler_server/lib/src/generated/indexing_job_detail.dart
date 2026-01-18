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

/// IndexingJobDetail model - tracks individual file progress within an indexing job
abstract class IndexingJobDetail
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  IndexingJobDetail._({
    this.id,
    required this.jobId,
    required this.filePath,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.errorCategory,
  });

  factory IndexingJobDetail({
    int? id,
    required int jobId,
    required String filePath,
    required String status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    String? errorCategory,
  }) = _IndexingJobDetailImpl;

  factory IndexingJobDetail.fromJson(Map<String, dynamic> jsonSerialization) {
    return IndexingJobDetail(
      id: jsonSerialization['id'] as int?,
      jobId: jsonSerialization['jobId'] as int,
      filePath: jsonSerialization['filePath'] as String,
      status: jsonSerialization['status'] as String,
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      errorMessage: jsonSerialization['errorMessage'] as String?,
      errorCategory: jsonSerialization['errorCategory'] as String?,
    );
  }

  static final t = IndexingJobDetailTable();

  static const db = IndexingJobDetailRepository._();

  @override
  int? id;

  /// Reference to the parent indexing job
  int jobId;

  /// File path being processed
  String filePath;

  /// Current status: discovered, extracting, summarizing, embedding, complete, skipped, failed
  String status;

  /// When processing started for this file
  DateTime? startedAt;

  /// When processing completed for this file
  DateTime? completedAt;

  /// Error message if processing failed
  String? errorMessage;

  /// Error category if processing failed (e.g., APITimeout, CorruptFile, NetworkError)
  String? errorCategory;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [IndexingJobDetail]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IndexingJobDetail copyWith({
    int? id,
    int? jobId,
    String? filePath,
    String? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    String? errorCategory,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IndexingJobDetail',
      if (id != null) 'id': id,
      'jobId': jobId,
      'filePath': filePath,
      'status': status,
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (errorCategory != null) 'errorCategory': errorCategory,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IndexingJobDetail',
      if (id != null) 'id': id,
      'jobId': jobId,
      'filePath': filePath,
      'status': status,
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (errorCategory != null) 'errorCategory': errorCategory,
    };
  }

  static IndexingJobDetailInclude include() {
    return IndexingJobDetailInclude._();
  }

  static IndexingJobDetailIncludeList includeList({
    _i1.WhereExpressionBuilder<IndexingJobDetailTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<IndexingJobDetailTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<IndexingJobDetailTable>? orderByList,
    IndexingJobDetailInclude? include,
  }) {
    return IndexingJobDetailIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(IndexingJobDetail.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(IndexingJobDetail.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IndexingJobDetailImpl extends IndexingJobDetail {
  _IndexingJobDetailImpl({
    int? id,
    required int jobId,
    required String filePath,
    required String status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    String? errorCategory,
  }) : super._(
         id: id,
         jobId: jobId,
         filePath: filePath,
         status: status,
         startedAt: startedAt,
         completedAt: completedAt,
         errorMessage: errorMessage,
         errorCategory: errorCategory,
       );

  /// Returns a shallow copy of this [IndexingJobDetail]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IndexingJobDetail copyWith({
    Object? id = _Undefined,
    int? jobId,
    String? filePath,
    String? status,
    Object? startedAt = _Undefined,
    Object? completedAt = _Undefined,
    Object? errorMessage = _Undefined,
    Object? errorCategory = _Undefined,
  }) {
    return IndexingJobDetail(
      id: id is int? ? id : this.id,
      jobId: jobId ?? this.jobId,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      errorCategory: errorCategory is String?
          ? errorCategory
          : this.errorCategory,
    );
  }
}

class IndexingJobDetailUpdateTable
    extends _i1.UpdateTable<IndexingJobDetailTable> {
  IndexingJobDetailUpdateTable(super.table);

  _i1.ColumnValue<int, int> jobId(int value) => _i1.ColumnValue(
    table.jobId,
    value,
  );

  _i1.ColumnValue<String, String> filePath(String value) => _i1.ColumnValue(
    table.filePath,
    value,
  );

  _i1.ColumnValue<String, String> status(String value) => _i1.ColumnValue(
    table.status,
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

  _i1.ColumnValue<String, String> errorCategory(String? value) =>
      _i1.ColumnValue(
        table.errorCategory,
        value,
      );
}

class IndexingJobDetailTable extends _i1.Table<int?> {
  IndexingJobDetailTable({super.tableRelation})
    : super(tableName: 'indexing_job_detail') {
    updateTable = IndexingJobDetailUpdateTable(this);
    jobId = _i1.ColumnInt(
      'jobId',
      this,
    );
    filePath = _i1.ColumnString(
      'filePath',
      this,
    );
    status = _i1.ColumnString(
      'status',
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
    errorCategory = _i1.ColumnString(
      'errorCategory',
      this,
    );
  }

  late final IndexingJobDetailUpdateTable updateTable;

  /// Reference to the parent indexing job
  late final _i1.ColumnInt jobId;

  /// File path being processed
  late final _i1.ColumnString filePath;

  /// Current status: discovered, extracting, summarizing, embedding, complete, skipped, failed
  late final _i1.ColumnString status;

  /// When processing started for this file
  late final _i1.ColumnDateTime startedAt;

  /// When processing completed for this file
  late final _i1.ColumnDateTime completedAt;

  /// Error message if processing failed
  late final _i1.ColumnString errorMessage;

  /// Error category if processing failed (e.g., APITimeout, CorruptFile, NetworkError)
  late final _i1.ColumnString errorCategory;

  @override
  List<_i1.Column> get columns => [
    id,
    jobId,
    filePath,
    status,
    startedAt,
    completedAt,
    errorMessage,
    errorCategory,
  ];
}

class IndexingJobDetailInclude extends _i1.IncludeObject {
  IndexingJobDetailInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => IndexingJobDetail.t;
}

class IndexingJobDetailIncludeList extends _i1.IncludeList {
  IndexingJobDetailIncludeList._({
    _i1.WhereExpressionBuilder<IndexingJobDetailTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(IndexingJobDetail.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => IndexingJobDetail.t;
}

class IndexingJobDetailRepository {
  const IndexingJobDetailRepository._();

  /// Returns a list of [IndexingJobDetail]s matching the given query parameters.
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
  Future<List<IndexingJobDetail>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<IndexingJobDetailTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<IndexingJobDetailTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<IndexingJobDetailTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<IndexingJobDetail>(
      where: where?.call(IndexingJobDetail.t),
      orderBy: orderBy?.call(IndexingJobDetail.t),
      orderByList: orderByList?.call(IndexingJobDetail.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [IndexingJobDetail] matching the given query parameters.
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
  Future<IndexingJobDetail?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<IndexingJobDetailTable>? where,
    int? offset,
    _i1.OrderByBuilder<IndexingJobDetailTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<IndexingJobDetailTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<IndexingJobDetail>(
      where: where?.call(IndexingJobDetail.t),
      orderBy: orderBy?.call(IndexingJobDetail.t),
      orderByList: orderByList?.call(IndexingJobDetail.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [IndexingJobDetail] by its [id] or null if no such row exists.
  Future<IndexingJobDetail?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<IndexingJobDetail>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [IndexingJobDetail]s in the list and returns the inserted rows.
  ///
  /// The returned [IndexingJobDetail]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<IndexingJobDetail>> insert(
    _i1.Session session,
    List<IndexingJobDetail> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<IndexingJobDetail>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [IndexingJobDetail] and returns the inserted row.
  ///
  /// The returned [IndexingJobDetail] will have its `id` field set.
  Future<IndexingJobDetail> insertRow(
    _i1.Session session,
    IndexingJobDetail row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<IndexingJobDetail>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [IndexingJobDetail]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<IndexingJobDetail>> update(
    _i1.Session session,
    List<IndexingJobDetail> rows, {
    _i1.ColumnSelections<IndexingJobDetailTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<IndexingJobDetail>(
      rows,
      columns: columns?.call(IndexingJobDetail.t),
      transaction: transaction,
    );
  }

  /// Updates a single [IndexingJobDetail]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<IndexingJobDetail> updateRow(
    _i1.Session session,
    IndexingJobDetail row, {
    _i1.ColumnSelections<IndexingJobDetailTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<IndexingJobDetail>(
      row,
      columns: columns?.call(IndexingJobDetail.t),
      transaction: transaction,
    );
  }

  /// Updates a single [IndexingJobDetail] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<IndexingJobDetail?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<IndexingJobDetailUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<IndexingJobDetail>(
      id,
      columnValues: columnValues(IndexingJobDetail.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [IndexingJobDetail]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<IndexingJobDetail>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<IndexingJobDetailUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<IndexingJobDetailTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<IndexingJobDetailTable>? orderBy,
    _i1.OrderByListBuilder<IndexingJobDetailTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<IndexingJobDetail>(
      columnValues: columnValues(IndexingJobDetail.t.updateTable),
      where: where(IndexingJobDetail.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(IndexingJobDetail.t),
      orderByList: orderByList?.call(IndexingJobDetail.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [IndexingJobDetail]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<IndexingJobDetail>> delete(
    _i1.Session session,
    List<IndexingJobDetail> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<IndexingJobDetail>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [IndexingJobDetail].
  Future<IndexingJobDetail> deleteRow(
    _i1.Session session,
    IndexingJobDetail row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<IndexingJobDetail>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<IndexingJobDetail>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<IndexingJobDetailTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<IndexingJobDetail>(
      where: where(IndexingJobDetail.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<IndexingJobDetailTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<IndexingJobDetail>(
      where: where?.call(IndexingJobDetail.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
