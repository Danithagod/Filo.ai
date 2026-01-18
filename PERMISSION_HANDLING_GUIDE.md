# Cross-Platform Permission Handling Guide for Semantic Butler

**Version**: 2.0
**Created**: January 18, 2026
**Updated**: January 18, 2026
**Status**: Implementation Guide

---

## Executive Summary

This guide provides comprehensive strategies for handling file system permissions across macOS, Windows, and Linux in Semantic Butler, ensuring robust file access while maintaining security and providing excellent user experience.

### Current State Analysis

**Observations from Codebase**:
1. **No entitlements for file access (macOS)**: Current entitlements files only include:
   - `com.apple.security.app-sandbox` (sandbox enabled)
   - `com.apple.security.cs.allow-jit` (JIT compilation)
   - `com.apple.security.network.server` (network server)
   
2. **Missing UAC handling (Windows)**: No User Account Control elevation strategy
3. **No security-scoped bookmarks (macOS)**: No persistent file access mechanism for app restarts
4. **No AppArmor/SELinux profiles (Linux)**: No mandatory access control configuration
5. **No permission error handling**: Current implementation doesn't gracefully handle permission denials across platforms

### Key Problems

1. **Access Denied Errors**: Users cannot index files outside app sandbox without explicit permission
2. **Lost Permissions on Restart**: Access to folders requires re-authorization after app restart (macOS)
3. **Poor User Experience**: No clear guidance on enabling permissions across all platforms
4. **No Fallback**: App crashes or fails silently when permissions are denied
5. **Platform-Specific Issues**: 
   - macOS: App sandbox restrictions
   - Windows: UAC elevation prompts
   - Linux: AppArmor/SELinux enforcement

---

## Platform Overview

### macOS

**Security Model**: App Sandbox with Entitlements
- **App Sandbox**: Restricts access to app container only
- **Entitlements**: Special permissions to access files, network, etc.
- **Security-Scoped Bookmarks**: Persistent access to user-selected files
- **TCC (Transparency, Consent, Control)**: Manages privacy permissions

**Key Permissions**:
- `com.apple.security.files.user-selected.read-write`
- `com.apple.security.files.downloads.read-write`
- `com.apple.security.files.pictures.read-write`
- `com.apple.security.files.bookmarks.document-scope`

### Windows

**Security Model**: User Account Control (UAC) + Windows ACLs
- **UAC**: Elevation prompts for administrative operations
- **Windows ACLs**: Access Control Lists for file permissions
- **Windows Defender**: May block file access
- **No Sandbox**: Full file access by default (unless restricted by UAC)

**Key Considerations**:
- MSIX installer recommended for proper UAC handling
- `win32` package for Windows API calls
- Admin rights for system file operations
- Windows Defender exclusions for file scanning

### Linux

**Security Model**: Standard Unix Permissions + Mandatory Access Control
- **Unix Permissions**: chmod/chown (discretionary access control)
- **AppArmor**: Mandatory access control (Ubuntu, openSUSE)
- **SELinux**: Mandatory access control (CentOS, RHEL, Fedora)
- **No Sandbox**: Full file access by default (unless restricted by MAC)

**Key Considerations**:
- Standard file permissions (`rwx`)
- AppArmor profiles for confinement
- SELinux policies for security
- User namespace restrictions (Ubuntu 23.10+)

---

## macOS Implementation Strategies

### Strategy 1: User-Selected File Access (Recommended)

**Best for**: Initial indexing, folder selection, file operations

#### Required Entitlements

```xml
<!-- macos/Runner/DebugProfile.entitlements -->
<!-- macos/Runner/Release.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Sandbox (required for App Store) -->
    <key>com.apple.security.app-sandbox</key>
    <true/>
    
    <!-- JIT Compilation (required for Flutter) -->
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    
    <!-- Network Access (required for API calls) -->
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    
    <!-- User-Selected File Access (REQUIRED) -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- Optional: Allow reading downloads folder -->
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    
    <!-- Optional: Allow access to specific directories -->
    <key>com.apple.security.files.pictures.read-write</key>
    <true/>
    
    <!-- Bookmarks for persistent access -->
    <key>com.apple.security.files.bookmarks.document-scope</key>
    <true/>
</dict>
</plist>
```

---

## Windows Implementation Strategies

### Strategy 1: Proper UAC Handling

