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
import 'facet_entry.dart' as _i2;
import 'package:semantic_butler_client/src/protocol/protocol.dart' as _i3;

abstract class SearchFacet implements _i1.SerializableModel {
  SearchFacet._({
    required this.facetType,
    required this.entries,
  });

  factory SearchFacet({
    required String facetType,
    required List<_i2.FacetEntry> entries,
  }) = _SearchFacetImpl;

  factory SearchFacet.fromJson(Map<String, dynamic> jsonSerialization) {
    return SearchFacet(
      facetType: jsonSerialization['facetType'] as String,
      entries: _i3.Protocol().deserialize<List<_i2.FacetEntry>>(
        jsonSerialization['entries'],
      ),
    );
  }

  String facetType;

  List<_i2.FacetEntry> entries;

  /// Returns a shallow copy of this [SearchFacet]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SearchFacet copyWith({
    String? facetType,
    List<_i2.FacetEntry>? entries,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SearchFacet',
      'facetType': facetType,
      'entries': entries.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SearchFacetImpl extends SearchFacet {
  _SearchFacetImpl({
    required String facetType,
    required List<_i2.FacetEntry> entries,
  }) : super._(
         facetType: facetType,
         entries: entries,
       );

  /// Returns a shallow copy of this [SearchFacet]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SearchFacet copyWith({
    String? facetType,
    List<_i2.FacetEntry>? entries,
  }) {
    return SearchFacet(
      facetType: facetType ?? this.facetType,
      entries: entries ?? this.entries.map((e0) => e0.copyWith()).toList(),
    );
  }
}
