import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/chat/tool_result.dart';
import '../../../providers/navigation_provider.dart';

/// Widget to display semantic/grep search results
class SearchToolResult extends ConsumerWidget {
  final ToolResult result;
  final ThemeData theme;

  const SearchToolResult({
    super.key,
    required this.result,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    List<dynamic> items = [];
    String? error;

    try {
      final json = jsonDecode(result.result);
      if (json is Map && json.containsKey('results')) {
        items = json['results'] as List;
      } else if (json is List) {
        items = json;
      }
    } catch (e) {
      error = 'Failed to parse search results';
    }

    if (error != null || items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          error ?? 'No results found',
          style: textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Limit to 5 items to avoid blowing up the UI
    final displayItems = items.take(5).toList();
    final remainingCount = items.length - 5;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayItems.map((item) {
            final path = item['path'] ?? item['fullPath'] ?? '';
            final score = item['score'];
            final name = item['fileName'] ?? path.split(RegExp(r'[\\/]')).last;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  if (path.isNotEmpty) {
                    ref
                        .read(navigationProvider.notifier)
                        .navigateToFilesWithTarget(path);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: textTheme.titleSmall?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (path.isNotEmpty)
                              Text(
                                path,
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (score != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(score * 100).toInt()}%',
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (remainingCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                '+ $remainingCount more results...',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
