import 'dart:collection';

/// In-memory cache service with TTL support
///
/// Provides caching for expensive operations like AI embeddings and summaries.
/// Uses LRU eviction when the cache reaches maximum capacity.
class CacheService {
  /// Singleton instance
  static final CacheService instance = CacheService._();

  CacheService._();

  /// Cache storage: key -> CacheEntry
  final LinkedHashMap<String, _CacheEntry> _cache = LinkedHashMap();

  /// Maximum number of entries in the cache
  static const int maxEntries = 10000;

  /// Default TTL for cache entries
  static const Duration defaultTtl = Duration(hours: 24);

  /// Cache statistics
  int _hits = 0;
  int _misses = 0;

  /// Get a value from the cache
  ///
  /// Returns null if the key doesn't exist or the entry has expired.
  T? get<T>(String key) {
    final entry = _cache[key];

    if (entry == null) {
      _misses++;
      return null;
    }

    if (entry.isExpired) {
      _cache.remove(key);
      _misses++;
      return null;
    }

    // Move to end for LRU ordering
    _cache.remove(key);
    _cache[key] = entry;

    _hits++;
    return entry.value as T;
  }

  /// Set a value in the cache
  ///
  /// [key] - Cache key
  /// [value] - Value to cache
  /// [ttl] - Time-to-live (default: 24 hours)
  void set<T>(String key, T value, {Duration ttl = defaultTtl}) {
    // Evict oldest entries if at capacity
    while (_cache.length >= maxEntries) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  /// Check if a key exists and is not expired
  bool containsKey(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Remove a key from the cache
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clear all entries from the cache
  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Get cache statistics
  CacheStats get stats => CacheStats(
    size: _cache.length,
    maxSize: maxEntries,
    hits: _hits,
    misses: _misses,
    hitRate: _hits + _misses > 0 ? _hits / (_hits + _misses) : 0.0,
  );

  /// Generate a cache key for embeddings
  static String embeddingKey(String text) {
    return 'embed:${text.hashCode}';
  }

  /// Generate a cache key for summaries
  static String summaryKey(String contentHash, int maxWords) {
    return 'summary:$contentHash:$maxWords';
  }

  /// Generate a cache key for tags
  static String tagsKey(String contentHash) {
    return 'tags:$contentHash';
  }

  /// Cleanup expired entries (call periodically)
  int cleanupExpired() {
    final keysToRemove = <String>[];
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    return keysToRemove.length;
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  _CacheEntry({required this.value, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Cache statistics
class CacheStats {
  final int size;
  final int maxSize;
  final int hits;
  final int misses;
  final double hitRate;

  CacheStats({
    required this.size,
    required this.maxSize,
    required this.hits,
    required this.misses,
    required this.hitRate,
  });

  Map<String, dynamic> toJson() => {
    'size': size,
    'maxSize': maxSize,
    'hits': hits,
    'misses': misses,
    'hitRate': hitRate,
    'hitRatePercent': '${(hitRate * 100).toStringAsFixed(1)}%',
  };
}
