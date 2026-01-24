import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../../main.dart';
import '../../providers/watched_folders_provider.dart';
import '../../utils/app_logger.dart';
import '../common/shimmer_effect.dart';

/// Compact card for displaying indexing job in either grid or list mode
class CompactIndexCard extends ConsumerStatefulWidget {
  final IndexingJob job;
  final Future<void> Function()? onRefresh;
  final bool isListView;

  const CompactIndexCard({
    super.key,
    required this.job,
    this.onRefresh,
    this.isListView = false,
  });

  /// Factory-like static method to create a skeleton placeholder
  static Widget skeleton({required bool isListView}) {
    return _CompactIndexCardSkeleton(isListView: isListView);
  }

  @override
  ConsumerState<CompactIndexCard> createState() => _CompactIndexCardState();
}

class _CompactIndexCardState extends ConsumerState<CompactIndexCard> {
  bool _isRefreshing = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return widget.isListView ? _buildListLayout() : _buildGridLayout();
  }

  Widget _buildGridLayout() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final job = widget.job;

    // Use selector to avoid rebuilds when other folders change
    final isSmartIndexing = ref.watch(
      isFolderSmartlyWatchedProvider(job.folderPath),
    );

    final bool isRunning = job.status == 'running' || job.status == 'queued';
    final bool isFailed = job.status == 'failed';
    final bool isCompleted = job.status == 'completed';

    final accentColor = isRunning
        ? colorScheme.primary
        : isFailed
        ? colorScheme.error
        : colorScheme.secondary;

    final folderName = job.folderPath.split(Platform.pathSeparator).last;

    double progress = 0;
    if (job.totalFiles > 0) {
      progress = (job.processedFiles + job.skippedFiles) / job.totalFiles;
      if (progress > 1.0) progress = 1.0;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Card(
          elevation: _isHovered ? 4 : 1,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isHovered
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: _isHovered ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isRunning ? null : _refreshIndex,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon Area
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.folder_rounded,
                                size: 56,
                                color: colorScheme.primary,
                              ),

                              // Success Checkmark
                              if (isCompleted)
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorScheme.surface,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                              // failure Cross
                              if (isFailed)
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Tooltip(
                                    message:
                                        job.errorMessage ?? 'Indexing failed',
                                    child: Container(
                                      padding: const EdgeInsets.all(1.5),
                                      decoration: BoxDecoration(
                                        color: colorScheme.error,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colorScheme.surface,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Info Area
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            folderName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.totalFiles == 0
                                ? 'No files'
                                : '${job.totalFiles} files',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Sleek bottom-edge progress bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: (isRunning || progress > 0) && !isCompleted
                        ? 1.0
                        : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 30 / 255),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: accentColor,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 100 / 255),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Indexed Badge (Bolt icon) - Top Left
                if (isSmartIndexing)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.bolt_rounded,
                        size: 12,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),

                // Refresh/Actions Button (visible on hover)
                if (!isRunning)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert_rounded, size: 18),
                      onPressed: _isRefreshing
                          ? null
                          : () => _showOptionsMenu(context),
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surface.withValues(
                          alpha: 0.8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                // Grid Mode Loading Overlay
                if (_isRefreshing)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Processing...',
                              style: textTheme.labelSmall?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListLayout() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final job = widget.job;

    // Use selector to avoid rebuilds when other folders change
    final isSmartIndexing = ref.watch(
      isFolderSmartlyWatchedProvider(job.folderPath),
    );

    final bool isRunning = job.status == 'running' || job.status == 'queued';
    final bool isFailed = job.status == 'failed';
    final bool isCompleted = job.status == 'completed';

    final accentColor = isRunning
        ? colorScheme.primary
        : isFailed
        ? colorScheme.error
        : colorScheme.secondary;

    final folderName = job.folderPath.split(Platform.pathSeparator).last;

    double progress = 0.0;
    if (job.totalFiles > 0) {
      progress = (job.processedFiles + job.skippedFiles) / job.totalFiles;
      if (progress > 1.0) progress = 1.0;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _isHovered
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? colorScheme.outlineVariant.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: isRunning ? null : _refreshIndex,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer.withValues(
                              alpha: isFailed ? 0.3 : 1.0,
                            ),
                            colorScheme.primaryContainer.withValues(
                              alpha: isFailed ? 0.2 : 0.7,
                            ),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _isHovered
                            ? [
                                BoxShadow(
                                  color: colorScheme.shadow.withValues(
                                    alpha: 0.05,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.folder_rounded,
                            color: isFailed
                                ? colorScheme.error
                                : colorScheme.primary,
                            size: 26,
                          ),
                          if (isCompleted)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          if (isFailed)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: colorScheme.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Name and Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            folderName,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                job.totalFiles == 0
                                    ? 'No files'
                                    : '${job.totalFiles} files',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.3),
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  job.folderPath,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Actions / Status Badge
                    if (isCompleted || isSmartIndexing || isFailed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isFailed
                                      ? colorScheme.error
                                      : colorScheme.primary)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                (isFailed
                                        ? colorScheme.error
                                        : colorScheme.primary)
                                    .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFailed
                                  ? Icons.error_outline_rounded
                                  : (isSmartIndexing
                                        ? Icons.visibility_rounded
                                        : Icons.bolt_rounded),
                              size: 14,
                              color: isFailed
                                  ? colorScheme.error
                                  : colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isFailed
                                  ? 'failed'
                                  : (isSmartIndexing ? 'Smart' : 'Indexed'),
                              style: textTheme.labelSmall?.copyWith(
                                color: isFailed
                                    ? colorScheme.error
                                    : colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                      ),
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                      onPressed: _isRefreshing
                          ? null
                          : () => _showOptionsMenu(context),
                      tooltip: 'Options',
                    ),
                  ],
                ),
              ),

              // Sleek bottom-edge progress bar for list row
              Positioned(
                bottom: 0,
                left: 12,
                right: 12,
                child: AnimatedOpacity(
                  opacity: (isRunning || progress > 0) && !isCompleted
                      ? 1.0
                      : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(1),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // List Mode Loading Overlay
              if (_isRefreshing)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Processing...',
                            style: textTheme.labelSmall?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final folderName = widget.job.folderPath.split(Platform.pathSeparator).last;
    final isRunning =
        widget.job.status == 'running' || widget.job.status == 'queued';

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      folderName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Actions
            ListTile(
              leading: Icon(
                Icons.refresh_rounded,
                color: isRunning
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.primary,
              ),
              title: const Text('Re-index Folder'),
              enabled: !isRunning,
              onTap: () {
                Navigator.pop(context);
                _refreshIndex();
              },
            ),

            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text(
                'Remove from Index',
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmRemoveFromIndex();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemoveFromIndex() async {
    final folderName = widget.job.folderPath.split(Platform.pathSeparator).last;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Remove'),
        content: Text(
          'Are you sure you want to remove "$folderName" from the index? This will delete all semantic data for this folder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (result == true) {
      _removeFromIndex();
    }
  }

  Future<void> _removeFromIndex() async {
    setState(() => _isRefreshing = true);
    try {
      AppLogger.info(
        'Removing folder from index: ${widget.job.folderPath}',
        tag: 'CompactIndexCard',
      );
      final apiClient = ref.read(clientProvider);
      await apiClient.butler.removeFromIndex(path: widget.job.folderPath);

      // Small delay to ensure DB sync before refresh (safety measure)
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await widget.onRefresh?.call();
      }
    } catch (e) {
      AppLogger.error(
        'Failed to remove from index: $e',
        tag: 'CompactIndexCard',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove from index: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _refreshIndex() async {
    setState(() => _isRefreshing = true);
    try {
      AppLogger.info(
        'Re-indexing folder: ${widget.job.folderPath}',
        tag: 'CompactIndexCard',
      );
      final apiClient = ref.read(clientProvider);
      await apiClient.butler.startIndexing(widget.job.folderPath);
      if (mounted) {
        await widget.onRefresh?.call();
      }
    } catch (e) {
      AppLogger.error('Failed to re-index: $e', tag: 'CompactIndexCard');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to re-index: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }
}

/// Internal skeleton component for CompactIndexCard
class _CompactIndexCardSkeleton extends StatelessWidget {
  final bool isListView;

  const _CompactIndexCardSkeleton({required this.isListView});

  @override
  Widget build(BuildContext context) {
    if (isListView) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            const SizedBox().asSkeleton(width: 32, height: 32, borderRadius: 8),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox().asSkeleton(
                    width: 120,
                    height: 12,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  const SizedBox().asSkeleton(
                    width: 60,
                    height: 8,
                    borderRadius: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const SizedBox().asSkeleton(
              width: 24,
              height: 24,
              borderRadius: 12,
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ShimmerEffect(
              child: Container(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const SizedBox().asSkeleton(
                  width: 80,
                  height: 12,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                const SizedBox().asSkeleton(
                  width: 40,
                  height: 8,
                  borderRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
