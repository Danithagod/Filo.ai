# macOS Permission Handling Guide for Semantic Butler

**Version**: 1.0
**Created**: January 18, 2026
**Status**: Implementation Guide

---

## Executive Summary

This guide provides comprehensive strategies for handling macOS permissions in Semantic Butler, ensuring robust file system access while maintaining security and providing excellent user experience.

### Current State Analysis

**Observations from Codebase**:
1. **No entitlements for file access**: Current entitlements files only include:
   - `com.apple.security.app-sandbox` (sandbox enabled)
   - `com.apple.security.cs.allow-jit` (JIT compilation)
   - `com.apple.security.network.server` (network server)
   
2. **Missing file access entitlements**: No `com.apple.security.files.user-selected.read-write` or related entitlements

3. **No security-scoped bookmarks**: No persistent file access mechanism for app restarts

4. **No permission error handling**: Current implementation doesn't gracefully handle permission denials

### Key Problems

1. **Access Denied Errors**: Users cannot index files outside app sandbox without explicit permission
2. **Lost Permissions on Restart**: Access to folders requires re-authorization after app restart
3. **Poor User Experience**: No clear guidance on enabling Full Disk Access
4. **No Fallback**: App crashes or fails silently when permissions are denied

---

## macOS Permission Fundamentals

### 1. App Sandbox

macOS apps run in a sandbox that restricts access to:
- **App container only**: App can only access its own files by default
- **Limited system access**: No access to user files, folders, or network (unless explicitly allowed)
- **Resource isolation**: Cannot interfere with other apps

**Why This Matters for Semantic Butler**:
- Cannot scan user's Documents folder without permission
- Cannot access downloads or projects folder
- Cannot write indexed data outside app container

### 2. Entitlements

Entitlements are special permissions that allow sandboxed apps to:
- **Access specific resources**: Files, folders, camera, network, etc.
- **Bypass restrictions**: In a controlled, Apple-approved way
- **Request user permissions**: With explicit user consent

### 3. Security-Scoped Bookmarks

A mechanism to maintain persistent access to user-selected files:
- **Created after user selection**: User explicitly picks file/folder
- **Persisted across restarts**: Access maintained without re-authorization
- **Security enforced**: Only app that created bookmark can use it

---

## Implementation Strategies

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
    
    <!-- User-Selected File Access (NEW - REQUIRED) -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- Optional: Allow reading downloads folder -->
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    
    <!-- Optional: Allow access to specific directories -->
    <key>com.apple.security.files.pictures.read-write</key>
    <true/>
</dict>
</plist>
```

#### Implementation in Flutter

```dart
// semantic_butler_flutter/lib/services/permission_manager.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_logger.dart';

/// Service for managing macOS permissions
class PermissionManager {
  /// Check if app has file access permission
  static Future<bool> hasFileAccess() async {
    if (!Platform.isMacOS) return true;
    
    try {
      // Try to access a file to check permissions
      final tempDir = Directory.systemTemp;
      await tempDir.create(recursive: true);
      final testFile = File('${tempDir.path}/permission_test.txt');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      AppLogger.warning('File access check failed: $e', tag: 'PermissionManager');
      return false;
    }
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

      // Permissions are automatically granted for selected folders
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

  /// Request Full Disk Access (opens System Settings)
  static Future<bool> requestFullDiskAccess() async {
    if (!Platform.isMacOS) return true;

    // macOS doesn't allow programmatic FDA requests
    // Must guide user to System Settings
    AppLogger.info('Redirecting to System Settings for Full Disk Access', tag: 'PermissionManager');
    
    // Open System Settings > Security & Privacy > Full Disk Access
    final command = Process.runSync(
      'open',
      ['x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles'],
    );

    return command.exitCode == 0;
  }

  /// Handle permission errors gracefully
  static void handlePermissionError(dynamic error, {String? context}) {
    if (error is FileSystemException) {
      final fsError = error as FileSystemException;
      
      if (fsError.osError?.code == 'EPERM' || 
          fsError.osError?.code == 'EACCES') {
        // Permission denied
        _showPermissionDeniedDialog(context);
        return;
      }
    }

    if (error.toString().contains('Operation not permitted')) {
      _showPermissionDeniedDialog(context);
      return;
    }

    // Other errors
    AppLogger.error('Error: $error', tag: 'PermissionManager');
    _showGenericErrorDialog(context, error.toString());
  }

  static void _showPermissionDeniedDialog(String? context) {
    // Show dialog explaining how to grant permissions
  }

  static void _showGenericErrorDialog(String context, String message) {
    // Show dialog with error details
  }
}

class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);
  
  @override
  String toString() => 'PermissionException: $message';
}
```

### Strategy 2: Security-Scoped Bookmarks (Advanced)

**Best for**: Persistent access across app restarts, background indexing

#### Using directory_bookmarks Package

```yaml
# semantic_butler_flutter/pubspec.yaml

