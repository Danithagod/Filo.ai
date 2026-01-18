# Windows Permission Handling Guide for Semantic Butler

**Version**: 1.0
**Created**: January 18, 2026
**Status**: Implementation Guide

---

## Executive Summary

This guide provides comprehensive strategies for handling Windows permissions in Semantic Butler, ensuring robust file system access while maintaining security and providing excellent user experience.

### Windows Security Model

**User Account Control (UAC)**
- Elevation prompts for administrative operations
- Token-based security model
- Requires explicit user consent for privileged operations

**Windows ACLs (Access Control Lists)**
- Discretionary access control
- Granular permissions on files and directories
- Inherited permissions from parent directories

**Windows Defender**
- Real-time malware protection
- May block file access for unsigned applications
- Requires exclusions for custom apps

**No App Sandbox**
- Full file access by default (unless restricted by UAC)
- Different from macOS model
- More permissive but still has security restrictions

---

## Key Windows Permissions Concepts

### 1. User Account Control (UAC)

UAC is a security feature that:
- **Requires elevation** for administrative operations
- **Prompts user** before granting elevated privileges
- **Runs processes** with standard user tokens by default
- **Maintains security** by limiting privileged access

**When UAC is Triggered**:
- Accessing system directories (C:\Windows, C:\Program Files)
- Modifying system files or registry
- Installing applications
- Running as administrator

### 2. Windows ACLs

Access Control Lists define:
- **Who can access** files and directories
- **What operations** are allowed (read, write, execute, delete)
- **Inheritance** of permissions from parent directories
- **Deny rules** that always override allow rules

**Common Permissions**:
- **Read (R)**: View file contents
- **Write (W)**: Modify file contents
- **Execute (X)**: Run programs or scripts
- **Delete (D)**: Remove files
- **Full Control**: All permissions combined

### 3. Windows Defender

Windows Defender:
- **Scans files** for malware in real-time
- **Blocks unknown** or suspicious applications
- **Requires exclusions** for trusted custom apps
- **Can prevent** file access and execution

---

## Implementation Strategies

### Strategy 1: MSIX Installer (Recommended)

**Best for**: Distribution, proper UAC handling, automatic permission management

MSIX is the modern packaging format for Windows applications:
- **Automatic signing** and verification
- **Declarative permissions** in manifest
- **Clean installation** and uninstallation
- **App Store compatibility** (optional)

#### MSIX Manifest Configuration

```xml
<!-- windows/runner/Package.appxmanifest -->

<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
          IgnorableNames="uap mp uap4 build"
          xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
          xmlns:mp="http://schemas.microsoft.com/appx/2014/phone/manifest"
          xmlns:uap4="http://schemas.microsoft.com/appx/manifest/uap/windows10/4"
          xmlns:build="http://schemas.microsoft.com/appx/manifest/foundation/windows10/3">
  
  <Identity Name="SemanticButler" 
            Publisher="CN=YourPublisher" 
            Version="1.0.0.0"
            ProcessorArchitecture="x64" />
  
  <Properties>
    <DisplayName>Semantic Butler</DisplayName>
    <PublisherDisplayName>Your Publisher</PublisherDisplayName>
    <Description>Intelligent file search and organization</Description>
    <Logo>Assets\icon.png</Logo>
  </Properties>
  
  <Dependencies>
    <TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.17763.0" />
    <PackageDependency Name="Microsoft.VCLibs.140.00" 
                      MinVersion="14.0.29231.0" 
                      Publisher="CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US" />
  </Dependencies>
  
  <Capabilities>
    <!-- Allow access to all files -->
    <Capability Name="broadFileSystemAccess" />
    
    <!-- Allow network access (for API calls) -->
    <Capability Name="internetClient" />
    <Capability Name="internetClientServer" />
  </Capabilities>
  
  <Applications>
    <Application Id="App" 
                 Executable="semantic_butler.exe" 
                 EntryPoint="semantic_butler.App">
      <uap:VisualElements DisplayName="Semantic Butler"
                          Square150x150Logo="Assets\Square150x150Logo.png"
                          Square44x44Logo="Assets\Square44x44Logo.png"
                          Description="Intelligent file search and organization" />
    </Application>
  </Applications>
</Package>
```

