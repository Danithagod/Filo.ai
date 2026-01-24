import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../providers/organization_provider.dart';
import '../widgets/organization/confirmation_dialogs.dart';
import '../main.dart';
import '../utils/app_logger.dart';
import 'package:path/path.dart' as p;

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
      final apiClient = ref.read(clientProvider);
      final suggestions = await apiClient.butler.getOrganizationSuggestions();
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

  Future<void> _handleQuickFixAll() async {
    if (_suggestions == null) return;

    final namingCount = _suggestions!.namingIssues.length;
    final duplicateCount = _suggestions!.duplicates.length;
    final totalSavings = _suggestions!.potentialSavingsBytes;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 12),
            Expanded(child: Text('Quick Fix All')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will apply the following organization improvements in one step:',
            ),
            const SizedBox(height: 16),
            if (namingCount > 0)
              ListTile(
                dense: true,
                leading: const Icon(Icons.text_fields, color: Colors.blue),
                title: Text('Fix $namingCount naming issues'),
                subtitle: const Text(
                  'Spaces, case-consistency, and invalid characters',
                ),
              ),
            if (duplicateCount > 0)
              ListTile(
                dense: true,
                leading: const Icon(Icons.file_copy, color: Colors.red),
                title: Text('Resolve $duplicateCount duplicate groups'),
                subtitle: Text(
                  'Estimated space savings: ${_formatBytes(totalSavings)}',
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'All duplicate resolutions will keep the version with the shortest path.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              foregroundColor: Theme.of(context).colorScheme.onTertiary,
            ),
            child: const Text('Apply All Improvements'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final container = ProviderScope.containerOf(context);
      final notifier = container.read(organizationProvider.notifier);

      final actions = <OrganizationActionRequest>[];

      // Add naming fix actions
      for (final issue in _suggestions!.namingIssues) {
        final oldPaths = <String>[];
        final newNames = <String>[];
        for (final path in issue.affectedFiles) {
          oldPaths.add(path);
          newNames.add(_suggestNewName(p.basename(path), issue.issueType));
        }
        actions.add(
          OrganizationActionRequest(
            actionType: 'fix_naming',
            renameOldPaths: oldPaths,
            renameNewNames: newNames,
          ),
        );
      }

      // Add duplicate resolution actions
      for (final group in _suggestions!.duplicates) {
        final keep = group.files.reduce(
          (a, b) => a.path.length < b.path.length ? a : b,
        );
        final delete = group.files
            .where((f) => f.path != keep.path)
            .map((f) => f.path)
            .toList();

        actions.add(
          OrganizationActionRequest(
            actionType: 'resolve_duplicates',
            contentHash: group.contentHash,
            keepFilePath: keep.path,
            deleteFilePaths: delete,
          ),
        );
      }

      final result = await notifier.applyBatch(
        BatchOrganizationRequest(actions: actions, rollbackOnError: true),
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully completed ${result.successCount} organization actions.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadSuggestions();
      }
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
    final orgState = ref.watch(organizationProvider);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_fix_high,
                      color: colorScheme.primary,
                      size: 32,
                    ),
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
                    if (_suggestions != null &&
                        (_suggestions!.duplicates.isNotEmpty ||
                            _suggestions!.namingIssues.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilledButton.icon(
                          onPressed: _handleQuickFixAll,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Quick Fix All'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.tertiary,
                            foregroundColor: colorScheme.onTertiary,
                          ),
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
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(
                    icon: Badge(
                      label: Text(
                        '${_suggestions?.duplicates.length ?? 0}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      isLabelVisible:
                          (_suggestions?.duplicates.length ?? 0) > 0,
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
                      isLabelVisible:
                          (_suggestions?.namingIssues.length ?? 0) > 0,
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
          if (orgState.isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing organization...'),
                        Text(
                          'This may take a few moments',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
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

    return Column(
      children: [
        if (duplicates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      _handleResolveAllDuplicates(context, duplicates),
                  icon: const Icon(Icons.cleaning_services),
                  label: Text('Resolve All ${duplicates.length} Groups'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            key: const PageStorageKey<String>('duplicates_list'),
            padding: const EdgeInsets.all(16),
            itemCount: duplicates.length,
            itemBuilder: (context, index) {
              final group = duplicates[index];
              return _DuplicateGroupCard(
                group: group,
                formatBytes: _formatBytes,
                onRefresh: _loadSuggestions,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleResolveAllDuplicates(
    BuildContext context,
    List<DuplicateGroup> groups,
  ) async {
    final savings = groups.fold<int>(
      0,
      (sum, g) => sum + g.potentialSavingsBytes,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resolve All ${groups.length} Groups'),
        content: Text(
          'This will keep one copy of each file and move all other copies to trash.\n\n'
          'Estimated space savings: ${_formatBytes(savings)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Resolve All Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final container = ProviderScope.containerOf(context);
    final notifier = container.read(organizationProvider.notifier);

    final actions = groups.map((group) {
      // Simple strategy: keep the one with the shortest path
      final keep = group.files.reduce(
        (a, b) => a.path.length < b.path.length ? a : b,
      );
      final delete = group.files
          .where((f) => f.path != keep.path)
          .map((f) => f.path)
          .toList();

      return OrganizationActionRequest(
        actionType: 'resolve_duplicates',
        contentHash: group.contentHash,
        keepFilePath: keep.path,
        deleteFilePaths: delete,
      );
    }).toList();

    final result = await notifier.applyBatch(
      BatchOrganizationRequest(actions: actions, rollbackOnError: true),
    );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully resolved ${result.successCount} duplicate groups.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadSuggestions();
    }
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

    return Column(
      children: [
        if (issues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: () => _handleFixAllNaming(context, issues),
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text('Fix All ${issues.length} Issues'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            key: const PageStorageKey<String>('naming_issues_list'),
            padding: const EdgeInsets.all(16),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              return _NamingIssueCard(
                issue: issue,
                onRefresh: _loadSuggestions,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleFixAllNaming(
    BuildContext context,
    List<NamingIssue> issues,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => FixNamingDialog(issues: issues),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final container = ProviderScope.containerOf(context);
    final notifier = container.read(organizationProvider.notifier);

    final oldPaths = <String>[];
    final newNames = <String>[];

    for (final issue in issues) {
      for (final path in issue.affectedFiles) {
        oldPaths.add(path);
        newNames.add(_suggestNewName(p.basename(path), issue.issueType));
      }
    }

    final actionResult = await notifier.fixNamingIssues(
      oldPaths: oldPaths,
      newNames: newNames,
    );

    if (actionResult != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully fixed ${actionResult.successCount} naming issues.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadSuggestions();
    }
  }

  String _suggestNewName(String name, String issueType) {
    switch (issueType) {
      case 'spaces_in_name':
        return name.replaceAll(' ', '_');
      case 'invalid_characters':
        return name.replaceAll(RegExp(r'[<>:"|?*]'), '');
      case 'inconsistent_case':
        return name.toLowerCase().replaceAll(' ', '_');
      default:
        return name;
    }
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
      key: const PageStorageKey<String>('similar_content_list'),
      padding: const EdgeInsets.all(16),
      itemCount: similar.length,
      itemBuilder: (context, index) {
        final group = similar[index];
        return _SimilarContentCard(
          group: group,
          onRefresh: _loadSuggestions,
        );
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
  final VoidCallback onRefresh;

  const _DuplicateGroupCard({
    required this.group,
    required this.formatBytes,
    required this.onRefresh,
  });

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
        children: [
          ...group.files.map((file) {
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
          }),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _handleResolve(context),
                  icon: const Icon(Icons.cleaning_services, size: 18),
                  label: const Text('Resolve Duplicates'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleResolve(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ResolveDuplicatesDialog(group: group),
    );

    if (result != null && context.mounted) {
      final container = ProviderScope.containerOf(context);
      final notifier = container.read(organizationProvider.notifier);

      final actionResult = await notifier.resolveDuplicates(
        contentHash: group.contentHash,
        keepFilePath: result['keep'],
        deleteFilePaths: result['delete'],
      );

      if (actionResult != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully deleted ${actionResult.successCount} duplicates. '
              'Saved ${formatBytes(actionResult.spaceSavedBytes)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh analysis
        onRefresh();
      }
    }
  }
}

class _NamingIssueCard extends StatelessWidget {
  final NamingIssue issue;
  final VoidCallback onRefresh;

  const _NamingIssueCard({required this.issue, required this.onRefresh});

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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _handleFix(context),
                  icon: const Icon(Icons.spellcheck, size: 18),
                  label: const Text('Fix Naming'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFix(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => FixNamingDialog(issues: [issue]),
    );

    if (confirmed == true && context.mounted) {
      final container = ProviderScope.containerOf(context);
      final notifier = container.read(organizationProvider.notifier);

      // Calculate suggested names
      final newNames = issue.affectedFiles.map((path) {
        final oldName = p.basename(path);
        return _suggestNewName(oldName, issue.issueType);
      }).toList();

      final actionResult = await notifier.fixNamingIssues(
        oldPaths: issue.affectedFiles,
        newNames: newNames,
      );

      if (actionResult != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully renamed ${actionResult.successCount} files.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh analysis
        onRefresh();
      }
    }
  }

  String _suggestNewName(String name, String issueType) {
    switch (issueType) {
      case 'spaces_in_name':
        return name.replaceAll(' ', '_');
      case 'invalid_characters':
        return name.replaceAll(RegExp(r'[<>:"|?*]'), '');
      case 'inconsistent_case':
        // Fallback or generic suggestion
        return name.toLowerCase().replaceAll(' ', '_');
      default:
        return name;
    }
  }
}

class _SimilarContentCard extends StatelessWidget {
  final SimilarContentGroup group;
  final VoidCallback onRefresh;

  const _SimilarContentCard({required this.group, required this.onRefresh});

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
        children: [
          ...group.files.map((file) {
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
          }),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _handleOrganize(context),
                  icon: const Icon(Icons.folder_shared, size: 18),
                  label: const Text('Organize Into Folder'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOrganize(BuildContext context) async {
    final targetFolder = await showDialog<String>(
      context: context,
      builder: (context) => OrganizeSimilarDialog(group: group),
    );

    if (targetFolder != null && context.mounted) {
      final container = ProviderScope.containerOf(context);
      final notifier = container.read(organizationProvider.notifier);

      final actionResult = await notifier.organizeSimilarFiles(
        filePaths: group.files.map((f) => f.path).toList(),
        targetFolder: targetFolder,
      );

      if (actionResult != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully organized ${actionResult.successCount} files into $targetFolder.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh analysis
        onRefresh();
      }
    }
  }
}
