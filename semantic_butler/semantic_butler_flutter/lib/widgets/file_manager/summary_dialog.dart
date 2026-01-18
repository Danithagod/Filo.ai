import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog to display AI-generated file summary
///
/// Shows a hierarchical summary with brief, medium, and detailed levels.
/// Provides options to copy the summary or ask the AI assistant about the file.
class SummaryDialog extends StatefulWidget {
  /// The name of the file being summarized
  final String fileName;

  /// JSON string containing the summary data
  final String summaryJson;

  /// Callback to navigate to chat with file context
  final VoidCallback? onAskAssistant;

  const SummaryDialog({
    super.key,
    required this.fileName,
    required this.summaryJson,
    this.onAskAssistant,
  });

  @override
  State<SummaryDialog> createState() => _SummaryDialogState();
}

class _SummaryDialogState extends State<SummaryDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _summaryData;
  String? _parseError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _parseSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _parseSummary() {
    try {
      _summaryData = jsonDecode(widget.summaryJson) as Map<String, dynamic>;
    } catch (e) {
      _parseError = 'Failed to parse summary: $e';
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.summarize_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.fileName,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Error state
            if (_parseError != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _parseError!,
                      style: TextStyle(color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else ...[
              // Tabs
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Brief'),
                  Tab(text: 'Medium'),
                  Tab(text: 'Detailed'),
                ],
              ),

              // Truncation warning
              if (_summaryData?['isTruncated'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: This document is very large. The summary is based on the first part of the file.',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(
                      _summaryData?['briefSummary'] ?? 'No summary available',
                    ),
                    _buildSummaryTab(
                      _summaryData?['mediumSummary'] ?? 'No summary available',
                    ),
                    _buildSummaryTab(
                      _summaryData?['detailedSummary'] ??
                          'No summary available',
                    ),
                  ],
                ),
              ),

              // Metadata
              if (_summaryData != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetadataChip(
                        Icons.article_outlined,
                        '${_summaryData!['wordCount'] ?? 0} words',
                      ),
                      _buildMetadataChip(
                        Icons.compress,
                        '${((_summaryData!['compressionRatio'] ?? 1.0) * 100).toStringAsFixed(0)}% compressed',
                      ),
                      _buildMetadataChip(
                        Icons.layers_outlined,
                        '${_summaryData!['chunkCount'] ?? 1} chunks',
                      ),
                    ],
                  ),
                ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        final currentTab = _tabController.index;
                        String text;
                        switch (currentTab) {
                          case 0:
                            text = _summaryData?['briefSummary'] ?? '';
                            break;
                          case 1:
                            text = _summaryData?['mediumSummary'] ?? '';
                            break;
                          case 2:
                          default:
                            text = _summaryData?['detailedSummary'] ?? '';
                        }
                        _copyToClipboard(text);
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                    ),
                    const SizedBox(width: 8),
                    if (widget.onAskAssistant != null)
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onAskAssistant!();
                        },
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Ask Assistant'),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(String content) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        content,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildMetadataChip(IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
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
