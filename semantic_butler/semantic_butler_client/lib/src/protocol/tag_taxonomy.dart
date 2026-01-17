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

abstract class TagTaxonomy implements _i1.SerializableModel {
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
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
