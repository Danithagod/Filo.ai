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
import 'package:semantic_butler_client/src/protocol/protocol.dart' as _i2;

/// Request model for organization actions
abstract class OrganizationActionRequest implements _i1.SerializableModel {
  OrganizationActionRequest._({
    required this.actionType,
    this.contentHash,
    this.keepFilePath,
    this.deleteFilePaths,
    this.renameOldPaths,
    this.renameNewNames,
    this.organizeFilePaths,
    this.targetFolder,
    this.dryRun,
  });

  factory OrganizationActionRequest({
    required String actionType,
    String? contentHash,
    String? keepFilePath,
    List<String>? deleteFilePaths,
    List<String>? renameOldPaths,
    List<String>? renameNewNames,
    List<String>? organizeFilePaths,
    String? targetFolder,
    bool? dryRun,
  }) = _OrganizationActionRequestImpl;

  factory OrganizationActionRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return OrganizationActionRequest(
      actionType: jsonSerialization['actionType'] as String,
      contentHash: jsonSerialization['contentHash'] as String?,
      keepFilePath: jsonSerialization['keepFilePath'] as String?,
      deleteFilePaths: jsonSerialization['deleteFilePaths'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['deleteFilePaths'],
            ),
      renameOldPaths: jsonSerialization['renameOldPaths'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['renameOldPaths'],
            ),
      renameNewNames: jsonSerialization['renameNewNames'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['renameNewNames'],
            ),
      organizeFilePaths: jsonSerialization['organizeFilePaths'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['organizeFilePaths'],
            ),
      targetFolder: jsonSerialization['targetFolder'] as String?,
      dryRun: jsonSerialization['dryRun'] as bool?,
    );
  }

  /// Type of action: resolve_duplicates, fix_naming, organize_similar
  String actionType;

  /// Content hash for duplicate resolution (keeps newest, deletes others)
  String? contentHash;

  /// File to keep when resolving duplicates (path)
  String? keepFilePath;

  /// Files to delete when resolving duplicates (paths)
  List<String>? deleteFilePaths;

  /// For naming fixes: list of old paths
  List<String>? renameOldPaths;

  /// For naming fixes: list of new names (parallel to renameOldPaths)
  List<String>? renameNewNames;

  /// For similar content: paths of files to organize together
  List<String>? organizeFilePaths;

  /// Target folder for organizing similar files
  String? targetFolder;

  /// If true, preview changes without executing
  bool? dryRun;

  /// Returns a shallow copy of this [OrganizationActionRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OrganizationActionRequest copyWith({
    String? actionType,
    String? contentHash,
    String? keepFilePath,
    List<String>? deleteFilePaths,
    List<String>? renameOldPaths,
    List<String>? renameNewNames,
    List<String>? organizeFilePaths,
    String? targetFolder,
    bool? dryRun,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OrganizationActionRequest',
      'actionType': actionType,
      if (contentHash != null) 'contentHash': contentHash,
      if (keepFilePath != null) 'keepFilePath': keepFilePath,
      if (deleteFilePaths != null) 'deleteFilePaths': deleteFilePaths?.toJson(),
      if (renameOldPaths != null) 'renameOldPaths': renameOldPaths?.toJson(),
      if (renameNewNames != null) 'renameNewNames': renameNewNames?.toJson(),
      if (organizeFilePaths != null)
        'organizeFilePaths': organizeFilePaths?.toJson(),
      if (targetFolder != null) 'targetFolder': targetFolder,
      if (dryRun != null) 'dryRun': dryRun,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OrganizationActionRequestImpl extends OrganizationActionRequest {
  _OrganizationActionRequestImpl({
    required String actionType,
    String? contentHash,
    String? keepFilePath,
    List<String>? deleteFilePaths,
    List<String>? renameOldPaths,
    List<String>? renameNewNames,
    List<String>? organizeFilePaths,
    String? targetFolder,
    bool? dryRun,
  }) : super._(
         actionType: actionType,
         contentHash: contentHash,
         keepFilePath: keepFilePath,
         deleteFilePaths: deleteFilePaths,
         renameOldPaths: renameOldPaths,
         renameNewNames: renameNewNames,
         organizeFilePaths: organizeFilePaths,
         targetFolder: targetFolder,
         dryRun: dryRun,
       );

  /// Returns a shallow copy of this [OrganizationActionRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OrganizationActionRequest copyWith({
    String? actionType,
    Object? contentHash = _Undefined,
    Object? keepFilePath = _Undefined,
    Object? deleteFilePaths = _Undefined,
    Object? renameOldPaths = _Undefined,
    Object? renameNewNames = _Undefined,
    Object? organizeFilePaths = _Undefined,
    Object? targetFolder = _Undefined,
    Object? dryRun = _Undefined,
  }) {
    return OrganizationActionRequest(
      actionType: actionType ?? this.actionType,
      contentHash: contentHash is String? ? contentHash : this.contentHash,
      keepFilePath: keepFilePath is String? ? keepFilePath : this.keepFilePath,
      deleteFilePaths: deleteFilePaths is List<String>?
          ? deleteFilePaths
          : this.deleteFilePaths?.map((e0) => e0).toList(),
      renameOldPaths: renameOldPaths is List<String>?
          ? renameOldPaths
          : this.renameOldPaths?.map((e0) => e0).toList(),
      renameNewNames: renameNewNames is List<String>?
          ? renameNewNames
          : this.renameNewNames?.map((e0) => e0).toList(),
      organizeFilePaths: organizeFilePaths is List<String>?
          ? organizeFilePaths
          : this.organizeFilePaths?.map((e0) => e0).toList(),
      targetFolder: targetFolder is String? ? targetFolder : this.targetFolder,
      dryRun: dryRun is bool? ? dryRun : this.dryRun,
    );
  }
}
