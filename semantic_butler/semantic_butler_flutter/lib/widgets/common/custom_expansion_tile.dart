import 'package:flutter/material.dart';

/// A custom expansion tile that avoids the `_ExpansibleState` type error
/// by implementing the expansion logic using standard AnimatedSize and Column.
class CustomExpansionTile extends StatefulWidget {
  final Widget title;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> children;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final EdgeInsetsGeometry? tilePadding;
  final EdgeInsetsGeometry? childrenPadding;
  final Color? backgroundColor;
  final Color? collapsedBackgroundColor;
  final ShapeBorder? shape;
  final ShapeBorder? collapsedShape;
  final Clip clipBehavior;
  final bool dense;
  final VisualDensity? visualDensity;

  const CustomExpansionTile({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.children = const <Widget>[],
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.tilePadding,
    this.childrenPadding,
    this.backgroundColor,
    this.collapsedBackgroundColor,
    this.shape,
    this.collapsedShape,
    this.clipBehavior = Clip.none,
    this.dense = false,
    this.visualDensity,
  });

  @override
  State<CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.fastOutSlowIn,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onExpansionChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: ShapeDecoration(
        color: _isExpanded
            ? (widget.backgroundColor ?? Colors.transparent)
            : (widget.collapsedBackgroundColor ?? Colors.transparent),
        shape: _isExpanded
            ? (widget.shape ?? const Border())
            : (widget.collapsedShape ?? const Border()),
      ),
      clipBehavior: widget.clipBehavior,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _handleTap,
            child: Padding(
              padding:
                  widget.tilePadding ??
                  const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  if (widget.leading != null) ...[
                    widget.leading!,
                    const SizedBox(width: 16),
                  ],
                  Expanded(child: widget.title),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 16),
                    RotationTransition(
                      turns: _iconTurns,
                      child: widget.trailing,
                    ),
                  ] else ...[
                    const SizedBox(width: 16),
                    RotationTransition(
                      turns: _iconTurns,
                      child: Icon(
                        Icons.expand_more,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            child: SizedBox(
              height: _isExpanded ? null : 0,
              child: Column(
                children: [
                  if (widget.childrenPadding != null)
                    Padding(
                      padding: widget.childrenPadding!,
                      child: Column(children: widget.children),
                    )
                  else
                    Column(children: widget.children),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