#### Building MSIX Package

```powershell
# build-msix.ps1

# Build Flutter Windows executable
flutter build windows --release

# Create MSIX package using MakeAppx
$msixPath = "build\windows\x64\runner\Release"
$msixFile = "semantic-butler.msix"

& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\makeappx.exe" `
  /package `
  /f "build\windows\x64\runner\Release" `
  /o "$msixFile" `
  /p "windows\runner\Package.appxmanifest"

# Sign MSIX package (optional but recommended)
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\signt.exe" `
  sign `
  /fd sha256 `
  /a "$msixFile"
```

#### Installing MSIX Package

```powershell
# Install MSIX package
Add-AppxPackage .\semantic-butler.msix

# Or double-click the MSIX file
```

---

### Strategy 2: UAC Elevation Handling

**Best for**: Administrative file operations, system file access

#### Check if Running as Administrator

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
      // Get current executable path
      final executable = Platform.executable;
      
      // Launch app as administrator
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          'Start-Process',
          '-FilePath',
          '"$executable"',
          '-Verb',
          'RunAs',
        ],
        runInShell: true,
      );

      // Exit current instance
      if (result.exitCode == 0) {
        exit(0);
      }

      return result.exitCode == 0;
    } catch (e) {
      AppLogger.error('Failed to request admin privileges: $e', tag: 'PermissionManager');
      return false;
    }
  }

  /// Run command with elevation
  static Future<String> runElevated(String command, List<String> args) async {
    try {
      final argsString = args.map((arg) => '"$arg"').join(' ');
      
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          'Start-Process',
          '-FilePath',
          '"$command"',
          '-ArgumentList',
          argsString,
          '-Verb',
          'RunAs',
          '-Wait',
          '-RedirectStandardOutput',
          '"temp_output.txt"',
        ],
        runInShell: true,
      );

      final output = await File('temp_output.txt').readAsString();
      await File('temp_output.txt').delete();

      return output;
    } catch (e) {
      AppLogger.error('Failed to run elevated command: $e', tag: 'PermissionManager');
      throw PermissionException('Failed to run elevated command: $e');
    }
  }
}
```

---

### Strategy 3: Windows Defender Exclusions

**Best for**: Preventing false positives, ensuring smooth file scanning

#### Add Defender Exclusion

```dart
// semantic_butler_flutter/lib/services/defender_manager.dart

import 'dart:io';
import '../utils/app_logger.dart';

/// Service for managing Windows Defender
class DefenderManager {
  /// Add file exclusion
  static Future<bool> addFileExclusion(String path) async {
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

      AppLogger.info('Added Defender exclusion: $path', tag: 'DefenderManager');
      return result.exitCode == 0;
    } catch (e) {
      AppLogger.error('Failed to add Defender exclusion: $e', tag: 'DefenderManager');
      return false;
    }
  }

  /// Add directory exclusion
  static Future<bool> addDirectoryExclusion(String path) async {
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

      AppLogger.info('Added Defender exclusion: $path', tag: 'DefenderManager');
      return result.exitCode == 0;
    } catch (e) {
      AppLogger.error('Failed to add Defender exclusion: $e', tag: 'DefenderManager');
      return false;
    }
  }

  /// Add process exclusion
  static Future<bool> addProcessExclusion(String processName) async {
    try {
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          'Add-MpPreference',
          '-ExclusionProcess',
          '"$processName"',
          '-Force',
        ],
        runInShell: true,
      );

      AppLogger.info('Added Defender exclusion: $processName', tag: 'DefenderManager');
      return result.exitCode == 0;
    } catch (e) {
      AppLogger.error('Failed to add Defender exclusion: $e', tag: 'DefenderManager');
      return false;
    }
  }

  /// Check if exclusion exists
  static Future<bool> hasExclusion(String path) async {
    try {
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          'Get-MpPreference',
          '|',
          'Select-String',
          '"$path"',
        ],
        runInShell: true,
      );

      return result.stdout.toString().contains(path);
    } catch (e) {
      AppLogger.error('Failed to check Defender exclusion: $e', tag: 'DefenderManager');
      return false;
    }
  }
}
```

