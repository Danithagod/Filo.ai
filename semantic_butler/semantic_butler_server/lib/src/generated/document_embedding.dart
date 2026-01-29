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

/// DocumentEmbedding model - stores vector embeddings separately for flexibility
abstract class DocumentEmbedding
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  DocumentEmbedding._({
    this.id,
    required this.fileIndexId,
    required this.chunkIndex,
    this.chunkText,
    required this.embedding,
    this.embeddingJson,
    this.dimensions,
  });

  factory DocumentEmbedding({
    int? id,
    required int fileIndexId,
    required int chunkIndex,
    String? chunkText,
    required _i1.Vector embedding,
    String? embeddingJson,
    int? dimensions,
  }) = _DocumentEmbeddingImpl;

  factory DocumentEmbedding.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocumentEmbedding(
      id: jsonSerialization['id'] as int?,
      fileIndexId: jsonSerialization['fileIndexId'] as int,
      chunkIndex: jsonSerialization['chunkIndex'] as int,
      chunkText: jsonSerialization['chunkText'] as String?,
      embedding: _i1.VectorJsonExtension.fromJson(
        jsonSerialization['embedding'],
      ),
      embeddingJson: jsonSerialization['embeddingJson'] as String?,
      dimensions: jsonSerialization['dimensions'] as int?,
    );
  }

  static final t = DocumentEmbeddingTable();

  static const db = DocumentEmbeddingRepository._();

  @override
  int? id;

  /// Reference to the file_index record
  int fileIndexId;

  /// Chunk index (0 for single-chunk docs, 1+ for multi-chunk)
  int chunkIndex;

  /// The text chunk that was embedded
  String? chunkText;

  /// Vector embedding - 768 dimensions for sentence transformers
  _i1.Vector embedding;

  /// JSON encoded embedding vector (DEPRECATED: Use native embedding field)
  String? embeddingJson;

  /// Embedding dimensions (DEPRECATED)
  int? dimensions;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [DocumentEmbedding]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DocumentEmbedding copyWith({
    int? id,
    int? fileIndexId,
    int? chunkIndex,
    String? chunkText,
    _i1.Vector? embedding,
    String? embeddingJson,
    int? dimensions,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocumentEmbedding',
      if (id != null) 'id': id,
      'fileIndexId': fileIndexId,
      'chunkIndex': chunkIndex,
      if (chunkText != null) 'chunkText': chunkText,
      'embedding': embedding.toJson(),
      if (embeddingJson != null) 'embeddingJson': embeddingJson,
      if (dimensions != null) 'dimensions': dimensions,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocumentEmbedding',
      if (id != null) 'id': id,
      'fileIndexId': fileIndexId,
      'chunkIndex': chunkIndex,
      if (chunkText != null) 'chunkText': chunkText,
      'embedding': embedding.toJson(),
      if (embeddingJson != null) 'embeddingJson': embeddingJson,
      if (dimensions != null) 'dimensions': dimensions,
    };
  }

  static DocumentEmbeddingInclude include() {
    return DocumentEmbeddingInclude._();
  }

  static DocumentEmbeddingIncludeList includeList({
    _i1.WhereExpressionBuilder<DocumentEmbeddingTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DocumentEmbeddingTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DocumentEmbeddingTable>? orderByList,
    DocumentEmbeddingInclude? include,
  }) {
    return DocumentEmbeddingIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DocumentEmbedding.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(DocumentEmbedding.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentEmbeddingImpl extends DocumentEmbedding {
  _DocumentEmbeddingImpl({
    int? id,
    required int fileIndexId,
    required int chunkIndex,
    String? chunkText,
    required _i1.Vector embedding,
    String? embeddingJson,
    int? dimensions,
  }) : super._(
         id: id,
         fileIndexId: fileIndexId,
         chunkIndex: chunkIndex,
         chunkText: chunkText,
         embedding: embedding,
         embeddingJson: embeddingJson,
         dimensions: dimensions,
       );

  /// Returns a shallow copy of this [DocumentEmbedding]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DocumentEmbedding copyWith({
    Object? id = _Undefined,
    int? fileIndexId,
    int? chunkIndex,
    Object? chunkText = _Undefined,
    _i1.Vector? embedding,
    Object? embeddingJson = _Undefined,
    Object? dimensions = _Undefined,
  }) {
    return DocumentEmbedding(
      id: id is int? ? id : this.id,
      fileIndexId: fileIndexId ?? this.fileIndexId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      chunkText: chunkText is String? ? chunkText : this.chunkText,
      embedding: embedding ?? this.embedding.clone(),
      embeddingJson: embeddingJson is String?
          ? embeddingJson
          : this.embeddingJson,
      dimensions: dimensions is int? ? dimensions : this.dimensions,
    );
  }
}

class DocumentEmbeddingUpdateTable
    extends _i1.UpdateTable<DocumentEmbeddingTable> {
  DocumentEmbeddingUpdateTable(super.table);

  _i1.ColumnValue<int, int> fileIndexId(int value) => _i1.ColumnValue(
    table.fileIndexId,
    value,
  );

  _i1.ColumnValue<int, int> chunkIndex(int value) => _i1.ColumnValue(
    table.chunkIndex,
    value,
  );

  _i1.ColumnValue<String, String> chunkText(String? value) => _i1.ColumnValue(
    table.chunkText,
    value,
  );

  _i1.ColumnValue<_i1.Vector, _i1.Vector> embedding(_i1.Vector value) =>
      _i1.ColumnValue(
        table.embedding,
        value,
      );

  _i1.ColumnValue<String, String> embeddingJson(String? value) =>
      _i1.ColumnValue(
        table.embeddingJson,
        value,
      );

  _i1.ColumnValue<int, int> dimensions(int? value) => _i1.ColumnValue(
    table.dimensions,
    value,
  );
}

