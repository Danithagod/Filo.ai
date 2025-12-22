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

/// AgentFileCommand model - tracks file operations for audit/undo
abstract class AgentFileCommand
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  AgentFileCommand._({
    this.id,
    required this.operation,
    required this.sourcePath,
    this.destinationPath,
    this.newName,
    required this.executedAt,
    required this.success,
    this.errorMessage,
    required this.reversible,
    required this.wasUndone,
  });

  factory AgentFileCommand({
    int? id,
    required String operation,
    required String sourcePath,
    String? destinationPath,
    String? newName,
    required DateTime executedAt,
    required bool success,
    String? errorMessage,
    required bool reversible,
    required bool wasUndone,
  }) = _AgentFileCommandImpl;

  factory AgentFileCommand.fromJson(Map<String, dynamic> jsonSerialization) {
    return AgentFileCommand(
      id: jsonSerialization['id'] as int?,
      operation: jsonSerialization['operation'] as String,
      sourcePath: jsonSerialization['sourcePath'] as String,
      destinationPath: jsonSerialization['destinationPath'] as String?,
      newName: jsonSerialization['newName'] as String?,
      executedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['executedAt'],
      ),
      success: jsonSerialization['success'] as bool,
      errorMessage: jsonSerialization['errorMessage'] as String?,
      reversible: jsonSerialization['reversible'] as bool,
      wasUndone: jsonSerialization['wasUndone'] as bool,
    );
  }

  static final t = AgentFileCommandTable();

  static const db = AgentFileCommandRepository._();

  @override
  int? id;

  /// Operation type: rename, move, delete, create
  String operation;

  /// Source file or folder path
  String sourcePath;

  /// Destination path (for move/rename operations)
  String? destinationPath;

  /// New name (for rename operations)
  String? newName;

  /// When the operation was executed
  DateTime executedAt;

  /// Whether the operation succeeded
  bool success;

  /// Error message if operation failed
  String? errorMessage;

  /// Whether this operation can be undone
  bool reversible;

  /// Whether this was undone
  bool wasUndone;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [AgentFileCommand]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AgentFileCommand copyWith({
    int? id,
    String? operation,
    String? sourcePath,
    String? destinationPath,
    String? newName,
    DateTime? executedAt,
    bool? success,
    String? errorMessage,
    bool? reversible,
    bool? wasUndone,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AgentFileCommand',
      if (id != null) 'id': id,
      'operation': operation,
      'sourcePath': sourcePath,
      if (destinationPath != null) 'destinationPath': destinationPath,
      if (newName != null) 'newName': newName,
      'executedAt': executedAt.toJson(),
      'success': success,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'reversible': reversible,
      'wasUndone': wasUndone,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AgentFileCommand',
      if (id != null) 'id': id,
      'operation': operation,
      'sourcePath': sourcePath,
      if (destinationPath != null) 'destinationPath': destinationPath,
      if (newName != null) 'newName': newName,
      'executedAt': executedAt.toJson(),
      'success': success,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'reversible': reversible,
      'wasUndone': wasUndone,
    };
  }

  static AgentFileCommandInclude include() {
    return AgentFileCommandInclude._();
  }

  static AgentFileCommandIncludeList includeList({
    _i1.WhereExpressionBuilder<AgentFileCommandTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AgentFileCommandTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AgentFileCommandTable>? orderByList,
    AgentFileCommandInclude? include,
  }) {
    return AgentFileCommandIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AgentFileCommand.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(AgentFileCommand.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AgentFileCommandImpl extends AgentFileCommand {
  _AgentFileCommandImpl({
    int? id,
    required String operation,
    required String sourcePath,
    String? destinationPath,
    String? newName,
    required DateTime executedAt,
    required bool success,
    String? errorMessage,
    required bool reversible,
    required bool wasUndone,
  }) : super._(
         id: id,
         operation: operation,
         sourcePath: sourcePath,
         destinationPath: destinationPath,
         newName: newName,
         executedAt: executedAt,
         success: success,
         errorMessage: errorMessage,
         reversible: reversible,
         wasUndone: wasUndone,
       );

  /// Returns a shallow copy of this [AgentFileCommand]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AgentFileCommand copyWith({
    Object? id = _Undefined,
    String? operation,
    String? sourcePath,
    Object? destinationPath = _Undefined,
    Object? newName = _Undefined,
    DateTime? executedAt,
    bool? success,
    Object? errorMessage = _Undefined,
    bool? reversible,
    bool? wasUndone,
  }) {
    return AgentFileCommand(
      id: id is int? ? id : this.id,
      operation: operation ?? this.operation,
      sourcePath: sourcePath ?? this.sourcePath,
      destinationPath: destinationPath is String?
          ? destinationPath
          : this.destinationPath,
      newName: newName is String? ? newName : this.newName,
      executedAt: executedAt ?? this.executedAt,
      success: success ?? this.success,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      reversible: reversible ?? this.reversible,
      wasUndone: wasUndone ?? this.wasUndone,
    );
  }
}

