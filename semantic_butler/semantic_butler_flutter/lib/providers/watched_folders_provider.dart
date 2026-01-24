import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';
import '../utils/app_logger.dart';

/// Provider for the list of watched folders using AsyncNotifier
final watchedFoldersProvider =
    AsyncNotifierProvider<WatchedFoldersNotifier, List<WatchedFolder>>(
      WatchedFoldersNotifier.new,
    );

class WatchedFoldersNotifier extends AsyncNotifier<List<WatchedFolder>> {
  @override
  Future<List<WatchedFolder>> build() async {
    final apiClient = ref.read(clientProvider);
    try {
      return await apiClient.butler.getWatchedFolders();
    } catch (e) {
      AppLogger.error('Failed to load watched folders: $e', tag: 'Provider');
      rethrow;
    }
  }

  /// Refresh the watched folders list
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final apiClient = ref.read(clientProvider);
      return await apiClient.butler.getWatchedFolders();
    });
  }

  /// Toggle smart indexing for a folder path
  Future<void> toggle(String path) async {
    final apiClient = ref.read(clientProvider);
    try {
      await apiClient.butler.toggleSmartIndexing(path);
      // Invalidate to trigger a refresh
      ref.invalidateSelf();
    } catch (e) {
      AppLogger.error('Failed to toggle watched folder: $e', tag: 'Provider');
      rethrow;
    }
  }
}

/// Check if a specific folder is being smart-watched
/// Use this in widgets to avoid rebuilding when other folders change
///
/// Example usage in CompactIndexCard:
/// ```dart
/// final isSmartIndexing = ref.watch(isFolderSmartlyWatchedProvider(job.folderPath));
/// ```
final isFolderSmartlyWatchedProvider = Provider.family<bool, String>((ref, path) {
  final watchedFoldersAsync = ref.watch(watchedFoldersProvider);
  final watchedFolders = watchedFoldersAsync.value ?? [];
  return watchedFolders.any((f) => f.path == path && f.isEnabled);
});
