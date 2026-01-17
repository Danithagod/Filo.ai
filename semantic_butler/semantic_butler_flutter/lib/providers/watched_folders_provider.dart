import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';
import '../utils/app_logger.dart';

/// Provider for the list of watched folders
final watchedFoldersProvider =
    NotifierProvider<WatchedFoldersNotifier, List<WatchedFolder>>(
      WatchedFoldersNotifier.new,
    );

class WatchedFoldersNotifier extends Notifier<List<WatchedFolder>> {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  @override
  List<WatchedFolder> build() {
    // Initial load
    Future(() => load());
    return [];
  }

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final folders = await client.butler.getWatchedFolders();
      state = folders;
    } catch (e) {
      AppLogger.error('Failed to load watched folders: $e', tag: 'Provider');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> toggle(String path) async {
    try {
      await client.butler.toggleSmartIndexing(path);
      await load(); // Reload after toggle
    } catch (e) {
      AppLogger.error('Failed to toggle watched folder: $e', tag: 'Provider');
      rethrow;
    }
  }
}
