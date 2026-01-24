import 'dart:io';
import 'permission_manager_macos.dart'
    if (dart.library.io) 'permission_manager_macos.dart';
import 'permission_manager_windows.dart'
    if (dart.library.io) 'permission_manager_windows.dart';
import 'permission_manager_linux.dart'
    if (dart.library.io) 'permission_manager_linux.dart';
import '../utils/app_logger.dart';

/// Status of a particular permission
enum PermissionStatus {
  granted,
  denied,
  partial,
  notApplicable,
}

/// Result of a permission request or check
class PermissionResult {
  final PermissionStatus status;
  final String? message;

  const PermissionResult({
    required this.status,
    this.message,
  });

  bool get isGranted => status == PermissionStatus.granted;
}

/// Unified service for managing permissions across platforms
class PermissionManager {
  /// Check if the app has basic file access permissions
  static Future<bool> hasFileAccess() async {
    try {
      if (Platform.isMacOS) {
        return await PermissionManagerMacOS.hasFileAccess();
      } else if (Platform.isWindows) {
        return await PermissionManagerWindows.hasFileAccess();
      } else if (Platform.isLinux) {
        return await PermissionManagerLinux.hasFileAccess();
      }
    } catch (e) {
      AppLogger.error(
        'Failed to check file access: $e',
        tag: 'PermissionManager',
      );
    }
    return true; // Default to true for other platforms or if check fails
  }

  /// Get detailed permission status for the current platform
  static Future<PermissionResult> getPermissionStatus() async {
    try {
      if (Platform.isMacOS) {
        return await PermissionManagerMacOS.getDetailedStatus();
      } else if (Platform.isWindows) {
        return await PermissionManagerWindows.getDetailedStatus();
      } else if (Platform.isLinux) {
        return await PermissionManagerLinux.getDetailedStatus();
      }
    } catch (e) {
      AppLogger.error(
        'Failed to get permission status: $e',
        tag: 'PermissionManager',
      );
    }
    return const PermissionResult(
      status: PermissionStatus.notApplicable,
      message: 'Permission check not implemented for this platform',
    );
  }

  /// Request necessary permissions for the current platform
  static Future<PermissionResult> requestPermissions() async {
    try {
      if (Platform.isMacOS) {
        return await PermissionManagerMacOS.requestPermissions();
      } else if (Platform.isWindows) {
        return await PermissionManagerWindows.requestPermissions();
      } else if (Platform.isLinux) {
        return await PermissionManagerLinux.requestPermissions();
      }
    } catch (e) {
      AppLogger.error(
        'Failed to request permissions: $e',
        tag: 'PermissionManager',
      );
    }
    return const PermissionResult(
      status: PermissionStatus.notApplicable,
      message: 'Permission request not implemented for this platform',
    );
  }

  /// Request elevated permissions (Guide-driven)
  static Future<bool> requestElevatedPermissions() async {
    if (Platform.isMacOS) {
      return await PermissionManagerMacOS.requestFullDiskAccess();
    } else if (Platform.isWindows) {
      final res = await PermissionManagerWindows.requestPermissions();
      return res.status == PermissionStatus.granted;
    } else if (Platform.isLinux) {
      return false; // Typically manual on Linux
    }
    return true;
  }

  /// Handle permission errors gracefully
  static void handlePermissionError(dynamic error, {String? context}) {
    if (Platform.isMacOS) {
      PermissionManagerMacOS.handlePermissionError(error, context: context);
    } else if (Platform.isWindows) {
      // Standard logging for now
      AppLogger.error(
        'Windows Permission Error in $context: $error',
        tag: 'PermissionManager',
      );
    } else if (Platform.isLinux) {
      PermissionManagerLinux.handlePermissionError(error, context: context);
    }
  }
}

class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);

  @override
  String toString() => 'PermissionException: $message';
}