dependencies:
  directory_bookmarks: ^0.1.2
```

```dart
// semantic_butler_flutter/lib/services/bookmark_manager.dart

import 'package:directory_bookmarks/directory_bookmarks.dart';

/// Service for managing persistent file access via bookmarks
class BookmarkManager {
  final DirectoryBookmarks _bookmarks = DirectoryBookmarks();

  /// Store folder access as bookmark
  static Future<void> saveBookmark(String folderPath) async {
    try {
      await DirectoryBookmarks.saveDirectoryBookmark(folderPath);
      AppLogger.info('Saved bookmark for: $folderPath', tag: 'BookmarkManager');
    } catch (e) {
      AppLogger.error('Failed to save bookmark: $e', tag: 'BookmarkManager');
      throw PermissionException('Failed to save folder bookmark: $e');
    }
  }

  /// Load all saved bookmarks
  static Future<List<BookmarkDirectory>> loadBookmarks() async {
    try {
      final bookmarks = await DirectoryBookmarks.getAllDirectoryBookmarks();
      AppLogger.info(
        'Loaded ${bookmarks.length} bookmarks',
        tag: 'BookmarkManager',
      );
      return bookmarks;
    } catch (e) {
      AppLogger.error('Failed to load bookmarks: $e', tag: 'BookmarkManager');
      return [];
    }
  }

  /// Check if bookmark is still valid
  static Future<bool> isBookmarkValid(String bookmarkPath) async {
    try {
      final dir = await DirectoryBookmarks.getDirectoryFromBookmark(bookmarkPath);
      await dir.list();
      return true;
    } catch (e) {
      AppLogger.warning('Bookmark invalid: $bookmarkPath', tag: 'BookmarkManager');
      return false;
    }
  }

  /// Resolve bookmark to actual directory
  static Future<Directory> resolveBookmark(String bookmarkPath) async {
    try {
      return await DirectoryBookmarks.getDirectoryFromBookmark(bookmarkPath);
    } catch (e) {
      AppLogger.error('Failed to resolve bookmark: $e', tag: 'BookmarkManager');
      throw PermissionException('Cannot access bookmarked folder: $e');
    }
  }

  /// Clean up invalid bookmarks
  static Future<void> cleanupInvalidBookmarks() async {
    final bookmarks = await loadBookmarks();
    final validBookmarks = <BookmarkDirectory>[];

    for (final bookmark in bookmarks) {
      if (await isBookmarkValid(bookmark.bookmarkPath)) {
        validBookmarks.add(bookmark);
      }
    }

    // Remove all bookmarks and re-save valid ones
    await DirectoryBookmarks.clearAllBookmarks();
    for (final bookmark in validBookmarks) {
      await saveBookmark(bookmark.directory.path);
    }

    AppLogger.info(
      'Cleaned up ${bookmarks.length - validBookmarks.length} invalid bookmarks',
      tag: 'BookmarkManager',
    );
  }
}

class BookmarkDirectory {
  final String directoryPath;
  final String bookmarkPath;
  
  BookmarkDirectory(this.directoryPath, this.bookmarkPath);
}
```

#### Integration with File Operations

```dart
// semantic_butler_flutter/lib/services/file_operations_service.dart

import 'dart:io';
import 'bookmark_manager.dart';

/// Service for performing file operations with permissions
class FileOperationsService {
  static Future<List<File>> scanDirectory(String path) async {
    try {
      // Try direct access first
      return Directory(path).listSync();
    } catch (e) {
      // If permission denied, try to use bookmark
      final bookmark = await BookmarkManager.resolveBookmark(path);
      return bookmark.listSync();
    }
  }

  static Future<void> writeFile(String path, String content) async {
    try {
      await File(path).writeAsString(content);
    } catch (e) {
      // Try bookmarked path
      final bookmark = await BookmarkManager.resolveBookmark(path);
      await File('${bookmark.path}/${path.split('/').last}').writeAsString(content);
    }
  }
}
```

---

## User Experience Improvements

### 1. Permission Request Dialogs

```dart
// semantic_butler_flutter/lib/widgets/permission_dialog.dart

import 'package:flutter/material.dart';

