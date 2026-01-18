import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../utils/app_logger.dart';
import '../utils/file_content_loader.dart';
import '../providers/navigation_provider.dart';
import '../widgets/file_manager/summary_dialog.dart';

/// Preview pane for search results showing file content and actions
class SearchResultPreview extends ConsumerStatefulWidget {
  final String title;
  final String path;
  final double relevanceScore;
  final List<String> tags;

  const SearchResultPreview({
    super.key,
    required this.title,
    required this.path,
    required this.relevanceScore,
    required this.tags,
  });

  @override
  ConsumerState<SearchResultPreview> createState() =>
      _SearchResultPreviewState();
}

class _SearchResultPreviewState extends ConsumerState<SearchResultPreview> {
  String? _content;
  bool _isLoading = false;
  FileStat? _stats;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void didUpdateWidget(SearchResultPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _loadPreview();
    }
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isLoading = true;
      _content = null;
      _stats = null;
    });

    try {
      final file = File(widget.path);
      if (await file.exists()) {
        final stats = await file.stat();
        final content = await FileContentLoader.loadFileContent(widget.path);

        if (mounted) {
          setState(() {
            _stats = stats;
            _content = content;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _content = "File not found at: ${widget.path}";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _content = "Error loading preview: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openFile() async {
    try {
      final uri = Uri.file(widget.path);
      await launchUrl(uri);
    } catch (e) {
      AppLogger.error("Failed to open file: $e");
    }
  }

  void _askAssistant() {
    ref
        .read(navigationProvider.notifier)
        .navigateToChatWithContext(
          ChatNavigationContext(
            filePath: widget.path,
            fileName: widget.title,
            initialMessage: 'Tell me about this file: ${widget.title}',
          ),
        );
  }

  Future<void> _summarize() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating summary...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final summaryJson = await client.butler.summarizeFile(widget.path);
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      showDialog(
        context: context,
        builder: (dialogContext) => SummaryDialog(
          fileName: widget.title,
          summaryJson: summaryJson,
          onAskAssistant: _askAssistant,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Summarization failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: _openFile,
                      tooltip: 'Open with System App',
                    ),
                  ],
                ),
                Text(
                  widget.path,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _askAssistant,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Ask AI'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _summarize,
                    icon: const Icon(Icons.summarize_outlined, size: 18),
                    label: const Text('Summarize'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content Preview
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_stats != null) ...[
                          _MetadataRow(
                            label: 'Size',
                            value:
                                '${(_stats!.size / 1024).toStringAsFixed(1)} KB',
                            icon: Icons.sd_card_outlined,
                          ),
                          _MetadataRow(
                            label: 'Modified',
                            value: _stats!.modified.toString().split('.')[0],
                            icon: Icons.history,
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'PREVIEW',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _content ?? 'No content available for preview.',
                            style: textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetadataRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
