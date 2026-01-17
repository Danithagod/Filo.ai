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

abstract class FileOperationResult
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  FileOperationResult._({
    required this.success,
    this.newPath,
    this.error,
    this.errorType,
    required this.command,
    this.output,
    this.isDryRun,
    this.undoOperation,
    this.undoPath,
  });

  factory FileOperationResult({
    required bool success,
    String? newPath,
    String? error,
    String? errorType,
    required String command,
    String? output,
    bool? isDryRun,
    String? undoOperation,
    String? undoPath,
  }) = _FileOperationResultImpl;

  factory FileOperationResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return FileOperationResult(
      success: jsonSerialization['success'] as bool,
      newPath: jsonSerialization['newPath'] as String?,
      error: jsonSerialization['error'] as String?,
      errorType: jsonSerialization['errorType'] as String?,
      command: jsonSerialization['command'] as String,
      output: jsonSerialization['output'] as String?,
      isDryRun: jsonSerialization['isDryRun'] as bool?,
      undoOperation: jsonSerialization['undoOperation'] as String?,
      undoPath: jsonSerialization['undoPath'] as String?,
    );
  }

  /// Whether the operation succeeded
  bool success;

  /// New path after the operation (for rename/move/copy)
  String? newPath;

  /// Error message if failed
  String? error;

  /// Error type classification for better handling
  String? errorType;

  /// What operation was attempted
  String command;

  /// Additional output (for list operations)
  String? output;

  /// Whether this was a dry-run preview
  bool? isDryRun;

  /// For undo: the reversible operation type
  String? undoOperation;

  /// For undo: the original path to restore to
  String? undoPath;

  /// Returns a shallow copy of this [FileOperationResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FileOperationResult copyWith({
    bool? success,
    String? newPath,
    String? error,
    String? errorType,
    String? command,
    String? output,
    bool? isDryRun,
    String? undoOperation,
    String? undoPath,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FileOperationResult',
      'success': success,
      if (newPath != null) 'newPath': newPath,
      if (error != null) 'error': error,
      if (errorType != null) 'errorType': errorType,
      'command': command,
      if (output != null) 'output': output,
      if (isDryRun != null) 'isDryRun': isDryRun,
      if (undoOperation != null) 'undoOperation': undoOperation,
      if (undoPath != null) 'undoPath': undoPath,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FileOperationResult',
      'success': success,
      if (newPath != null) 'newPath': newPath,
      if (error != null) 'error': error,
      if (errorType != null) 'errorType': errorType,
      'command': command,
      if (output != null) 'output': output,
      if (isDryRun != null) 'isDryRun': isDryRun,
      if (undoOperation != null) 'undoOperation': undoOperation,
      if (undoPath != null) 'undoPath': undoPath,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FileOperationResultImpl extends FileOperationResult {
  _FileOperationResultImpl({
    required bool success,
    String? newPath,
    String? error,
    String? errorType,
    required String command,
    String? output,
    bool? isDryRun,
    String? undoOperation,
    String? undoPath,
  }) : super._(
         success: success,
         newPath: newPath,
         error: error,
         errorType: errorType,
         command: command,
         output: output,
         isDryRun: isDryRun,
         undoOperation: undoOperation,
         undoPath: undoPath,
       );

  /// Returns a shallow copy of this [FileOperationResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FileOperationResult copyWith({
    bool? success,
    Object? newPath = _Undefined,
    Object? error = _Undefined,
    Object? errorType = _Undefined,
    String? command,
    Object? output = _Undefined,
    Object? isDryRun = _Undefined,
    Object? undoOperation = _Undefined,
    Object? undoPath = _Undefined,
  }) {
    return FileOperationResult(
      success: success ?? this.success,
      newPath: newPath is String? ? newPath : this.newPath,
      error: error is String? ? error : this.error,
      errorType: errorType is String? ? errorType : this.errorType,
      command: command ?? this.command,
      output: output is String? ? output : this.output,
      isDryRun: isDryRun is bool? ? isDryRun : this.isDryRun,
      undoOperation: undoOperation is String?
          ? undoOperation
          : this.undoOperation,
      undoPath: undoPath is String? ? undoPath : this.undoPath,
    );
  }
}
