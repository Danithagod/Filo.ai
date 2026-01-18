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
import 'duplicate_group.dart' as _i2;
import 'naming_issue.dart' as _i3;
import 'similar_content_group.dart' as _i4;
import 'package:semantic_butler_server/src/generated/protocol.dart' as _i5;

/// OrganizationSuggestions - aggregated results from file organization analysis
abstract class OrganizationSuggestions
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  OrganizationSuggestions._({
    required this.duplicates,
    required this.namingIssues,
    required this.similarContent,
    required this.analyzedAt,
    required this.totalFilesAnalyzed,
    required this.potentialSavingsBytes,
  });

  factory OrganizationSuggestions({
    required List<_i2.DuplicateGroup> duplicates,
    required List<_i3.NamingIssue> namingIssues,
    required List<_i4.SimilarContentGroup> similarContent,
    required DateTime analyzedAt,
    required int totalFilesAnalyzed,
    required int potentialSavingsBytes,
  }) = _OrganizationSuggestionsImpl;

  factory OrganizationSuggestions.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return OrganizationSuggestions(
      duplicates: _i5.Protocol().deserialize<List<_i2.DuplicateGroup>>(
        jsonSerialization['duplicates'],
      ),
      namingIssues: _i5.Protocol().deserialize<List<_i3.NamingIssue>>(
        jsonSerialization['namingIssues'],
      ),
      similarContent: _i5.Protocol().deserialize<List<_i4.SimilarContentGroup>>(
        jsonSerialization['similarContent'],
      ),
      analyzedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['analyzedAt'],
      ),
      totalFilesAnalyzed: jsonSerialization['totalFilesAnalyzed'] as int,
      potentialSavingsBytes: jsonSerialization['potentialSavingsBytes'] as int,
    );
  }

  /// List of duplicate file groups found
  List<_i2.DuplicateGroup> duplicates;

  /// List of naming convention issues found
  List<_i3.NamingIssue> namingIssues;

  /// List of semantically similar content groups
  List<_i4.SimilarContentGroup> similarContent;

  /// When the analysis was performed
  DateTime analyzedAt;

  /// Total number of files analyzed
  int totalFilesAnalyzed;

  /// Total potential storage savings in bytes
  int potentialSavingsBytes;

  /// Returns a shallow copy of this [OrganizationSuggestions]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OrganizationSuggestions copyWith({
    List<_i2.DuplicateGroup>? duplicates,
    List<_i3.NamingIssue>? namingIssues,
    List<_i4.SimilarContentGroup>? similarContent,
    DateTime? analyzedAt,
    int? totalFilesAnalyzed,
    int? potentialSavingsBytes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OrganizationSuggestions',
      'duplicates': duplicates.toJson(valueToJson: (v) => v.toJson()),
      'namingIssues': namingIssues.toJson(valueToJson: (v) => v.toJson()),
      'similarContent': similarContent.toJson(valueToJson: (v) => v.toJson()),
      'analyzedAt': analyzedAt.toJson(),
      'totalFilesAnalyzed': totalFilesAnalyzed,
      'potentialSavingsBytes': potentialSavingsBytes,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OrganizationSuggestions',
      'duplicates': duplicates.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'namingIssues': namingIssues.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'similarContent': similarContent.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'analyzedAt': analyzedAt.toJson(),
      'totalFilesAnalyzed': totalFilesAnalyzed,
      'potentialSavingsBytes': potentialSavingsBytes,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _OrganizationSuggestionsImpl extends OrganizationSuggestions {
  _OrganizationSuggestionsImpl({
    required List<_i2.DuplicateGroup> duplicates,
    required List<_i3.NamingIssue> namingIssues,
    required List<_i4.SimilarContentGroup> similarContent,
    required DateTime analyzedAt,
    required int totalFilesAnalyzed,
    required int potentialSavingsBytes,
  }) : super._(
         duplicates: duplicates,
         namingIssues: namingIssues,
         similarContent: similarContent,
         analyzedAt: analyzedAt,
         totalFilesAnalyzed: totalFilesAnalyzed,
         potentialSavingsBytes: potentialSavingsBytes,
       );

  /// Returns a shallow copy of this [OrganizationSuggestions]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OrganizationSuggestions copyWith({
    List<_i2.DuplicateGroup>? duplicates,
    List<_i3.NamingIssue>? namingIssues,
    List<_i4.SimilarContentGroup>? similarContent,
    DateTime? analyzedAt,
    int? totalFilesAnalyzed,
    int? potentialSavingsBytes,
  }) {
    return OrganizationSuggestions(
      duplicates:
          duplicates ?? this.duplicates.map((e0) => e0.copyWith()).toList(),
      namingIssues:
          namingIssues ?? this.namingIssues.map((e0) => e0.copyWith()).toList(),
      similarContent:
          similarContent ??
          this.similarContent.map((e0) => e0.copyWith()).toList(),
      analyzedAt: analyzedAt ?? this.analyzedAt,
      totalFilesAnalyzed: totalFilesAnalyzed ?? this.totalFilesAnalyzed,
      potentialSavingsBytes:
          potentialSavingsBytes ?? this.potentialSavingsBytes,
    );
  }
}
