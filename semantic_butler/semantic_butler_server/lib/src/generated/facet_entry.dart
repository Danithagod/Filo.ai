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

abstract class FacetEntry
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  FacetEntry._({
    required this.label,
    required this.count,
    required this.value,
  });

  factory FacetEntry({
    required String label,
    required int count,
    required String value,
  }) = _FacetEntryImpl;

  factory FacetEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return FacetEntry(
      label: jsonSerialization['label'] as String,
      count: jsonSerialization['count'] as int,
      value: jsonSerialization['value'] as String,
    );
  }

  String label;

  int count;

  String value;

  /// Returns a shallow copy of this [FacetEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FacetEntry copyWith({
    String? label,
    int? count,
    String? value,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FacetEntry',
      'label': label,
      'count': count,
      'value': value,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FacetEntry',
      'label': label,
      'count': count,
      'value': value,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _FacetEntryImpl extends FacetEntry {
  _FacetEntryImpl({
    required String label,
    required int count,
    required String value,
  }) : super._(
         label: label,
         count: count,
         value: value,
       );

  /// Returns a shallow copy of this [FacetEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FacetEntry copyWith({
    String? label,
    int? count,
    String? value,
  }) {
    return FacetEntry(
      label: label ?? this.label,
      count: count ?? this.count,
      value: value ?? this.value,
    );
  }
}
