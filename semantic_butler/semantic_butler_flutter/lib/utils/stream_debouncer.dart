import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debouncer for streaming updates to reduce UI rebuilds
/// Buffers updates and only triggers callback after delay period
class StreamDebouncer {
  final Duration delay;
  Timer? _timer;
  String _latestValue = '';
  VoidCallback? _callback;
  bool _disposed = false;

  StreamDebouncer({required this.delay});

  /// Debounce a callback with the latest value
  void debounce(String value, VoidCallback callback) {
    if (_disposed) return;

    _latestValue = value;
    _callback = callback;

    _timer?.cancel();
    _timer = Timer(delay, _flush);
  }

  /// Flush any pending content immediately
  void flush() {
    if (_disposed) return;
    _timer?.cancel();
    _flush();
  }

  void _flush() {
    if (_disposed || _callback == null) return;

    _callback!();
    _callback = null;
  }

  /// Get latest value
  String get content => _latestValue;

  /// Clear without triggering callback
  void clear() {
    _latestValue = '';
    _callback = null;
    _timer?.cancel();
  }

  /// Check if there's a pending notification
  bool get hasPending => _callback != null;

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _latestValue = '';
    _callback = null;
  }
}

/// Value notifier that only notifies after debounce period
/// Useful for streaming text updates
class DebouncedValueNotifier extends ValueNotifier<String> {
  final Duration debounceDelay;
  Timer? _debounceTimer;
  String _pendingValue = '';
  bool _disposed = false;

  DebouncedValueNotifier(
    super.initialValue, {
    this.debounceDelay = const Duration(milliseconds: 75),
  });

  @override
  set value(String newValue) {
    if (_disposed) return;

    _pendingValue = newValue;
    _debounceTimer?.cancel();

    _debounceTimer = Timer(debounceDelay, () {
      if (_disposed) return;
      super.value = _pendingValue;
    });
  }

  /// Force immediate update without debouncing
  void updateImmediately(String newValue) {
    if (_disposed) return;
    _debounceTimer?.cancel();
    _pendingValue = newValue;
    super.value = newValue;
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Manages debouncing for multiple message streams
/// Each stream ID has its own debouncer
class MultiStreamDebouncer {
  final Duration delay;
  final Map<String, StreamDebouncer> _debouncers = {};

  MultiStreamDebouncer({required this.delay});

  /// Debounce a specific stream
  void debounce(String streamId, String text, VoidCallback callback) {
    _debouncers.putIfAbsent(streamId, () => StreamDebouncer(delay: delay));
    _debouncers[streamId]!.debounce(text, callback);
  }

  /// Flush a specific stream
  void flush(String streamId) {
    _debouncers[streamId]?.flush();
  }

  /// Flush all streams
  void flushAll() {
    for (final debouncer in _debouncers.values) {
      debouncer.flush();
    }
  }

  /// Remove a stream debouncer
  void remove(String streamId) {
    _debouncers[streamId]?.dispose();
    _debouncers.remove(streamId);
  }

  /// Clear all debouncers
  void clear() {
    for (final debouncer in _debouncers.values) {
      debouncer.dispose();
    }
    _debouncers.clear();
  }

  void dispose() {
    clear();
  }
}
