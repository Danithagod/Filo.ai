import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../../providers/indexing_status_provider.dart';
import '../../main.dart';

/// Floating overlay showing active indexing progress
class IndexingProgressOverlay extends ConsumerStatefulWidget {
  const IndexingProgressOverlay({super.key});

  @override
  ConsumerState<IndexingProgressOverlay> createState() =>
      _IndexingProgressOverlayState();
}

class _IndexingProgressOverlayState
    extends ConsumerState<IndexingProgressOverlay>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  bool _isDismissed = false;
  bool _isCancelling = false;
  late AnimationController _pulseController;

  // For ETA calculation
  final Map<int, _JobProgress> _jobProgressHistory = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(indexingStatusProvider);

    return statusAsync.when(
      data: (status) {
        if (status == null || _isDismissed) return const SizedBox.shrink();

        final activeJobs = status.recentJobs
                ?.where((j) => j.status == 'running')
                .toList() ??
            [];

        if (activeJobs.isEmpty) {
          // Reset dismissed state when no active jobs
          if (_isDismissed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isDismissed = false);
            });
          }
          return const SizedBox.shrink();
        }

        // Update progress history for ETA calculation
        for (final job in activeJobs) {
          _updateProgressHistory(job);
        }

        return _buildOverlay(context, activeJobs);
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  void _updateProgressHistory(IndexingJob job) {
    if (job.id == null) return;

    final history = _jobProgressHistory.putIfAbsent(
      job.id!,
      () => _JobProgress(),
    );

    final processed = job.processedFiles + job.failedFiles + job.skippedFiles;
    if (processed != history.lastProcessed) {
      history.timestamps.add(DateTime.now());
      history.processedCounts.add(processed);
      history.lastProcessed = processed;

      // Keep only last 10 data points for smoothing
      if (history.timestamps.length > 10) {
        history.timestamps.removeAt(0);
        history.processedCounts.removeAt(0);
      }
    }
  }

  Duration? _estimateTimeRemaining(IndexingJob job) {
    if (job.id == null || job.totalFiles == 0) return null;

    final history = _jobProgressHistory[job.id!];
    if (history == null || history.timestamps.length < 2) return null;

    final processed = job.processedFiles + job.failedFiles + job.skippedFiles;
    final remaining = job.totalFiles - processed;
    if (remaining <= 0) return null;

    // Calculate average rate from history
    final firstTime = history.timestamps.first;
    final lastTime = history.timestamps.last;
    final firstCount = history.processedCounts.first;
    final lastCount = history.processedCounts.last;

    final elapsedSeconds = lastTime.difference(firstTime).inSeconds;
    final processedInPeriod = lastCount - firstCount;

    if (elapsedSeconds <= 0 || processedInPeriod <= 0) return null;

    final filesPerSecond = processedInPeriod / elapsedSeconds;
    final secondsRemaining = remaining / filesPerSecond;

    return Duration(seconds: secondsRemaining.round());
  }

  Widget _buildOverlay(BuildContext context, List<IndexingJob> activeJobs) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Positioned(
      bottom: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isExpanded ? 320 : 56,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surfaceContainerHigh,
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _buildExpandedContent(
                context,
                activeJobs,
                colorScheme,
                textTheme,
              ),
              secondChild: _buildCollapsedContent(
                context,
                activeJobs,
                colorScheme,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    List<IndexingJob> activeJobs,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                        _pulseController.value,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Indexing in Progress',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _isDismissed = true),
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Job list
          ...activeJobs.map((job) => _buildJobProgress(
                context,
                job,
                colorScheme,
                textTheme,
              )),
        ],
      ),
    );
  }

  Widget _buildJobProgress(
    BuildContext context,
    IndexingJob job,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final processed = job.processedFiles + job.failedFiles + job.skippedFiles;
    final progress = job.totalFiles > 0 ? processed / job.totalFiles : 0.0;
    final eta = _estimateTimeRemaining(job);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Folder name
          Text(
            job.folderPath.split(RegExp(r'[/\\]')).last,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 4),

          // Stats row
          Row(
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$processed / ${job.totalFiles} files',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (eta != null)
                Text(
                  _formatDuration(eta),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),

          // Error/skip counts and cancel button
          Row(
            children: [
              if (job.failedFiles > 0) ...[
                Icon(
                  Icons.warning_amber_rounded,
                  size: 12,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 2),
                Text(
                  '${job.failedFiles} failed',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (job.skippedFiles > 0) ...[
                Icon(
                  Icons.skip_next,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 2),
                Text(
                  '${job.skippedFiles} skipped',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const Spacer(),
              // Cancel button
              if (job.id != null)
                _isCancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : InkWell(
                        onTap: () => _cancelJob(job.id!),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                size: 14,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Cancel',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancelJob(int jobId) async {
    setState(() => _isCancelling = true);

    // Optimistic update - immediately show cancelled state
    final previousState = ref
        .read(indexingStatusProvider.notifier)
        .optimisticUpdateJobStatus(jobId, 'cancelled');

    try {
      final client = ref.read(clientProvider);
      final success = await client.indexing.cancelJob(jobId);
      if (!success && mounted) {
        // Rollback if server rejected
        ref.read(indexingStatusProvider.notifier).rollback(previousState);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel job')),
        );
      }
    } catch (e) {
      // Rollback on error
      ref.read(indexingStatusProvider.notifier).rollback(previousState);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel job: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Widget _buildCollapsedContent(
    BuildContext context,
    List<IndexingJob> activeJobs,
    ColorScheme colorScheme,
  ) {
    // Calculate overall progress
    int totalProcessed = 0;
    int totalFiles = 0;
    for (final job in activeJobs) {
      totalProcessed +=
          job.processedFiles + job.failedFiles + job.skippedFiles;
      totalFiles += job.totalFiles;
    }
    final progress = totalFiles > 0 ? totalProcessed / totalFiles : 0.0;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '~${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '~${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '~${duration.inSeconds}s';
    }
  }
}

class _JobProgress {
  final List<DateTime> timestamps = [];
  final List<int> processedCounts = [];
  int lastProcessed = 0;
}
