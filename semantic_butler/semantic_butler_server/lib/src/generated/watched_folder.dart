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

/// WatchedFolder - Tracks folders being watched for automatic re-indexing
abstract class WatchedFolder
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  WatchedFolder._({
    this.id,
    required this.path,
    required this.isEnabled,
    this.lastEventAt,
    this.filesWatched,
  });

  factory WatchedFolder({
    int? id,
    required String path,
    required bool isEnabled,
    DateTime? lastEventAt,
    int? filesWatched,
  }) = _WatchedFolderImpl;

  factory WatchedFolder.fromJson(Map<String, dynamic> jsonSerialization) {
    return WatchedFolder(
      id: jsonSerialization['id'] as int?,
      path: jsonSerialization['path'] as String,
      isEnabled: jsonSerialization['isEnabled'] as bool,
      lastEventAt: jsonSerialization['lastEventAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastEventAt'],
            ),
      filesWatched: jsonSerialization['filesWatched'] as int?,
    );
  }

  static final t = WatchedFolderTable();

  static const db = WatchedFolderRepository._();

  @override
  int? id;

  /// The absolute path to the watched folder
  String path;

  /// Whether smart indexing is currently enabled for this folder
  bool isEnabled;

  /// Timestamp of the last detected file event
  DateTime? lastEventAt;

  /// Number of files currently being monitored
  int? filesWatched;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [WatchedFolder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WatchedFolder copyWith({
    int? id,
    String? path,
    bool? isEnabled,
    DateTime? lastEventAt,
    int? filesWatched,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WatchedFolder',
      if (id != null) 'id': id,
      'path': path,
      'isEnabled': isEnabled,
      if (lastEventAt != null) 'lastEventAt': lastEventAt?.toJson(),
      if (filesWatched != null) 'filesWatched': filesWatched,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WatchedFolder',
      if (id != null) 'id': id,
      'path': path,
      'isEnabled': isEnabled,
      if (lastEventAt != null) 'lastEventAt': lastEventAt?.toJson(),
      if (filesWatched != null) 'filesWatched': filesWatched,
    };
  }

  static WatchedFolderInclude include() {
    return WatchedFolderInclude._();
  }

  static WatchedFolderIncludeList includeList({
    _i1.WhereExpressionBuilder<WatchedFolderTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WatchedFolderTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WatchedFolderTable>? orderByList,
    WatchedFolderInclude? include,
  }) {
    return WatchedFolderIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WatchedFolder.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(WatchedFolder.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WatchedFolderImpl extends WatchedFolder {
  _WatchedFolderImpl({
    int? id,
    required String path,
    required bool isEnabled,
    DateTime? lastEventAt,
    int? filesWatched,
  }) : super._(
         id: id,
         path: path,
         isEnabled: isEnabled,
         lastEventAt: lastEventAt,
         filesWatched: filesWatched,
       );

  /// Returns a shallow copy of this [WatchedFolder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WatchedFolder copyWith({
    Object? id = _Undefined,
    String? path,
    bool? isEnabled,
    Object? lastEventAt = _Undefined,
    Object? filesWatched = _Undefined,
  }) {
    return WatchedFolder(
      id: id is int? ? id : this.id,
      path: path ?? this.path,
      isEnabled: isEnabled ?? this.isEnabled,
      lastEventAt: lastEventAt is DateTime? ? lastEventAt : this.lastEventAt,
      filesWatched: filesWatched is int? ? filesWatched : this.filesWatched,
    );
  }
}

class WatchedFolderUpdateTable extends _i1.UpdateTable<WatchedFolderTable> {
  WatchedFolderUpdateTable(super.table);

  _i1.ColumnValue<String, String> path(String value) => _i1.ColumnValue(
    table.path,
    value,
  );

  _i1.ColumnValue<bool, bool> isEnabled(bool value) => _i1.ColumnValue(
    table.isEnabled,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> lastEventAt(DateTime? value) =>
      _i1.ColumnValue(
        table.lastEventAt,
        value,
      );

  _i1.ColumnValue<int, int> filesWatched(int? value) => _i1.ColumnValue(
    table.filesWatched,
    value,
  );
}

class WatchedFolderTable extends _i1.Table<int?> {
  WatchedFolderTable({super.tableRelation})
    : super(tableName: 'watched_folders') {
    updateTable = WatchedFolderUpdateTable(this);
    path = _i1.ColumnString(
      'path',
      this,
    );
    isEnabled = _i1.ColumnBool(
      'isEnabled',
      this,
    );
    lastEventAt = _i1.ColumnDateTime(
      'lastEventAt',
      this,
    );
    filesWatched = _i1.ColumnInt(
      'filesWatched',
      this,
    );
  }

  late final WatchedFolderUpdateTable updateTable;

  /// The absolute path to the watched folder
  late final _i1.ColumnString path;

  /// Whether smart indexing is currently enabled for this folder
  late final _i1.ColumnBool isEnabled;

  /// Timestamp of the last detected file event
  late final _i1.ColumnDateTime lastEventAt;

  /// Number of files currently being monitored
  late final _i1.ColumnInt filesWatched;

  @override
  List<_i1.Column> get columns => [
    id,
    path,
    isEnabled,
    lastEventAt,
    filesWatched,
  ];
}

class WatchedFolderInclude extends _i1.IncludeObject {
  WatchedFolderInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => WatchedFolder.t;
}

class WatchedFolderIncludeList extends _i1.IncludeList {
  WatchedFolderIncludeList._({
    _i1.WhereExpressionBuilder<WatchedFolderTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WatchedFolder.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => WatchedFolder.t;
}

class WatchedFolderRepository {
  const WatchedFolderRepository._();

  /// Returns a list of [WatchedFolder]s matching the given query parameters.
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
  Future<List<WatchedFolder>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<WatchedFolderTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WatchedFolderTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WatchedFolderTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<WatchedFolder>(
      where: where?.call(WatchedFolder.t),
      orderBy: orderBy?.call(WatchedFolder.t),
      orderByList: orderByList?.call(WatchedFolder.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [WatchedFolder] matching the given query parameters.
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
  Future<WatchedFolder?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<WatchedFolderTable>? where,
    int? offset,
    _i1.OrderByBuilder<WatchedFolderTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WatchedFolderTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<WatchedFolder>(
      where: where?.call(WatchedFolder.t),
      orderBy: orderBy?.call(WatchedFolder.t),
      orderByList: orderByList?.call(WatchedFolder.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [WatchedFolder] by its [id] or null if no such row exists.
  Future<WatchedFolder?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<WatchedFolder>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [WatchedFolder]s in the list and returns the inserted rows.
  ///
  /// The returned [WatchedFolder]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<WatchedFolder>> insert(
    _i1.Session session,
    List<WatchedFolder> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<WatchedFolder>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [WatchedFolder] and returns the inserted row.
  ///
  /// The returned [WatchedFolder] will have its `id` field set.
  Future<WatchedFolder> insertRow(
    _i1.Session session,
    WatchedFolder row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<WatchedFolder>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [WatchedFolder]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<WatchedFolder>> update(
    _i1.Session session,
    List<WatchedFolder> rows, {
    _i1.ColumnSelections<WatchedFolderTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<WatchedFolder>(
      rows,
      columns: columns?.call(WatchedFolder.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WatchedFolder]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WatchedFolder> updateRow(
    _i1.Session session,
    WatchedFolder row, {
    _i1.ColumnSelections<WatchedFolderTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<WatchedFolder>(
      row,
      columns: columns?.call(WatchedFolder.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WatchedFolder] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WatchedFolder?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<WatchedFolderUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<WatchedFolder>(
      id,
      columnValues: columnValues(WatchedFolder.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WatchedFolder]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<WatchedFolder>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<WatchedFolderUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<WatchedFolderTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WatchedFolderTable>? orderBy,
    _i1.OrderByListBuilder<WatchedFolderTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<WatchedFolder>(
      columnValues: columnValues(WatchedFolder.t.updateTable),
      where: where(WatchedFolder.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WatchedFolder.t),
      orderByList: orderByList?.call(WatchedFolder.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [WatchedFolder]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<WatchedFolder>> delete(
    _i1.Session session,
    List<WatchedFolder> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<WatchedFolder>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [WatchedFolder].
  Future<WatchedFolder> deleteRow(
    _i1.Session session,
    WatchedFolder row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WatchedFolder>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<WatchedFolder>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<WatchedFolderTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<WatchedFolder>(
      where: where(WatchedFolder.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<WatchedFolderTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<WatchedFolder>(
      where: where?.call(WatchedFolder.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
