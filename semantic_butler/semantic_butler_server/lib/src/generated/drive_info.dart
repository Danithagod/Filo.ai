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

abstract class DriveInfo
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DriveInfo._({
    required this.name,
    required this.path,
    this.totalSpace,
    this.availableSpace,
    this.driveType,
  });

  factory DriveInfo({
    required String name,
    required String path,
    int? totalSpace,
    int? availableSpace,
    String? driveType,
  }) = _DriveInfoImpl;

  factory DriveInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return DriveInfo(
      name: jsonSerialization['name'] as String,
      path: jsonSerialization['path'] as String,
      totalSpace: jsonSerialization['totalSpace'] as int?,
      availableSpace: jsonSerialization['availableSpace'] as int?,
      driveType: jsonSerialization['driveType'] as String?,
    );
  }

  String name;

  String path;

  int? totalSpace;

  int? availableSpace;

  String? driveType;

  /// Returns a shallow copy of this [DriveInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DriveInfo copyWith({
    String? name,
    String? path,
    int? totalSpace,
    int? availableSpace,
    String? driveType,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DriveInfo',
      'name': name,
      'path': path,
      if (totalSpace != null) 'totalSpace': totalSpace,
      if (availableSpace != null) 'availableSpace': availableSpace,
      if (driveType != null) 'driveType': driveType,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DriveInfo',
      'name': name,
      'path': path,
      if (totalSpace != null) 'totalSpace': totalSpace,
      if (availableSpace != null) 'availableSpace': availableSpace,
      if (driveType != null) 'driveType': driveType,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DriveInfoImpl extends DriveInfo {
  _DriveInfoImpl({
    required String name,
    required String path,
    int? totalSpace,
    int? availableSpace,
    String? driveType,
  }) : super._(
         name: name,
         path: path,
         totalSpace: totalSpace,
         availableSpace: availableSpace,
         driveType: driveType,
       );

  /// Returns a shallow copy of this [DriveInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DriveInfo copyWith({
    String? name,
    String? path,
    Object? totalSpace = _Undefined,
    Object? availableSpace = _Undefined,
    Object? driveType = _Undefined,
  }) {
    return DriveInfo(
      name: name ?? this.name,
      path: path ?? this.path,
      totalSpace: totalSpace is int? ? totalSpace : this.totalSpace,
      availableSpace: availableSpace is int?
          ? availableSpace
          : this.availableSpace,
      driveType: driveType is String? ? driveType : this.driveType,
    );
  }
}