**Best for**: Administrative file operations, system file access

#### MSIX Installer Configuration

```xml
<!-- windows/runner/Package.appxmanifest -->

<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10">
  <Identity Name="SemanticButler" Publisher="CN=YourPublisher" Version="1.0.0.0" />
  <Properties>
    <DisplayName>Semantic Butler</DisplayName>
    <PublisherDisplayName>Your Publisher</PublisherDisplayName>
    <Description>Intelligent file search and organization</Description>
  </Properties>
  <Capabilities>
    <!-- Allow file system access -->
    <Capability Name="broadFileSystemAccess" />
  </Capabilities>
</Package>
```

#### UAC Elevation Request

```dart
// semantic_butler_flutter/lib/services/permission_manager_windows.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';

/// Service for managing Windows permissions
class PermissionManagerWindows {
  /// Check if running as administrator
  static Future<bool> isRunningAsAdmin() async {
    if (!Platform.isWindows) return true;
    
    try {
      // Try to access a system directory
      final windowsDir = Directory(r'C:\Windows\System32');
      await windowsDir.list();
      return true;
    } catch (e) {
      AppLogger.info('Not running as admin: $e', tag: 'PermissionManager');
      return false;
    }
  }

  /// Request administrator privileges
  static Future<bool> requestAdminPrivileges() async {
    if (!Platform.isWindows) return true;
    
    try {
      // Launch app as administrator
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          'Start-Process',
          '"${Platform.executable}"',
          '-Verb',
          'RunAs',
          '-ArgumentList',
          '"--elevated"',
        ],
        runInShell: true,
      );

      return result.exitCode == 0;
    } catch (e) {
      AppLogger.error('Failed to request admin privileges: $e', tag: 'PermissionManager');
      return false;
    }
  }

  /// Add Windows Defender exclusion
  static Future<bool> addDefenderExclusion(String path) async {
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
      AppLogger.error('Failed to add Defender exclusion: $e', tag: 'PermissionManager');
      return false;
    }
  }
}
```

---

## Linux Implementation Strategies

### Strategy 1: Handle Standard Unix Permissions

**Best for**: Basic file operations, user home directory access

#### Permission Check

```dart
// semantic_butler_flutter/lib/services/permission_manager_linux.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';

/// Service for managing Linux permissions
class PermissionManagerLinux {
  /// Check if can write to directory
  static Future<bool> canWriteTo(String path) async {
    try {
      final testFile = File('$path/.permission_test');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      AppLogger.warning('Cannot write to $path: $e', tag: 'PermissionManager');
      return false;
    }
  }

  /// Fix permissions for directory
  static Future<bool> fixPermissions(String path) async {
    try {
      final result = await Process.run(
        'chmod',
        ['+w', path],
      );

      return result.exitCode == 0;
    } catch (e) {
      AppLogger.error('Failed to fix permissions: $e', tag: 'PermissionManager');
      return false;
    }
  }

  /// Check if AppArmor is blocking
  static Future<bool> isAppArmorBlocking() async {
    try {
      final result = await Process.run(
        'aa-status',
        [],
        runInShell: true,
      );

      return result.exitCode == 0;
    } catch (e) {
      // aa-status not available, AppArmor may not be installed
      return false;
    }
  }

  /// Check if SELinux is enforcing
  static Future<bool> isSELinuxEnforcing() async {
    try {
      final result = await Process.run(
        'getenforce',
        [],
        runInShell: true,
      );

      final output = result.stdout.toString().trim();
      return output.toLowerCase() == 'enforcing';
    } catch (e) {
      // getenforce not available, SELinux may not be installed
      return false;
    }
  }
}
```

### Strategy 2: AppArmor Profile Creation

**Best for**: Distribution on Ubuntu, openSUSE, and other AppArmor-based distros

#### AppArmor Profile Template

```bash
# scripts/apparmor-profile

# Semantic Butler AppArmor Profile
# Install: sudo apparmor_parser -r semantic-butler.profile

#include <tunables/global>

profile semantic-butler {
  # Allow read access to all files
  capability dac_read_search,
  capability dac_override,

  /usr/bin/semantic-butler mr,
  
  # Allow read access to user home directory
  owner @{HOME}/ r,
  owner @{HOME}/** r,
  
  # Allow write access to app data directory
  owner @{HOME}/.local/share/semantic-butler/ rw,
  owner @{HOME}/.local/share/semantic-butler/** rw,
  
  # Allow read access to system libraries
  /usr/lib/** mr,
  /usr/lib/x86_64-linux-gnu/** mr,
  
  # Allow network access
  network inet stream,
  network inet dgram,
}
```

