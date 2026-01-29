import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';
import '../utils/app_logger.dart';

/// Provider for the real-time indexing status using AsyncNotifier
final indexingStatusProvider =
    AsyncNotifierProvider<IndexingStatusNotifier, IndexingStatus?>(
      IndexingStatusNotifier.new,
    );

class IndexingStatusNotifier extends AsyncNotifier<IndexingStatus?> {
  Timer? _pollingTimer;
  final Map<int, StreamSubscription> _jobSubscriptions = {};
  bool _isUpdatingSubscriptions = false;

  @override
  Future<IndexingStatus?> build() async {
    // Cleanup on dispose
    ref.onDispose(() {
      _stopPolling();
      _cancelAllSubscriptions();
    });

    // Start global polling
    _startPolling();

    // Initial load
    return await _fetchStatus();
  }

  void _startPolling() {
    _stopPolling();
    // Use a unified 5s poll, but we'll adjust work based on active jobs/streams
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final currentData = state.value;
      final hasActiveJobs =
          currentData?.activeJobs != null && currentData!.activeJobs > 0;
      final hasActiveStreams = _jobSubscriptions.isNotEmpty;

      if (!hasActiveJobs) {
        // When completely idle, poll much slower (every 30s)
        if (timer.tick % 6 != 0) return;
        refresh();
      } else if (!hasActiveStreams) {
        // If jobs are running but we don't have streams yet, poll every 5s
        refresh();
      } else {
        // If we have active streams, we can poll general status slower (every 15s)
        if (timer.tick % 3 == 0) {
          refresh();
        }
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _cancelAllSubscriptions() {
    for (final sub in _jobSubscriptions.values) {
      sub.cancel();
    }
    _jobSubscriptions.clear();
  }

  Future<void> refresh() async {
    // Skip refresh if already updating subscriptions to prevent race conditions
    if (_isUpdatingSubscriptions) {
      return;
    }

    state = await AsyncValue.guard(() async {
      final status = await _fetchStatus();
      if (status != null) {
        _updateJobSubscriptions(status);
      }
      return status;
    });
  }

  Future<IndexingStatus?> _fetchStatus() async {
    try {
      final apiClient = ref.read(clientProvider);
      return await apiClient.butler.getIndexingStatus();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load indexing status in provider: $e',
        tag: 'Provider',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  void _updateJobSubscriptions(IndexingStatus status) {
    if (status.recentJobs == null) return;

    // Prevent concurrent updates to avoid race conditions
    if (_isUpdatingSubscriptions) {
      AppLogger.debug('Skipping subscription update - already updating', tag: 'Provider');
      return;
    }

    _isUpdatingSubscriptions = true;
    try {
      final activeJobIds = status.recentJobs!
          .where((job) => job.status == 'running' && job.id != null)
          .map((job) => job.id!)
          .toSet();

      // Cancel subscriptions for jobs that are no longer running
      final jobsToCancel = _jobSubscriptions.keys
          .where((id) => !activeJobIds.contains(id))
          .toList();
      for (final id in jobsToCancel) {
        _jobSubscriptions[id]?.cancel();
        _jobSubscriptions.remove(id);
      }

      // Start subscriptions for new running jobs
      for (final id in activeJobIds) {
        if (!_jobSubscriptions.containsKey(id)) {
          final apiClient = ref.read(clientProvider);
          _jobSubscriptions[id] = apiClient.butler
              .streamIndexingProgress(id)
              .listen(
                (progress) {
                  _handleProgressUpdate(id, progress);
                },
                onError: (e) {
                  AppLogger.error(
                    'Stream error for job $id: $e',
                    tag: 'Provider',
                  );
                  _jobSubscriptions.remove(id)?.cancel();
                },
                onDone: () {
                  _jobSubscriptions.remove(id);
                  // Trigger refresh without race condition check
                  Future.microtask(() => _fetchStatus().then((status) {
                    if (status != null) {
                      state = AsyncData(status);
                    }
                  }));
                },
              );
        }
      }
    } finally {
      _isUpdatingSubscriptions = false;
    }
  }

  void _handleProgressUpdate(int jobId, IndexingProgress progress) {
    final currentData = state.value;
    if (currentData == null || currentData.recentJobs == null) return;

    // Update the specific job in the state for instant UI feedback
    final updatedJobs = currentData.recentJobs!.map((job) {
      if (job.id == jobId) {
        return job.copyWith(
          processedFiles: progress.processedFiles,
          totalFiles: progress.totalFiles,
          failedFiles: progress.failedFiles,
          skippedFiles: progress.skippedFiles,
          status: progress.status,
        );
      }
      return job;
    }).toList();

    state = AsyncData(currentData.copyWith(recentJobs: updatedJobs));
  }

  /// Optimistically update a job's status in the UI before server confirms
  /// Returns the previous state for rollback if needed
  IndexingStatus? optimisticUpdateJobStatus(int jobId, String newStatus) {
    final currentData = state.value;
    if (currentData == null || currentData.recentJobs == null) return null;

    final previousState = currentData;

    final updatedJobs = currentData.recentJobs!.map((job) {
      if (job.id == jobId) {
        return job.copyWith(status: newStatus);
      }
      return job;
    }).toList();

    // Update active jobs count if status changed to/from active
    int activeJobs = currentData.activeJobs;
    final job = currentData.recentJobs!.firstWhere(
      (j) => j.id == jobId,
      orElse: () => IndexingJob(
        folderPath: '',
        status: '',
        totalFiles: 0,
        processedFiles: 0,
        failedFiles: 0,
        skippedFiles: 0,
        startedAt: DateTime.now(),
      ),
    );

    final wasActive = job.status == 'running' || job.status == 'queued';
    final isActive = newStatus == 'running' || newStatus == 'queued';

    if (wasActive && !isActive) {
      activeJobs = (activeJobs - 1).clamp(0, activeJobs);
    } else if (!wasActive && isActive) {
      activeJobs++;
    }

    state = AsyncData(currentData.copyWith(
      recentJobs: updatedJobs,
      activeJobs: activeJobs,
    ));

    return previousState;
  }

  /// Rollback to a previous state (used when optimistic update fails)
  void rollback(IndexingStatus? previousState) {
    if (previousState != null) {
      state = AsyncData(previousState);
    }
  }

  /// Optimistically remove a job from the list (e.g., after cancellation)
  IndexingStatus? optimisticRemoveJob(int jobId) {
    final currentData = state.value;
    if (currentData == null || currentData.recentJobs == null) return null;

    final previousState = currentData;

    final updatedJobs = currentData.recentJobs!
        .where((job) => job.id != jobId)
        .toList();

    state = AsyncData(currentData.copyWith(
      recentJobs: updatedJobs,
      activeJobs: (currentData.activeJobs - 1).clamp(0, currentData.activeJobs),
    ));

    return previousState;
  }
}