class AgentFileCommandUpdateTable
    extends _i1.UpdateTable<AgentFileCommandTable> {
  AgentFileCommandUpdateTable(super.table);

  _i1.ColumnValue<String, String> operation(String value) => _i1.ColumnValue(
    table.operation,
    value,
  );

  _i1.ColumnValue<String, String> sourcePath(String value) => _i1.ColumnValue(
    table.sourcePath,
    value,
  );

  _i1.ColumnValue<String, String> destinationPath(String? value) =>
      _i1.ColumnValue(
        table.destinationPath,
        value,
      );

  _i1.ColumnValue<String, String> newName(String? value) => _i1.ColumnValue(
    table.newName,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> executedAt(DateTime value) =>
      _i1.ColumnValue(
        table.executedAt,
        value,
      );

  _i1.ColumnValue<bool, bool> success(bool value) => _i1.ColumnValue(
    table.success,
    value,
  );

  _i1.ColumnValue<String, String> errorMessage(String? value) =>
      _i1.ColumnValue(
        table.errorMessage,
        value,
      );

  _i1.ColumnValue<bool, bool> reversible(bool value) => _i1.ColumnValue(
    table.reversible,
    value,
  );

  _i1.ColumnValue<bool, bool> wasUndone(bool value) => _i1.ColumnValue(
    table.wasUndone,
    value,
  );
}

class AgentFileCommandTable extends _i1.Table<int?> {
  AgentFileCommandTable({super.tableRelation})
    : super(tableName: 'agent_file_command') {
    updateTable = AgentFileCommandUpdateTable(this);
    operation = _i1.ColumnString(
      'operation',
      this,
    );
    sourcePath = _i1.ColumnString(
      'sourcePath',
      this,
    );
    destinationPath = _i1.ColumnString(
      'destinationPath',
      this,
    );
    newName = _i1.ColumnString(
      'newName',
      this,
    );
    executedAt = _i1.ColumnDateTime(
      'executedAt',
      this,
    );
    success = _i1.ColumnBool(
      'success',
      this,
    );
    errorMessage = _i1.ColumnString(
      'errorMessage',
      this,
    );
    reversible = _i1.ColumnBool(
      'reversible',
      this,
    );
    wasUndone = _i1.ColumnBool(
      'wasUndone',
      this,
    );
  }

  late final AgentFileCommandUpdateTable updateTable;

  /// Operation type: rename, move, delete, create
  late final _i1.ColumnString operation;

  /// Source file or folder path
  late final _i1.ColumnString sourcePath;

  /// Destination path (for move/rename operations)
  late final _i1.ColumnString destinationPath;

  /// New name (for rename operations)
  late final _i1.ColumnString newName;

  /// When the operation was executed
  late final _i1.ColumnDateTime executedAt;

  /// Whether the operation succeeded
  late final _i1.ColumnBool success;

  /// Error message if operation failed
  late final _i1.ColumnString errorMessage;

  /// Whether this operation can be undone
  late final _i1.ColumnBool reversible;

  /// Whether this was undone
  late final _i1.ColumnBool wasUndone;

  @override
  List<_i1.Column> get columns => [
    id,
    operation,
    sourcePath,
    destinationPath,
    newName,
    executedAt,
    success,
    errorMessage,
    reversible,
    wasUndone,
  ];
}

class AgentFileCommandInclude extends _i1.IncludeObject {
  AgentFileCommandInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => AgentFileCommand.t;
}

class AgentFileCommandIncludeList extends _i1.IncludeList {
  AgentFileCommandIncludeList._({
    _i1.WhereExpressionBuilder<AgentFileCommandTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AgentFileCommand.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => AgentFileCommand.t;
}

class AgentFileCommandRepository {
  const AgentFileCommandRepository._();

  /// Returns a list of [AgentFileCommand]s matching the given query parameters.
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
  Future<List<AgentFileCommand>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AgentFileCommandTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AgentFileCommandTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AgentFileCommandTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<AgentFileCommand>(
      where: where?.call(AgentFileCommand.t),
      orderBy: orderBy?.call(AgentFileCommand.t),
      orderByList: orderByList?.call(AgentFileCommand.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [AgentFileCommand] matching the given query parameters.
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
  Future<AgentFileCommand?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AgentFileCommandTable>? where,
    int? offset,
    _i1.OrderByBuilder<AgentFileCommandTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AgentFileCommandTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<AgentFileCommand>(
      where: where?.call(AgentFileCommand.t),
      orderBy: orderBy?.call(AgentFileCommand.t),
      orderByList: orderByList?.call(AgentFileCommand.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [AgentFileCommand] by its [id] or null if no such row exists.
  Future<AgentFileCommand?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<AgentFileCommand>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [AgentFileCommand]s in the list and returns the inserted rows.
  ///
  /// The returned [AgentFileCommand]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<AgentFileCommand>> insert(
    _i1.Session session,
    List<AgentFileCommand> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<AgentFileCommand>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [AgentFileCommand] and returns the inserted row.
  ///
  /// The returned [AgentFileCommand] will have its `id` field set.
  Future<AgentFileCommand> insertRow(
    _i1.Session session,
    AgentFileCommand row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<AgentFileCommand>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [AgentFileCommand]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<AgentFileCommand>> update(
    _i1.Session session,
    List<AgentFileCommand> rows, {
    _i1.ColumnSelections<AgentFileCommandTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<AgentFileCommand>(
      rows,
      columns: columns?.call(AgentFileCommand.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AgentFileCommand]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AgentFileCommand> updateRow(
    _i1.Session session,
    AgentFileCommand row, {
    _i1.ColumnSelections<AgentFileCommandTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<AgentFileCommand>(
      row,
      columns: columns?.call(AgentFileCommand.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AgentFileCommand] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AgentFileCommand?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<AgentFileCommandUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<AgentFileCommand>(
      id,
      columnValues: columnValues(AgentFileCommand.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AgentFileCommand]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<AgentFileCommand>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<AgentFileCommandUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<AgentFileCommandTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AgentFileCommandTable>? orderBy,
    _i1.OrderByListBuilder<AgentFileCommandTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<AgentFileCommand>(
      columnValues: columnValues(AgentFileCommand.t.updateTable),
      where: where(AgentFileCommand.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AgentFileCommand.t),
      orderByList: orderByList?.call(AgentFileCommand.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [AgentFileCommand]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<AgentFileCommand>> delete(
    _i1.Session session,
    List<AgentFileCommand> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<AgentFileCommand>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [AgentFileCommand].
  Future<AgentFileCommand> deleteRow(
    _i1.Session session,
    AgentFileCommand row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AgentFileCommand>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<AgentFileCommand>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<AgentFileCommandTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<AgentFileCommand>(
      where: where(AgentFileCommand.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AgentFileCommandTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<AgentFileCommand>(
      where: where?.call(AgentFileCommand.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