/// Dialog explaining how to grant permissions
class PermissionRequestDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onGrant;
  final VoidCallback onCancel;
  final bool? canRequestFullDiskAccess;

  const PermissionRequestDialog({
    required this.title,
    required this.message,
    required this.onGrant,
    required this.onCancel,
    this.canRequestFullDiskAccess,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (canRequestFullDiskAccess == true) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Full Disk Access is recommended for best experience. '
                      'This allows the app to index all your files.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel'),
        ),
        if (canRequestFullDiskAccess == true)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              PermissionManager.requestFullDiskAccess();
            },
            child: Text('Open Settings'),
          ),
        ElevatedButton(
          onPressed: onGrant,
          child: Text('Grant Access'),
        ),
      ],
    );
  }
}
```

### 2. Permission Status Indicator

```dart
// semantic_butler_flutter/lib/widgets/permission_status_widget.dart

import 'package:flutter/material.dart';
import 'permission_manager.dart';

/// Widget showing current permission status
class PermissionStatusWidget extends StatefulWidget {
  @override
  _PermissionStatusWidgetState createState() => _PermissionStatusWidgetState();
}

class _PermissionStatusWidgetState extends State<PermissionStatusWidget> {
  bool _hasAccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    final hasAccess = await PermissionManager.hasFileAccess();
    setState(() {
      _hasAccess = hasAccess;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LinearProgressIndicator();
    }

    if (_hasAccess) {
      return Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Text(
            'File access granted',
            style: TextStyle(color: Colors.green),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.warning, color: Colors.orange, size: 20),
        SizedBox(width: 8),
        Text(
          'Limited file access',
          style: TextStyle(color: Colors.orange),
        ),
        SizedBox(width: 8),
        TextButton(
          onPressed: _checkPermissions,
          child: Text('Fix'),
        ),
      ],
    );
  }
}
```

### 3. Onboarding for Permissions

```dart
// semantic_butler_flutter/lib/screens/onboarding/permission_setup_screen.dart

import 'package:flutter/material.dart';
import 'permission_manager.dart';

/// Onboarding screen for setting up permissions
class PermissionSetupScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Permissions'),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To search and organize your files, Semantic Butler needs access to them.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24),
            Text(
              'Choose how you want to grant permissions:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 32),

            // Option 1: Select folders
            _PermissionOptionCard(
              icon: Icons.folder,
              title: 'Select Folders',
              description: 'Choose specific folders to index. '
                          'Recommended for better privacy.',
              action: () async {
                final folders = await PermissionManager.requestFolderAccess();
                if (folders.isNotEmpty) {
                  // Save bookmarks for persistence
                  for (final folder in folders) {
                    await BookmarkManager.saveBookmark(folder);
                  }
                }
              },
            ),

            // Option 2: Full Disk Access
            _PermissionOptionCard(
              icon: Icons.storage,
              title: 'Full Disk Access',
              description: 'Grant access to all files. '
                          'Best experience but less private.',
              action: () => PermissionManager.requestFullDiskAccess(),
              recommended: true,
            ),

            Spacer(),

            // Permission status
            PermissionStatusWidget(),

            SizedBox(height: 32),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasPermissions ? _onContinue : null,
                child: Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasPermissions {
    // Check if any permissions are granted
    return false; // TODO: Implement
  }

  void _onContinue() {
    // Navigate to next onboarding step
  }
}

class _PermissionOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback action;
  final bool recommended;

  const _PermissionOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    this.recommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: recommended 
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (recommended) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'RECOMMENDED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Error Handling Patterns

### 1. Graceful Degradation

```dart
// semantic_butler_flutter/lib/services/indexing_service.dart

import 'dart:io';
import 'permission_manager.dart';

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
      final code = fsError.osError?.code;
      return code == 'EPERM' || code == 'EACCES';
    }
    return false;
  }

  String _getPermissionSuggestion(dynamic error) {
    // Provide actionable suggestions based on error type
    if (_isPermissionError(error)) {
      return 'Grant file access permission or select the folder again.';
    }
    return 'Check folder path and permissions.';
  }
}

class IndexingResult {
  final bool success;
  final String? error;
  final String? suggestion;

  IndexingResult({
    required this.success,
    this.error,
    this.suggestion,
  });
}
```

### 2. Retry Mechanism

