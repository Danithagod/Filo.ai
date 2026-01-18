import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../main.dart';
import '../utils/app_logger.dart';

/// Screen for displaying file organization suggestions.
/// Shows duplicates, naming issues, and similar content groups.
class OrganizationScreen extends ConsumerStatefulWidget {
  const OrganizationScreen({super.key});

  @override
  ConsumerState<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends ConsumerState<OrganizationScreen>
    with SingleTickerProviderStateMixin {
  OrganizationSuggestions? _suggestions;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSuggestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final suggestions = await client.butler.getOrganizationSuggestions();
      if (!mounted) return;
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load organization suggestions',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Icon(Icons.auto_fix_high, color: colorScheme.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Organization',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'AI-powered suggestions to organize your files',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _loadSuggestions,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Analysis',
                ),
              ],
            ),
          ),

          // Stats Summary
          if (_suggestions != null && !_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildStatsSummary(),
            ),

          const SizedBox(height: 16),

          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: Badge(
                  label: Text(
                    '${_suggestions?.duplicates.length ?? 0}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  isLabelVisible: (_suggestions?.duplicates.length ?? 0) > 0,
                  child: const Icon(Icons.file_copy_outlined),
                ),
                text: 'Duplicates',
              ),
              Tab(
                icon: Badge(
                  label: Text(
                    '${_suggestions?.namingIssues.length ?? 0}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  isLabelVisible: (_suggestions?.namingIssues.length ?? 0) > 0,
                  child: const Icon(Icons.text_fields),
                ),
                text: 'Naming',
              ),
              Tab(
                icon: Badge(
                  label: Text(
                    '${_suggestions?.similarContent.length ?? 0}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  isLabelVisible:
                      (_suggestions?.similarContent.length ?? 0) > 0,
                  child: const Icon(Icons.compare),
                ),
                text: 'Similar',
              ),
            ],
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDuplicatesTab(),
                      _buildNamingTab(),
                      _buildSimilarTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    final colorScheme = Theme.of(context).colorScheme;

    final suggestions = _suggestions!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.description,
                label: 'Files Analyzed',
                value: '${suggestions.totalFilesAnalyzed}',
                color: colorScheme.primary,
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: _StatItem(
                icon: Icons.storage,
                label: 'Potential Savings',
                value: _formatBytes(suggestions.potentialSavingsBytes),
                color: colorScheme.tertiary,
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: _StatItem(
                icon: Icons.schedule,
                label: 'Last Analyzed',
                value: _formatTime(suggestions.analyzedAt),
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  Widget _buildErrorState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Failed to analyze files',
            style: TextStyle(color: colorScheme.error),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: _loadSuggestions,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicatesTab() {
    final duplicates = _suggestions?.duplicates ?? [];
    if (duplicates.isEmpty) {
      return _buildEmptyState(
        Icons.check_circle_outline,
        'No Duplicates Found',
        'Your files are unique!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: duplicates.length,
      itemBuilder: (context, index) {
        final group = duplicates[index];
        return _DuplicateGroupCard(
          group: group,
          formatBytes: _formatBytes,
        );
      },
    );
  }

  Widget _buildNamingTab() {
    final issues = _suggestions?.namingIssues ?? [];
    if (issues.isEmpty) {
      return _buildEmptyState(
        Icons.check_circle_outline,
        'No Naming Issues',
        'Your file names follow consistent conventions!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        return _NamingIssueCard(issue: issue);
      },
    );
  }

  Widget _buildSimilarTab() {
    final similar = _suggestions?.similarContent ?? [];
    if (similar.isEmpty) {
      return _buildEmptyState(
        Icons.check_circle_outline,
        'No Similar Content',
        'No semantically similar documents found.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: similar.length,
      itemBuilder: (context, index) {
        final group = similar[index];
        return _SimilarContentCard(group: group);
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(title, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DuplicateGroupCard extends StatelessWidget {
  final DuplicateGroup group;
  final String Function(int) formatBytes;

  const _DuplicateGroupCard({required this.group, required this.formatBytes});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.file_copy,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
        ),
        title: Text('${group.fileCount} duplicate files'),
        subtitle: Text(
          'Save ${formatBytes(group.potentialSavingsBytes)}',
          style: TextStyle(
            color: colorScheme.tertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: group.files.map((file) {
          return ListTile(
            dense: true,
            leading: Icon(
              Icons.insert_drive_file,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            title: Text(
              file.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              file.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Text(
              formatBytes(file.sizeBytes),
              style: textTheme.labelSmall,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NamingIssueCard extends StatelessWidget {
  final NamingIssue issue;

  const _NamingIssueCard({required this.issue});

  Color _getSeverityColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (issue.severity) {
      case 'error':
        return colorScheme.error;
      case 'warning':
        return Colors.orange;
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final severityColor = _getSeverityColor(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: severityColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.warning_amber, color: severityColor, size: 20),
        ),
        title: Text(issue.description),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                issue.severity.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: severityColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${issue.affectedCount} files'),
          ],
        ),
        children: [
          if (issue.suggestedFix != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: colorScheme.tertiary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Suggestion: ${issue.suggestedFix}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ...issue.affectedFiles.take(5).map((path) {
            return ListTile(
              dense: true,
              leading: Icon(
                Icons.insert_drive_file,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              title: Text(
                path.split('/').last.split('\\').last,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }),
          if (issue.affectedFiles.length > 5)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '...and ${issue.affectedFiles.length - 5} more files',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SimilarContentCard extends StatelessWidget {
  final SimilarContentGroup group;

  const _SimilarContentCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.compare,
            color: colorScheme.onSecondaryContainer,
            size: 20,
          ),
        ),
        title: Text('${group.fileCount} similar files'),
        subtitle: Text(
          '${(group.similarityScore * 100).toStringAsFixed(0)}% similarity',
          style: TextStyle(color: colorScheme.secondary),
        ),
        children: group.files.map((file) {
          return ListTile(
            dense: true,
            leading: Icon(
              Icons.insert_drive_file,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            title: Text(
              file.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (file.contentPreview != null &&
                    file.contentPreview!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      file.contentPreview!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
