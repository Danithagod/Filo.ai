import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Material 3 styled search result card
class SearchResultCard extends StatelessWidget {
  final String title;
  final String path;
  final String preview;
  final double relevanceScore;
  final List<String> tags;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? highlightQuery;
  final bool showCheckbox;
  final bool isChecked;
  final ValueChanged<bool?>? onCheckChanged;

  const SearchResultCard({
    super.key,
    required this.title,
    required this.path,
    required this.preview,
    required this.relevanceScore,
    required this.tags,
    this.isSelected = false,
    this.onTap,
    this.highlightQuery,
    this.showCheckbox = false,
    this.isChecked = false,
    this.onCheckChanged,
  });

  /// Build a TextSpan with highlighted query terms
  TextSpan _buildHighlightedText(
    String text,
    TextStyle? baseStyle,
    Color highlightColor,
  ) {
    if (highlightQuery == null || highlightQuery!.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    // Extract search terms (split by spaces, remove common operators)
    final terms = highlightQuery!
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2 && !{'and', 'or', 'not', 'the', 'for'}.contains(t))
        .toList();

    if (terms.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    // Build regex pattern for all terms
    final pattern = terms.map((t) => RegExp.escape(t)).join('|');
    final regex = RegExp('($pattern)', caseSensitive: false);

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }
      // Add highlighted match
      spans.add(TextSpan(
        text: match.group(0),
        style: baseStyle?.copyWith(
          backgroundColor: highlightColor.withValues(alpha: 0.3),
          fontWeight: FontWeight.w600,
        ),
      ));
      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans);
  }

  Future<void> _openFile(BuildContext context) async {
    try {
      // Use Uri.file with strict parsing or join to handle special characters (Issue 20)
      final uri = Uri.file(path, windows: true);

      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        _showErrorDialog(
          context,
          'Cannot Open File',
          'The system could not open the file. It might be missing or there is no application associated with this type.\n\nPath: $path',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(
          context,
          'Error Opening File',
          'An error occurred while trying to open the file.\n\n$e',
        );
      }
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error_outline, color: colorScheme.error),
        title: Text(title),
        content: SelectableText(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show dialog with all tags when user clicks "show more"
  void _showAllTags(BuildContext context, List<String> allTags) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.label_outline, color: colorScheme.primary),
        title: const Text('All Tags'),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allTags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Cache calculations for performance (Issue 7.2)
    final fileIcon = _getFileIcon(title);
    final fileColor = _getFileColor(title);
    final scoreColor = _getScoreColor(relevanceScore);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () => _openFile(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Checkbox for bulk selection
                  if (showCheckbox) ...[
                    Checkbox(
                      value: isChecked,
                      onChanged: onCheckChanged,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                  ],
                  // File icon in container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: fileColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      fileIcon,
                      color: fileColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and path
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          path,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Relevance badge with accessibility label (Issue 19)
                  Semantics(
                    label:
                        'Relevance score: ${(relevanceScore * 100).toInt()}%',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${(relevanceScore * 100).toInt()}%',
                        style: textTheme.labelMedium?.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Preview text with query highlighting
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 12),
                RichText(
                  text: _buildHighlightedText(
                    preview,
                    textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    colorScheme.primary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Tags with "show more" indicator
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...tags
                        .take(5)
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    // Show "more" indicator if there are additional tags
                    if (tags.length > 5)
                      ActionChip(
                        label: Text('+${tags.length - 5} more'),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onPressed: () => _showAllTags(context, tags),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart':
      case 'js':
      case 'ts':
      case 'py':
      case 'java':
      case 'c':
      case 'cpp':
      case 'cs':
      case 'go':
      case 'rs':
      case 'swift':
      case 'kt':
        return Icons.code;
      case 'md':
      case 'txt':
      case 'log':
        return Icons.article;
      case 'json':
      case 'yaml':
      case 'yml':
      case 'xml':
      case 'html':
      case 'css':
        return Icons.data_object;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
      case 'webp':
        return Icons.image;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'ogg':
        return Icons.audiotrack;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return Icons.movie;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart':
        return const Color(0xFF00B4AB);
      case 'js':
      case 'ts':
        return const Color(0xFFF7DF1E);
      case 'py':
        return const Color(0xFF3776AB);
      case 'md':
        return const Color(0xFF6750A4);
      case 'json':
        return const Color(0xFF7C4DFF);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return const Color(0xFF22C55E);
    if (score >= 0.6) return const Color(0xFF84CC16);
    if (score >= 0.4) return const Color(0xFFEAB308);
    return const Color(0xFFF97316);
  }
}