```dart
// semantic_butler_flutter/lib/services/retry_service.dart

class RetryService {
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration delayBetweenAttempts = const Duration(seconds: 1),
    required Future<T> Function(dynamic) onRetry,
  }) async {
    int attempt = 1;
    T? result;

    while (attempt <= maxAttempts) {
      try {
        result = await operation();
        return result!;
      } catch (e) {
        if (_isRecoverableError(e) && attempt < maxAttempts) {
          AppLogger.warning(
            'Attempt $attempt failed, retrying...',
            tag: 'RetryService',
          );
          await Future.delayed(delayBetweenAttempts);
          attempt++;
          await onRetry(e);
        } else {
          AppLogger.error('All attempts failed: $e', tag: 'RetryService');
          rethrow;
        }
      }
    }

    throw StateError('Should not reach here');
  }

  static bool _isRecoverableError(dynamic error) {
    // Permission errors might be recoverable after user grants permission
    if (error is FileSystemException) {
      final code = (error as FileSystemException).osError?.code;
      return code == 'EPERM' || code == 'EACCES';
    }
    return false;
  }
}
```

---

## Testing Strategy

### 1. Permission Tests

```dart
// semantic_butler_flutter/test/permission_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../services/permission_manager.dart';

void main() {
  group('PermissionManager', () {
    test('should detect permission denied errors', () {
      final error = FileSystemException(
        'Permission denied',
        '/test/file.txt',
        osError: OSError(code: 'EPERM'),
      );

      expect(PermissionManager._isPermissionError(error), true);
    });

    test('should handle file access checks', () async {
      // Mock file system operations
      when(mockDir.create()).thenAnswer((_) {});
      
      final result = await PermissionManager.hasFileAccess();
      
      expect(result, isA<bool>());
    });

    test('should show permission dialog on error', () async {
      // Test dialog is shown when permission error occurs
      // ...
    });
  });
}
```

### 2. Integration Tests

```dart
// semantic_butler_flutter/test/integration/permission_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgets('Permission flow test', (tester) async {
    // Test 1: Select folder and save bookmark
    await tester.pumpWidget(MyApp());
    
    // Navigate to folder selection
    await tester.tap(find.text('Select Folders'));
    
    // Select test folder
    await tester.pumpAndSettle();
    
    // Verify bookmark is saved
    expect(find.text('Folder bookmarked'), findsOneWidget);

    // Test 2: Restart app and access bookmarked folder
    await tester.restartApp();
    
    // Verify bookmark still works
    expect(find.text('Accessing bookmarked folder'), findsOneWidget);

    // Test 3: Permission denied handling
    // Mock permission error
    await tester.pumpWidget(MyApp());
    
    // Trigger permission error
    await tester.tap(find.text('Index Files'));
    
    // Verify error dialog is shown
    expect(find.text('Permission denied'), findsOneWidget);
    expect(find.text('Grant Access'), findsOneWidget);
  });
}
```

---

## Best Practices

### 1. Always Ask User Permission

```dart
// BAD: Assume access to Documents folder
final docsPath = '/Users/$username/Documents';
final files = await Directory(docsPath).list(); // May fail

// GOOD: Request user to select folder
final result = await FilePicker.platform.getDirectoryPaths();
if (result != null) {
  final files = await Directory(result!.first).list(); // Safe
}
```

### 2. Use Security-Scoped Bookmarks

```dart
// Save access to selected folders
await BookmarkManager.saveBookmark(selectedPath);

// Load saved bookmarks on app start
final bookmarks = await BookmarkManager.loadBookmarks();

// Use bookmarked paths for indexing
for (final bookmark in bookmarks) {
  final folder = await BookmarkManager.resolveBookmark(bookmark.bookmarkPath);
  await indexFolder(folder.path);
}
```

### 3. Handle Permission Errors Gracefully

```dart
try {
  await performFileOperation();
} catch (e) {
  if (_isPermissionError(e)) {
    // Show helpful dialog
    await showPermissionDialog();
    
    // Don't crash, just log
    AppLogger.error('Permission denied: $e');
  } else {
    // Handle other errors
    rethrow;
  }
}
```

### 4. Provide Clear Guidance

- **Explain what access is needed**: "To index your files, we need access to your Documents folder"
- **Show how to grant it**: Step-by-step instructions with screenshots
- **Offer alternatives**: "Or select specific folders instead of Full Disk Access"
- **Confirm success**: Show confirmation when permission is granted

---

## Implementation Checklist

### Phase 1: Entitlements (1 hour)
- [ ] Update `macos/Runner/DebugProfile.entitlements`
- [ ] Update `macos/Runner/Release.entitlements`
- [ ] Add `com.apple.security.files.user-selected.read-write`
- [ ] Add optional directory access entitlements
- [ ] Test with Xcode build

### Phase 2: Permission Manager (2 hours)
- [ ] Create `PermissionManager` service
- [ ] Implement `hasFileAccess()` check
- [ ] Implement `requestFolderAccess()` method
- [ ] Implement `requestFullDiskAccess()` method
- [ ] Add error handling with `handlePermissionError()`

