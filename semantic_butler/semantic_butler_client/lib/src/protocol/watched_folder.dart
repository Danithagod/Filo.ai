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

/// WatchedFolder - Tracks folders being watched for automatic re-indexing
abstract class WatchedFolder implements _i1.SerializableModel {
  WatchedFolder._({
    this.id,
    required this.path,
    required this.isEnabled,
    this.lastEventAt,
    this.filesWatched,
  });

  factory WatchedFolder({
    int? id,
    required String path,
    required bool isEnabled,
    DateTime? lastEventAt,
    int? filesWatched,
  }) = _WatchedFolderImpl;

  factory WatchedFolder.fromJson(Map<String, dynamic> jsonSerialization) {
    return WatchedFolder(
      id: jsonSerialization['id'] as int?,
      path: jsonSerialization['path'] as String,
      isEnabled: jsonSerialization['isEnabled'] as bool,
      lastEventAt: jsonSerialization['lastEventAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastEventAt'],
            ),
      filesWatched: jsonSerialization['filesWatched'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The absolute path to the watched folder
  String path;

  /// Whether smart indexing is currently enabled for this folder
  bool isEnabled;

  /// Timestamp of the last detected file event
  DateTime? lastEventAt;

  /// Number of files currently being monitored
  int? filesWatched;

  /// Returns a shallow copy of this [WatchedFolder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WatchedFolder copyWith({
    int? id,
    String? path,
    bool? isEnabled,
    DateTime? lastEventAt,
    int? filesWatched,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WatchedFolder',
      if (id != null) 'id': id,
      'path': path,
      'isEnabled': isEnabled,
      if (lastEventAt != null) 'lastEventAt': lastEventAt?.toJson(),
      if (filesWatched != null) 'filesWatched': filesWatched,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WatchedFolderImpl extends WatchedFolder {
  _WatchedFolderImpl({
    int? id,
    required String path,
    required bool isEnabled,
    DateTime? lastEventAt,
    int? filesWatched,
  }) : super._(
         id: id,
         path: path,
         isEnabled: isEnabled,
         lastEventAt: lastEventAt,
         filesWatched: filesWatched,
       );

  /// Returns a shallow copy of this [WatchedFolder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WatchedFolder copyWith({
    Object? id = _Undefined,
    String? path,
    bool? isEnabled,
    Object? lastEventAt = _Undefined,
    Object? filesWatched = _Undefined,
  }) {
    return WatchedFolder(
      id: id is int? ? id : this.id,
      path: path ?? this.path,
      isEnabled: isEnabled ?? this.isEnabled,
      lastEventAt: lastEventAt is DateTime? ? lastEventAt : this.lastEventAt,
      filesWatched: filesWatched is int? ? filesWatched : this.filesWatched,
    );
  }
}
