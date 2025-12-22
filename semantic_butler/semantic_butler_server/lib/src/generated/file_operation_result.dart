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
    required this.command,
    this.output,
  });

  factory FileOperationResult({
    required bool success,
    String? newPath,
    String? error,
    required String command,
    String? output,
  }) = _FileOperationResultImpl;

  factory FileOperationResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return FileOperationResult(
      success: jsonSerialization['success'] as bool,
      newPath: jsonSerialization['newPath'] as String?,
      error: jsonSerialization['error'] as String?,
      command: jsonSerialization['command'] as String,
      output: jsonSerialization['output'] as String?,
    );
  }

  bool success;

  String? newPath;

  String? error;

  String command;

  String? output;

  /// Returns a shallow copy of this [FileOperationResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FileOperationResult copyWith({
    bool? success,
    String? newPath,
    String? error,
    String? command,
    String? output,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FileOperationResult',
      'success': success,
      if (newPath != null) 'newPath': newPath,
      if (error != null) 'error': error,
      'command': command,
      if (output != null) 'output': output,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FileOperationResult',
      'success': success,
      if (newPath != null) 'newPath': newPath,
      if (error != null) 'error': error,
      'command': command,
      if (output != null) 'output': output,
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
    required String command,
    String? output,
  }) : super._(
         success: success,
         newPath: newPath,
         error: error,
         command: command,
         output: output,
       );

  /// Returns a shallow copy of this [FileOperationResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FileOperationResult copyWith({
    bool? success,
    Object? newPath = _Undefined,
    Object? error = _Undefined,
    String? command,
    Object? output = _Undefined,
  }) {
    return FileOperationResult(
      success: success ?? this.success,
      newPath: newPath is String? ? newPath : this.newPath,
      error: error is String? ? error : this.error,
      command: command ?? this.command,
      output: output is String? ? output : this.output,
    );
  }
}
