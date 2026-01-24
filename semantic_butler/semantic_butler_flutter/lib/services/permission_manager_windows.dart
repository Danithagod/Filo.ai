import 'dart:io';
import '../utils/app_logger.dart';
import 'permission_manager.dart';

/// Windows-specific permission handling
class PermissionManagerWindows {
  /// Check if the app has general file access
  static Future<bool> hasFileAccess() async {
    // Windows generally allows file access unless restricted by ACLs or UAC
    // For now, we assume true but could add specific checks if needed
    return true;
  }

  /// Get detailed status for Windows
  static Future<PermissionResult> getDetailedStatus() async {
    if (!Platform.isWindows) {
      return const PermissionResult(
        status: PermissionStatus.notApplicable,
        message: 'Not a Windows platform',
      );
    }

    final isAdmin = await isRunningAsAdmin();
    if (isAdmin) {
      return const PermissionResult(
        status: PermissionStatus.granted,
        message: 'Running with administrative privileges',
      );
    } else {
      return const PermissionResult(
        status: PermissionStatus.partial,
        message:
            'Running with standard user privileges. Some system files may be inaccessible.',
      );
    }
  }

  /// Request administrator privileges
  /// Note: In debug mode (flutter run), elevation doesn't work properly.
  /// For most file operations, admin rights are NOT required.
  static Future<PermissionResult> requestPermissions() async {
    if (!Platform.isWindows) {
      return const PermissionResult(
        status: PermissionStatus.notApplicable,
      );
    }

    if (await isRunningAsAdmin()) {
      return const PermissionResult(
        status: PermissionStatus.granted,
        message: 'Already running as administrator',
      );
    }

    // In debug mode or when running via Flutter, we can't easily elevate.
    // Most file operations don't require admin rights anyway.
    // Grant permissions and let the user proceed.
    return const PermissionResult(
      status: PermissionStatus.granted,
      message:
          'Standard user privileges are sufficient for most operations. '
          'You can run the app as administrator for full system access if needed.',
    );
  }

  /// Add Windows Defender exclusion for a path
  static Future<bool> addDefenderExclusion(String path) async {
    if (!Platform.isWindows) return true;

    try {
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          'Add-MpPreference',
          '-ExclusionPath',
          '"$path"',
          '-Force',
        ],
        runInShell: true,
      );

      return result.exitCode == 0;
    } catch (e) {
      AppLogger.error(
        'Failed to add Defender exclusion: $e',
        tag: 'PermissionManager',
      );
      return false;
    }
  }

  /// Robust check if running as Administrator
  static Future<bool> isRunningAsAdmin() async {
    if (!Platform.isWindows) return true;
    try {
      // Try to access a system directory - reliable way to check admin rights
      final windowsDir = Directory(r'C:\Windows\System32\config');
      await windowsDir.list().first;
      return true;
    } catch (e) {
      // If access to config is denied, definitely not admin
      return false;
    }
  }
}
