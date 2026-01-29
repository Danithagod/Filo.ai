import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../utils/app_logger.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';

/// Dashboard for monitoring and maintaining index health
class IndexHealthDashboard extends ConsumerStatefulWidget {
  const IndexHealthDashboard({super.key});

  @override
  ConsumerState<IndexHealthDashboard> createState() =>
      _IndexHealthDashboardState();
}

class _IndexHealthDashboardState extends ConsumerState<IndexHealthDashboard> {
  bool _isLoading = true;
  IndexHealthReport? _healthReport;
  bool _isFixing = false;

  @override
  void initState() {
    super.initState();
    _loadHealthReport();
  }

  Future<void> _loadHealthReport() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(clientProvider);
      final report = await apiClient.butler.getIndexHealthReport();
      if (mounted) {
        setState(() {
          _healthReport = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load health report: $e', tag: 'IndexHealth');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cleanupOrphaned() async {
    if (!mounted) return;
    setState(() => _isFixing = true);

    try {
      final apiClient = ref.read(clientProvider);
      final count = await apiClient.butler.cleanupOrphanedFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleaned up $count orphaned file(s)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadHealthReport();
      }
    } catch (e) {
      AppLogger.error(
        'Failed to cleanup orphaned files: $e',
        tag: 'IndexHealth',
      );
    } finally {
      if (mounted) {
        setState(() => _isFixing = false);
      }
    }
  }

  Future<void> _refreshStale() async {
    if (!mounted) return;
    setState(() => _isFixing = true);

    try {
      final apiClient = ref.read(clientProvider);
      final count = await apiClient.butler.refreshStaleEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Queued $count stale file(s) for re-indexing'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadHealthReport();
      }
    } catch (e) {
      AppLogger.error(
        'Failed to refresh stale entries: $e',
        tag: 'IndexHealth',
      );
    } finally {
      if (mounted) {
        setState(() => _isFixing = false);
      }
    }
  }

  Future<void> _removeDuplicates() async {
    if (!mounted) return;
    setState(() => _isFixing = true);

    try {
      final apiClient = ref.read(clientProvider);
      final count = await apiClient.butler.removeDuplicates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed $count duplicate file(s)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadHealthReport();
      }
    } catch (e) {
      AppLogger.error('Failed to remove duplicates: $e', tag: 'IndexHealth');
    } finally {
      if (mounted) {
        setState(() => _isFixing = false);
      }
    }
  }

  Future<void> _fixMissingEmbeddings() async {
    if (!mounted) return;
    setState(() => _isFixing = true);

    try {
      final apiClient = ref.read(clientProvider);
      final count = await apiClient.butler.fixMissingEmbeddings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Queued $count file(s) for embedding generation'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadHealthReport();
      }
    } catch (e) {
      AppLogger.error(
        'Failed to fix missing embeddings: $e',
        tag: 'IndexHealth',
      );
    } finally {
      if (mounted) {
        setState(() => _isFixing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      child: SizedBox(
        width: 900,
        height: 700,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.health_and_safety, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'Index Health Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loadHealthReport,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _healthReport == null
                  ? const Center(child: Text('Failed to load health report'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Health score
                          _buildHealthScore(),
                          const SizedBox(height: 24),

                          // Statistics
                          _buildStatistics(),
                          const SizedBox(height: 24),

                          // Issues
                          _buildIssuesSection(),
                          const SizedBox(height: 24),

                          // Actions
                          if (!_isFixing) _buildActionsSection(),
                          if (_isFixing)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 16),
                                    Text('Fixing issues...'),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScore() {
    final healthScore = _healthReport?.healthScore ?? 0.0;
    final colorScheme = Theme.of(context).colorScheme;

    Color scoreColor;
    IconData scoreIcon;
    String scoreLabel;

    if (healthScore >= 90) {
      scoreColor = colorScheme.tertiary;
      scoreIcon = Icons.check_circle;
      scoreLabel = 'Excellent';
    } else if (healthScore >= 70) {
      scoreColor = colorScheme.secondary;
      scoreIcon = Icons.warning;
      scoreLabel = 'Good';
    } else if (healthScore >= 50) {
      scoreColor = colorScheme.secondary.withValues(alpha: 0.8);
      scoreIcon = Icons.error_outline;
      scoreLabel = 'Fair';
    } else {
      scoreColor = colorScheme.error;
      scoreIcon = Icons.cancel;
      scoreLabel = 'Poor';
    }

    return Card(
      color: scoreColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(scoreIcon, size: 64, color: scoreColor),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Score',
                    style: TextStyle(
                      fontSize: 16,
                      color: scoreColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${healthScore.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    scoreLabel,
                    style: TextStyle(
                      fontSize: 18,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final report = _healthReport;
    if (report == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Indexed',
                report.totalIndexed,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Pending',
                report.totalPending,
                Icons.hourglass_empty,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard('Failed', report.totalFailed, Icons.error),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Embeddings',
                report.totalEmbeddings,
                Icons.memory,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesSection() {
    final report = _healthReport;
    if (report == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Issues Found',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildIssueCard(
          'Orphaned Files',
          report.orphanedFiles.length,
          Icons.broken_image,
          'Files in index that no longer exist on disk',
        ),
        const SizedBox(height: 8),
        _buildIssueCard(
          'Stale Entries',
          report.staleEntryCount,
          Icons.schedule,
          'Files not updated in over 6 months',
        ),
        const SizedBox(height: 8),
        _buildIssueCard(
          'Duplicate Files',
          report.duplicateFileCount,
          Icons.content_copy,
          'Files with identical content',
        ),
        const SizedBox(height: 8),
        _buildIssueCard(
          'Missing Embeddings',
          report.missingEmbeddingsCount,
          Icons.memory,
          'Indexed files without embeddings',
        ),
      ],
    );
  }

  Widget _buildIssueCard(
    String title,
    int count,
    IconData icon,
    String description,
  ) {
    final hasIssue = count > 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: hasIssue
          ? colorScheme.errorContainer.withValues(alpha: 0.3)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasIssue
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: hasIssue
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    final report = _healthReport;
    if (report == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (report.orphanedFiles.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _cleanupOrphaned,
                icon: const Icon(Icons.cleaning_services, size: 18),
                label: const Text('Cleanup Orphaned'),
              ),
            if (report.staleEntryCount > 0)
              OutlinedButton.icon(
                onPressed: _refreshStale,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Stale'),
              ),
            if (report.duplicateFileCount > 0)
              OutlinedButton.icon(
                onPressed: _removeDuplicates,
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('Remove Duplicates'),
              ),
            if (report.missingEmbeddingsCount > 0)
              OutlinedButton.icon(
                onPressed: _fixMissingEmbeddings,
                icon: const Icon(Icons.build, size: 18),
                label: const Text('Fix Embeddings'),
              ),
          ],
        ),
      ],
    );
  }
}
