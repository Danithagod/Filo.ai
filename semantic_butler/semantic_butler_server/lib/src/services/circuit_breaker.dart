/// Circuit Breaker pattern for external service calls
///
/// Prevents cascading failures by tracking failure rates and
/// temporarily stopping calls to failing services.
class CircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration resetTimeout;
  final Duration halfOpenTimeout;

  int _failureCount = 0;
  DateTime? _lastFailure;
  DateTime? _openedAt;
  _CircuitState _state = _CircuitState.closed;

  CircuitBreaker({
    required this.name,
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(minutes: 1),
    this.halfOpenTimeout = const Duration(seconds: 30),
  });

  /// Check if circuit allows the call
  bool get allowRequest {
    _updateState();
    return _state != _CircuitState.open;
  }

  /// Current state of the circuit
  String get state => _state.name;

  /// Number of consecutive failures
  int get failureCount => _failureCount;

  /// Time of last failure (for debugging)
  DateTime? get lastFailure => _lastFailure;

  /// Record a successful call
  void recordSuccess() {
    _failureCount = 0;
    _state = _CircuitState.closed;
    _openedAt = null;
  }

  /// Record a failed call
  void recordFailure() {
    _failureCount++;
    _lastFailure = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = _CircuitState.open;
      _openedAt = DateTime.now();
    }
  }

  /// Update state based on timeouts
  void _updateState() {
    if (_state == _CircuitState.open && _openedAt != null) {
      final elapsed = DateTime.now().difference(_openedAt!);
      if (elapsed >= resetTimeout) {
        _state = _CircuitState.halfOpen;
      }
    }
  }

  /// Execute an action with circuit breaker protection
  Future<T> execute<T>(
    Future<T> Function() action, {
    T Function()? fallback,
  }) async {
    if (!allowRequest) {
      if (fallback != null) {
        return fallback();
      }
      throw CircuitBreakerOpenException(
        'Circuit breaker "$name" is open. Try again after ${resetTimeout.inSeconds}s',
      );
    }

    try {
      final result = await action();
      recordSuccess();
      return result;
    } catch (e) {
      recordFailure();
      rethrow;
    }
  }

  /// Reset the circuit breaker
  void reset() {
    _failureCount = 0;
    _state = _CircuitState.closed;
    _openedAt = null;
    _lastFailure = null;
  }
}

enum _CircuitState { closed, open, halfOpen }

/// Exception thrown when circuit breaker is open
class CircuitBreakerOpenException implements Exception {
  final String message;

  CircuitBreakerOpenException(this.message);

  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

/// Manages multiple circuit breakers for different services
class CircuitBreakerRegistry {
  static final CircuitBreakerRegistry instance = CircuitBreakerRegistry._();

  CircuitBreakerRegistry._();

  final Map<String, CircuitBreaker> _breakers = {};

  /// Get or create a circuit breaker for a service
  CircuitBreaker getBreaker(
    String name, {
    int failureThreshold = 5,
    Duration resetTimeout = const Duration(minutes: 1),
  }) {
    return _breakers.putIfAbsent(
      name,
      () => CircuitBreaker(
        name: name,
        failureThreshold: failureThreshold,
        resetTimeout: resetTimeout,
      ),
    );
  }

  /// Get status of all circuit breakers
  Map<String, Map<String, dynamic>> getStatus() {
    return _breakers.map(
      (name, breaker) => MapEntry(name, {
        'state': breaker.state,
        'failureCount': breaker.failureCount,
        'allowRequest': breaker.allowRequest,
      }),
    );
  }

  /// Reset all circuit breakers
  void resetAll() {
    for (final breaker in _breakers.values) {
      breaker.reset();
    }
  }
}
