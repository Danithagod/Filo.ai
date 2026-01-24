import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/permission_manager.dart';

class PermissionRequestWidget extends StatefulWidget {
  final VoidCallback onPermissionGranted;

  const PermissionRequestWidget({
    super.key,
    required this.onPermissionGranted,
  });

  @override
  State<PermissionRequestWidget> createState() =>
      _PermissionRequestWidgetState();
}

class _PermissionRequestWidgetState extends State<PermissionRequestWidget> {
  bool _isRequesting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await PermissionManager.getPermissionStatus();
    if (mounted && status.isGranted) {
      widget.onPermissionGranted();
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isRequesting = true;
      _errorMessage = null;
    });

    try {
      final result = await PermissionManager.requestPermissions();
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });

        if (result.isGranted) {
          widget.onPermissionGranted();
        } else {
          setState(() {
            _errorMessage = result.message ?? 'Permission request denied';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRequesting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  IconData _getPlatformIcon() {
    if (Platform.isWindows) return Icons.admin_panel_settings;
    if (Platform.isMacOS) return Icons.security;
    return Icons.folder_shared;
  }

  String _getPlatformMessage() {
    if (Platform.isWindows) {
      return 'Semantic Butler requires administrative privileges to index and search all your files effectively. This will prompt a UAC elevation for broad file system access.';
    }
    if (Platform.isMacOS) {
      return 'macOS requires explicit permission for sandboxed apps. Semantic Butler needs Full Disk Access to search your folders. You can also select folders manually.';
    }
    if (Platform.isLinux) {
      return 'Linux permissions are file-based. Ensure the app has read/write permissions for your data folders. You can use "chmod +rw <folder>" if you encounter errors.';
    }
    return 'Semantic Butler requires access to your file system to provide intelligent search and organization features.';
  }

  Widget _buildPlatformInstructions() {
    if (Platform.isMacOS) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 16),
                SizedBox(width: 8),
                Text(
                  'macOS System Access',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '1. Click "Grant Access" below',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              '2. Select folders you want to index',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              '3. Or enable Full Disk Access in Settings',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }
    if (Platform.isWindows) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 16),
                SizedBox(width: 8),
                Text(
                  'Windows Administrator Access',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '1. Click "Grant Access" below',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              '2. Approve UAC elevation prompt if shown',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              '3. App will restart with full permissions',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPlatformIcon(),
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'System Access Required',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getPlatformMessage(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          _buildPlatformInstructions(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRequesting ? null : _requestPermission,
              icon: _isRequesting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.security),
              label: Text(_isRequesting ? 'Requesting...' : 'Grant Access'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onPermissionGranted,
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }
}
