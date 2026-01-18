# Linux Permission Handling Guide for Semantic Butler

**Version**: 1.0
**Created**: January 18, 2026
**Status**: Implementation Guide

---

## Executive Summary

This guide provides comprehensive strategies for handling Linux permissions in Semantic Butler, ensuring robust file system access while maintaining security and providing excellent user experience.

### Linux Security Model

**Standard Unix Permissions**
- Discretionary access control (DAC)
- User/Group/Other permissions
- Read/Write/Execute bits
- File mode bits (chmod)

**Mandatory Access Control (MAC)**
- AppArmor (Ubuntu, openSUSE, SLES)
- SELinux (RHEL, CentOS, Fedora)
- Enforces security policies
- Restricts beyond standard permissions

**No App Sandbox**
- Full file access by default
- Security enforced by MAC
- Different from macOS model
- More flexible but complex

---

## Key Linux Permissions Concepts

### 1. Standard Unix Permissions

Standard permissions define:
- **User (u)**: Owner of the file
- **Group (g)**: Group that owns the file
- **Other (o)**: Everyone else

**Permission Bits**:
- **Read (r)**: View file contents or list directory
- **Write (w)**: Modify file contents or add/remove files
- **Execute (x)**: Run programs or traverse directories

**Numeric Values**:
- **4**: Read
- **2**: Write
- **1**: Execute
- **7**: Read + Write + Execute

**Examples**:
- `755`: Owner=rwx, Group=rx, Other=rx
- `644`: Owner=rw, Group=r, Other=r

### 2. AppArmor

AppArmor is a mandatory access control system:
- **Profile-based**: Policies defined for each application
- **Path-based**: Rules for specific files/directories
- **Enforce/Complain modes**: Block or log violations
- **Default in**: Ubuntu, openSUSE, SLES

**Profile Components**:
- **Capabilities**: Allowed Linux capabilities
- **File access**: Allowed file/directory access
- **Network**: Allowed network sockets
- **Rules**: Specific access patterns

### 3. SELinux

SELinux is a mandatory access control system:
- **Type Enforcement (TE)**: Security types for processes and objects
- **Policy-based**: Centralized security policy
- **Enforce/Permissive modes**: Block or log violations
- **Default in**: RHEL, CentOS, Fedora

**Key Concepts**:
- **Domains**: Security types for processes
- **Types**: Security types for files
- **Contexts**: Security labels
- **Rules**: Allow/deny based on types

---

## Implementation Strategies

### Strategy 1: Standard Unix Permissions

**Best for**: Basic file operations, user home directory access

#### Permission Check

```dart
// semantic_butler_flutter/lib/services/permission_manager_linux.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';

/// Service for managing Linux permissions
class PermissionManagerLinux {
  /// Check if can read directory
  static Future<bool> canReadDirectory(String path) async {
    try {
      final dir = Directory(path);
      await dir.list();
      return true;
    } catch (e) {
      AppLogger.warning('Cannot read directory $path: $e', tag: 'PermissionManager');
      return false;
    }
  }

  /// Check if can write to directory
  static Future<bool> canWriteToDirectory(String path) async {
    try {
      final testFile = File('$path/.permission_test');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      AppLogger.warning('Cannot write to directory $path: $e', tag: 'PermissionManager');
      return false;
    }
  }

  /// Check if can execute file
  static Future<bool> canExecuteFile(String path) async {
    try {
      final file = File(path);
      final stat = await file.stat();
      return stat.mode & 0x111 != 0; // Check execute bits
    } catch (e) {
      AppLogger.warning('Cannot execute file $path: $e', tag: 'PermissionManager');
      return false;
    }
  }

  /// Fix permissions for directory
  static Future<bool> fixPermissions(String path, {String mode = '755'}) async {
    try {
      final result = await Process.run(
        'chmod',
        [mode, path],
      );

      if (result.exitCode == 0) {
        AppLogger.info('Fixed permissions for $path to $mode', tag: 'PermissionManager');
        return true;
      } else {
        AppLogger.error('Failed to fix permissions: ${result.stderr}', tag: 'PermissionManager');
        return false;
      }
    } catch (e) {
      AppLogger.error('Failed to fix permissions: $e', tag: 'PermissionManager');
      return false;
    }
  }

  /// Fix ownership for directory
  static Future<bool> fixOwnership(String path, String owner) async {
    try {
      final result = await Process.run(
        'chown',
        ['-R', owner, path],
      );

      if (result.exitCode == 0) {
        AppLogger.info('Fixed ownership for $path to $owner', tag: 'PermissionManager');
        return true;
      } else {
        AppLogger.error('Failed to fix ownership: ${result.stderr}', tag: 'PermissionManager');
        return false;
      }
    } catch (e) {
      AppLogger.error('Failed to fix ownership: $e', tag: 'PermissionManager');
      return false;
    }
  }
}
```