---

## Cross-Platform Implementation

### Unified Permission Manager

```dart
// semantic_butler_flutter/lib/services/permission_manager.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'permission_manager_macos.dart' if (dart.library.io) 'permission_manager_macos.dart';
import 'permission_manager_windows.dart' if (dart.library.io) 'permission_manager_windows.dart';
import 'permission_manager_linux.dart' if (dart.library.io) 'permission_manager_linux.dart';
import '../utils/app_logger.dart';

/// Unified service for managing permissions across platforms
class PermissionManager {
  /// Check if app has file access permission
  static Future<bool> hasFileAccess() async {
    if (Platform.isMacOS) {
      return await PermissionManagerMacOS.hasFileAccess();
    } else if (Platform.isWindows) {
      return await PermissionManagerWindows.hasFileAccess();
    } else if (Platform.isLinux) {
      return await PermissionManagerLinux.canWriteTo(Directory.current.path);
    }
    return true;
  }

  /// Request user to select folders for indexing
  static Future<List<String>> requestFolderAccess() async {
    try {
      final result = await FilePicker.platform.getDirectoryPaths(
        dialogTitle: 'Select Folders to Index',
        lockParentWindow: true,
      );

      if (result == null || result.isEmpty) {
        AppLogger.info('User cancelled folder selection', tag: 'PermissionManager');
        return [];
      }

      // Platform-specific handling
      if (Platform.isMacOS) {
        // Save bookmarks for persistence
        for (final folder in result) {
          await BookmarkManager.saveBookmark(folder);
        }
      }

      AppLogger.info(
        'User selected ${result.length} folders',
        tag: 'PermissionManager',
      );

      return result;
    } catch (e) {
      AppLogger.error('Folder selection failed: $e', tag: 'PermissionManager');
      throw PermissionException('Failed to select folders: $e');
    }
  }

  /// Request elevated permissions
  static Future<bool> requestElevatedPermissions() async {
    if (Platform.isMacOS) {
      // Guide user to Full Disk Access
      return await PermissionManagerMacOS.requestFullDiskAccess();
    } else if (Platform.isWindows) {
      // Request admin privileges
      return await PermissionManagerWindows.requestAdminPrivileges();
    } else if (Platform.isLinux) {
      // Provide instructions for AppArmor/SELinux
      return await _showLinuxPermissionInstructions();
    }
    return true;
  }

  static Future<bool> _showLinuxPermissionInstructions() async {
    // Show dialog with instructions for Linux
    // Implementation depends on UI framework
    return true;
  }

  /// Handle permission errors gracefully
  static void handlePermissionError(dynamic error, {String? context}) {
    if (Platform.isMacOS) {
      PermissionManagerMacOS.handlePermissionError(error, context: context);
    } else if (Platform.isWindows) {
      PermissionManagerWindows.handlePermissionError(error, context: context);
    } else if (Platform.isLinux) {
      PermissionManagerLinux.handlePermissionError(error, context: context);
    }
  }

  /// Get platform-specific permission status
  static Future<PermissionStatus> getPermissionStatus() async {
    if (Platform.isMacOS) {
      return await PermissionManagerMacOS.getPermissionStatus();
    } else if (Platform.isWindows) {
      return await PermissionManagerWindows.getPermissionStatus();
    } else if (Platform.isLinux) {
      return await PermissionManagerLinux.getPermissionStatus();
    }
    return PermissionStatus(granted: true, message: 'Permissions not applicable');
  }
}

enum PermissionStatus {
  granted,
  denied,
  partial,
  notApplicable,
}

class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);
  
  @override
  String toString() => 'PermissionException: $message';
}
```

---

## User Experience Improvements

### Cross-Platform Permission Dialog

