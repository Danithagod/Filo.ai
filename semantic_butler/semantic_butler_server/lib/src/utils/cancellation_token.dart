import 'dart:async';

/// Cancellation token for aborting long-running operations
/// 
/// Provides a mechanism to cancel asynchronous operations gracefully.
/// Useful for search operations that may be superseded by new requests.
class CancellationToken {
  bool _isCancelled = false;
  final _completer = Completer<void>();
  final List<StreamController> _controllers = [];
  final List<Timer> _timers = [];

  /// Check if cancellation has been requested
  bool get isCancelled => _isCancelled;

  /// Future that completes when cancellation is requested
  Future<void> get cancelled => _completer.future;

  /// Request cancellation
  void cancel() {
    if (_isCancelled) return;
    
    _isCancelled = true;
    
    // Close all registered stream controllers
    for (final controller in _controllers) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();
    
    // Cancel all registered timers
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    
    // Complete the cancellation future
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  /// Register a stream controller to be closed on cancellation
  void registerController(StreamController controller) {
    if (_isCancelled) {
      if (!controller.isClosed) {
        controller.close();
      }
      return;
    }
    _controllers.add(controller);
  }

  /// Register a timer to be cancelled on cancellation
  void registerTimer(Timer timer) {
    if (_isCancelled) {
      timer.cancel();
      return;
    }
    _timers.add(timer);
  }

  /// Throw if cancelled
  void throwIfCancelled() {
    if (_isCancelled) {
      throw CancelledException('Operation was cancelled');
    }
  }

  /// Check cancellation at an async boundary
  Future<void> checkCancellation() async {
    throwIfCancelled();
  }
}

/// Exception thrown when an operation is cancelled
class CancelledException implements Exception {
  final String message;

  CancelledException(this.message);

  @override
  String toString() => 'CancelledException: $message';
}

/// Registry for managing active cancellation tokens
class CancellationTokenRegistry {
  static final CancellationTokenRegistry instance = CancellationTokenRegistry._();
  CancellationTokenRegistry._();

  final Map<String, CancellationToken> _tokens = {};

  /// Create or get a cancellation token for a search session
  CancellationToken getOrCreate(String searchId) {
    // Cancel any existing token for this search ID
    _tokens[searchId]?.cancel();
    
    // Create new token
    final token = CancellationToken();
    _tokens[searchId] = token;
    
    return token;
  }

  /// Cancel a specific search
  void cancel(String searchId) {
    _tokens[searchId]?.cancel();
    _tokens.remove(searchId);
  }

  /// Cancel all active searches
  void cancelAll() {
    for (final token in _tokens.values) {
      token.cancel();
    }
    _tokens.clear();
  }

  /// Clean up completed tokens
  void cleanup() {
    _tokens.removeWhere((_, token) => token.isCancelled);
  }
}
