/// Token bucket rate limiter for API protection
///
/// Implements the token bucket algorithm to prevent abuse and DoS attacks.
/// Each client gets a bucket of tokens that refills over time.
class RateLimitService {
  /// Singleton instance
  static final RateLimitService instance = RateLimitService._();

  RateLimitService._();

  /// Token buckets per client: key -> bucket
  final Map<String, _TokenBucket> _buckets = {};

  /// Default rate limit: 60 requests per minute
  static const int defaultTokensPerMinute = 60;

  /// Check if request is allowed and consume a token
  ///
  /// [clientId] - Unique identifier for the client (e.g., IP address, API key)
  /// [endpoint] - The endpoint being accessed
  /// [limit] - Maximum requests per minute for this endpoint
  ///
  /// Returns true if the request is allowed, false if rate limited
  bool checkAndConsume(
    String clientId,
    String endpoint, {
    int limit = defaultTokensPerMinute,
  }) {
    final key = '$endpoint:$clientId';
    final now = DateTime.now();

    final bucket = _buckets.putIfAbsent(
      key,
      () => _TokenBucket(tokens: limit, lastRefill: now),
    );

    // Refill tokens based on time elapsed
    final elapsed = now.difference(bucket.lastRefill);
    if (elapsed.inSeconds >= 60) {
      // Full refill after a minute
      bucket.tokens = limit;
      bucket.lastRefill = now;
    } else if (elapsed.inSeconds > 0) {
      // Partial refill based on elapsed time
      final refillTokens = (elapsed.inSeconds / 60 * limit).floor();
      bucket.tokens = (bucket.tokens + refillTokens).clamp(0, limit);
      if (refillTokens > 0) {
        bucket.lastRefill = now;
      }
    }

    if (bucket.tokens > 0) {
      bucket.tokens--;
      return true;
    }
    return false;
  }

  /// Get remaining tokens for a client
  int getRemainingTokens(String clientId, String endpoint) {
    final key = '$endpoint:$clientId';
    return _buckets[key]?.tokens ?? defaultTokensPerMinute;
  }

  /// Get time until next token refill in seconds
  int getSecondsUntilRefill(String clientId, String endpoint) {
    final key = '$endpoint:$clientId';
    final bucket = _buckets[key];
    if (bucket == null) return 0;

    final elapsed = DateTime.now().difference(bucket.lastRefill);
    return (60 - elapsed.inSeconds).clamp(0, 60);
  }

  /// Require rate limit check or throw RateLimitException
  ///
  /// [clientId] - Unique identifier for the client
  /// [endpoint] - The endpoint being accessed
  /// [limit] - Maximum requests per minute
  void requireRateLimit(
    String clientId,
    String endpoint, {
    int limit = defaultTokensPerMinute,
  }) {
    if (!checkAndConsume(clientId, endpoint, limit: limit)) {
      final remaining = getSecondsUntilRefill(clientId, endpoint);
      throw RateLimitException(
        'Rate limit exceeded. Try again in $remaining seconds.',
      );
    }
  }

  /// Clear all rate limit buckets (useful for testing)
  void clearAll() {
    _buckets.clear();
  }

  /// Clear rate limit for a specific client
  void clearClient(String clientId) {
    _buckets.removeWhere((key, _) => key.contains(':$clientId'));
  }
}

class _TokenBucket {
  int tokens;
  DateTime lastRefill;

  _TokenBucket({required this.tokens, required this.lastRefill});
}

/// Exception when rate limit exceeded
class RateLimitException implements Exception {
  final String message;

  RateLimitException(this.message);

  @override
  String toString() => 'RateLimitException: $message';
}
