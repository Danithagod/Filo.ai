import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_logger.dart';
import 'code_block_widget.dart';
import '../../utils/background_processor.dart';

/// Custom markdown renderer that handles code blocks with syntax highlighting
class MarkdownBodyWidget extends StatelessWidget {
  final String content;
  final Color? textColor;
  final TextStyle? baseTextStyle;

  const MarkdownBodyWidget({
    super.key,
    required this.content,
    this.textColor,
    this.baseTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Check if content has code blocks
    if (MarkdownCodeParser.hasCodeBlocks(content)) {
      return _MarkdownWithCodeBlocks(
        widget: this,
        content: content,
      );
    }

    // No code blocks, use standard markdown renderer
    return MarkdownBody(
      data: content,
      styleSheet: _buildStyleSheet(context, textColor),

      selectable: true,
      onTapLink: (text, href, title) {
        // Handle link taps
        _launchLink(context, href ?? text);
      },
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context, Color? textColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final defaultStyle = theme.textTheme.bodyMedium?.copyWith(
      color: textColor ?? colorScheme.onSurface,
      height: 1.5,
    );
    // Use baseTextStyle if provided, otherwise defaultStyle
    final pStyle = baseTextStyle ?? defaultStyle;

    return MarkdownStyleSheet(
      // Text styles
      p: pStyle,
      // Headers
      h1: theme.textTheme.headlineMedium?.copyWith(
        color: textColor ?? colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      h2: theme.textTheme.titleLarge?.copyWith(
        color: textColor ?? colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      h3: theme.textTheme.titleMedium?.copyWith(
        color: textColor ?? colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      h4: theme.textTheme.titleSmall?.copyWith(
        color: textColor ?? colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      h5: theme.textTheme.bodyLarge?.copyWith(
        color: textColor ?? colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      h6: theme.textTheme.bodyLarge?.copyWith(
        color: textColor ?? colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      // Emphasis
      em: theme.textTheme.bodyMedium?.copyWith(
        color: textColor ?? colorScheme.onSurface,
        fontStyle: FontStyle.italic,
      ),
      strong: theme.textTheme.bodyMedium?.copyWith(
        color: textColor ?? colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      // Lists
      listBullet: theme.textTheme.bodyMedium?.copyWith(
        color: textColor ?? colorScheme.onSurface,
      ),
      // Blockquote
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: colorScheme.outlineVariant,
            width: 3,
          ),
        ),
      ),
      // Code (inline)
      code: theme.textTheme.bodyMedium
          ?.copyWith(
            fontFamily: 'monospace',
            fontSize: 13,
            color: colorScheme.primary,
            backgroundColor: colorScheme.primaryContainer.withValues(
              alpha: 0.3,
            ),
          )
          .copyWith(
            fontFamily: 'monospace',
          ),
      codeblockDecoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      // Links
      a: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      // Tables
      tableHead: theme.textTheme.titleSmall?.copyWith(
        color: textColor ?? colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      tableBody: theme.textTheme.bodyMedium?.copyWith(
        color: textColor ?? colorScheme.onSurface,
      ),
      tableBorder: TableBorder.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        width: 1,
      ),
      // Block spacing
      blockSpacing: 8.0,
      listIndent: 24.0,
    );
  }

  Future<void> _launchLink(BuildContext context, String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch: $url')),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error launching URL: $e');
    }
  }
}

/// Markdown renderer that handles code blocks separately
class _MarkdownWithCodeBlocks extends StatelessWidget {
  final MarkdownBodyWidget widget;
  final String content;

  const _MarkdownWithCodeBlocks({
    required this.widget,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: BackgroundProcessor().parseMarkdown(content),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Fallback to standard markdown if parsing fails
          return MarkdownBody(
            data: content,
            styleSheet: widget._buildStyleSheet(context, widget.textColor),
            selectable: true,
            onTapLink: (text, href, title) =>
                widget._launchLink(context, href ?? text),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox(height: 20);
        }

        final blocks = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: blocks.map((block) {
            final type = block['type'];
            final content = block['content'] ?? '';
            final language = block['language'];

            if (type == 'code') {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: CodeBlockWidget(
                  code: content,
                  language: language,
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: MarkdownBody(
                data: content,
                styleSheet: widget._buildStyleSheet(context, widget.textColor),
                selectable: true,
                onTapLink: (text, href, title) =>
                    widget._launchLink(context, href ?? text),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
