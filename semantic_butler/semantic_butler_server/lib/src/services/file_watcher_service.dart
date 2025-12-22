import 'dart:async';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'package:watcher/watcher.dart';
import '../generated/protocol.dart';
import 'file_extraction_service.dart';

/// Service that watches directories for file changes and triggers re-indexing.
class FileWatcherService {
  final Session _session;

  /// Active directory watchers: path -> subscription
  final Map<String, StreamSubscription<WatchEvent>> _watchers = {};

  /// Debounce timers to batch rapid file changes
  final Map<String, Timer> _debounceTimers = {};

  /// Files queued for re-indexing
  final Set<String> _pendingFiles = {};

  /// Callback to trigger re-indexing
  final Future<void> Function(List<String> paths)? onFilesChanged;

  FileWatcherService(
    this._session, {
    this.onFilesChanged,
  });

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
      },
    );

    _watchers[path] = subscription;

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

  /// Stop watching a directory
  Future<void> stopWatching(String path) async {
    final subscription = _watchers.remove(path);
    if (subscription != null) {
      await subscription.cancel();
    }

    _debounceTimers[path]?.cancel();
    _debounceTimers.remove(path);

    // Update database
    final watchedFolder = await WatchedFolder.db.findFirstRow(
      _session,
      where: (t) => t.path.equals(path),
    );

    if (watchedFolder != null) {
      watchedFolder.isEnabled = false;
      await WatchedFolder.db.updateRow(_session, watchedFolder);
    }

    _session.log('Stopped watching: $path', level: LogLevel.info);
  }

  /// Handle a file system event
  void _handleEvent(WatchEvent event) {
    final path = event.path;

    // Only process supported file types
    if (!FileExtractionService.isSupported(path)) {
      return;
    }

    _session.log(
      'File event: ${event.type} - $path',
      level: LogLevel.debug,
    );

    switch (event.type) {
      case ChangeType.ADD:
      case ChangeType.MODIFY:
        _queueForReindexing(path);
        break;
      case ChangeType.REMOVE:
        _handleFileRemoved(path);
        break;
    }
  }

  /// Queue a file for re-indexing with debouncing
  void _queueForReindexing(String filePath) {
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

  /// Handle a removed file
  Future<void> _handleFileRemoved(String filePath) async {
    // This would remove the file from the index
    // For now, just log it - the actual removal logic would be in ButlerEndpoint
    _session.log(
      'File removed, should be unindexed: $filePath',
      level: LogLevel.info,
    );
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

    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    _pendingFiles.clear();
  }
}
