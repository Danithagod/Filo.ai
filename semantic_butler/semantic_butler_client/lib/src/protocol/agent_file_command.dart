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

/// AgentFileCommand model - tracks file operations for audit/undo
abstract class AgentFileCommand implements _i1.SerializableModel {
  AgentFileCommand._({
    this.id,
    required this.operation,
    required this.sourcePath,
    this.destinationPath,
    this.newName,
    required this.executedAt,
    required this.success,
    this.errorMessage,
    required this.reversible,
    required this.wasUndone,
  });

  factory AgentFileCommand({
    int? id,
    required String operation,
    required String sourcePath,
    String? destinationPath,
    String? newName,
    required DateTime executedAt,
    required bool success,
    String? errorMessage,
    required bool reversible,
    required bool wasUndone,
  }) = _AgentFileCommandImpl;

  factory AgentFileCommand.fromJson(Map<String, dynamic> jsonSerialization) {
    return AgentFileCommand(
      id: jsonSerialization['id'] as int?,
      operation: jsonSerialization['operation'] as String,
      sourcePath: jsonSerialization['sourcePath'] as String,
      destinationPath: jsonSerialization['destinationPath'] as String?,
      newName: jsonSerialization['newName'] as String?,
      executedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['executedAt'],
      ),
      success: jsonSerialization['success'] as bool,
      errorMessage: jsonSerialization['errorMessage'] as String?,
      reversible: jsonSerialization['reversible'] as bool,
      wasUndone: jsonSerialization['wasUndone'] as bool,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Operation type: rename, move, delete, create
  String operation;

  /// Source file or folder path
  String sourcePath;

  /// Destination path (for move/rename operations)
  String? destinationPath;

  /// New name (for rename operations)
  String? newName;

  /// When the operation was executed
  DateTime executedAt;

  /// Whether the operation succeeded
  bool success;

  /// Error message if operation failed
  String? errorMessage;

  /// Whether this operation can be undone
  bool reversible;

  /// Whether this was undone
  bool wasUndone;

  /// Returns a shallow copy of this [AgentFileCommand]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AgentFileCommand copyWith({
    int? id,
    String? operation,
    String? sourcePath,
    String? destinationPath,
    String? newName,
    DateTime? executedAt,
    bool? success,
    String? errorMessage,
    bool? reversible,
    bool? wasUndone,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AgentFileCommand',
      if (id != null) 'id': id,
      'operation': operation,
      'sourcePath': sourcePath,
      if (destinationPath != null) 'destinationPath': destinationPath,
      if (newName != null) 'newName': newName,
      'executedAt': executedAt.toJson(),
      'success': success,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'reversible': reversible,
      'wasUndone': wasUndone,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AgentFileCommandImpl extends AgentFileCommand {
  _AgentFileCommandImpl({
    int? id,
    required String operation,
    required String sourcePath,
    String? destinationPath,
    String? newName,
    required DateTime executedAt,
    required bool success,
    String? errorMessage,
    required bool reversible,
    required bool wasUndone,
  }) : super._(
         id: id,
         operation: operation,
         sourcePath: sourcePath,
         destinationPath: destinationPath,
         newName: newName,
         executedAt: executedAt,
         success: success,
         errorMessage: errorMessage,
         reversible: reversible,
         wasUndone: wasUndone,
       );

  /// Returns a shallow copy of this [AgentFileCommand]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AgentFileCommand copyWith({
    Object? id = _Undefined,
    String? operation,
    String? sourcePath,
    Object? destinationPath = _Undefined,
    Object? newName = _Undefined,
    DateTime? executedAt,
    bool? success,
    Object? errorMessage = _Undefined,
    bool? reversible,
    bool? wasUndone,
  }) {
    return AgentFileCommand(
      id: id is int? ? id : this.id,
      operation: operation ?? this.operation,
      sourcePath: sourcePath ?? this.sourcePath,
      destinationPath: destinationPath is String?
          ? destinationPath
          : this.destinationPath,
      newName: newName is String? ? newName : this.newName,
      executedAt: executedAt ?? this.executedAt,
      success: success ?? this.success,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      reversible: reversible ?? this.reversible,
      wasUndone: wasUndone ?? this.wasUndone,
    );
  }
}
