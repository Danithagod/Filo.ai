/// Client-side rate limiter for better UX
///
/// Prevents excessive API calls and provides immediate feedback
/// when rate limits would be exceeded, rather than waiting for
/// server rejection.
class RateLimiter {
  /// Request timestamps per endpoint
  final Map<String, List<DateTime>> _requests = {};

  /// Default limit: 60 requests per minute
  static const int defaultLimit = 60;

  /// Check if a request is allowed and record it
  ///
  /// [endpoint] - The endpoint being accessed
  /// [maxPerMinute] - Maximum requests allowed per minute
  ///
  /// Returns true if the request is allowed, false if rate limited
  bool checkAndRecord(String endpoint, {int maxPerMinute = defaultLimit}) {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    // Initialize or clean up old requests
    _requests[endpoint] ??= [];
    _requests[endpoint]!.removeWhere((t) => t.isBefore(oneMinuteAgo));

    // Check if at limit
    if (_requests[endpoint]!.length >= maxPerMinute) {
      return false;
    }

    // Record this request
    _requests[endpoint]!.add(now);
    return true;
  }

  /// Check if a request would be allowed without recording it
  bool check(String endpoint, {int maxPerMinute = defaultLimit}) {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    final requests = _requests[endpoint];
    if (requests == null) return true;

    // Count requests within the last minute
    final recentRequests = requests.where((t) => t.isAfter(oneMinuteAgo)).length;
    return recentRequests < maxPerMinute;
  }

  /// Get remaining requests for an endpoint
  int getRemainingRequests(String endpoint, {int maxPerMinute = defaultLimit}) {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    final requests = _requests[endpoint];
    if (requests == null) return maxPerMinute;

    final recentRequests = requests.where((t) => t.isAfter(oneMinuteAgo)).length;
    return (maxPerMinute - recentRequests).clamp(0, maxPerMinute);
  }

  /// Get seconds until the next request would be allowed
  int getSecondsUntilAvailable(String endpoint, {int maxPerMinute = defaultLimit}) {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    final requests = _requests[endpoint];
    if (requests == null || requests.isEmpty) return 0;

    // Filter to recent requests
    final recentRequests = requests.where((t) => t.isAfter(oneMinuteAgo)).toList();
    if (recentRequests.length < maxPerMinute) return 0;

    // Find the oldest request that would need to expire
    recentRequests.sort();
    final oldestRelevant = recentRequests.first;
    final expiresAt = oldestRelevant.add(const Duration(minutes: 1));
    final secondsUntil = expiresAt.difference(now).inSeconds;

    return secondsUntil.clamp(0, 60);
  }

  /// Clear all rate limit tracking
  void clear() {
    _requests.clear();
  }

  /// Clear rate limit tracking for a specific endpoint
  void clearEndpoint(String endpoint) {
    _requests.remove(endpoint);
  }
}

/// Singleton rate limiter instance for app-wide use
final rateLimiter = RateLimiter();

/// Rate limit exception for client-side limiting
class ClientRateLimitException implements Exception {
  final String message;
  final int secondsUntilRetry;

  ClientRateLimitException(this.message, this.secondsUntilRetry);

  @override
  String toString() => 'ClientRateLimitException: $message';
}
