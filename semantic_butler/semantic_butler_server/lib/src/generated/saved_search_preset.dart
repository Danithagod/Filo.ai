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
import 'package:semantic_butler_server/src/generated/protocol.dart' as _i2;

abstract class SavedSearchPreset
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  SavedSearchPreset._({
    this.id,
    required this.name,
    required this.query,
    this.category,
    this.tags,
    this.fileTypes,
    this.dateFrom,
    this.dateTo,
    this.minSize,
    this.maxSize,
    required this.createdAt,
    required this.usageCount,
  });

  factory SavedSearchPreset({
    int? id,
    required String name,
    required String query,
    String? category,
    List<String>? tags,
    List<String>? fileTypes,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? minSize,
    int? maxSize,
    required DateTime createdAt,
    required int usageCount,
  }) = _SavedSearchPresetImpl;

  factory SavedSearchPreset.fromJson(Map<String, dynamic> jsonSerialization) {
    return SavedSearchPreset(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      query: jsonSerialization['query'] as String,
      category: jsonSerialization['category'] as String?,
      tags: jsonSerialization['tags'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(jsonSerialization['tags']),
      fileTypes: jsonSerialization['fileTypes'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['fileTypes'],
            ),
      dateFrom: jsonSerialization['dateFrom'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dateFrom']),
      dateTo: jsonSerialization['dateTo'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dateTo']),
      minSize: jsonSerialization['minSize'] as int?,
      maxSize: jsonSerialization['maxSize'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      usageCount: jsonSerialization['usageCount'] as int,
    );
  }

  static final t = SavedSearchPresetTable();

  static const db = SavedSearchPresetRepository._();

  @override
  int? id;

  String name;

  String query;

  String? category;

  List<String>? tags;

  List<String>? fileTypes;

  DateTime? dateFrom;

  DateTime? dateTo;

  int? minSize;

  int? maxSize;

  DateTime createdAt;

  int usageCount;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [SavedSearchPreset]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SavedSearchPreset copyWith({
    int? id,
    String? name,
    String? query,
    String? category,
    List<String>? tags,
    List<String>? fileTypes,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? minSize,
    int? maxSize,
    DateTime? createdAt,
    int? usageCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SavedSearchPreset',
      if (id != null) 'id': id,
      'name': name,
      'query': query,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags?.toJson(),
      if (fileTypes != null) 'fileTypes': fileTypes?.toJson(),
      if (dateFrom != null) 'dateFrom': dateFrom?.toJson(),
      if (dateTo != null) 'dateTo': dateTo?.toJson(),
      if (minSize != null) 'minSize': minSize,
      if (maxSize != null) 'maxSize': maxSize,
      'createdAt': createdAt.toJson(),
      'usageCount': usageCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SavedSearchPreset',
      if (id != null) 'id': id,
      'name': name,
      'query': query,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags?.toJson(),
      if (fileTypes != null) 'fileTypes': fileTypes?.toJson(),
      if (dateFrom != null) 'dateFrom': dateFrom?.toJson(),
      if (dateTo != null) 'dateTo': dateTo?.toJson(),
      if (minSize != null) 'minSize': minSize,
      if (maxSize != null) 'maxSize': maxSize,
      'createdAt': createdAt.toJson(),
      'usageCount': usageCount,
    };
  }

  static SavedSearchPresetInclude include() {
    return SavedSearchPresetInclude._();
  }

  static SavedSearchPresetIncludeList includeList({
    _i1.WhereExpressionBuilder<SavedSearchPresetTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SavedSearchPresetTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SavedSearchPresetTable>? orderByList,
    SavedSearchPresetInclude? include,
  }) {
    return SavedSearchPresetIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SavedSearchPreset.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SavedSearchPreset.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SavedSearchPresetImpl extends SavedSearchPreset {
  _SavedSearchPresetImpl({
    int? id,
    required String name,
    required String query,
    String? category,
    List<String>? tags,
    List<String>? fileTypes,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? minSize,
    int? maxSize,
    required DateTime createdAt,
    required int usageCount,
  }) : super._(
         id: id,
         name: name,
         query: query,
         category: category,
         tags: tags,
         fileTypes: fileTypes,
         dateFrom: dateFrom,
         dateTo: dateTo,
         minSize: minSize,
         maxSize: maxSize,
         createdAt: createdAt,
         usageCount: usageCount,
       );

  /// Returns a shallow copy of this [SavedSearchPreset]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SavedSearchPreset copyWith({
    Object? id = _Undefined,
    String? name,
    String? query,
    Object? category = _Undefined,
    Object? tags = _Undefined,
    Object? fileTypes = _Undefined,
    Object? dateFrom = _Undefined,
    Object? dateTo = _Undefined,
    Object? minSize = _Undefined,
    Object? maxSize = _Undefined,
    DateTime? createdAt,
    int? usageCount,
  }) {
    return SavedSearchPreset(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      query: query ?? this.query,
      category: category is String? ? category : this.category,
      tags: tags is List<String>? ? tags : this.tags?.map((e0) => e0).toList(),
      fileTypes: fileTypes is List<String>?
          ? fileTypes
          : this.fileTypes?.map((e0) => e0).toList(),
      dateFrom: dateFrom is DateTime? ? dateFrom : this.dateFrom,
      dateTo: dateTo is DateTime? ? dateTo : this.dateTo,
      minSize: minSize is int? ? minSize : this.minSize,
      maxSize: maxSize is int? ? maxSize : this.maxSize,
      createdAt: createdAt ?? this.createdAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}

class SavedSearchPresetUpdateTable
    extends _i1.UpdateTable<SavedSearchPresetTable> {
  SavedSearchPresetUpdateTable(super.table);

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> query(String value) => _i1.ColumnValue(
    table.query,
    value,
  );

  _i1.ColumnValue<String, String> category(String? value) => _i1.ColumnValue(
    table.category,
    value,
  );

  _i1.ColumnValue<List<String>, List<String>> tags(List<String>? value) =>
      _i1.ColumnValue(
        table.tags,
        value,
      );

  _i1.ColumnValue<List<String>, List<String>> fileTypes(List<String>? value) =>
      _i1.ColumnValue(
        table.fileTypes,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> dateFrom(DateTime? value) =>
      _i1.ColumnValue(
        table.dateFrom,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> dateTo(DateTime? value) =>
      _i1.ColumnValue(
        table.dateTo,
        value,
      );

  _i1.ColumnValue<int, int> minSize(int? value) => _i1.ColumnValue(
    table.minSize,
    value,
  );

  _i1.ColumnValue<int, int> maxSize(int? value) => _i1.ColumnValue(
    table.maxSize,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<int, int> usageCount(int value) => _i1.ColumnValue(
    table.usageCount,
    value,
  );
}

class SavedSearchPresetTable extends _i1.Table<int?> {
  SavedSearchPresetTable({super.tableRelation})
    : super(tableName: 'saved_search_preset') {
    updateTable = SavedSearchPresetUpdateTable(this);
    name = _i1.ColumnString(
      'name',
      this,
    );
    query = _i1.ColumnString(
      'query',
      this,
    );
    category = _i1.ColumnString(
      'category',
      this,
    );
    tags = _i1.ColumnSerializable<List<String>>(
      'tags',
      this,
    );
    fileTypes = _i1.ColumnSerializable<List<String>>(
      'fileTypes',
      this,
    );
    dateFrom = _i1.ColumnDateTime(
      'dateFrom',
      this,
    );
    dateTo = _i1.ColumnDateTime(
      'dateTo',
      this,
    );
    minSize = _i1.ColumnInt(
      'minSize',
      this,
    );
    maxSize = _i1.ColumnInt(
      'maxSize',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    usageCount = _i1.ColumnInt(
      'usageCount',
      this,
    );
  }

  late final SavedSearchPresetUpdateTable updateTable;

  late final _i1.ColumnString name;

  late final _i1.ColumnString query;

  late final _i1.ColumnString category;

  late final _i1.ColumnSerializable<List<String>> tags;

  late final _i1.ColumnSerializable<List<String>> fileTypes;

  late final _i1.ColumnDateTime dateFrom;

  late final _i1.ColumnDateTime dateTo;

  late final _i1.ColumnInt minSize;

  late final _i1.ColumnInt maxSize;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnInt usageCount;

  @override
  List<_i1.Column> get columns => [
    id,
    name,
    query,
    category,
    tags,
    fileTypes,
    dateFrom,
    dateTo,
    minSize,
    maxSize,
    createdAt,
    usageCount,
  ];
}

class SavedSearchPresetInclude extends _i1.IncludeObject {
  SavedSearchPresetInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => SavedSearchPreset.t;
}

class SavedSearchPresetIncludeList extends _i1.IncludeList {
  SavedSearchPresetIncludeList._({
    _i1.WhereExpressionBuilder<SavedSearchPresetTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SavedSearchPreset.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => SavedSearchPreset.t;
}

class SavedSearchPresetRepository {
  const SavedSearchPresetRepository._();

  /// Returns a list of [SavedSearchPreset]s matching the given query parameters.
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
  Future<List<SavedSearchPreset>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SavedSearchPresetTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SavedSearchPresetTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SavedSearchPresetTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<SavedSearchPreset>(
      where: where?.call(SavedSearchPreset.t),
      orderBy: orderBy?.call(SavedSearchPreset.t),
      orderByList: orderByList?.call(SavedSearchPreset.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [SavedSearchPreset] matching the given query parameters.
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
  Future<SavedSearchPreset?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SavedSearchPresetTable>? where,
    int? offset,
    _i1.OrderByBuilder<SavedSearchPresetTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SavedSearchPresetTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<SavedSearchPreset>(
      where: where?.call(SavedSearchPreset.t),
      orderBy: orderBy?.call(SavedSearchPreset.t),
      orderByList: orderByList?.call(SavedSearchPreset.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [SavedSearchPreset] by its [id] or null if no such row exists.
  Future<SavedSearchPreset?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<SavedSearchPreset>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [SavedSearchPreset]s in the list and returns the inserted rows.
  ///
  /// The returned [SavedSearchPreset]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<SavedSearchPreset>> insert(
    _i1.Session session,
    List<SavedSearchPreset> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<SavedSearchPreset>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [SavedSearchPreset] and returns the inserted row.
  ///
  /// The returned [SavedSearchPreset] will have its `id` field set.
  Future<SavedSearchPreset> insertRow(
    _i1.Session session,
    SavedSearchPreset row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SavedSearchPreset>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SavedSearchPreset]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SavedSearchPreset>> update(
    _i1.Session session,
    List<SavedSearchPreset> rows, {
    _i1.ColumnSelections<SavedSearchPresetTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SavedSearchPreset>(
      rows,
      columns: columns?.call(SavedSearchPreset.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SavedSearchPreset]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SavedSearchPreset> updateRow(
    _i1.Session session,
    SavedSearchPreset row, {
    _i1.ColumnSelections<SavedSearchPresetTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SavedSearchPreset>(
      row,
      columns: columns?.call(SavedSearchPreset.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SavedSearchPreset] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SavedSearchPreset?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<SavedSearchPresetUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<SavedSearchPreset>(
      id,
      columnValues: columnValues(SavedSearchPreset.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SavedSearchPreset]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<SavedSearchPreset>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<SavedSearchPresetUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<SavedSearchPresetTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SavedSearchPresetTable>? orderBy,
    _i1.OrderByListBuilder<SavedSearchPresetTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<SavedSearchPreset>(
      columnValues: columnValues(SavedSearchPreset.t.updateTable),
      where: where(SavedSearchPreset.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SavedSearchPreset.t),
      orderByList: orderByList?.call(SavedSearchPreset.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [SavedSearchPreset]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SavedSearchPreset>> delete(
    _i1.Session session,
    List<SavedSearchPreset> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SavedSearchPreset>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SavedSearchPreset].
  Future<SavedSearchPreset> deleteRow(
    _i1.Session session,
    SavedSearchPreset row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SavedSearchPreset>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SavedSearchPreset>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<SavedSearchPresetTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SavedSearchPreset>(
      where: where(SavedSearchPreset.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SavedSearchPresetTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SavedSearchPreset>(
      where: where?.call(SavedSearchPreset.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
