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

abstract class TagTaxonomy
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  TagTaxonomy._({
    this.id,
    required this.category,
    required this.tagValue,
    required this.frequency,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  factory TagTaxonomy({
    int? id,
    required String category,
    required String tagValue,
    required int frequency,
    required DateTime firstSeenAt,
    required DateTime lastSeenAt,
  }) = _TagTaxonomyImpl;

  factory TagTaxonomy.fromJson(Map<String, dynamic> jsonSerialization) {
    return TagTaxonomy(
      id: jsonSerialization['id'] as int?,
      category: jsonSerialization['category'] as String,
      tagValue: jsonSerialization['tagValue'] as String,
      frequency: jsonSerialization['frequency'] as int,
      firstSeenAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['firstSeenAt'],
      ),
      lastSeenAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenAt'],
      ),
    );
  }

  static final t = TagTaxonomyTable();

  static const db = TagTaxonomyRepository._();

  @override
  int? id;

  /// Tag category: 'topic', 'entity', 'keyword', 'technology', etc.
  String category;

  /// The actual tag value
  String tagValue;

  /// How many times this tag appears across documents
  int frequency;

  /// First document that used this tag
  DateTime firstSeenAt;

  /// Last document that used this tag
  DateTime lastSeenAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [TagTaxonomy]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TagTaxonomy copyWith({
    int? id,
    String? category,
    String? tagValue,
    int? frequency,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TagTaxonomy',
      if (id != null) 'id': id,
      'category': category,
      'tagValue': tagValue,
      'frequency': frequency,
      'firstSeenAt': firstSeenAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TagTaxonomy',
      if (id != null) 'id': id,
      'category': category,
      'tagValue': tagValue,
      'frequency': frequency,
      'firstSeenAt': firstSeenAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
    };
  }

  static TagTaxonomyInclude include() {
    return TagTaxonomyInclude._();
  }

  static TagTaxonomyIncludeList includeList({
    _i1.WhereExpressionBuilder<TagTaxonomyTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TagTaxonomyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TagTaxonomyTable>? orderByList,
    TagTaxonomyInclude? include,
  }) {
    return TagTaxonomyIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TagTaxonomy.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TagTaxonomy.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TagTaxonomyImpl extends TagTaxonomy {
  _TagTaxonomyImpl({
    int? id,
    required String category,
    required String tagValue,
    required int frequency,
    required DateTime firstSeenAt,
    required DateTime lastSeenAt,
  }) : super._(
         id: id,
         category: category,
         tagValue: tagValue,
         frequency: frequency,
         firstSeenAt: firstSeenAt,
         lastSeenAt: lastSeenAt,
       );

  /// Returns a shallow copy of this [TagTaxonomy]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TagTaxonomy copyWith({
    Object? id = _Undefined,
    String? category,
    String? tagValue,
    int? frequency,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
  }) {
    return TagTaxonomy(
      id: id is int? ? id : this.id,
      category: category ?? this.category,
      tagValue: tagValue ?? this.tagValue,
      frequency: frequency ?? this.frequency,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}

class TagTaxonomyUpdateTable extends _i1.UpdateTable<TagTaxonomyTable> {
  TagTaxonomyUpdateTable(super.table);

  _i1.ColumnValue<String, String> category(String value) => _i1.ColumnValue(
    table.category,
    value,
  );

  _i1.ColumnValue<String, String> tagValue(String value) => _i1.ColumnValue(
    table.tagValue,
    value,
  );

  _i1.ColumnValue<int, int> frequency(int value) => _i1.ColumnValue(
    table.frequency,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> firstSeenAt(DateTime value) =>
      _i1.ColumnValue(
        table.firstSeenAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> lastSeenAt(DateTime value) =>
      _i1.ColumnValue(
        table.lastSeenAt,
        value,
      );
}

class TagTaxonomyTable extends _i1.Table<int?> {
  TagTaxonomyTable({super.tableRelation}) : super(tableName: 'tag_taxonomy') {
    updateTable = TagTaxonomyUpdateTable(this);
    category = _i1.ColumnString(
      'category',
      this,
    );
    tagValue = _i1.ColumnString(
      'tagValue',
      this,
    );
    frequency = _i1.ColumnInt(
      'frequency',
      this,
    );
    firstSeenAt = _i1.ColumnDateTime(
      'firstSeenAt',
      this,
    );
    lastSeenAt = _i1.ColumnDateTime(
      'lastSeenAt',
      this,
    );
  }

  late final TagTaxonomyUpdateTable updateTable;

  /// Tag category: 'topic', 'entity', 'keyword', 'technology', etc.
  late final _i1.ColumnString category;

  /// The actual tag value
  late final _i1.ColumnString tagValue;

  /// How many times this tag appears across documents
  late final _i1.ColumnInt frequency;

  /// First document that used this tag
  late final _i1.ColumnDateTime firstSeenAt;

  /// Last document that used this tag
  late final _i1.ColumnDateTime lastSeenAt;

  @override
  List<_i1.Column> get columns => [
    id,
    category,
    tagValue,
    frequency,
    firstSeenAt,
    lastSeenAt,
  ];
}

class TagTaxonomyInclude extends _i1.IncludeObject {
  TagTaxonomyInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => TagTaxonomy.t;
}

class TagTaxonomyIncludeList extends _i1.IncludeList {
  TagTaxonomyIncludeList._({
    _i1.WhereExpressionBuilder<TagTaxonomyTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TagTaxonomy.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => TagTaxonomy.t;
}

class TagTaxonomyRepository {
  const TagTaxonomyRepository._();

  /// Returns a list of [TagTaxonomy]s matching the given query parameters.
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
  Future<List<TagTaxonomy>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TagTaxonomyTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TagTaxonomyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TagTaxonomyTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<TagTaxonomy>(
      where: where?.call(TagTaxonomy.t),
      orderBy: orderBy?.call(TagTaxonomy.t),
      orderByList: orderByList?.call(TagTaxonomy.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [TagTaxonomy] matching the given query parameters.
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
  Future<TagTaxonomy?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TagTaxonomyTable>? where,
    int? offset,
    _i1.OrderByBuilder<TagTaxonomyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TagTaxonomyTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<TagTaxonomy>(
      where: where?.call(TagTaxonomy.t),
      orderBy: orderBy?.call(TagTaxonomy.t),
      orderByList: orderByList?.call(TagTaxonomy.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [TagTaxonomy] by its [id] or null if no such row exists.
  Future<TagTaxonomy?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<TagTaxonomy>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [TagTaxonomy]s in the list and returns the inserted rows.
  ///
  /// The returned [TagTaxonomy]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<TagTaxonomy>> insert(
    _i1.Session session,
    List<TagTaxonomy> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<TagTaxonomy>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [TagTaxonomy] and returns the inserted row.
  ///
  /// The returned [TagTaxonomy] will have its `id` field set.
  Future<TagTaxonomy> insertRow(
    _i1.Session session,
    TagTaxonomy row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TagTaxonomy>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TagTaxonomy]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TagTaxonomy>> update(
    _i1.Session session,
    List<TagTaxonomy> rows, {
    _i1.ColumnSelections<TagTaxonomyTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TagTaxonomy>(
      rows,
      columns: columns?.call(TagTaxonomy.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TagTaxonomy]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TagTaxonomy> updateRow(
    _i1.Session session,
    TagTaxonomy row, {
    _i1.ColumnSelections<TagTaxonomyTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TagTaxonomy>(
      row,
      columns: columns?.call(TagTaxonomy.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TagTaxonomy] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TagTaxonomy?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<TagTaxonomyUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<TagTaxonomy>(
      id,
      columnValues: columnValues(TagTaxonomy.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TagTaxonomy]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<TagTaxonomy>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<TagTaxonomyUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TagTaxonomyTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TagTaxonomyTable>? orderBy,
    _i1.OrderByListBuilder<TagTaxonomyTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<TagTaxonomy>(
      columnValues: columnValues(TagTaxonomy.t.updateTable),
      where: where(TagTaxonomy.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TagTaxonomy.t),
      orderByList: orderByList?.call(TagTaxonomy.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [TagTaxonomy]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TagTaxonomy>> delete(
    _i1.Session session,
    List<TagTaxonomy> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TagTaxonomy>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TagTaxonomy].
  Future<TagTaxonomy> deleteRow(
    _i1.Session session,
    TagTaxonomy row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TagTaxonomy>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TagTaxonomy>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TagTaxonomyTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TagTaxonomy>(
      where: where(TagTaxonomy.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TagTaxonomyTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TagTaxonomy>(
      where: where?.call(TagTaxonomy.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
