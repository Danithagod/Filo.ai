import 'package:flutter/material.dart';
import '../../models/chat/tool_result.dart';
import 'tool_result_card.dart';

class ToolResultBadge extends StatefulWidget {
  final List<ToolResult> results;
  final bool isStreaming;
  final String? statusMessage;

  const ToolResultBadge({
    super.key,
    required this.results,
    this.isStreaming = false,
    this.statusMessage,
  });

  @override
  State<ToolResultBadge> createState() => _ToolResultBadgeState();
}

class _ToolResultBadgeState extends State<ToolResultBadge> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty && !widget.isStreaming) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine aggregate state
    final hasError = widget.results.any((r) => !r.success);

    // Status color
    final statusColor = widget.isStreaming
        ? colorScheme.primary
        : hasError
        ? colorScheme.error
        : colorScheme.secondary;

    // Status text
    String statusText;
    if (widget.isStreaming) {
      statusText = widget.statusMessage ?? 'Processing...';
    } else if (hasError) {
      final failCount = widget.results.where((r) => !r.success).length;
      statusText = '$failCount action${failCount > 1 ? 's' : ''} failed';
    } else {
      final count = widget.results.length;
      statusText = '$count action${count > 1 ? 's' : ''} completed';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge Header
        InkWell(
          onTap: () {
            if (widget.results.isNotEmpty) {
              setState(() => _isExpanded = !_isExpanded);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                if (widget.isStreaming)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: statusColor,
                    ),
                  )
                else
                  Icon(
                    hasError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                    color: statusColor,
                  ),

                const SizedBox(width: 8),

                // Text
                Text(
                  statusText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Expand/Collapse caret (if we have results)
                if (widget.results.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: statusColor.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Expanded Details
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.results
                  .map(
                    (res) => ToolResultCard(
                      result: res,
                      isUser:
                          false, // Always render as assistant content inside badge
                    ),
                  )
                  .toList(),
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}