```dart
// semantic_butler_flutter/lib/widgets/permission_dialog.dart

import 'package:flutter/material.dart';
import 'dart:io';

/// Platform-aware permission dialog
class PermissionRequestDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onGrant;
  final VoidCallback onCancel;

  const PermissionRequestDialog({
    required this.title,
    required this.message,
    required this.onGrant,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_getPlatformIcon(), color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          SizedBox(height: 16),
          _getPlatformInstructions(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onGrant,
          child: Text('Grant Access'),
        ),
      ],
    );
  }

  IconData _getPlatformIcon() {
    if (Platform.isMacOS) return Icons.security;
    if (Platform.isWindows) return Icons.admin_panel_settings;
    if (Platform.isLinux) return Icons.settings;
    return Icons.security;
  }

  Widget _getPlatformInstructions() {
    if (Platform.isMacOS) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 16),
                SizedBox(width: 8),
                Text('macOS requires explicit permission', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text('1. Click "Grant Access"', style: TextStyle(fontSize: 12)),
            Text('2. Select folders to index', style: TextStyle(fontSize: 12)),
            Text('3. Or enable Full Disk Access in System Settings', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    } else if (Platform.isWindows) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 16),
                SizedBox(width: 8),
                Text('Windows may require administrator access', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text('1. Click "Grant Access"', style: TextStyle(fontSize: 12)),
            Text('2. Approve UAC elevation prompt if shown', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    } else if (Platform.isLinux) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 16),
                SizedBox(width: 8),
                Text('Linux permissions are file-based', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text('1. Click "Grant Access"', style: TextStyle(fontSize: 12)),
            Text('2. Select folders to index', style: TextStyle(fontSize: 12)),
            Text('3. Ensure app has read/write permissions', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }
}
```

---

## Error Handling Patterns

### Cross-Platform Error Handling

```dart
// semantic_butler_flutter/lib/services/file_operations_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'permission_manager.dart';

class FileOperationsService {
  static Future<List<File>> scanDirectory(String path) async {
    try {
      // Try direct access first
      return Directory(path).listSync();
    } catch (e) {
      // Platform-specific error handling
      if (Platform.isMacOS) {
        // Try to use bookmark
        final bookmark = await BookmarkManager.resolveBookmark(path);
        return bookmark.listSync();
      } else if (Platform.isWindows) {
        // Check if UAC elevation is needed
        if (await PermissionManagerWindows.isRunningAsAdmin()) {
          // Retry with elevated permissions
          return await _scanWithElevation(path);
        } else {
          // Request elevation
          await PermissionManagerWindows.requestAdminPrivileges();
          throw PermissionException('Administrator access required');
        }
      } else if (Platform.isLinux) {
        // Check if permission can be fixed
        if (await PermissionManagerLinux.canWriteTo(path)) {
          return Directory(path).listSync();
        } else {
          // Try to fix permissions
          await PermissionManagerLinux.fixPermissions(path);
          return Directory(path).listSync();
        }
      }
      
      // Re-throw if not recoverable
      rethrow;
    }
  }

  static Future<List<File>> _scanWithElevation(String path) async {
    // Implement elevated scan for Windows
    return Directory(path).listSync();
  }
}
```

---

## Implementation Checklist

### Phase 1: Platform Configuration (2 hours)

#### macOS
- [ ] Update `macos/Runner/DebugProfile.entitlements`
- [ ] Update `macos/Runner/Release.entitlements`
- [ ] Add file access entitlements
- [ ] Add bookmark entitlements
- [ ] Test with Xcode build

#### Windows
- [ ] Configure MSIX installer
- [ ] Add UAC execution level to manifest
- [ ] Add file system access capabilities
- [ ] Test with MSIX build

#### Linux
- [ ] Create AppArmor profile
- [ ] Test with AppArmor enabled
- [ ] Test with SELinux enabled
- [ ] Create .deb and .rpm packages

### Phase 2: Permission Manager (4 hours)
- [ ] Create `PermissionManager` (unified)
- [ ] Implement `PermissionManagerMacOS`
- [ ] Implement `PermissionManagerWindows`
- [ ] Implement `PermissionManagerLinux`
- [ ] Add error handling for each platform

### Phase 3: Bookmark System (4 hours) - macOS Only
- [ ] Add `directory_bookmarks` dependency
- [ ] Create `BookmarkManager` service
- [ ] Implement bookmark save/load/resolve
- [ ] Add bookmark cleanup on startup

### Phase 4: UI Components (3 hours)
- [ ] Create `PermissionRequestDialog` (cross-platform)
- [ ] Create `PermissionStatusWidget`
- [ ] Create `PermissionSetupScreen` for onboarding
- [ ] Add platform-specific instructions

