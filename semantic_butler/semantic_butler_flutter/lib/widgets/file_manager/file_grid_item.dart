import 'package:flutter/material.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../../utils/file_display_helper.dart';

/// Grid view item for a file or folder
class FileGridItem extends StatefulWidget {
  final FileSystemEntry entry;
  final VoidCallback onTap;
  final VoidCallback onContextMenu;
  final bool isHighlighted;

  const FileGridItem({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onContextMenu,
    this.isHighlighted = false,
  });

  @override
  State<FileGridItem> createState() => _FileGridItemState();
}

class _FileGridItemState extends State<FileGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onSecondaryTap: widget.onContextMenu,
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Card(
            elevation: _isHovered ? 4 : 1,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: widget.isHighlighted
                    ? colorScheme.primary
                    : (_isHovered
                          ? colorScheme.primary.withValues(alpha: 0.3)
                          : colorScheme.outlineVariant.withValues(alpha: 0.3)),
                width: widget.isHighlighted ? 2.5 : (_isHovered ? 1.5 : 1),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icon Area
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.entry.isDirectory
                                ? colorScheme.primaryContainer.withValues(
                                    alpha: 0.3,
                                  )
                                : colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                          ),
                          child: Center(
                            child: Icon(
                              widget.entry.isDirectory
                                  ? Icons.folder_rounded
                                  : FileDisplayHelper.getIconForFile(
                                      widget.entry.name,
                                    ),
                              size: 56,
                              color: widget.entry.isDirectory
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.8,
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // Info Area
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              widget.entry.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.entry.isDirectory
                                  ? 'Folder'
                                  : FileDisplayHelper.formatSize(
                                      widget.entry.size,
                                    ),
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Indexed Badge
                  if (widget.entry.isIndexed)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.bolt_rounded,
                          size: 12,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),

                  // Context Menu Button (visible on hover)
                  if (_isHovered)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        onPressed: widget.onContextMenu,
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
