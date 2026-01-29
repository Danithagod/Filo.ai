import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../../main.dart';
import 'dart:io';

class IndexingDiagnosticsDialog extends ConsumerWidget {
  final int jobId;
  final String folderPath;

  const IndexingDiagnosticsDialog({
    super.key,
    required this.jobId,
    required this.folderPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final folderName = folderPath.split(Platform.pathSeparator).last;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.analytics_outlined, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text('Diagnostics: $folderName')),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 400,
        child: FutureBuilder<List<IndexingJobDetail>>(
          future: ref.read(clientProvider).indexing.getJobDetails(jobId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final details = snapshot.data ?? [];
            if (details.isEmpty) {
              return const Center(
                child: Text('No detailed logs available yet.'),
              );
            }

            return ListView.separated(
              itemCount: details.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final detail = details[index];
                final fileName = detail.filePath
                    .split(Platform.pathSeparator)
                    .last;

                return ListTile(
                  dense: true,
                  leading: _getStatusIcon(detail.status, colorScheme),
                  title: Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.filePath,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      if (detail.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            detail.errorMessage!,
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Text(
                    detail.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(detail.status, colorScheme),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _getStatusIcon(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'complete':
        return Icon(Icons.check_circle, color: colorScheme.tertiary, size: 20);
      case 'failed':
        return Icon(Icons.error, color: colorScheme.error, size: 20);
      case 'skipped':
        return Icon(Icons.skip_next, color: colorScheme.secondary, size: 20);
      case 'extracting':
      case 'embedding':
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      default:
        return Icon(
          Icons.help_outline,
          color: colorScheme.onSurfaceVariant,
          size: 20,
        );
    }
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'complete':
        return colorScheme.tertiary;
      case 'failed':
        return colorScheme.error;
      case 'skipped':
        return colorScheme.secondary;
      case 'extracting':
      case 'embedding':
        return colorScheme.primary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }
}
