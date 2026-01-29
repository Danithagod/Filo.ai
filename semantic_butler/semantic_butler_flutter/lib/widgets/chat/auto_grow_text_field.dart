import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text field that automatically grows based on content
/// Min lines specified, max lines clamped to prevent overflow
class AutoGrowTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final bool obscureText;

  const AutoGrowTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.minLines = 1,
    this.maxLines = 6,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.hintText,
    this.hintStyle,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.obscureText = false,
  });

  @override
  State<AutoGrowTextField> createState() => _AutoGrowTextFieldState();
}

class _AutoGrowTextFieldState extends State<AutoGrowTextField> {
  late int _currentMaxLines;

  @override
  void initState() {
    super.initState();
    _currentMaxLines = widget.minLines;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(AutoGrowTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final newLineCount = '\n'.allMatches(text).length + 1;

    // Calculate new max lines based on content
    final newMaxLines = (newLineCount.clamp(widget.minLines, widget.maxLines));

    if (newMaxLines != _currentMaxLines) {
      setState(() {
        _currentMaxLines = newMaxLines;
      });
    }

    widget.onChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      maxLines: _currentMaxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType ?? TextInputType.multiline,
      inputFormatters: widget.inputFormatters,
      obscureText: widget.obscureText,
      textInputAction: TextInputAction.newline,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle:
            widget.hintStyle ??
            theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        prefixIcon: widget.prefixIcon,
      ),
      textAlignVertical: TextAlignVertical.top,
    );
  }
}
