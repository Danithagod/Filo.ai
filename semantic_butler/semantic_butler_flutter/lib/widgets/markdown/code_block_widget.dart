import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:highlight/highlight.dart' show Node;
import '../../utils/syntax_highlighter.dart';

/// Widget for displaying code blocks with syntax highlighting
class CodeBlockWidget extends StatefulWidget {
  final String code;
  final String? language;
  final bool initiallyExpanded;

  const CodeBlockWidget({
    super.key,
    required this.code,
    this.language,
    this.initiallyExpanded = true,
  });

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  late bool _isExpanded;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayLanguage = AppSyntaxHighlighter.getDisplayName(
      widget.language ?? '',
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with language and actions
          _buildHeader(context, displayLanguage, colorScheme),

          // Code content
          if (_isExpanded)
            _buildCodeContent(context, colorScheme)
          else
            _buildCollapsedPreview(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String language,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          // Language indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              language,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          // Line count
          Text(
            '$_lineCount lines',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          // Copy button
          _ActionButton(
            icon: _isCopied ? Icons.check : Icons.copy,
            label: _isCopied ? 'Copied!' : 'Copy',
            onPressed: _copyToClipboard,
          ),
          const SizedBox(width: 4),
          // Expand/collapse button
          _ActionButton(
            icon: _isExpanded ? Icons.expand_less : Icons.expand_more,
            label: _isExpanded ? 'Collapse' : 'Expand',
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeContent(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _HighlightedCodeView(
        code: widget.code,
        language: widget.language ?? '',
      ),
    );
  }

  Widget _buildCollapsedPreview(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        _getPreview(),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  int get _lineCount {
    return '\n'.allMatches(widget.code).length + 1;
  }

  String _getPreview() {
    final lines = widget.code.split('\n');
    final previewLines = lines.take(3).join('\n');
    if (lines.length > 3) {
      return '$previewLines\n...';
    }
    return previewLines;
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal widget for rendering highlighted code
class _HighlightedCodeView extends StatelessWidget {
  final String code;
  final String language;

  const _HighlightedCodeView({
    required this.code,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final nodes = AppSyntaxHighlighter.parse(code, language);

    if (nodes == null) {
      return _buildRawCode(context);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SelectableText.rich(
        TextSpan(
          style: _baseStyle(context),
          children: nodes.map((node) => _buildSpan(context, node)).toList(),
        ),
      ),
    );
  }

  Widget _buildRawCode(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SelectableText(
        code,
        style: _baseStyle(context),
      ),
    );
  }

  TextStyle _baseStyle(BuildContext context) {
    return TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      height: 1.5,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  InlineSpan _buildSpan(BuildContext context, Node node) {
    if (node.children == null || node.children!.isEmpty) {
      return TextSpan(
        text: node.value,
        style: TextStyle(
          color: AppSyntaxHighlighter.getColorForType(node.className, context),
        ),
      );
    }

    return TextSpan(
      children: node.children!
          .map((child) => _buildSpan(context, child))
          .toList(),
      style: TextStyle(
        color: AppSyntaxHighlighter.getColorForType(node.className, context),
      ),
    );
  }
}

/// Parser for extracting code blocks from markdown text
class MarkdownCodeParser {
  static final _codeBlockRegex = RegExp(
    r'```(\w*)\n([\s\S]*?)```',
    multiLine: true,
  );

  /// Parse markdown and extract code blocks
  static List<MarkdownBlock> parse(String markdown) {
    final blocks = <MarkdownBlock>[];
    int lastIndex = 0;

    for (final match in _codeBlockRegex.allMatches(markdown)) {
      // Add text before code block
      if (match.start > lastIndex) {
        final text = markdown.substring(lastIndex, match.start);
        if (text.trim().isNotEmpty) {
          blocks.add(
            MarkdownBlock(type: MarkdownBlockType.text, content: text),
          );
        }
      }

      // Add code block
      final language = match.group(1)?.trim() ?? '';
      final code = match.group(2) ?? '';
      blocks.add(
        MarkdownBlock(
          type: MarkdownBlockType.code,
          content: code,
          language: language.isEmpty ? 'plaintext' : language,
        ),
      );

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < markdown.length) {
      final text = markdown.substring(lastIndex);
      if (text.trim().isNotEmpty) {
        blocks.add(MarkdownBlock(type: MarkdownBlockType.text, content: text));
      }
    }

    // If no code blocks found, treat entire content as text
    if (blocks.isEmpty && markdown.trim().isNotEmpty) {
      blocks.add(
        MarkdownBlock(
          type: MarkdownBlockType.text,
          content: markdown,
        ),
      );
    }

    return blocks;
  }

  /// Check if content contains code blocks
  static bool hasCodeBlocks(String markdown) {
    return _codeBlockRegex.hasMatch(markdown);
  }
}

/// Types of markdown blocks
enum MarkdownBlockType { text, code }

/// Represents a block of markdown content
class MarkdownBlock {
  final MarkdownBlockType type;
  final String content;
  final String? language;

  MarkdownBlock({
    required this.type,
    required this.content,
    this.language,
  });

  @override
  String toString() =>
      'MarkdownBlock(type: $type, length: ${content.length}, language: $language)';
}
