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

/// SearchHistory model - stores user search queries
abstract class SearchHistory
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  SearchHistory._({
    this.id,
    required this.query,
    required this.resultCount,
    this.topResultId,
    required this.queryTimeMs,
    required this.searchedAt,
    this.searchType,
    this.directoryContext,
  });

  factory SearchHistory({
    int? id,
    required String query,
    required int resultCount,
    int? topResultId,
    required int queryTimeMs,
    required DateTime searchedAt,
    String? searchType,
    String? directoryContext,
  }) = _SearchHistoryImpl;

  factory SearchHistory.fromJson(Map<String, dynamic> jsonSerialization) {
    return SearchHistory(
      id: jsonSerialization['id'] as int?,
      query: jsonSerialization['query'] as String,
      resultCount: jsonSerialization['resultCount'] as int,
      topResultId: jsonSerialization['topResultId'] as int?,
      queryTimeMs: jsonSerialization['queryTimeMs'] as int,
      searchedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['searchedAt'],
      ),
      searchType: jsonSerialization['searchType'] as String?,
      directoryContext: jsonSerialization['directoryContext'] as String?,
    );
  }

  static final t = SearchHistoryTable();

  static const db = SearchHistoryRepository._();

  @override
  int? id;

  /// The search query text
  String query;

  /// Number of results returned
  int resultCount;

  /// ID of the top result (if any)
  int? topResultId;

  /// Time taken to execute the query in milliseconds
  int queryTimeMs;

  /// When the search was executed
  DateTime searchedAt;

  /// Type of search: 'semantic' or 'local'
  String? searchType;

  /// Directory path for local searches (null for semantic)
  String? directoryContext;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [SearchHistory]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SearchHistory copyWith({
    int? id,
    String? query,
    int? resultCount,
    int? topResultId,
    int? queryTimeMs,
    DateTime? searchedAt,
    String? searchType,
    String? directoryContext,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SearchHistory',
      if (id != null) 'id': id,
      'query': query,
      'resultCount': resultCount,
      if (topResultId != null) 'topResultId': topResultId,
      'queryTimeMs': queryTimeMs,
      'searchedAt': searchedAt.toJson(),
      if (searchType != null) 'searchType': searchType,
      if (directoryContext != null) 'directoryContext': directoryContext,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SearchHistory',
      if (id != null) 'id': id,
      'query': query,
      'resultCount': resultCount,
      if (topResultId != null) 'topResultId': topResultId,
      'queryTimeMs': queryTimeMs,
      'searchedAt': searchedAt.toJson(),
      if (searchType != null) 'searchType': searchType,
      if (directoryContext != null) 'directoryContext': directoryContext,
    };
  }

  static SearchHistoryInclude include() {
    return SearchHistoryInclude._();
  }

  static SearchHistoryIncludeList includeList({
    _i1.WhereExpressionBuilder<SearchHistoryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SearchHistoryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SearchHistoryTable>? orderByList,
    SearchHistoryInclude? include,
  }) {
    return SearchHistoryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SearchHistory.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SearchHistory.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SearchHistoryImpl extends SearchHistory {
  _SearchHistoryImpl({
    int? id,
    required String query,
    required int resultCount,
    int? topResultId,
    required int queryTimeMs,
    required DateTime searchedAt,
    String? searchType,
    String? directoryContext,
  }) : super._(
         id: id,
         query: query,
         resultCount: resultCount,
         topResultId: topResultId,
         queryTimeMs: queryTimeMs,
         searchedAt: searchedAt,
         searchType: searchType,
         directoryContext: directoryContext,
       );

  /// Returns a shallow copy of this [SearchHistory]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SearchHistory copyWith({
    Object? id = _Undefined,
    String? query,
    int? resultCount,
    Object? topResultId = _Undefined,
    int? queryTimeMs,
    DateTime? searchedAt,
    Object? searchType = _Undefined,
    Object? directoryContext = _Undefined,
  }) {
    return SearchHistory(
      id: id is int? ? id : this.id,
      query: query ?? this.query,
      resultCount: resultCount ?? this.resultCount,
      topResultId: topResultId is int? ? topResultId : this.topResultId,
      queryTimeMs: queryTimeMs ?? this.queryTimeMs,
      searchedAt: searchedAt ?? this.searchedAt,
      searchType: searchType is String? ? searchType : this.searchType,
      directoryContext: directoryContext is String?
          ? directoryContext
          : this.directoryContext,
    );
  }
}

class SearchHistoryUpdateTable extends _i1.UpdateTable<SearchHistoryTable> {
  SearchHistoryUpdateTable(super.table);

  _i1.ColumnValue<String, String> query(String value) => _i1.ColumnValue(
    table.query,
    value,
  );

  _i1.ColumnValue<int, int> resultCount(int value) => _i1.ColumnValue(
    table.resultCount,
    value,
  );

  _i1.ColumnValue<int, int> topResultId(int? value) => _i1.ColumnValue(
    table.topResultId,
    value,
  );

