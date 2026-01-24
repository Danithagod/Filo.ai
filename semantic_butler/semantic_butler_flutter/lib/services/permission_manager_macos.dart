import 'dart:io';
import '../utils/app_logger.dart';
import 'permission_manager.dart';

/// macOS-specific permission handling
class PermissionManagerMacOS {
  /// Check if the app has general file access
  static Future<bool> hasFileAccess() async {
    if (!Platform.isMacOS) return true;
    try {
      // Check if can write to a test file in the documents directory
      // This is a simple way to check sandbox/FDA status
      final testDir = Directory('${Platform.environment['HOME']}/Documents');
      if (await testDir.exists()) {
        final testFile = File('${testDir.path}/.permission_test');
        await testFile.writeAsString('test');
        await testFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.info(
        'macOS: Restricted file access: $e',
        tag: 'PermissionManager',
      );
      return false;
    }
  }

  /// Get detailed status for macOS
  static Future<PermissionResult> getDetailedStatus() async {
    if (!Platform.isMacOS) {
      return const PermissionResult(
        status: PermissionStatus.notApplicable,
        message: 'Not a macOS platform',
      );
    }

    final hasAccess = await hasFileAccess();
    if (hasAccess) {
      return const PermissionResult(
        status: PermissionStatus.granted,
        message: 'App has file system access.',
      );
    } else {
      return const PermissionResult(
        status: PermissionStatus.partial,
        message:
            'App is sandboxed or lacks Full Disk Access. Some folders may be inaccessible.',
      );
    }
  }

  /// Request permissions on macOS (Guidance to FDA)
  static Future<PermissionResult> requestPermissions() async {
    if (!Platform.isMacOS) {
      return const PermissionResult(
        status: PermissionStatus.notApplicable,
      );
    }

    // On macOS, you can't programmatically request FDA,
    // but you can open the System Settings.
    try {
      AppLogger.info(
        'Opening macOS Privacy settings for FDA',
        tag: 'PermissionManager',
      );
      await Process.run('open', [
        'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles',
      ]);

      return const PermissionResult(
        status: PermissionStatus.partial,
        message:
            'System Settings opened. Please enable Full Disk Access for Semantic Butler and restart the app.',
      );
    } catch (e) {
      return PermissionResult(
        status: PermissionStatus.denied,
        message: 'Failed to open System Settings: $e',
      );
    }
  }

  /// Request Full Disk Access guidance (Alias for unified manager)
  static Future<bool> requestFullDiskAccess() async {
    final result = await requestPermissions();
    return result.status == PermissionStatus.partial;
  }

  /// Handle macOS specific permission errors
  static void handlePermissionError(dynamic error, {String? context}) {
    AppLogger.error(
      'macOS Permission Error in $context: $error. Suggesting Full Disk Access.',
      tag: 'PermissionManager',
    );
  }
}
