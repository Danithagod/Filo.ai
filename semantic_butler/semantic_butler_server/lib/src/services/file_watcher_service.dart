import 'dart:async';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'package:watcher/watcher.dart';
import '../generated/protocol.dart';
import 'file_extraction_service.dart';

/// Centralized manager for FileWatcherService instances to ensure clean disposal
class WatcherManager {
  static FileWatcherService? _instance;

  /// Get or create the singleton instance
  static FileWatcherService getInstance(Session session) {
    _instance ??= FileWatcherService(session);
    return _instance!;
  }

  /// Configure callbacks for the singleton instance
  static void setupCallbacks({
    Future<void> Function(List<String> paths)? onFilesChanged,
    Future<void> Function(String path)? onFileRemoved,
  }) {
    if (_instance != null) {
      _instance!.onFilesChanged = onFilesChanged;
      _instance!.onFileRemoved = onFileRemoved;
    }
  }

  /// Dispose the singleton instance
  static Future<void> dispose() async {
    if (_instance != null) {
      await _instance!.dispose();
      _instance = null;
    }
  }
}

/// Service that watches directories for file changes and triggers re-indexing.
class FileWatcherService {
  final Session _session;

  /// Callback to trigger re-indexing
  Future<void> Function(List<String> paths)? onFilesChanged;

  /// Callback to handle file removal (for cleanup)
  Future<void> Function(String path)? onFileRemoved;

  /// Active directory watchers: path -> subscription
  final Map<String, StreamSubscription<WatchEvent>> _watchers = {};

  /// Debounce timers to batch rapid file changes
  final Map<String, Timer> _debounceTimers = {};

  /// Files queued for re-indexing
  final Set<String> _pendingFiles = {};

  /// Ignore patterns (glob patterns like "*.log", "node_modules/**")
  List<String> _ignorePatterns = [];

  /// Maximum queue size to prevent memory leaks
  static const int maxQueueSize = 10000;

  /// Maximum file size to index (Issue #20: 50MB limit)
  static const int maxFileSizeBytes = 50 * 1024 * 1024;

  /// Watcher health status (Issue #17)
  final Map<String, bool> _watcherHealth = {};

  /// Delay before attempting watcher restart
  static const Duration _restartDelay = Duration(seconds: 5);

  /// Pending file removals - delayed to detect moves (Issue #14)
  final Map<String, Timer> _pendingRemovals = {};

  /// Recently removed files with their content hashes for move detection
  final Map<String, _RemovedFileInfo> _recentlyRemovedFiles = {};

  /// Delay before processing REMOVE events to detect file moves
  static const Duration _moveDetectionDelay = Duration(milliseconds: 500);

  /// How long to keep removed file info for cross-path move detection
  static const Duration _moveDetectionWindow = Duration(seconds: 2);

  FileWatcherService(
    this._session, {
    this.onFilesChanged,
    this.onFileRemoved,
  });

  /// Set ignore patterns for file filtering
  void setIgnorePatterns(List<String> patterns) {
    _ignorePatterns = patterns;
    _session.log(
      'File watcher ignore patterns updated: ${patterns.length} patterns',
      level: LogLevel.debug,
    );
  }