---

### Strategy 2: AppArmor Profile

**Best for**: Ubuntu, openSUSE, SLES distributions

#### AppArmor Profile

```bash
# scripts/semantic-butler.apparmor

# Semantic Butler AppArmor Profile
# Install: sudo apparmor_parser -r semantic-butler.apparmor

#include <tunables/global>

profile semantic-butler flags=(complain) {
  # Capabilities needed
  capability dac_read_search,
  capability dac_override,
  capability net_raw,

  # Allow execution
  /usr/bin/semantic-butler mr,
  
  # Allow read access to user home directory
  owner @{HOME}/ r,
  owner @{HOME}/** r,
  
  # Allow write access to app data directory
  owner @{HOME}/.local/share/semantic-butler/ rw,
  owner @{HOME}/.local/share/semantic-butler/** rw,
  
  # Allow write access to cache directory
  owner @{HOME}/.cache/semantic-butler/ rw,
  owner @{HOME}/.cache/semantic-butler/** rw,
  
  # Allow read access to system libraries
  /usr/lib/** mr,
  /usr/lib/x86_64-linux-gnu/** mr,
  /usr/lib64/** mr,
  
  # Allow read access to X11 libraries
  /usr/share/X11/** mr,
  
  # Allow network access
  network inet stream,
  network inet dgram,
  network unix stream,
  
  # Allow access to D-Bus
  unix (send, receive) type=stream addr=@/org/freedesktop/DBus,
  unix (send, receive) type=stream addr=/var/run/dbus/system_bus_socket,
}
```

#### Installing AppArmor Profile

```bash
# Install AppArmor profile
sudo apparmor_parser -r scripts/semantic-butler.apparmor

# Verify profile is loaded
sudo aa-status

# Check profile status
sudo aa-status semantic-butler

# View profile logs
sudo journalctl -t apparmor | grep semantic-butler

# Disable profile (if needed)
sudo aa-disable /etc/apparmor.d/semantic-butler

# Enable profile
sudo aa-enable /etc/apparmor.d/semantic-butler
```

#### Troubleshooting AppArmor

```bash
# Check if AppArmor is enabled
sudo aa-status

# Check profile is in enforce mode
sudo aa-status | grep semantic-butler

# Set to complain mode (logs violations but doesn't block)
sudo aa-complain /etc/apparmor.d/semantic-butler

# Set to enforce mode (blocks violations)
sudo aa-enforce /etc/apparmor.d/semantic-butler

# Generate profile from logs
sudo aa-logprof

# View audit logs
sudo dmesg | grep apparmor
sudo journalctl -t audit | grep apparmor
```

---

### Strategy 3: SELinux Policy

**Best for**: RHEL, CentOS, Fedora distributions

#### SELinux Module

```bash
# scripts/semantic-butler.te

# Semantic Butler SELinux Policy Module
# Build and install: make -f /usr/share/selinux/devel/Makefile

module semantic-butler 1.0;

require {
    type unconfined_t;
    type user_home_dir_t;
    type user_home_t;
    type lib_t;
    type xauth_exec_t;
}

# Allow semantic-butler to read user home directory
allow unconfined_t user_home_dir_t:dir { read search };
allow unconfined_t user_home_t:file { read getattr open };

# Allow semantic-butler to write to app data
type semantic-butler_data_t;
files_type(semantic-butler_data_t)
type semantic-butler_data_t file;
allow unconfined_t semantic-butler_data_t:file { create read write getattr unlink open };

# Allow network access
allow unconfined_t self:tcp_socket { create_stream_socket_perms };
allow unconfined_t self:udp_socket { create_socket_perms };

# Allow access to system libraries
allow unconfined_t lib_t:file { read getattr open };
```

#### SELinux Policy File

```bash
# scripts/semantic-butler.if

# Semantic Butler SELinux Interface

## <summary>
##  Allow semantic-butler to access user home directory
## </summary>
## <param name="domain">
##  <summary>
##  Domain allowed access.
##  </summary>
## </param>
interface(`semantic_butler_read_user_home',`
    type $1;
    type user_home_t;

    allow $1 user_home_dir_t:dir { read search getattr open };
    allow $1 user_home_t:file { read getattr open };
')
```

#### Building and Installing SELinux Policy

```bash
# Compile policy
make -f /usr/share/selinux/devel/Makefile semantic-butler.pp

# Install policy
sudo semodule -i semantic-butler.pp

# Restore contexts
sudo restorecon -R -v /usr/bin/semantic-butler
sudo restorecon -R -v ~/.local/share/semantic-butler