### Phase 3: Bookmark System (4 hours)
- [ ] Add `directory_bookmarks` dependency
- [ ] Create `BookmarkManager` service
- [ ] Implement `saveBookmark()` method
- [ ] Implement `loadBookmarks()` method
- [ ] Implement `resolveBookmark()` method
- [ ] Add bookmark cleanup on startup

### Phase 4: UI Components (3 hours)
- [ ] Create `PermissionRequestDialog` widget
- [ ] Create `PermissionStatusWidget` widget
- [ ] Create `PermissionSetupScreen` for onboarding
- [ ] Add permission status to dashboard
- [ ] Add permission error dialogs throughout app

### Phase 5: Error Handling (2 hours)
- [ ] Update file operations to use bookmarks
- [ ] Add graceful error handling
- [ ] Implement retry mechanism
- [ ] Add user-friendly error messages

### Phase 6: Testing (2 hours)
- [ ] Write unit tests for permission manager
- [ ] Write integration tests for permission flow
- [ ] Test on macOS (local development)
- [ ] Test on macOS (TestFlight)

---

## Troubleshooting Guide

### Common Issues

#### 1. App Crashes on File Access

**Symptoms**: App crashes when user tries to access files
**Cause**: No entitlements or incorrect implementation
**Solution**:
1. Verify entitlements are added to both DebugProfile and Release files
2. Ensure `com.apple.security.files.user-selected.read-write` is present
3. Use `file_picker` for initial file selection
4. Implement error handling to catch crashes

#### 2. Lost Access After Restart

**Symptoms**: Folder access works initially but fails after app restart
**Cause**: Not using security-scoped bookmarks
**Solution**:
1. Implement bookmark system using `directory_bookmarks` package
2. Save bookmarks when user selects folders
3. Resolve bookmarks on app startup
4. Clean up invalid bookmarks

#### 3. User Denies Permission

**Symptoms**: User selects "Cancel" in permission dialog
**Cause**: User doesn't want to grant access
**Solution**:
1. Provide fallback option (select different folder)
2. Show clear explanation of why access is needed
3. Don't crash or hang, continue with limited functionality
4. Allow user to try again later

#### 4. Full Disk Access Not Working

**Symptoms**: User enables FDA but app still can't access files
**Cause**: App not appearing in FDA list or user needs to restart app
**Solution**:
1. User must quit and restart app after enabling FDA
2. Verify app appears in System Settings > Privacy > Full Disk Access
3. Try accessing a file to trigger macOS permission check
4. If still not working, user may need to re-enable FDA

---

## Security Considerations

### 1. Minimal Permission Scope

- Only request access that is actually needed
- Don't ask for Full Disk Access if user-selected folders work
- Prefer user-selected files over broad access

### 2. User Consent

- Always ask user before accessing files
- Show what will be accessed and why
- Allow user to revoke access at any time

### 3. Privacy First

- Store bookmarks securely in Keychain
- Don't log or transmit file contents
- Explain privacy policies clearly

---

## Resources

### Documentation
- [Apple App Sandbox](https://developer.apple.com/documentation/security/app-sandbox)
- [Entitlements Guide](https://developer.apple.com/documentation/bundleresources/entitlements)
- [File Access](https://developer.apple.com/documentation/security/accessing-files-from-the-mac...)

### Flutter Packages
- [directory_bookmarks](https://pub.dev/packages/directory_bookmarks) - Persistent folder access
- [file_picker](https://pub.dev/packages/file_picker) - File selection
- [permission_handler](https://pub.dev/packages/permission_handler) - Cross-platform permissions

### Examples
- [macos_secure_bookmarks](https://github.com/authpass/macos_secure_bookmarks) - Bookmark implementation
- [Flutter macOS guide](https://docs.flutter.dev/platform-integration/macos/building) - macOS setup

---

## Conclusion

Implementing robust permission handling for macOS requires:

1. **Proper entitlements**: Configure file access permissions correctly
2. **Security-scoped bookmarks**: Maintain access across app restarts
3. **Graceful error handling**: Don't crash on permission denied
4. **Clear user guidance**: Help users understand and grant permissions
5. **Fallback options**: Provide alternatives when permissions are denied

By following this guide, Semantic Butler will provide a smooth, secure, and user-friendly experience on macOS while maintaining privacy and security standards.

---

**Document Version**: 1.0
**Last Updated**: January 18, 2026
**Owner**: Development Team
**Review Date**: January 25, 2026
