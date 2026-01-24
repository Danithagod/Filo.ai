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

/// Represents a preview of what will be deleted during a reset operation.
/// This is a non-persisted DTO (no table) used for API responses.
abstract class ResetPreview
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ResetPreview._({
    required this.tables,
    required this.totalRows,
    required this.estimatedTimeSeconds,
  });

  factory ResetPreview({
    required Map<String, int> tables,
    required int totalRows,
    required int estimatedTimeSeconds,
  }) = _ResetPreviewImpl;

  factory ResetPreview.fromJson(Map<String, dynamic> jsonSerialization) {
    return ResetPreview(
      tables: _i2.Protocol().deserialize<Map<String, int>>(
        jsonSerialization['tables'],
      ),
      totalRows: jsonSerialization['totalRows'] as int,
      estimatedTimeSeconds: jsonSerialization['estimatedTimeSeconds'] as int,
    );
  }

  /// Map of table name to row count
  Map<String, int> tables;

  /// Total rows across all tables that will be deleted
  int totalRows;

  /// Estimated reset duration in seconds
  int estimatedTimeSeconds;

  /// Returns a shallow copy of this [ResetPreview]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ResetPreview copyWith({
    Map<String, int>? tables,
    int? totalRows,
    int? estimatedTimeSeconds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ResetPreview',
      'tables': tables.toJson(),
      'totalRows': totalRows,
      'estimatedTimeSeconds': estimatedTimeSeconds,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ResetPreview',
      'tables': tables.toJson(),
      'totalRows': totalRows,
      'estimatedTimeSeconds': estimatedTimeSeconds,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ResetPreviewImpl extends ResetPreview {
  _ResetPreviewImpl({
    required Map<String, int> tables,
    required int totalRows,
    required int estimatedTimeSeconds,
  }) : super._(
         tables: tables,
         totalRows: totalRows,
         estimatedTimeSeconds: estimatedTimeSeconds,
       );

  /// Returns a shallow copy of this [ResetPreview]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ResetPreview copyWith({
    Map<String, int>? tables,
    int? totalRows,
    int? estimatedTimeSeconds,
  }) {
    return ResetPreview(
      tables:
          tables ??
          this.tables.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      totalRows: totalRows ?? this.totalRows,
      estimatedTimeSeconds: estimatedTimeSeconds ?? this.estimatedTimeSeconds,
    );
  }
}
