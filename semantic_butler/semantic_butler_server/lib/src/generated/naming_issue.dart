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

/// NamingIssue - represents a file naming convention issue
abstract class NamingIssue
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  NamingIssue._({
    required this.issueType,
    required this.description,
    required this.severity,
    required this.affectedFiles,
    required this.affectedCount,
    this.suggestedFix,
  });

  factory NamingIssue({
    required String issueType,
    required String description,
    required String severity,
    required List<String> affectedFiles,
    required int affectedCount,
    String? suggestedFix,
  }) = _NamingIssueImpl;

  factory NamingIssue.fromJson(Map<String, dynamic> jsonSerialization) {
    return NamingIssue(
      issueType: jsonSerialization['issueType'] as String,
      description: jsonSerialization['description'] as String,
      severity: jsonSerialization['severity'] as String,
      affectedFiles: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['affectedFiles'],
      ),
      affectedCount: jsonSerialization['affectedCount'] as int,
      suggestedFix: jsonSerialization['suggestedFix'] as String?,
    );
  }

  /// Type of issue: inconsistent_case, spaces_in_name, invalid_characters, mixed_conventions
  String issueType;

  /// Human-readable description of the issue
  String description;

  /// Severity level: info, warning, error
  String severity;

  /// List of file paths affected by this issue
  List<String> affectedFiles;

  /// Number of files affected
  int affectedCount;

  /// Suggested fix or recommendation
  String? suggestedFix;

  /// Returns a shallow copy of this [NamingIssue]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NamingIssue copyWith({
    String? issueType,
    String? description,
    String? severity,
    List<String>? affectedFiles,
    int? affectedCount,
    String? suggestedFix,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NamingIssue',
      'issueType': issueType,
      'description': description,
      'severity': severity,
      'affectedFiles': affectedFiles.toJson(),
      'affectedCount': affectedCount,
      if (suggestedFix != null) 'suggestedFix': suggestedFix,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'NamingIssue',
      'issueType': issueType,
      'description': description,
      'severity': severity,
      'affectedFiles': affectedFiles.toJson(),
      'affectedCount': affectedCount,
      if (suggestedFix != null) 'suggestedFix': suggestedFix,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NamingIssueImpl extends NamingIssue {
  _NamingIssueImpl({
    required String issueType,
    required String description,
    required String severity,
    required List<String> affectedFiles,
    required int affectedCount,
    String? suggestedFix,
  }) : super._(
         issueType: issueType,
         description: description,
         severity: severity,
         affectedFiles: affectedFiles,
         affectedCount: affectedCount,
         suggestedFix: suggestedFix,
       );

  /// Returns a shallow copy of this [NamingIssue]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NamingIssue copyWith({
    String? issueType,
    String? description,
    String? severity,
    List<String>? affectedFiles,
    int? affectedCount,
    Object? suggestedFix = _Undefined,
  }) {
    return NamingIssue(
      issueType: issueType ?? this.issueType,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      affectedFiles:
          affectedFiles ?? this.affectedFiles.map((e0) => e0).toList(),
      affectedCount: affectedCount ?? this.affectedCount,
      suggestedFix: suggestedFix is String? ? suggestedFix : this.suggestedFix,
    );
  }
}
