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

/// ErrorCategoryCount model - counts for a specific error category
abstract class ErrorCategoryCount
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ErrorCategoryCount._({
    required this.category,
    required this.count,
    required this.percentage,
  });

  factory ErrorCategoryCount({
    required String category,
    required int count,
    required double percentage,
  }) = _ErrorCategoryCountImpl;

  factory ErrorCategoryCount.fromJson(Map<String, dynamic> jsonSerialization) {
    return ErrorCategoryCount(
      category: jsonSerialization['category'] as String,
      count: jsonSerialization['count'] as int,
      percentage: (jsonSerialization['percentage'] as num).toDouble(),
    );
  }

  /// Error category name (e.g., "APITimeout", "CorruptFile")
  String category;

  /// Number of errors in this category
  int count;

  /// Percentage of total errors (0.0 to 100.0)
  double percentage;

  /// Returns a shallow copy of this [ErrorCategoryCount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ErrorCategoryCount copyWith({
    String? category,
    int? count,
    double? percentage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ErrorCategoryCount',
      'category': category,
      'count': count,
      'percentage': percentage,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ErrorCategoryCount',
      'category': category,
      'count': count,
      'percentage': percentage,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ErrorCategoryCountImpl extends ErrorCategoryCount {
  _ErrorCategoryCountImpl({
    required String category,
    required int count,
    required double percentage,
  }) : super._(
         category: category,
         count: count,
         percentage: percentage,
       );

  /// Returns a shallow copy of this [ErrorCategoryCount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ErrorCategoryCount copyWith({
    String? category,
    int? count,
    double? percentage,
  }) {
    return ErrorCategoryCount(
      category: category ?? this.category,
      count: count ?? this.count,
      percentage: percentage ?? this.percentage,
    );
  }
}
