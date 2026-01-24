import 'dart:io';
import '../utils/app_logger.dart';
import 'permission_manager.dart';

/// Linux-specific permission handling
class PermissionManagerLinux {
  /// Check if the app has general file access
  static Future<bool> hasFileAccess() async {
    if (!Platform.isLinux) return true;
    return await canWriteTo(Directory.current.path);
  }

  /// Check if can write to directory
  static Future<bool> canWriteTo(String path) async {
    try {
      final testFile = File('$path/.permission_test');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      AppLogger.warning(
        'Linux: Cannot write to $path: $e',
        tag: 'PermissionManager',
      );
      return false;
    }
  }

  /// Get detailed status for Linux
  static Future<PermissionResult> getDetailedStatus() async {
    if (!Platform.isLinux) {
      return const PermissionResult(
        status: PermissionStatus.notApplicable,
        message: 'Not a Linux platform',
      );
    }

    final isWriteable = await hasFileAccess();
    final isAppArmor = await isAppArmorBlocking();
    final isSELinux = await isSELinuxEnforcing();

    String msg = '';
    if (isWriteable) {
      msg = 'App has file system access.';
    } else {
      msg = 'Standard Unix permissions restricted.';
    }

    if (isAppArmor) msg += ' AppArmor is active.';
    if (isSELinux) msg += ' SELinux is enforcing.';

    return PermissionResult(
      status: isWriteable ? PermissionStatus.granted : PermissionStatus.partial,
      message: msg,
    );
  }

  /// Request permissions (providing instructions for Linux users)
  static Future<PermissionResult> requestPermissions() async {
    if (!Platform.isLinux) {
      return const PermissionResult(
        status: PermissionStatus.notApplicable,
      );
    }

    // On Linux, we typically guide them to fix permissions manually
    // or through a script.
    return const PermissionResult(
      status: PermissionStatus.partial,
      message:
          'Please ensure the app has read/write permissions for your data folders. You can use "chmod +rw <folder>" if needed.',
    );
  }

  /// Fix permissions for directory
  static Future<bool> fixPermissions(String path) async {
    try {
      final result = await Process.run('chmod', ['+w', path]);
      return result.exitCode == 0;
    } catch (e) {
      AppLogger.error(
        'Failed to fix permissions: $e',
        tag: 'PermissionManager',
      );
      return false;
    }
  }

  /// Check if AppArmor is blocking
  static Future<bool> isAppArmorBlocking() async {
    try {
      final result = await Process.run('aa-status', [], runInShell: true);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Check if SELinux is enforcing
  static Future<bool> isSELinuxEnforcing() async {
    try {
      final result = await Process.run('getenforce', [], runInShell: true);
      final output = result.stdout.toString().trim().toLowerCase();
      return output == 'enforcing';
    } catch (e) {
      return false;
    }
  }

  /// Handle Linux specific permission errors
  static void handlePermissionError(dynamic error, {String? context}) {
    AppLogger.error(
      'Linux Permission Error in $context: $error. Suggesting chmod or checking AppArmor/SELinux.',
      tag: 'PermissionManager',
    );
  }
}
