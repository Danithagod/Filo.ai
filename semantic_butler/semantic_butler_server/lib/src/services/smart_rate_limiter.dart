import 'dart:async';
import 'dart:math';

/// Enhanced rate limiter with retry budget and intelligent backoff
class SmartRateLimiter {
  static final SmartRateLimiter instance = SmartRateLimiter._();
  SmartRateLimiter._();

  /// Per-client request tracking
  final Map<String, Map<String, RequestWindow>> _clientRequests = {};

  /// Retry budget per client for handling transient errors
  final Map<String, RetryBudget> _retryBudgets = {};

  /// Cleanup timer for stale data
  Timer? _cleanupTimer;

  /// Configuration
  static const int defaultLimitPerMinute = 60;
  static const int defaultLimitPerSecond = 10;
  static const int defaultRetryBudget = 20;
  static const Duration windowSize = Duration(minutes: 1);
  static const Duration retryWindow = Duration(minutes: 1);

  /// Start the cleanup timer
  void _startCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _cleanupStaleData();
    });
  }

  /// Clean up stale request data
  void _cleanupStaleData() {
    final now = DateTime.now();
    final staleThreshold = now.subtract(windowSize * 2);

    _clientRequests.removeWhere((clientId, endpoints) {
      endpoints.removeWhere((endpoint, window) {
        return window.isEmpty ||
            (window.hasData && window.oldestTimestamp.isBefore(staleThreshold));
      });
      return endpoints.isEmpty;
    });

    _retryBudgets.removeWhere((clientId, budget) {
      return budget.isEmpty || budget.lastRefill.isBefore(staleThreshold);
    });
  }

  /// Check if a request is allowed (without recording)
  bool check(
    String endpoint, {
    String? clientId,
    int limitPerMinute = defaultLimitPerMinute,
    int limitPerSecond = defaultLimitPerSecond,
    bool isRetry = false, // Compatibility with previous usage
  }) {
    final id = clientId ?? 'default';
    final now = DateTime.now();

    final window = _clientRequests[id] ?? {};
    final current = window[endpoint];

    if (current == null) return true;

    // Check per-second limit
    if (current.countInLastSecond(now) >= limitPerSecond) {
      return false;
    }

    // Check per-minute limit
    return current.countInWindow(now) < limitPerMinute;
  }

  /// Check and record a request
  bool checkAndRecord(
    String endpoint, {
    String? clientId,
    int limitPerMinute = defaultLimitPerMinute,
    int limitPerSecond = defaultLimitPerSecond,
  }) {
    final allowed = check(
      endpoint,
      clientId: clientId,
      limitPerMinute: limitPerMinute,
      limitPerSecond: limitPerSecond,
    );

    if (allowed) {
      _recordRequest(endpoint, clientId: clientId);
    }

    return allowed;
  }

  /// Record a request
  void record(
    String endpoint, {
    String? clientId,
  }) {
    _recordRequest(endpoint, clientId: clientId);
  }

  /// Internal request recording
  void _recordRequest(String endpoint, {String? clientId}) {
    _startCleanup();

    final id = clientId ?? 'default';
    _clientRequests[id] ??= {};
    _clientRequests[id]![endpoint] ??= RequestWindow();
    _clientRequests[id]![endpoint]!.add(DateTime.now());
  }

  /// Check if retry is allowed based on retry budget
  bool canRetry(String? clientId, {int cost = 1}) {
    final id = clientId ?? 'default';
    final budget = _retryBudgets[id];

    if (budget == null) {
      _retryBudgets[id] = RetryBudget(initialBudget: defaultRetryBudget);
      return true;
    }

    return budget.canSpend(cost);
  }

  /// Record a retry attempt (consumes from budget)
  bool recordRetry(String? clientId, {int cost = 1}) {
    final id = clientId ?? 'default';

    if (!canRetry(clientId, cost: cost)) {
      return false;
    }

    _retryBudgets[id]!.spend(cost);
    return true;
  }

  /// Refill retry budget (call on successful requests)
  void refillRetryBudget(String? clientId, {int amount = 1}) {
    final id = clientId ?? 'default';
    _retryBudgets[id] ??= RetryBudget(initialBudget: defaultRetryBudget);
    _retryBudgets[id]!.refill(amount);
  }

  /// Get remaining requests for a client/endpoint
  int getRemainingRequests(
    String endpoint, {
    String? clientId,
    int limit = defaultLimitPerMinute,
  }) {
    final id = clientId ?? 'default';
    final window = _clientRequests[id]?[endpoint];

    if (window == null) return limit;

    final used = window.countInWindow(DateTime.now());
    return (limit - used).clamp(0, limit);
  }

  /// Get retry budget remaining
  int getRetryBudget(String? clientId) {
    final id = clientId ?? 'default';
    return _retryBudgets[id]?.remaining ?? defaultRetryBudget;
  }

  /// Calculate backoff delay with jitter for retries
  Duration calculateBackoff(
    int attempt, {
    Duration baseDelay = const Duration(seconds: 2),
  }) {
    if (attempt <= 0) return Duration.zero;

    final exponentialDelay = baseDelay * pow(2, attempt - 1).toInt();

    final cappedDelay = exponentialDelay > const Duration(seconds: 60)
        ? const Duration(seconds: 60)
        : exponentialDelay;

    // Add jitter: ±25% randomization
    final random = Random();
    final jitterFactor = 0.75 + (random.nextDouble() * 0.5);
    final finalDelayMs = (cappedDelay.inMilliseconds * jitterFactor).round();

    return Duration(milliseconds: finalDelayMs);
  }

  /// Get time until next request is allowed
  Duration? getTimeUntilAllowed(
    String endpoint, {
    String? clientId,
    int limitPerMinute = defaultLimitPerMinute,
  }) {
    if (check(endpoint, clientId: clientId, limitPerMinute: limitPerMinute)) {
      return null;
    }

    final id = clientId ?? 'default';
    final window = _clientRequests[id]?[endpoint];

    if (window == null || window.isEmpty) return null;

    final oldestInWindow = window.oldestTimestamp;
    final windowEnd = oldestInWindow.add(windowSize);
    final now = DateTime.now();

    if (now.isAfter(windowEnd)) return null;

    return windowEnd.difference(now);
  }

  /// Compatibility method for previous usage
  int getSecondsUntilAvailable(String endpoint, String clientId) {
    final time = getTimeUntilAllowed(endpoint, clientId: clientId);
    return time?.inSeconds ?? 0;
  }

  /// Clear all tracking for a client
  void clearClient(String? clientId) {
    final id = clientId ?? 'default';
    _clientRequests.remove(id);
    _retryBudgets.remove(id);
  }

  /// Clear all tracking
  void clear() {
    _clientRequests.clear();
    _retryBudgets.clear();
  }
}

