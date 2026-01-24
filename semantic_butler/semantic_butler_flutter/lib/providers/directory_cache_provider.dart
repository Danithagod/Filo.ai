import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';

/// Riverpod provider for DirectoryCacheProvider
/// Provides a singleton cache instance accessible throughout the app
final directoryCacheProvider = Provider<DirectoryCacheProvider>((ref) {
  final client = ref.read(clientProvider);
  return DirectoryCacheProvider(client);
});

/// Simple in-memory cache for directory listing to avoid repeated API calls
class DirectoryCacheProvider {
  final Client _client;
  final Map<String, _CacheEntry<List<FileSystemEntry>>> _cache = {};
  static const Duration _cacheTimeout = Duration(minutes: 5);

  DirectoryCacheProvider(this._client);

  /// Get directory contents, using cache if available and not expired
  Future<List<FileSystemEntry>> getDirectory(String path) async {
    final cached = _cache[path];
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    final entries = await _client.fileSystem.listDirectory(path);
    _cache[path] = _CacheEntry(entries);
    return entries;
  }

  /// Invalidate a specific path in the cache
  void invalidate(String path) {
    _cache.remove(path);
  }

  /// Clear all cached entries
  void clearAll() {
    _cache.clear();
  }
}

class _CacheEntry<T> {
  final T data;
  final DateTime createdAt;

  _CacheEntry(this.data) : createdAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(createdAt) >
      DirectoryCacheProvider._cacheTimeout;
}