  _i1.ColumnValue<int, int> queryTimeMs(int value) => _i1.ColumnValue(
    table.queryTimeMs,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> searchedAt(DateTime value) =>
      _i1.ColumnValue(
        table.searchedAt,
        value,
      );

  _i1.ColumnValue<String, String> searchType(String? value) => _i1.ColumnValue(
    table.searchType,
    value,
  );

  _i1.ColumnValue<String, String> directoryContext(String? value) =>
      _i1.ColumnValue(
        table.directoryContext,
        value,
      );
}

class SearchHistoryTable extends _i1.Table<int?> {
  SearchHistoryTable({super.tableRelation})
    : super(tableName: 'search_history') {
    updateTable = SearchHistoryUpdateTable(this);
    query = _i1.ColumnString(
      'query',
      this,
    );
    resultCount = _i1.ColumnInt(
      'resultCount',
      this,
    );
    topResultId = _i1.ColumnInt(
      'topResultId',
      this,
    );
    queryTimeMs = _i1.ColumnInt(
      'queryTimeMs',
      this,
    );
    searchedAt = _i1.ColumnDateTime(
      'searchedAt',
      this,
    );
    searchType = _i1.ColumnString(
      'searchType',
      this,
    );
    directoryContext = _i1.ColumnString(
      'directoryContext',
      this,
    );
  }

  late final SearchHistoryUpdateTable updateTable;

  /// The search query text
  late final _i1.ColumnString query;

  /// Number of results returned
  late final _i1.ColumnInt resultCount;

  /// ID of the top result (if any)
  late final _i1.ColumnInt topResultId;

  /// Time taken to execute the query in milliseconds
  late final _i1.ColumnInt queryTimeMs;

  /// When the search was executed
  late final _i1.ColumnDateTime searchedAt;

  /// Type of search: 'semantic' or 'local'
  late final _i1.ColumnString searchType;

  /// Directory path for local searches (null for semantic)
  late final _i1.ColumnString directoryContext;

  @override
  List<_i1.Column> get columns => [
    id,
    query,
    resultCount,
    topResultId,
    queryTimeMs,
    searchedAt,
    searchType,
    directoryContext,
  ];
}

class SearchHistoryInclude extends _i1.IncludeObject {
  SearchHistoryInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => SearchHistory.t;
}

class SearchHistoryIncludeList extends _i1.IncludeList {
  SearchHistoryIncludeList._({
    _i1.WhereExpressionBuilder<SearchHistoryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SearchHistory.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => SearchHistory.t;
}

class SearchHistoryRepository {
  const SearchHistoryRepository._();

  /// Returns a list of [SearchHistory]s matching the given query parameters.
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
  Future<List<SearchHistory>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SearchHistoryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SearchHistoryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SearchHistoryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<SearchHistory>(
      where: where?.call(SearchHistory.t),
      orderBy: orderBy?.call(SearchHistory.t),
      orderByList: orderByList?.call(SearchHistory.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [SearchHistory] matching the given query parameters.
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
  Future<SearchHistory?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SearchHistoryTable>? where,
    int? offset,
    _i1.OrderByBuilder<SearchHistoryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SearchHistoryTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<SearchHistory>(
      where: where?.call(SearchHistory.t),
      orderBy: orderBy?.call(SearchHistory.t),
      orderByList: orderByList?.call(SearchHistory.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [SearchHistory] by its [id] or null if no such row exists.
  Future<SearchHistory?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<SearchHistory>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [SearchHistory]s in the list and returns the inserted rows.
  ///
  /// The returned [SearchHistory]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<SearchHistory>> insert(
    _i1.Session session,
    List<SearchHistory> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<SearchHistory>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [SearchHistory] and returns the inserted row.
  ///
  /// The returned [SearchHistory] will have its `id` field set.
  Future<SearchHistory> insertRow(
    _i1.Session session,
    SearchHistory row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SearchHistory>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SearchHistory]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SearchHistory>> update(
    _i1.Session session,
    List<SearchHistory> rows, {
    _i1.ColumnSelections<SearchHistoryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SearchHistory>(
      rows,
      columns: columns?.call(SearchHistory.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SearchHistory]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SearchHistory> updateRow(
    _i1.Session session,
    SearchHistory row, {
    _i1.ColumnSelections<SearchHistoryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SearchHistory>(
      row,
      columns: columns?.call(SearchHistory.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SearchHistory] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SearchHistory?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<SearchHistoryUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<SearchHistory>(
      id,
      columnValues: columnValues(SearchHistory.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SearchHistory]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<SearchHistory>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<SearchHistoryUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SearchHistoryTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SearchHistoryTable>? orderBy,
    _i1.OrderByListBuilder<SearchHistoryTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<SearchHistory>(
      columnValues: columnValues(SearchHistory.t.updateTable),
      where: where(SearchHistory.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SearchHistory.t),
      orderByList: orderByList?.call(SearchHistory.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [SearchHistory]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SearchHistory>> delete(
    _i1.Session session,
    List<SearchHistory> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SearchHistory>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SearchHistory].
  Future<SearchHistory> deleteRow(
    _i1.Session session,
    SearchHistory row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SearchHistory>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SearchHistory>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<SearchHistoryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SearchHistory>(
      where: where(SearchHistory.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SearchHistoryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SearchHistory>(
      where: where?.call(SearchHistory.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