/// Tracks requests within a sliding time window
class RequestWindow {
  final List<DateTime> _timestamps = [];
  static const int maxSamples = 100;

  void add(DateTime timestamp) {
    _timestamps.add(timestamp);
    if (_timestamps.length > maxSamples) {
      _timestamps.removeAt(0);
    }
  }

  int countInWindow(DateTime now) {
    final cutoff = now.subtract(SmartRateLimiter.windowSize);
    return _timestamps.where((t) => t.isAfter(cutoff)).length;
  }

  int countInLastSecond(DateTime now) {
    final cutoff = now.subtract(const Duration(seconds: 1));
    return _timestamps.where((t) => t.isAfter(cutoff)).length;
  }

  bool get isEmpty => _timestamps.isEmpty;
  bool get hasData => _timestamps.isNotEmpty;
  DateTime get oldestTimestamp => _timestamps.first;
}

/// Retry budget for handling transient errors gracefully
class RetryBudget {
  int remaining;
  final int maxBudget;
  DateTime lastRefill;
  static const int refillRate = 1;

  RetryBudget({int initialBudget = 20, int? max})
    : remaining = initialBudget,
      maxBudget = max ?? initialBudget,
      lastRefill = DateTime.now();

  bool canSpend(int cost) => remaining >= cost;

  void spend(int cost) {
    remaining = (remaining - cost).clamp(0, maxBudget);
    lastRefill = DateTime.now();
  }

  void refill(int amount) {
    remaining = (remaining + amount).clamp(0, maxBudget);
    lastRefill = DateTime.now();
  }

  bool get isEmpty => remaining == 0;
}
