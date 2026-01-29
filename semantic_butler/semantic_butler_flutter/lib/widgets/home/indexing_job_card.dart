import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../../providers/watched_folders_provider.dart';
import '../../theme/app_theme.dart';

/// Card displaying indexing job information
class IndexingJobCard extends ConsumerStatefulWidget {
  final IndexingJob job;

  const IndexingJobCard({super.key, required this.job});

  @override
  ConsumerState<IndexingJobCard> createState() => _IndexingJobCardState();
}

class _IndexingJobCardState extends ConsumerState<IndexingJobCard> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final job = widget.job;

    final watchedFoldersAsync = ref.watch(watchedFoldersProvider);
    final watchedFolders = watchedFoldersAsync.value ?? [];
    final isSmartIndexing = watchedFolders.any(
      (f) => f.path == job.folderPath && f.isEnabled,
    );

    final isRunning = job.status == 'running';
    final isFailed = job.status == 'failed';

    // Calculate progress
    double progress = 0.0;
    if (job.totalFiles > 0) {
      progress =
          (job.processedFiles + job.failedFiles + job.skippedFiles) /
          job.totalFiles;
      if (progress > 1.0) progress = 1.0;
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isRunning
                        ? colorScheme.primaryContainer
                        : isFailed
                        ? colorScheme.errorContainer
                        : (Theme.of(context).brightness == Brightness.dark
                                  ? AppTheme.successColorDark
                                  : AppTheme.successColor)
                              .withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRunning
                        ? Icons.sync
                        : isFailed
                        ? Icons.error_outline
                        : Icons.check,
                    size: 20,
                    color: isRunning
                        ? colorScheme.onPrimaryContainer
                        : isFailed
                        ? colorScheme.onErrorContainer
                        : (Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.successColorDark
                              : AppTheme.successColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.folderPath.split(Platform.pathSeparator).last,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        job.folderPath,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    job.status.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (isRunning || progress > 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${job.processedFiles}/${job.totalFiles} files',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                borderRadius: BorderRadius.circular(4),
              ),
            ],

            if (isFailed && job.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                job.errorMessage!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Error Stats Summary (show if there are failed or skipped files)
            if (job.failedFiles > 0 || job.skippedFiles > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (job.failedFiles > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${job.failedFiles} failed',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (job.failedFiles > 0 && job.skippedFiles > 0)
                    const SizedBox(width: 8),
                  if (job.skippedFiles > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.skip_next_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${job.skippedFiles} skipped',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],

            // Smart Indexing Toggle
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isSmartIndexing
                      ? Icons.visibility_rounded
                      : Icons.visibility_outlined,
                  size: 18,
                  color: isSmartIndexing
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSmartIndexing ? 'Smart Indexing On' : 'Smart Indexing',
                    style: textTheme.bodyMedium?.copyWith(
                      color: isSmartIndexing
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isSmartIndexing ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                _isToggling
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Switch.adaptive(
                        value: isSmartIndexing,
                        onChanged: (value) =>
                            _toggleSmartIndexing(job.folderPath),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSmartIndexing(String folderPath) async {
    setState(() => _isToggling = true);
    try {
      await ref.read(watchedFoldersProvider.notifier).toggle(folderPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle smart indexing: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }
}
