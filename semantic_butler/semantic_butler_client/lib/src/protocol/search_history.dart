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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// SearchHistory model - stores user search queries
abstract class SearchHistory implements _i1.SerializableModel {
  SearchHistory._({
    this.id,
    required this.query,
    required this.resultCount,
    this.topResultId,
    required this.queryTimeMs,
    required this.searchedAt,
  });

  factory SearchHistory({
    int? id,
    required String query,
    required int resultCount,
    int? topResultId,
    required int queryTimeMs,
    required DateTime searchedAt,
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
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
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
    };
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
  }) : super._(
         id: id,
         query: query,
         resultCount: resultCount,
         topResultId: topResultId,
         queryTimeMs: queryTimeMs,
         searchedAt: searchedAt,
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
  }) {
    return SearchHistory(
      id: id is int? ? id : this.id,
      query: query ?? this.query,
      resultCount: resultCount ?? this.resultCount,
      topResultId: topResultId is int? ? topResultId : this.topResultId,
      queryTimeMs: queryTimeMs ?? this.queryTimeMs,
      searchedAt: searchedAt ?? this.searchedAt,
    );
  }
}