  /// Start watching a directory for changes
  Future<WatchedFolder> startWatching(String path) async {
    // Check if already watching
    if (_watchers.containsKey(path)) {
      _session.log('Already watching: $path', level: LogLevel.debug);
      final existing = await WatchedFolder.db.findFirstRow(
        _session,
        where: (t) => t.path.equals(path),
      );
      if (existing != null) return existing;
    }

    // Verify directory exists
    final dir = Directory(path);
    if (!await dir.exists()) {
      throw Exception('Directory does not exist: $path');
    }

    // Create directory watcher
    final watcher = DirectoryWatcher(path);
    final subscription = watcher.events.listen(
      (event) => _handleEvent(event),
      onError: (error) {
        _session.log('Watcher error for $path: $error', level: LogLevel.error);
        _watcherHealth[path] = false;
        _scheduleRestart(path);
      },
      onDone: () {
        _session.log(
          'Watcher closed unexpectedly: $path',
          level: LogLevel.warning,
        );
        _watcherHealth[path] = false;
        _scheduleRestart(path);
      },
    );

    _watchers[path] = subscription;
    _watcherHealth[path] = true;

    // Count files in directory
    int fileCount = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && FileExtractionService.isSupported(entity.path)) {
        fileCount++;
      }
    }

    // Save to database
    var watchedFolder = await WatchedFolder.db.findFirstRow(
      _session,
      where: (t) => t.path.equals(path),
    );

    if (watchedFolder != null) {
      watchedFolder.isEnabled = true;
      watchedFolder.filesWatched = fileCount;
      await WatchedFolder.db.updateRow(_session, watchedFolder);
    } else {
      watchedFolder = WatchedFolder(
        path: path,
        isEnabled: true,
        filesWatched: fileCount,
      );
      await WatchedFolder.db.insertRow(_session, watchedFolder);
    }

    _session.log(
      'Started watching: $path ($fileCount files)',
      level: LogLevel.info,
    );

    return watchedFolder;
  }

  /// Stop watching a directory and clean up orphaned records
  Future<void> stopWatching(String path) async {
    _session.log('Stopping watch for: $path', level: LogLevel.info);

    // Step 1: Stop file watcher subscription
    final subscription = _watchers.remove(path);
    if (subscription != null) {
      await subscription.cancel();
    }

    // Step 2: Clear debounce timers
    _debounceTimers[path]?.cancel();
    _debounceTimers.remove(path);

    // Issue #21: Clear all timers for subdirectories of this path
    final keysToRemove = _debounceTimers.keys
        .where((k) => k.startsWith(path))
        .toList();
    for (final key in keysToRemove) {
      _debounceTimers[key]?.cancel();
      _debounceTimers.remove(key);
    }

    // Step 3: Delete WatchedFolder record (not just disable)
    int deletedWatchedFolders = 0;
    try {
      final deleted = await WatchedFolder.db.deleteWhere(
        _session,
        where: (t) => t.path.equals(path),
      );
      deletedWatchedFolders = deleted.length;
      _session.log(
        'Deleted $deletedWatchedFolders WatchedFolder record(s)',
        level: LogLevel.debug,
      );
    } catch (e) {
      _session.log(
        'Failed to delete WatchedFolder: $e',
        level: LogLevel.error,
      );
    }

    // Step 4: Delete orphaned FileIndex records (use LIKE for nested files)
    int deletedFileIndexes = 0;
    try {
      // Normalize path separator for matching
      final normalizedPath = path.endsWith(Platform.pathSeparator)
          ? path
          : '$path${Platform.pathSeparator}';

      final deleted = await FileIndex.db.deleteWhere(
        _session,
        where: (t) => t.path.like('$normalizedPath%'),
      );
      deletedFileIndexes = deleted.length;
      _session.log(
        'Deleted $deletedFileIndexes FileIndex record(s)',
        level: LogLevel.debug,
      );
    } catch (e) {
      _session.log(
        'Failed to delete FileIndex records: $e',
        level: LogLevel.error,
      );
    }

    // Note: DocumentEmbedding records are deleted via CASCADE foreign key

    _session.log(
      'Stopped watching: $path (deleted $deletedWatchedFolders WatchedFolder, $deletedFileIndexes FileIndex)',
      level: LogLevel.info,
    );
  }

  /// Handle a file system event
  void _handleEvent(WatchEvent event) {
    final path = event.path;

    // Only process supported file types
    if (!FileExtractionService.isSupported(path)) {
      return;
    }

    // Check ignore patterns (Issue #5)
    if (_shouldIgnore(path)) {
      _session.log(
        'File ignored by pattern: $path',
        level: LogLevel.debug,
      );
      return;
    }

    // Issue #20: Skip files exceeding max size
    if (event.type != ChangeType.REMOVE) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          final size = file.lengthSync();
          if (size > maxFileSizeBytes) {
            _session.log(
              'File too large (${(size / 1024 / 1024).toStringAsFixed(1)}MB), skipping: $path',
              level: LogLevel.warning,
            );
            return;
          }
        }
      } catch (e) {
        // Ignore stat errors - file may have been deleted
      }
    }

    _session.log(
      'File event: ${event.type} - $path',
      level: LogLevel.debug,
    );

    switch (event.type) {
      case ChangeType.ADD:
        // Issue #14: Cancel pending removal if this is a file move (same path)
        if (_pendingRemovals.containsKey(path)) {
          _pendingRemovals[path]?.cancel();
          _pendingRemovals.remove(path);
          _session.log(
            'File move detected (ADD after REMOVE): $path',
            level: LogLevel.debug,
          );
        }
        // Check for cross-path move (different path, same content)
        _detectCrossPathMove(path).then((oldPath) {
          if (oldPath != null) {
            // Remove the old path from recently removed files
            _recentlyRemovedFiles.remove(oldPath);
          }
        });
        _queueForReindexing(path);
        break;
      case ChangeType.MODIFY:
        _queueForReindexing(path);
        break;
      case ChangeType.REMOVE:
        // Issue #14: Delay REMOVE to detect file moves
        _pendingRemovals[path]?.cancel();
        _pendingRemovals[path] = Timer(_moveDetectionDelay, () {
          _pendingRemovals.remove(path);
          _handleFileRemoved(path);
        });
        break;
    }
  }

  /// Check if a path should be ignored based on configured patterns
  bool _shouldIgnore(String filePath) {
    if (_ignorePatterns.isEmpty) return false;

    final fileName = File(filePath).uri.pathSegments.last;
    final normalizedPath = filePath.replaceAll('\\', '/');

    for (final pattern in _ignorePatterns) {
      // Simple glob matching for common patterns
      if (pattern.startsWith('*.')) {
        // Extension match (e.g., "*.log")
        final ext = pattern.substring(1); // ".log"
        if (fileName.endsWith(ext)) return true;
      } else if (pattern.endsWith('/**')) {
        // Directory match (e.g., "node_modules/**")
        final dirName = pattern.substring(0, pattern.length - 3);
        if (normalizedPath.contains('/$dirName/') ||
            normalizedPath.contains('\\$dirName\\')) {
          return true;
        }
      } else if (pattern == fileName) {
        // Exact filename match
        return true;
      } else if (normalizedPath.contains(pattern)) {
        // Substring match for simple patterns
        return true;
      }
    }
    return false;
  }

  /// Queue a file for re-indexing with debouncing
  void _queueForReindexing(String filePath) {
    // Issue #6: Enforce queue size limit to prevent memory leaks
    if (_pendingFiles.length >= maxQueueSize) {
      // LRU eviction - remove oldest entries (first 10%)
      // Using a slightly more efficient approach for Set eviction
      final toEvict = _pendingFiles.take((maxQueueSize * 0.1).ceil()).toList();
      for (final p in toEvict) {
        _pendingFiles.remove(p);
      }
      _session.log(
        'Queue size limit reached, evicted ${toEvict.length} oldest entries',
        level: LogLevel.warning,
      );
    }

    _pendingFiles.add(filePath);

    // Get the parent directory for debouncing
    final parentDir = File(filePath).parent.path;

    // Cancel existing timer
    _debounceTimers[parentDir]?.cancel();

    // Set new timer - wait 2 seconds for more changes before processing
    _debounceTimers[parentDir] = Timer(
      const Duration(seconds: 2),
      () => _processPendingFiles(parentDir),
    );
  }

  /// Process all pending files for a directory
  Future<void> _processPendingFiles(String parentDir) async {
    if (_pendingFiles.isEmpty) return;

    final filesToProcess = _pendingFiles
        .where((f) => f.startsWith(parentDir))
        .toList();

    _pendingFiles.removeAll(filesToProcess);

    if (filesToProcess.isEmpty) return;

    _session.log(
      'Processing ${filesToProcess.length} changed files in $parentDir',
      level: LogLevel.info,
    );

    // Update lastEventAt
    final watchedFolder = await WatchedFolder.db.findFirstRow(
      _session,
      where: (t) => t.path.equals(parentDir),
    );

    if (watchedFolder != null) {
      watchedFolder.lastEventAt = DateTime.now();
      await WatchedFolder.db.updateRow(_session, watchedFolder);
    }

    // Trigger re-indexing callback
    if (onFilesChanged != null) {
      await onFilesChanged!(filesToProcess);
    }
  }

  /// Handle a removed file (Issue #1: Proper cleanup)
  Future<void> _handleFileRemoved(String filePath) async {
    _session.log(
      'File removed, triggering cleanup: $filePath',
      level: LogLevel.info,
    );

    // Store file info for cross-path move detection before removing from index
    try {
      final existingIndex = await FileIndex.db.findFirstRow(
        _session,
        where: (t) => t.path.equals(filePath),
      );
      if (existingIndex != null && existingIndex.contentHash.isNotEmpty) {
        _recentlyRemovedFiles[filePath] = _RemovedFileInfo(
          contentHash: existingIndex.contentHash,
          removedAt: DateTime.now(),
        );
      }
    } catch (e) {
      _session.log(
        'Error storing removed file info: $e',
        level: LogLevel.debug,
      );
    }

    // Trigger cleanup callback to remove from index
    if (onFileRemoved != null) {
      try {
        await onFileRemoved!(filePath);
        _session.log(
          'File successfully removed from index: $filePath',
          level: LogLevel.debug,
        );
      } catch (e) {
        _session.log(
          'Failed to remove file from index: $filePath - $e',
          level: LogLevel.error,
        );
      }
    }
  }

  /// Get all watched folders
  Future<List<WatchedFolder>> getWatchedFolders() async {
    return await WatchedFolder.db.find(_session);
  }

  /// Restore watchers from database on server startup
  Future<void> restoreWatchers() async {
    final folders = await WatchedFolder.db.find(
      _session,
      where: (t) => t.isEnabled.equals(true),
    );

    for (final folder in folders) {
      try {
        await startWatching(folder.path);
      } catch (e) {
        _session.log(
          'Failed to restore watcher for ${folder.path}: $e',
          level: LogLevel.warning,
        );
      }
    }

    _session.log(
      'Restored ${folders.length} file watchers',
      level: LogLevel.info,
    );
  }

  /// Stop all watchers and clean up
  Future<void> dispose() async {
    for (final subscription in _watchers.values) {
      await subscription.cancel();
    }
    _watchers.clear();
    _watcherHealth.clear();

    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    // Issue #14: Cancel pending removal timers
    for (final timer in _pendingRemovals.values) {
      timer.cancel();
    }
    _pendingRemovals.clear();

    _pendingFiles.clear();
  }

  /// Issue #17: Schedule watcher restart after failure
  void _scheduleRestart(String path) {
    Future.delayed(_restartDelay, () async {
      if (_watcherHealth[path] == false) {
        _session.log(
          'Attempting to restart watcher: $path',
          level: LogLevel.info,
        );
        try {
          await stopWatching(path);
          await startWatching(path);
          _session.log(
            'Watcher restarted successfully: $path',
            level: LogLevel.info,
          );
        } catch (e) {
          _session.log(
            'Failed to restart watcher: $path - $e',
            level: LogLevel.error,
          );
        }
      }
    });
  }

  /// Issue #17: Check if a watcher is healthy
  bool isHealthy(String path) => _watcherHealth[path] ?? false;

  /// Issue #17: Get overall health status of all watchers
  Map<String, bool> get watcherHealthStatus => Map.unmodifiable(_watcherHealth);

  /// Check if a newly added file matches a recently removed file (cross-path move detection)
  Future<String?> _detectCrossPathMove(String newPath) async {
    // Clean up expired entries
    final now = DateTime.now();
    _recentlyRemovedFiles.removeWhere(
      (_, info) => now.difference(info.removedAt) > _moveDetectionWindow,
    );

    if (_recentlyRemovedFiles.isEmpty) return null;

    // Get content hash of the new file
    try {
      final file = File(newPath);
      if (!file.existsSync()) return null;

      final bytes = await file.readAsBytes();
      final hash = _computeHash(bytes);

      // Check if any recently removed file has the same hash
      for (final entry in _recentlyRemovedFiles.entries) {
        if (entry.value.contentHash == hash) {
          _session.log(
            'Cross-path move detected: ${entry.key} -> $newPath',
            level: LogLevel.info,
          );
          return entry.key; // Return the old path
        }
      }
    } catch (e) {
      _session.log(
        'Error checking for cross-path move: $e',
        level: LogLevel.debug,
      );
    }
    return null;
  }

  /// Compute a simple hash for move detection (first 4KB + file size)
  String _computeHash(List<int> bytes) {
    // Use first 4KB + size for quick comparison
    final sampleSize = bytes.length > 4096 ? 4096 : bytes.length;
    final sample = bytes.sublist(0, sampleSize);
    var hash = bytes.length;
    for (final b in sample) {
      hash = ((hash << 5) - hash + b) & 0xFFFFFFFF;
    }
    return '${bytes.length}_$hash';
  }
}

/// Info about a recently removed file for move detection
class _RemovedFileInfo {
  final String contentHash;
  final DateTime removedAt;

  _RemovedFileInfo({required this.contentHash, required this.removedAt});
}
