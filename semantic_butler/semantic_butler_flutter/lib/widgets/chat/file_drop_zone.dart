import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Drag target zone for dropping files into chat
class FileDropZone extends StatefulWidget {
  final Widget child;
  final ValueChanged<List<File>> onFilesDropped;
  final ValueChanged<List<String>>? onPathsDropped;

  const FileDropZone({
    super.key,
    required this.child,
    required this.onFilesDropped,
    this.onPathsDropped,
  });

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _isDragging = false;
  final Set<String> _pendingFiles = {};

  @override
  Widget build(BuildContext context) {
    return DragTarget<Object>(
      onAcceptWithDetails: (details) {
        setState(() => _isDragging = false);
        _handleDrop(details.data);
      },
      onLeave: (_) {
        setState(() => _isDragging = false);
        _pendingFiles.clear();
      },
      onWillAcceptWithDetails: (details) {
        final isValid = _isValidDropType(details.data);
        if (isValid) {
          _updatePendingFiles(details.data);
          setState(() => _isDragging = true);
        }
        return isValid;
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            widget.child,
            if (_isDragging)
              Positioned.fill(
                child: _buildDropOverlay(context),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDropOverlay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.file_upload,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Drop files to attach',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              if (_pendingFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${_pendingFiles.length} file${_pendingFiles.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isValidDropType(Object? data) {
    if (data == null) return false;

    // Handle different platform representations of dropped files
    if (data is File) return true;
    if (data is List) {
      if (data.isNotEmpty && data.first is File) return true;
      if (data.isNotEmpty && data.first is String) return true;
    }
    if (data is String) {
      // Check if it's a file path
      try {
        return File(data).existsSync();
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  void _updatePendingFiles(Object? data) {
    _pendingFiles.clear();

    if (data is File) {
      _pendingFiles.add(data.path);
    } else if (data is List) {
      for (final item in data) {
        if (item is File) {
          _pendingFiles.add(item.path);
        } else if (item is String) {
          _pendingFiles.add(item);
        }
      }
    } else if (data is String) {
      _pendingFiles.add(data);
    }
  }

  void _handleDrop(Object? data) {
    final files = <File>[];
    final paths = <String>[];

    if (data is File) {
      files.add(data);
      paths.add(data.path);
    } else if (data is List) {
      for (final item in data) {
        if (item is File) {
          files.add(item);
          paths.add(item.path);
        } else if (item is String) {
          paths.add(item);
          files.add(File(item));
        }
      }
    } else if (data is String) {
      paths.add(data);
      files.add(File(data));
    }

    if (files.isNotEmpty) {
      widget.onFilesDropped(files);
    }
    if (paths.isNotEmpty && widget.onPathsDropped != null) {
      widget.onPathsDropped!(paths);
    }

    _pendingFiles.clear();
  }
}

/// Service for handling paste events from clipboard
class ClipboardFileHandler {
  /// Check if clipboard has file data
  static Future<bool> hasFiles() async {
    // On desktop, check for file paths in clipboard
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    return clipboardData?.text?.contains('\n') == true;
  }

  /// Get files from clipboard (if available)
  static Future<List<String>> getFilesFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text;
    if (text == null) return [];

    // Check if text contains file paths (one per line)
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty);
    final files = <String>[];

    for (final line in lines) {
      final path = line.trim();
      if (File(path).existsSync() || Directory(path).existsSync()) {
        files.add(path);
      }
    }

    return files;
  }

  /// Check if clipboard has image data
  static Future<bool> hasImage() async {
    // This would require platform-specific implementation
    // For now, return false
    return false;
  }
}
