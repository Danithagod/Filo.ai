import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// Attachment type for chat messages
enum AttachmentType {
  image,
  document,
  other,
}

/// Model for file attachments in chat
class ChatAttachment {
  final String filePath;
  final String fileName;
  final int? fileSize;
  final AttachmentType type;
  final Uint8List? thumbnailData;

  ChatAttachment({
    required this.filePath,
    required this.fileName,
    this.fileSize,
    required this.type,
    this.thumbnailData,
  });

  /// Create attachment from file
  factory ChatAttachment.fromFile(File file) {
    final fileName = path.basename(file.path);
    final fileSize = file.lengthSync();
    final ext = path.extension(fileName).toLowerCase();

    AttachmentType type = AttachmentType.other;
    if (_isImage(ext)) {
      type = AttachmentType.image;
    } else if (_isDocument(ext)) {
      type = AttachmentType.document;
    }

    return ChatAttachment(
      filePath: file.path,
      fileName: fileName,
      fileSize: fileSize,
      type: type,
    );
  }

  static bool _isImage(String ext) {
    return [
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.bmp',
      '.webp',
      '.svg',
    ].contains(ext);
  }

  static bool _isDocument(String ext) {
    return [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt',
      '.md',
    ].contains(ext);
  }

  String get formattedSize {
    if (fileSize == null) return '';
    final size = fileSize!;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData get icon {
    switch (type) {
      case AttachmentType.image:
        return Icons.image;
      case AttachmentType.document:
        return Icons.description;
      case AttachmentType.other:
        return Icons.insert_drive_file;
    }
  }
}

/// Chip widget for displaying attached files
class AttachedFileChip extends StatelessWidget {
  final ChatAttachment attachment;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const AttachedFileChip({
    super.key,
    required this.attachment,
    required this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (attachment.type == AttachmentType.image) {
      return _ImageAttachmentChip(
        attachment: attachment,
        onRemove: onRemove,
        onTap: onTap,
      );
    }

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          Icon(
            attachment.icon,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              attachment.fileName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (attachment.fileSize != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${attachment.formattedSize})',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
            ),
          ],
          const SizedBox(width: 4),
          Tooltip(
            message: 'Remove attachment',
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Specialized chip for image attachments with thumbnail
class _ImageAttachmentChip extends StatefulWidget {
  final ChatAttachment attachment;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const _ImageAttachmentChip({
    required this.attachment,
    required this.onRemove,
    this.onTap,
  });

  @override
  State<_ImageAttachmentChip> createState() => _ImageAttachmentChipState();
}

class _ImageAttachmentChipState extends State<_ImageAttachmentChip> {
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.attachment.filePath);
      if (await file.exists()) {
        setState(() {
          _imageProvider = FileImage(file);
        });
      }
    } catch (e) {
      // Failed to load image, will use placeholder
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Stack(
        children: [
          // Image/Preview
          GestureDetector(
            onTap: widget.onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: _imageProvider != null
                  ? Ink.image(
                      image: _imageProvider!,
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 78,
                      height: 78,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image,
                        size: 32,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          // Remove button
          Positioned(
            top: 2,
            right: 2,
            child: Tooltip(
              message: 'Remove image',
              child: InkWell(
                onTap: widget.onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Preview dialog for image attachments
class ImagePreviewDialog extends StatelessWidget {
  final ChatAttachment attachment;

  const ImagePreviewDialog({
    super.key,
    required this.attachment,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(attachment.filePath);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Image
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Image.file(file),
            ),
          ),
          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: IconButton.filled(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
              ),
            ),
          ),
          // File info
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                attachment.fileName,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show image preview dialog
void showImagePreview(BuildContext context, ChatAttachment attachment) {
  showDialog(
    context: context,
    builder: (context) => ImagePreviewDialog(attachment: attachment),
  );
}
