import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';
import '../utils/app_logger.dart';

/// Provider for the real-time indexing status
final indexingStatusProvider =
    NotifierProvider<IndexingStatusNotifier, IndexingStatus?>(
      IndexingStatusNotifier.new,
    );

class IndexingStatusNotifier extends Notifier<IndexingStatus?> {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  Timer? _pollingTimer;

  @override
  IndexingStatus? build() {
    // Start initial load
    Future.microtask(() => refresh());

    // Start global polling
    _startPolling();

    // Cleanup on dispose
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    return null;
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (state == null || state!.activeJobs > 0) {
        // Accelerate polling if jobs are running, or we haven't loaded yet
        if (state?.activeJobs != null &&
            state!.activeJobs > 0 &&
            timer.tick % 2 != 0) {
          // Poll every 2.5s effectively when active (tick is 5s, but we can do logic here)
          // Actually let's just make it simpler: use 5s base, but we can call refresh more often if needed
        }
        refresh();
      } else {
        // Less frequent polling when idle
        if (timer.tick % 6 == 0) {
          // Every 30 seconds when idle
          refresh();
        }
      }
    });
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final status = await client.butler.getIndexingStatus();
      state = status;
    } catch (e) {
      AppLogger.error(
        'Failed to load indexing status in provider: $e',
        tag: 'Provider',
      );
    } finally {
      _isLoading = false;
    }
  }
}
