import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';
import '../utils/app_logger.dart';
import 'directory_cache_provider.dart';

/// State for file system browsing
class FileSystemState {
  final String currentPath;
  final List<FileSystemEntry> entries;
  final List<DriveInfo> drives;
  final bool isLoading;
  final bool isLoadingDrives;
  final String? error;
  final String? drivesError;

  const FileSystemState({
    this.currentPath = '',
    this.entries = const [],
    this.drives = const [],
    this.isLoading = false,
    this.isLoadingDrives = false,
    this.error,
    this.drivesError,
  });

  FileSystemState copyWith({
    String? currentPath,
    List<FileSystemEntry>? entries,
    List<DriveInfo>? drives,
    bool? isLoading,
    bool? isLoadingDrives,
    String? error,
    String? drivesError,
    bool clearError = false,
    bool clearDrivesError = false,
  }) {
    return FileSystemState(
      currentPath: currentPath ?? this.currentPath,
      entries: entries ?? this.entries,
      drives: drives ?? this.drives,
      isLoading: isLoading ?? this.isLoading,
      isLoadingDrives: isLoadingDrives ?? this.isLoadingDrives,
      error: clearError ? null : (error ?? this.error),
      drivesError: clearDrivesError ? null : (drivesError ?? this.drivesError),
    );
  }
}

/// Notifier for file system state
class FileSystemNotifier extends Notifier<FileSystemState> {
  @override
  FileSystemState build() {
    // Auto-load drives on initialization
    Future.microtask(() => loadDrives());
    return FileSystemState();
  }

  /// Load available drives
  Future<void> loadDrives() async {
    state = state.copyWith(isLoadingDrives: true, clearDrivesError: true);

    try {
      final apiClient = ref.read(clientProvider);
      final drives = await apiClient.fileSystem.getDrives();

      state = state.copyWith(
        drives: drives,
        isLoadingDrives: false,
      );

      // If no path is set and we have drives, select the first one
      if (state.currentPath.isEmpty && drives.isNotEmpty) {
        loadDirectory(drives.first.path);
      }
    } catch (e) {
      AppLogger.error('Failed to load drives: $e', tag: 'FileSystemProvider');
      state = state.copyWith(
        drivesError: e.toString(),
        isLoadingDrives: false,
      );
    }
  }

  /// Load directory contents for a given path
  Future<void> loadDirectory(String path) async {
    state = state.copyWith(
      currentPath: path,
      isLoading: true,
      clearError: true,
    );

    try {
      final cache = ref.read(directoryCacheProvider);
      final entries = await cache.getDirectory(path);

      state = state.copyWith(
        entries: entries,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to load directory: $e',
        tag: 'FileSystemProvider',
      );
      state = state.copyWith(
        error: 'Failed to load directory: $e',
        isLoading: false,
      );
    }
  }

  /// Navigate to parent directory
  void navigateUp() {
    if (state.currentPath.isEmpty) return;

    // Use path package to get parent
    final path = state.currentPath;
    final separator = path.contains('\\') ? '\\' : '/';
    final lastSeparator = path.lastIndexOf(separator);

    if (lastSeparator <= 0) {
      // At root, reload drives
      loadDrives();
    } else {
      final parentPath = path.substring(0, lastSeparator);
      loadDirectory(parentPath);
    }
  }

  /// Invalidate cache for current directory and reload
  Future<void> refreshCurrentDirectory() async {
    if (state.currentPath.isNotEmpty) {
      final cache = ref.read(directoryCacheProvider);
      cache.invalidate(state.currentPath);
      await loadDirectory(state.currentPath);
    }
  }

  /// Invalidate cache and reload drives
  Future<void> refreshDrives() async {
    await loadDrives();
  }
}

/// Provider for file system state
final fileSystemProvider =
    NotifierProvider<FileSystemNotifier, FileSystemState>(
      FileSystemNotifier.new,
    );
