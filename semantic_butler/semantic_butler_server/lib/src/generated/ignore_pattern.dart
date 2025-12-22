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

/// IgnorePattern model - stores patterns to exclude from indexing
abstract class IgnorePattern
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  IgnorePattern._({
    this.id,
    required this.pattern,
    required this.patternType,
    this.description,
    required this.createdAt,
  });

  factory IgnorePattern({
    int? id,
    required String pattern,
    required String patternType,
    String? description,
    required DateTime createdAt,
  }) = _IgnorePatternImpl;

  factory IgnorePattern.fromJson(Map<String, dynamic> jsonSerialization) {
    return IgnorePattern(
      id: jsonSerialization['id'] as int?,
      pattern: jsonSerialization['pattern'] as String,
      patternType: jsonSerialization['patternType'] as String,
      description: jsonSerialization['description'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = IgnorePatternTable();

  static const db = IgnorePatternRepository._();

  @override
  int? id;

  /// Glob pattern like "*.log", "node_modules/**", or specific paths
  String pattern;

  /// Pattern type: file, directory, or both
  String patternType;

  /// Optional description for the pattern
  String? description;

  /// When the pattern was created
  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [IgnorePattern]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IgnorePattern copyWith({
    int? id,
    String? pattern,
    String? patternType,
    String? description,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IgnorePattern',
      if (id != null) 'id': id,
      'pattern': pattern,
      'patternType': patternType,
      if (description != null) 'description': description,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IgnorePattern',
      if (id != null) 'id': id,
      'pattern': pattern,
      'patternType': patternType,
      if (description != null) 'description': description,
      'createdAt': createdAt.toJson(),
    };
  }

  static IgnorePatternInclude include() {
    return IgnorePatternInclude._();
  }

  static IgnorePatternIncludeList includeList({
    _i1.WhereExpressionBuilder<IgnorePatternTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<IgnorePatternTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<IgnorePatternTable>? orderByList,
    IgnorePatternInclude? include,
  }) {
    return IgnorePatternIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(IgnorePattern.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(IgnorePattern.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IgnorePatternImpl extends IgnorePattern {
  _IgnorePatternImpl({
    int? id,
    required String pattern,
    required String patternType,
    String? description,
    required DateTime createdAt,
  }) : super._(
         id: id,
         pattern: pattern,
         patternType: patternType,
         description: description,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [IgnorePattern]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IgnorePattern copyWith({
    Object? id = _Undefined,
    String? pattern,
    String? patternType,
    Object? description = _Undefined,
    DateTime? createdAt,
  }) {
    return IgnorePattern(
      id: id is int? ? id : this.id,
      pattern: pattern ?? this.pattern,
      patternType: patternType ?? this.patternType,
      description: description is String? ? description : this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class IgnorePatternUpdateTable extends _i1.UpdateTable<IgnorePatternTable> {
  IgnorePatternUpdateTable(super.table);

  _i1.ColumnValue<String, String> pattern(String value) => _i1.ColumnValue(
    table.pattern,
    value,
  );

  _i1.ColumnValue<String, String> patternType(String value) => _i1.ColumnValue(
    table.patternType,
    value,
  );

  _i1.ColumnValue<String, String> description(String? value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class IgnorePatternTable extends _i1.Table<int?> {
  IgnorePatternTable({super.tableRelation})
    : super(tableName: 'ignore_pattern') {
    updateTable = IgnorePatternUpdateTable(this);
    pattern = _i1.ColumnString(
      'pattern',
      this,
    );
    patternType = _i1.ColumnString(
      'patternType',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final IgnorePatternUpdateTable updateTable;

  /// Glob pattern like "*.log", "node_modules/**", or specific paths
  late final _i1.ColumnString pattern;

  /// Pattern type: file, directory, or both
  late final _i1.ColumnString patternType;

  /// Optional description for the pattern
  late final _i1.ColumnString description;

  /// When the pattern was created
  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    pattern,
    patternType,
    description,
    createdAt,
  ];
}

class IgnorePatternInclude extends _i1.IncludeObject {
  IgnorePatternInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => IgnorePattern.t;
}

class IgnorePatternIncludeList extends _i1.IncludeList {
  IgnorePatternIncludeList._({
    _i1.WhereExpressionBuilder<IgnorePatternTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(IgnorePattern.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => IgnorePattern.t;
}

class IgnorePatternRepository {
  const IgnorePatternRepository._();

  /// Returns a list of [IgnorePattern]s matching the given query parameters.
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
  Future<List<IgnorePattern>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<IgnorePatternTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<IgnorePatternTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<IgnorePatternTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<IgnorePattern>(
      where: where?.call(IgnorePattern.t),
      orderBy: orderBy?.call(IgnorePattern.t),
      orderByList: orderByList?.call(IgnorePattern.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [IgnorePattern] matching the given query parameters.
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
  Future<IgnorePattern?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<IgnorePatternTable>? where,
    int? offset,
    _i1.OrderByBuilder<IgnorePatternTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<IgnorePatternTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<IgnorePattern>(
      where: where?.call(IgnorePattern.t),
      orderBy: orderBy?.call(IgnorePattern.t),
      orderByList: orderByList?.call(IgnorePattern.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [IgnorePattern] by its [id] or null if no such row exists.
  Future<IgnorePattern?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<IgnorePattern>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [IgnorePattern]s in the list and returns the inserted rows.
  ///
  /// The returned [IgnorePattern]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<IgnorePattern>> insert(
    _i1.Session session,
    List<IgnorePattern> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<IgnorePattern>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [IgnorePattern] and returns the inserted row.
  ///
  /// The returned [IgnorePattern] will have its `id` field set.
  Future<IgnorePattern> insertRow(
    _i1.Session session,
    IgnorePattern row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<IgnorePattern>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [IgnorePattern]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<IgnorePattern>> update(
    _i1.Session session,
    List<IgnorePattern> rows, {
    _i1.ColumnSelections<IgnorePatternTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<IgnorePattern>(
      rows,
      columns: columns?.call(IgnorePattern.t),
      transaction: transaction,
    );
  }

  /// Updates a single [IgnorePattern]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<IgnorePattern> updateRow(
    _i1.Session session,
    IgnorePattern row, {
    _i1.ColumnSelections<IgnorePatternTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<IgnorePattern>(
      row,
      columns: columns?.call(IgnorePattern.t),
      transaction: transaction,
    );
  }

  /// Updates a single [IgnorePattern] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<IgnorePattern?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<IgnorePatternUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<IgnorePattern>(
      id,
      columnValues: columnValues(IgnorePattern.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [IgnorePattern]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<IgnorePattern>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<IgnorePatternUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<IgnorePatternTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<IgnorePatternTable>? orderBy,
    _i1.OrderByListBuilder<IgnorePatternTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<IgnorePattern>(
      columnValues: columnValues(IgnorePattern.t.updateTable),
      where: where(IgnorePattern.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(IgnorePattern.t),
      orderByList: orderByList?.call(IgnorePattern.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [IgnorePattern]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<IgnorePattern>> delete(
    _i1.Session session,
    List<IgnorePattern> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<IgnorePattern>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [IgnorePattern].
  Future<IgnorePattern> deleteRow(
    _i1.Session session,
    IgnorePattern row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<IgnorePattern>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<IgnorePattern>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<IgnorePatternTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<IgnorePattern>(
      where: where(IgnorePattern.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<IgnorePatternTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<IgnorePattern>(
      where: where?.call(IgnorePattern.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