---

## User Experience Improvements

### UAC Elevation Dialog

```dart
// semantic_butler_flutter/lib/widgets/elevation_dialog.dart

import 'package:flutter/material.dart';

/// Dialog requesting UAC elevation
class ElevationRequestDialog extends StatelessWidget {
  final String operation;
  final VoidCallback onApprove;
  final VoidCallback onCancel;

  const ElevationRequestDialog({
    required this.operation,
    required this.onApprove,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.admin_panel_settings, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(child: Text('Administrator Access Required')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To perform the following operation, Semantic Butler requires administrator privileges:',
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              operation,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Click "Approve" to relaunch the app as administrator. '
            'You will be prompted by Windows to confirm.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onApprove,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield),
              SizedBox(width: 8),
              Text('Approve'),
            ],
          ),
        ),
      ],
    );
  }
}
```

### Permission Status Widget

```dart
// semantic_butler_flutter/lib/widgets/permission_status_widget.dart

import 'package:flutter/material.dart';
import '../services/permission_manager_windows.dart';

/// Widget showing Windows permission status
class WindowsPermissionStatusWidget extends StatefulWidget {
  @override
  _WindowsPermissionStatusWidgetState createState() => _WindowsPermissionStatusWidgetState();
}

class _WindowsPermissionStatusWidgetState extends State<WindowsPermissionStatusWidget> {
  bool _isRunningAsAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    final isAdmin = await PermissionManagerWindows.isRunningAsAdmin();
    setState(() {
      _isRunningAsAdmin = isAdmin;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LinearProgressIndicator();
    }

    if (_isRunningAsAdmin) {
      return Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Text(
            'Running as Administrator',
            style: TextStyle(color: Colors.green, fontSize: 12),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.warning, color: Colors.orange, size: 20),
        SizedBox(width: 8),
        Text(
          'Standard user (limited access)',
          style: TextStyle(color: Colors.orange, fontSize: 12),
        ),
        SizedBox(width: 8),
        TextButton(
          onPressed: _checkPermissions,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          child: Text('Elevate', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
```

---

## Error Handling Patterns

### Graceful Degradation

```dart
// semantic_butler_flutter/lib/services/indexing_service.dart

import 'dart:io';
import '../services/permission_manager_windows.dart';

class IndexingService {
  Future<IndexingResult> indexFolder(String path) async {
    try {
      // Attempt to scan folder
      final files = await Directory(path).list();
      return await _processFiles(files);
    } catch (e) {
      if (_isPermissionError(e)) {
        // Handle permission error gracefully
        return IndexingResult(
          success: false,
          error: 'Permission denied',
          suggestion: _getPermissionSuggestion(e),
          requiresElevation: true,
        );
      } else {
        // Handle other errors
        return IndexingResult(
          success: false,
          error: e.toString(),
        );
      }
    }
  }

  bool _isPermissionError(dynamic error) {
    if (error is FileSystemException) {
      final fsError = error as FileSystemException;
      return fsError.osError?.message?.toLowerCase().contains('denied') == true ||
             fsError.osError?.message?.toLowerCase().contains('permission') == true;
    }
    return false;
  }

  String _getPermissionSuggestion(dynamic error) {
    if (_isPermissionError(error)) {
      return 'Run as administrator or select a different folder.';
    }
    return 'Check folder path and permissions.';
  }
}

class IndexingResult {
  final bool success;
  final String? error;
  final String? suggestion;
  final bool requiresElevation;

  IndexingResult({
    required this.success,
    this.error,
    this.suggestion,
    this.requiresElevation = false,
  });
}
```

---

## Testing Strategy

### Unit Tests

