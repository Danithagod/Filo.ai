import 'package:flutter/material.dart';

/// Model for a quick action chip
class QuickAction {
  final String label;
  final IconData icon;
  final String template;
  final String placeholder;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.template,
    required this.placeholder,
  });
}

/// Predefined quick actions for common queries
class QuickActions {
  static const List<QuickAction> defaultActions = [
    QuickAction(
      label: 'Find files',
      icon: Icons.search,
      template: 'Find files named ',
      placeholder: 'search term...',
    ),
    QuickAction(
      label: 'Search',
      icon: Icons.article_outlined,
      template: 'Search for ',
      placeholder: 'topic...',
    ),
    QuickAction(
      label: 'Summarize',
      icon: Icons.summarize_outlined,
      template: 'Summarize the file ',
      placeholder: 'file path or @tagged file',
    ),
    QuickAction(
      label: 'Organize',
      icon: Icons.folder_open,
      template: 'Help me organize ',
      placeholder: 'folder path...',
    ),
    QuickAction(
      label: 'Similar files',
      icon: Icons.link,
      template: 'Find files similar to ',
      placeholder: 'file path or @tagged file',
    ),
  ];
}

/// Horizontal scrollable list of quick action chips (collapsible)
class QuickActionChips extends StatefulWidget {
  final List<QuickAction> actions;
  final ValueChanged<String> onActionSelected;
  final String? Function()? getCurrentTaggedFile;
  final bool? isExpanded;
  final VoidCallback? onToggle;
  final bool showToggleButton;

  const QuickActionChips({
    super.key,
    this.actions = QuickActions.defaultActions,
    required this.onActionSelected,
    this.getCurrentTaggedFile,
    this.isExpanded,
    this.onToggle,
    this.showToggleButton = true,
  });

  @override
  State<QuickActionChips> createState() => _QuickActionChipsState();
}

class _QuickActionChipsState extends State<QuickActionChips> {
  bool _localIsExpanded = false;

  bool get _isExpanded => widget.isExpanded ?? _localIsExpanded;

  void _handleToggle() {
    if (widget.onToggle != null) {
      widget.onToggle!();
    } else {
      setState(() {
        _localIsExpanded = !_localIsExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Toggle Button (Optional)
        if (widget.showToggleButton)
          IconButton(
            onPressed: _handleToggle,
            icon: Icon(
              _isExpanded ? Icons.close : Icons.add_circle_outline,
              size: 20,
              color: colorScheme.primary,
            ),
            tooltip: _isExpanded ? 'Hide actions' : 'Quick actions',
            visualDensity: VisualDensity.compact,
          ),

        // Collapsible Content
        Expanded(
          child: AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: widget.actions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final action = widget.actions[index];
                  return _QuickActionChip(
                    action: action,
                    onTap: () => _handleAction(action),
                  );
                },
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }

  void _handleAction(QuickAction action) {
    String template = action.template;

    // If there's a tagged file available, append it automatically
    final taggedFile = widget.getCurrentTaggedFile?.call();
    if (taggedFile != null) {
      template += '$taggedFile ';
    }

    widget.onActionSelected(template);
  }
}

class _QuickActionChip extends StatelessWidget {
  final QuickAction action;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                action.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal divider for quick actions section
class QuickActionDivider extends StatelessWidget {
  final VoidCallback? onToggleCollapse;
  final bool isCollapsed;

  const QuickActionDivider({
    super.key,
    this.onToggleCollapse,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          if (onToggleCollapse != null)
            InkWell(
              onTap: onToggleCollapse,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  isCollapsed ? Icons.expand_more : Icons.expand_less,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Quick actions',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Expanded(
            child: Divider(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