class DocumentEmbeddingTable extends _i1.Table<int?> {
  DocumentEmbeddingTable({super.tableRelation})
    : super(tableName: 'document_embedding') {
    updateTable = DocumentEmbeddingUpdateTable(this);
    fileIndexId = _i1.ColumnInt(
      'fileIndexId',
      this,
    );
    chunkIndex = _i1.ColumnInt(
      'chunkIndex',
      this,
    );
    chunkText = _i1.ColumnString(
      'chunkText',
      this,
    );
    embedding = _i1.ColumnVector(
      'embedding',
      this,
      dimension: 768,
    );
    embeddingJson = _i1.ColumnString(
      'embeddingJson',
      this,
    );
    dimensions = _i1.ColumnInt(
      'dimensions',
      this,
    );
  }

  late final DocumentEmbeddingUpdateTable updateTable;

  /// Reference to the file_index record
  late final _i1.ColumnInt fileIndexId;

  /// Chunk index (0 for single-chunk docs, 1+ for multi-chunk)
  late final _i1.ColumnInt chunkIndex;

  /// The text chunk that was embedded
  late final _i1.ColumnString chunkText;

  /// Vector embedding - 768 dimensions for sentence transformers
  late final _i1.ColumnVector embedding;

  /// JSON encoded embedding vector (DEPRECATED: Use native embedding field)
  late final _i1.ColumnString embeddingJson;

  /// Embedding dimensions (DEPRECATED)
  late final _i1.ColumnInt dimensions;

  @override
  List<_i1.Column> get columns => [
    id,
    fileIndexId,
    chunkIndex,
    chunkText,
    embedding,
    embeddingJson,
    dimensions,
  ];
}

class DocumentEmbeddingInclude extends _i1.IncludeObject {
  DocumentEmbeddingInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => DocumentEmbedding.t;
}

class DocumentEmbeddingIncludeList extends _i1.IncludeList {
  DocumentEmbeddingIncludeList._({
    _i1.WhereExpressionBuilder<DocumentEmbeddingTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DocumentEmbedding.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => DocumentEmbedding.t;
}

class DocumentEmbeddingRepository {
  const DocumentEmbeddingRepository._();

  /// Returns a list of [DocumentEmbedding]s matching the given query parameters.
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
  Future<List<DocumentEmbedding>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<DocumentEmbeddingTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DocumentEmbeddingTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DocumentEmbeddingTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<DocumentEmbedding>(
      where: where?.call(DocumentEmbedding.t),
      orderBy: orderBy?.call(DocumentEmbedding.t),
      orderByList: orderByList?.call(DocumentEmbedding.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [DocumentEmbedding] matching the given query parameters.
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
  Future<DocumentEmbedding?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<DocumentEmbeddingTable>? where,
    int? offset,
    _i1.OrderByBuilder<DocumentEmbeddingTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<DocumentEmbeddingTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<DocumentEmbedding>(
      where: where?.call(DocumentEmbedding.t),
      orderBy: orderBy?.call(DocumentEmbedding.t),
      orderByList: orderByList?.call(DocumentEmbedding.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [DocumentEmbedding] by its [id] or null if no such row exists.
  Future<DocumentEmbedding?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<DocumentEmbedding>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [DocumentEmbedding]s in the list and returns the inserted rows.
  ///
  /// The returned [DocumentEmbedding]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<DocumentEmbedding>> insert(
    _i1.Session session,
    List<DocumentEmbedding> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<DocumentEmbedding>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [DocumentEmbedding] and returns the inserted row.
  ///
  /// The returned [DocumentEmbedding] will have its `id` field set.
  Future<DocumentEmbedding> insertRow(
    _i1.Session session,
    DocumentEmbedding row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<DocumentEmbedding>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [DocumentEmbedding]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<DocumentEmbedding>> update(
    _i1.Session session,
    List<DocumentEmbedding> rows, {
    _i1.ColumnSelections<DocumentEmbeddingTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<DocumentEmbedding>(
      rows,
      columns: columns?.call(DocumentEmbedding.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DocumentEmbedding]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DocumentEmbedding> updateRow(
    _i1.Session session,
    DocumentEmbedding row, {
    _i1.ColumnSelections<DocumentEmbeddingTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<DocumentEmbedding>(
      row,
      columns: columns?.call(DocumentEmbedding.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DocumentEmbedding] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DocumentEmbedding?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<DocumentEmbeddingUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<DocumentEmbedding>(
      id,
      columnValues: columnValues(DocumentEmbedding.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DocumentEmbedding]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<DocumentEmbedding>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<DocumentEmbeddingUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<DocumentEmbeddingTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<DocumentEmbeddingTable>? orderBy,
    _i1.OrderByListBuilder<DocumentEmbeddingTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<DocumentEmbedding>(
      columnValues: columnValues(DocumentEmbedding.t.updateTable),
      where: where(DocumentEmbedding.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DocumentEmbedding.t),
      orderByList: orderByList?.call(DocumentEmbedding.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [DocumentEmbedding]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<DocumentEmbedding>> delete(
    _i1.Session session,
    List<DocumentEmbedding> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<DocumentEmbedding>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [DocumentEmbedding].
  Future<DocumentEmbedding> deleteRow(
    _i1.Session session,
    DocumentEmbedding row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DocumentEmbedding>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<DocumentEmbedding>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<DocumentEmbeddingTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<DocumentEmbedding>(
      where: where(DocumentEmbedding.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<DocumentEmbeddingTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<DocumentEmbedding>(
      where: where?.call(DocumentEmbedding.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