# Verify policy is loaded
sudo semodule -l | grep semantic-butler

# Check SELinux mode
getenforce

# View audit logs
sudo ausearch -m avc -ts recent | grep semantic-butler
sudo journalctl -t audit | grep semantic-butler
```

#### Troubleshooting SELinux

```bash
# Check if SELinux is enabled
getenforce

# Check SELinux mode
sestatus

# Set to permissive mode (logs but doesn't block)
sudo setenforce 0

# Set to enforcing mode (blocks violations)
sudo setenforce 1

# Make permanent change
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

# View denied operations
sudo ausearch -m avc -ts recent | tail -n 20

# Generate policy from logs
sudo audit2allow -a

# View context of file
ls -Z /usr/bin/semantic-butler

# Change context
sudo chcon -R -t lib_t /usr/lib/semantic-butler/
```

---

## User Experience Improvements

### Permission Check Dialog

```dart
// semantic_butler_flutter/lib/widgets/permission_dialog.dart

import 'package:flutter/material.dart';

/// Linux permission check dialog
class LinuxPermissionCheckDialog extends StatelessWidget {
  final String path;
  final String permission;
  final VoidCallback onFix;
  final VoidCallback onCancel;

  const LinuxPermissionCheckDialog({
    required this.path,
    required this.permission,
    required this.onFix,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.folder_open, color: Colors.green),
          SizedBox(width: 12),
          Expanded(child: Text('Permission Required')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semantic Butler cannot $permission the following directory:',
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              path,
              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
          ),
          SizedBox(height: 16),
          _getPermissionInstructions(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onFix,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings),
              SizedBox(width: 8),
              Text('Fix Permissions'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getPermissionInstructions() {
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
              Text('How to fix:', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Text('Run the following command in terminal:', style: TextStyle(fontSize: 12)),
          Container(
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'chmod +rwx $path',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### MAC Status Widget

```dart
// semantic_butler_flutter/lib/widgets/mac_status_widget.dart

import 'package:flutter/material.dart';
import '../services/permission_manager_linux.dart';

/// Widget showing Linux MAC status
class LinuxMACStatusWidget extends StatefulWidget {
  @override
  _LinuxMACStatusWidgetState createState() => _LinuxMACStatusWidgetState();
}

class _LinuxMACStatusWidgetState extends State<LinuxMACStatusWidget> {
  bool _appArmorEnabled = false;
  bool _selinuxEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkMACStatus();
  }

  Future<void> _checkMACStatus() async {
    setState(() => _isLoading = true);
    
    final appArmor = await PermissionManagerLinux.isAppArmorEnabled();
    final selinux = await PermissionManagerLinux.isSELinuxEnabled();
    
    setState(() {
      _appArmorEnabled = appArmor;
      _selinuxEnabled = selinux;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LinearProgressIndicator();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_appArmorEnabled) _MACIndicator(
          name: 'AppArmor',
          status: 'Active',
          color: Colors.blue,
        ),
        if (_selinuxEnabled) _MACIndicator(
          name: 'SELinux',
          status: 'Active',
          color: Colors.red,
        ),
        if (!_appArmorEnabled && !_selinuxEnabled) _MACIndicator(
          name: 'MAC',
          status: 'Not Active',
          color: Colors.grey,
        ),
      ],
    );
  }
}

class _MACIndicator extends StatelessWidget {
  final String name;
  final String status;
  final Color color;

  const _MACIndicator({
    required this.name,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            status == 'Active' ? Icons.security : Icons.info,
            color: color,
            size: 20,
          ),
          SizedBox(width: 12),
          Text(
            '$name: $status',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Error Handling Patterns

### Cross-Platform Error Handling

```dart
// semantic_butler_flutter/lib/services/file_operations_service.dart

import 'dart:io';
import '../services/permission_manager_linux.dart';

class FileOperationsService {
  static Future<List<File>> scanDirectory(String path) async {
    try {
      // Try direct access first
      return Directory(path).listSync();
    } catch (e) {
      // Handle permission errors
      if (_isPermissionError(e)) {
        // Try to fix permissions
        final fixed = await PermissionManagerLinux.fixPermissions(path);
        if (fixed) {
          // Retry scan
          return Directory(path).listSync();
        } else {
          // Cannot fix, throw error
          throw PermissionException('Cannot fix permissions for $path');
        }
      } else {
        // Other errors
        rethrow;
      }
    }
  }

  static bool _isPermissionError(dynamic error) {
    if (error is FileSystemException) {
      final fsError = error as FileSystemException;
      final message = fsError.osError?.message?.toLowerCase() ?? '';
      return message.contains('permission') || 
             message.contains('denied') ||
             message.contains('eacces') ||
             message.contains('eperm');
    }
    return false;
  }
}
```

---

## Testing Strategy

### Unit Tests

```dart
// semantic_butler_flutter/test/permission_linux_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../services/permission_manager_linux.dart';

void main() {
  group('PermissionManagerLinux', () {
    test('should check read permissions', () async {
      final result = await PermissionManagerLinux.canReadDirectory('/tmp');
      expect(result, isA<bool>());
    });

    test('should check write permissions', () async {
      final result = await PermissionManagerLinux.canWriteToDirectory('/tmp');
      expect(result, isA<bool>());
    });

    test('should fix permissions', () async {
      // Mock process.run
      final result = await PermissionManagerLinux.fixPermissions('/tmp/test', mode: '777');
      expect(result, isA<bool>());
    });
  });
}
```

### Integration Tests

```dart
// semantic_butler_flutter/test/integration/permission_linux_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgets('Linux permission flow test', (tester) async {
    // Test 1: Check initial permission status
    await tester.pumpWidget(MyApp());
    
    // Verify MAC status widget
    expect(find.text('AppArmor: Active'), findsOneWidget);

    // Test 2: Permission denied handling
    await tester.pumpWidget(MyApp());
    
    // Trigger permission error
    await tester.tap(find.text('Index Files'));
    
    // Verify permission dialog is shown
    expect(find.text('Permission Required'), findsOneWidget);
    expect(find.text('Fix Permissions'), findsOneWidget);

    // Test 3: Fix permissions
    await tester.tap(find.text('Fix Permissions'));
    
    // Verify command is executed (mocked)
    // Verify success message is shown

    // Test 4: AppArmor blocking
    // Mock AppArmor blocking
    await tester.pumpWidget(MyApp());
    
    // Verify error dialog
    expect(find.text('AppArmor blocked access'), findsOneWidget);
  });
}
```

---

## Best Practices

### 1. Handle Standard Permissions

```dart
// Always check before operation
if (await canReadDirectory(path)) {
  await readDirectory(path);
} else {
  _showPermissionDialog();
}
```

### 2. Support MAC Profiles

```bash
# Install AppArmor or SELinux profiles
sudo apparmor_parser -r semantic-butler.apparmor
# or
sudo semodule -i semantic-butler.pp
```

### 3. Provide Clear Instructions

```dart
// Show exact commands to run
Text('Run: chmod +rwx $path', style: TextStyle(fontFamily: 'monospace'));
```

### 4. Test on Multiple Distributions

- [ ] Ubuntu (AppArmor)
- [ ] Fedora (SELinux)
- [ ] Arch (No MAC)
- [ ] Debian (No MAC)

---

## Troubleshooting

### Common Issues

#### 1. Permission Denied

**Symptoms**: Cannot read or write files
**Cause**: Insufficient permissions, MAC blocking
**Solution**:
1. Check file permissions with `ls -l`
2. Fix with `chmod +rwx path`
3. Check AppArmor/SELinux logs

#### 2. AppArmor Blocking

**Symptoms**: Operations fail silently, logged to audit
**Cause**: AppArmor profile too restrictive
**Solution**:
1. Check AppArmor logs: `sudo aa-status`
2. Switch to complain mode: `sudo aa-complain`
3. Update profile based on logs
4. Switch back to enforce mode

#### 3. SELinux Blocking

**Symptoms**: Operations fail silently, logged to audit
**Cause**: SELinux policy too restrictive
**Solution**:
1. Check SELinux logs: `sudo ausearch -m avc -ts recent`
2. Set to permissive mode: `sudo setenforce 0`
3. Generate policy: `sudo audit2allow -a`
4. Switch back to enforcing mode

---

## Resources

### Documentation
- [Linux File Permissions](https://wiki.archlinux.org/title/File_permissions_and_attributes)
- [AppArmor](https://gitlab.com/apparmor/apparmor)
- [SELinux](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/using_selinux/index)
- [chmod Manual](https://man7.org/linux/man-pages/man1/chmod.1.html)

### Tools
- [aa-status](https://manpages.ubuntu.com/manpages/xenial/aa-status.8.html)
- [sestatus](https://man7.org/linux/man-pages/man1/sestatus.1.html)
- [audit2allow](https://man7.org/linux/man-pages/man1/audit2allow.1.html)

### Examples
- [AppArmor Profiles](https://gitlab.com/apparmor/apparmor/-/wikis/home)
- [SELinux Policies](https://github.com/selinux/selinux-policy)
- [Flutter Linux Guide](https://docs.flutter.dev/platform-integration/linux/building)

---

**Document Version**: 1.0
**Last Updated**: January 18, 2026
**Owner**: Development Team
**Review Date**: January 25, 2026