### Phase 5: Error Handling (3 hours)
- [ ] Update file operations to use platform-specific handlers
- [ ] Add graceful error handling
- [ ] Implement retry mechanism
- [ ] Add user-friendly error messages

### Phase 6: Testing (3 hours)
- [ ] Write unit tests for permission managers
- [ ] Write integration tests for permission flow
- [ ] Test on macOS (local development)
- [ ] Test on Windows (local development)
- [ ] Test on Linux (local development)
- [ ] Test on all platforms (CI/CD)

---

## Best Practices

### 1. Platform-Specific Implementation

```dart
// Use platform-specific logic where needed
if (Platform.isMacOS) {
  // macOS-specific code
} else if (Platform.isWindows) {
  // Windows-specific code
} else if (Platform.isLinux) {
  // Linux-specific code
}
```

### 2. Unified Error Handling

```dart
// Provide consistent error handling across platforms
try {
  await performFileOperation();
} catch (e) {
  PermissionManager.handlePermissionError(e, context: 'File indexing');
}
```

### 3. User-Friendly Messages

```dart
// Provide clear, actionable messages
if (Platform.isMacOS) {
  _showMessage('Grant file access permission or select folder again');
} else if (Platform.isWindows) {
  _showMessage('Run as administrator to access system files');
} else if (Platform.isLinux) {
  _showMessage('Ensure app has read/write permissions');
}
```

### 4. Test on All Platforms

- [ ] macOS: Intel and Apple Silicon
- [ ] Windows: 10 and 11
- [ ] Linux: Ubuntu, Debian, Fedora, Arch

---

## Troubleshooting Guide

### macOS

#### 1. App Crashes on File Access
**Solution**: Verify entitlements, use file_picker, implement error handling

#### 2. Lost Access After Restart
**Solution**: Use security-scoped bookmarks

#### 3. Full Disk Access Not Working
**Solution**: Restart app after enabling FDA, verify app appears in list

### Windows

#### 1. UAC Elevation Fails
**Solution**: Check MSIX manifest, ensure executable is signed

#### 2. Windows Defender Blocks Access
**Solution**: Add app to exclusions, create proper MSIX package

#### 3. File Access Denied
**Solution**: Check file permissions, run as administrator if needed

### Linux

#### 1. Permission Denied
**Solution**: Fix file permissions with chmod, check AppArmor/SELinux

#### 2. AppArmor Blocking
**Solution**: Create AppArmor profile, or disable AppArmor for testing

#### 3. SELinux Blocking
**Solution**: Create SELinux policy, or set to Permissive mode for testing

---

## Resources

### Documentation
- [Apple App Sandbox](https://developer.apple.com/documentation/security/app-sandbox)
- [Windows UAC](https://learn.microsoft.com/en-us/windows/win32/secauthz/user-account-control)
- [Linux File Permissions](https://wiki.archlinux.org/title/File_permissions_and_attributes)
- [AppArmor](https://gitlab.com/apparmor/apparmor)
- [SELinux](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/using_selinux/index)

### Flutter Packages
- [directory_bookmarks](https://pub.dev/packages/directory_bookmarks) - macOS persistent access
- [file_picker](https://pub.dev/packages/file_picker) - Cross-platform file selection
- [permission_handler](https://pub.dev/packages/permission_handler) - Cross-platform permissions
- [win32](https://pub.dev/packages/win32) - Windows API

### Examples
- [macos_secure_bookmarks](https://github.com/authpass/macos_secure_bookmarks)
- [Flutter Windows Guide](https://docs.flutter.dev/platform-integration/windows/building)
- [Flutter Linux Guide](https://docs.flutter.dev/platform-integration/linux/building)

---

## Conclusion

Implementing robust permission handling across macOS, Windows, and Linux requires:

1. **Platform-specific configuration**: Entitlements, manifests, profiles
2. **Unified error handling**: Consistent behavior across platforms
3. **Clear user guidance**: Platform-specific instructions
4. **Fallback options**: Alternative ways to use the app
5. **Thorough testing**: Test on all supported platforms

By following this guide, Semantic Butler will provide a smooth, secure, and user-friendly experience across all desktop platforms while maintaining privacy and security standards.

---

**Document Version**: 2.0
**Last Updated**: January 18, 2026
**Owner**: Development Team
**Review Date**: January 25, 2026
