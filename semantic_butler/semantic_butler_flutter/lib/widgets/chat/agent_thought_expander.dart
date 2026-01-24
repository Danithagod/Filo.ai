import 'package:flutter/material.dart';

class AgentThoughtExpander extends StatefulWidget {
  final List<String> thoughts;
  final bool isStreaming;

  const AgentThoughtExpander({
    super.key,
    required this.thoughts,
    this.isStreaming = false,
  });

  @override
  State<AgentThoughtExpander> createState() => _AgentThoughtExpanderState();
}

class _AgentThoughtExpanderState extends State<AgentThoughtExpander> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.thoughts.isEmpty && !widget.isStreaming) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If streaming and we have thoughts, maybe show "Thinking..." with indicator
    // If completed and we have thoughts, show "View thought process"

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(
                Icons.psychology,
                size: 16.0,
                color: widget.isStreaming
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8.0),
              Flexible(
                child: Text(
                  widget.isStreaming ? 'Thinking...' : 'Reasoning Process',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: widget.isStreaming
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isStreaming) ...[
                const SizedBox(width: 8.0),
                SizedBox(
                  width: 10.0,
                  height: 10.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (value) => setState(() => _isExpanded = value),
          visualDensity: VisualDensity.compact,
          dense: true,
          shape: const Border(), // Remove default borders
          children: [
            ...widget.thoughts.map(
              (thought) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, right: 8.0),
                      child: Icon(
                        Icons.arrow_right,
                        size: 16.0,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        thought,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                          fontSize: 12.0,
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
}
