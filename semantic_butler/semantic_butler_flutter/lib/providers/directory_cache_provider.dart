import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';

/// Cache entry with expiration time and last access tracking for LRU
class _CacheEntry {
  final List<FileSystemEntry> entries;
  final DateTime expiresAt;
  DateTime lastAccessed;

  _CacheEntry(this.entries, this.expiresAt) : lastAccessed = DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Directory cache provider with LRU eviction to avoid unbounded memory growth
/// Caches directory listings with a 5-minute TTL and max 100 entries
class DirectoryCacheProvider {
  /// Use LinkedHashMap to maintain insertion order for LRU
  final LinkedHashMap<String, _CacheEntry> _cache = LinkedHashMap();
  final Duration _ttl = const Duration(minutes: 5);
  final Client _client;

  /// Maximum number of cached directories to prevent memory exhaustion
  static const int _maxCacheSize = 100;

  DirectoryCacheProvider(this._client);

  /// Get directory contents, using cache if available and not expired
  /// Implements LRU eviction when cache is full
  Future<List<FileSystemEntry>> getDirectory(String path) async {
    // Normalize path for consistent cache keys
    final normalizedPath = _normalizePath(path);

    final entry = _cache[normalizedPath];
    if (entry != null && !entry.isExpired) {
      // Move to end for LRU (most recently used)
      _cache.remove(normalizedPath);
      entry.lastAccessed = DateTime.now();
      _cache[normalizedPath] = entry;
      return entry.entries;
    }

    final entries = await _client.fileSystem.listDirectory(path);

    // Evict oldest entry if at capacity
    if (_cache.length >= _maxCacheSize) {
      _evictOldest();
    }

    _cache[normalizedPath] = _CacheEntry(entries, DateTime.now().add(_ttl));
    return entries;
  }

  /// Normalize path for consistent cache keys
  String _normalizePath(String path) {
    return path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
  }

  /// Evict the oldest (least recently used) entry
  void _evictOldest() {
    if (_cache.isEmpty) return;

    // LinkedHashMap maintains insertion order, so first key is oldest
    // But we want LRU based on access time, so find the entry with oldest lastAccessed
    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cache.entries) {
      // Also evict expired entries while we're at it
      if (entry.value.isExpired) {
        _cache.remove(entry.key);
        return;
      }

      if (oldestTime == null || entry.value.lastAccessed.isBefore(oldestTime)) {
        oldestTime = entry.value.lastAccessed;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }

  /// Clean up expired entries
  void cleanupExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  /// Invalidate cache for a specific path (e.g., after file operations)
  void invalidate(String path) {
    final normalizedPath = _normalizePath(path);
    _cache.remove(normalizedPath);
  }

  /// Invalidate all cache entries
  void invalidateAll() {
    _cache.clear();
  }

  /// Invalidate cache for parent directory
  /// Useful when a file is renamed, moved, or deleted
  void invalidateParent(String filePath) {
    // Normalize and extract parent directory path
    final normalizedPath = _normalizePath(filePath);
    final separatorIndex = normalizedPath.lastIndexOf('/');
    if (separatorIndex > 0) {
      final parentPath = normalizedPath.substring(0, separatorIndex);
      _cache.remove(parentPath);
    }
  }

  /// Get current cache size for debugging/monitoring
  int get cacheSize => _cache.length;

  /// Preload directory for faster navigation
  Future<void> preload(String path) async {
    try {
      await getDirectory(path);
    } catch (e) {
      // Ignore preload errors
    }
  }
}

/// Riverpod provider for directory cache
final directoryCacheProvider = Provider<DirectoryCacheProvider>((ref) {
  // Get client from your existing client provider
  // Adjust this based on your app's provider setup
  throw UnimplementedError(
    'DirectoryCacheProvider requires Client instance. '
    'Override this provider in your app with the actual client.',
  );
});