```dart
// semantic_butler_flutter/test/permission_windows_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../services/permission_manager_windows.dart';

void main() {
  group('PermissionManagerWindows', () {
    test('should detect admin privileges', () async {
      final result = await PermissionManagerWindows.isRunningAsAdmin();
      expect(result, isA<bool>());
    });

    test('should request elevation', () async {
      // Test elevation request (mocked)
      final result = await PermissionManagerWindows.requestAdminPrivileges();
      expect(result, isA<bool>());
    });
  });
}
```

### Integration Tests

```dart
// semantic_butler_flutter/test/integration/permission_windows_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgets('Windows permission flow test', (tester) async {
    // Test 1: Check initial permission status
    await tester.pumpWidget(MyApp());
    
    // Verify status widget shows standard user
    expect(find.text('Standard user (limited access)'), findsOneWidget);

    // Test 2: Request elevation
    await tester.tap(find.text('Elevate'));
    await tester.pumpAndSettle();
    
    // Verify elevation dialog is shown
    expect(find.text('Administrator Access Required'), findsOneWidget);

    // Test 3: Approve elevation
    await tester.tap(find.text('Approve'));
    
    // (In real test, this would relaunch app)
    // Verify new instance is launched

    // Test 4: Permission denied handling
    await tester.pumpWidget(MyApp());
    
    // Trigger permission error
    await tester.tap(find.text('Index Files'));
    
    // Verify error dialog is shown
    expect(find.text('Permission denied'), findsOneWidget);
  });
}
```

---

## Best Practices

### 1. Use MSIX for Distribution

```powershell
# Build signed MSIX package
flutter build windows --release
& makeappx.exe /package /f build\windows\x64\runner\Release
& signt.exe sign /fd sha256 /a semantic-butler.msix
```

### 2. Request Elevation Gracefully

```dart
// Don't force elevation, ask user
if (await requiresAdmin) {
  _showElevationDialog();
}
```

### 3. Handle Permission Errors

```dart
// Never crash on permission denied
try {
  await performFileOperation();
} catch (e) {
  if (_isPermissionError(e)) {
    _showPermissionDialog();
  } else {
    rethrow;
  }
}
```

### 4. Use Windows APIs When Needed

```dart
// Use win32 package for Windows-specific features
import 'package:win32/win32.dart';

// Example: Get Windows version
final version = GetVersionEx();
```

---

## Troubleshooting

### Common Issues

#### 1. UAC Elevation Fails

**Symptoms**: Elevation prompt doesn't appear or fails
**Cause**: MSIX manifest incorrect, executable not signed
**Solution**:
1. Verify MSIX manifest has correct execution level
2. Sign executable with trusted certificate
3. Test with elevated PowerShell

#### 2. Windows Defender Blocks Access

**Symptoms**: Files cannot be accessed, app is blocked
**Cause**: App not recognized as trusted
**Solution**:
1. Add app to Windows Defender exclusions
2. Sign executable with trusted certificate
3. Submit to Microsoft SmartScreen

#### 3. File Access Denied

**Symptoms**: Cannot read or write files
**Cause**: Insufficient permissions, ACLs blocking access
**Solution**:
1. Check file permissions with `icacls`
2. Run as administrator if needed
3. Ensure user has read/write access

---

## Resources

### Documentation
- [Windows UAC](https://learn.microsoft.com/en-us/windows/win32/secauthz/user-account-control)
- [MSIX Packaging](https://docs.microsoft.com/en-us/windows/msix/package)
- [Windows ACLs](https://docs.microsoft.com/en-us/windows/win32/fileio/file-security-and-access-rights)
- [Windows Defender](https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-antivirus)

### Flutter Packages
- [win32](https://pub.dev/packages/win32) - Windows API
- [file_picker](https://pub.dev/packages/file_picker) - File selection

### Examples
- [Flutter Windows Guide](https://docs.flutter.dev/platform-integration/windows/building)
- [MSIX Samples](https://github.com/microsoft/Windows-classic-samples/tree/master/Samples/MSIX/desktop)

---

**Document Version**: 1.0
**Last Updated**: January 18, 2026
**Owner**: Development Team
**Review Date**: January 25, 2026
