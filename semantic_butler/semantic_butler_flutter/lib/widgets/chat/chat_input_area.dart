import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/chat/chat_message.dart';
import '../../models/tagged_file.dart';
import '../../utils/app_logger.dart';
import '../chat/attached_file_chip.dart';
import '../chat/message_quote_bar.dart';
import 'auto_grow_text_field.dart';
import 'quick_action_chips.dart';
import 'file_drop_zone.dart';

/// Chat input area with text field, file attachments, and quick actions
class ChatInputArea extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final List<TaggedFile> taggedFiles;
  final List<File> attachedFiles;
  final VoidCallback onSend;
  final void Function(TaggedFile) onRemoveTag;
  final void Function(File) onRemoveAttachment;
  final void Function(List<File>) onFilesDropped;
  final ChatMessage? replyToMessage;
  final VoidCallback? onCancelReply;
  final LayerLink? layerLink;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.taggedFiles,
    this.attachedFiles = const [],
    required this.onSend,
    required this.onRemoveTag,
    required this.onRemoveAttachment,
    required this.onFilesDropped,
    this.replyToMessage,
    this.onCancelReply,
    this.layerLink,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  bool _isQuickActionsExpanded = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(ChatInputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      // Background gradient or transparent to let content show through slightly if needed
      // But usually just transparent so the floating card stands out
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface.withValues(alpha: 0.0),
            theme.colorScheme.surface.withValues(alpha: 0.8),
            theme.colorScheme.surface,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Card(
          elevation: 4,
          shadowColor: Theme.of(
            context,
          ).colorScheme.shadow.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          color:
              colorScheme.surfaceContainer, // Slightly lighter than background
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Reply to bar
                if (widget.replyToMessage != null)
                  MessageQuoteBar(
                    quotedContent: widget.replyToMessage!.content,
                    quotedRole: widget.replyToMessage!.role,
                    onCancel: widget.onCancelReply ?? () {},
                  ),

                // Attached files preview
                if (widget.attachedFiles.isNotEmpty) _buildAttachments(context),

                // Tagged files chips
                if (widget.taggedFiles.isNotEmpty) _buildTaggedFiles(context),

                // Quick actions (controlled externally)
                if (!widget.isLoading) _buildQuickActions(context),

                // Tagging discovery hint
                if (widget.controller.text.isEmpty &&
                    widget.focusNode.hasFocus &&
                    !widget.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withValues(
                            alpha: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.alternate_email,
                              size: 14,
                              color: colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Type @ to tag files or folders',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Input row
                _buildInputRow(context, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePaste() async {
    // Check for files in clipboard
    final filePaths = await ClipboardFileHandler.getFilesFromClipboard();
    if (filePaths.isNotEmpty) {
      final files = filePaths.map((path) => File(path)).toList();
      widget.onFilesDropped(files);
      return;
    }

    // Default behavior for text paste is handled by TextField itself
    // But since we intercepted the shortcut, we should handle text paste too
    // if no files were found.
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final text = data!.text!;
      final baseOffset = widget.controller.selection.baseOffset;
      final extentOffset = widget.controller.selection.extentOffset;
      final currentText = widget.controller.text;

      if (baseOffset >= 0) {
        final newText = currentText.replaceRange(
          baseOffset,
          extentOffset,
          text,
        );
        widget.controller.text = newText;
        widget.controller.selection = TextSelection.collapsed(
          offset: baseOffset + text.length,
        );
      } else {
        widget.controller.text += text;
      }
    }
  }

  Future<void> _handleFilePick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final files = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
        widget.onFilesDropped(files);
      }
    } catch (e) {
      AppLogger.error('Failed to pick files: $e');
    }
  }

  Future<void> _handleDirectoryPick() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath();

      if (path != null) {
        // We handle directories as File objects for API compatibility
        // The FileTaggingMixin and ChatAttachment know how to handle them
        widget.onFilesDropped([File(path)]);
      }
    } catch (e) {
      AppLogger.error('Failed to pick directory: $e');
    }
  }

  Future<void> _openFile(String path) async {
    try {
      final uri = Uri.file(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: $path')),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error opening file: $e');
    }
  }

  Widget _buildAttachments(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.attachedFiles.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Tooltip(
                message: 'Remove all attachments',
                child: InkWell(
                  onTap: () {
                    for (final file in List<File>.from(widget.attachedFiles)) {
                      widget.onRemoveAttachment(file);
                    }
                  },
                  child: Text(
                    'Remove all',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.attachedFiles.map((file) {
              final attachment = ChatAttachment.fromFile(file);
              return AttachedFileChip(
                attachment: attachment,
                onRemove: () => widget.onRemoveAttachment(file),
                onTap: () {
                  if (attachment.type == AttachmentType.image) {
                    showImagePreview(context, attachment);
                  } else {
                    _openFile(attachment.filePath);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaggedFiles(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: widget.taggedFiles.map((file) {
          return Tooltip(
            message: 'Path: ${file.path}',
            child: InputChip(
              label: Text(file.displayName),
              avatar: Icon(
                file.isDirectory
                    ? Icons.folder_rounded
                    : Icons.insert_drive_file_outlined,
                size: 16,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('File path: ${file.path}'),
                    action: SnackBarAction(
                      label: 'Open',
                      onPressed: () => _openFile(file.path),
                    ),
                  ),
                );
              },
              onDeleted: () => widget.onRemoveTag(file),
              deleteIcon: const Icon(Icons.close, size: 16),
              deleteButtonTooltipMessage: 'Remove tag',
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: QuickActionChips(
        isExpanded: _isQuickActionsExpanded,
        showToggleButton: false,
        onActionSelected: (template) {
          widget.controller.text = template;
          widget.focusNode.requestFocus();
          // Collapse after selection for a cleaner flow
          setState(() {
            _isQuickActionsExpanded = false;
          });
        },
        getCurrentTaggedFile: () {
          if (widget.taggedFiles.isNotEmpty) {
            return '@${widget.taggedFiles.first.displayName}';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildInputRow(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Quick Actions Toggle
        if (!widget.isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, right: 8),
            child: IconButton(
              onPressed: () => setState(() {
                _isQuickActionsExpanded = !_isQuickActionsExpanded;
              }),
              icon: Icon(
                _isQuickActionsExpanded
                    ? Icons.close_rounded
                    : Icons.add_circle_outline_rounded,
                size: 24,
                color: colorScheme.primary,
              ),
              tooltip: _isQuickActionsExpanded
                  ? 'Hide quick actions'
                  : 'Show quick actions',
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),

        // Input field container
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: CallbackShortcuts(
                        bindings: {
                          const SingleActivator(
                            LogicalKeyboardKey.keyV,
                            control: true,
                          ): () =>
                              _handlePaste(),
                          const SingleActivator(
                            LogicalKeyboardKey.keyV,
                            meta: true,
                          ): () =>
                              _handlePaste(),
                          const SingleActivator(
                            LogicalKeyboardKey.enter,
                            control: true,
                          ): () =>
                              widget.onSend(),
                          const SingleActivator(
                            LogicalKeyboardKey.enter,
                            meta: true,
                          ): () =>
                              widget.onSend(),
                        },
                        child: AutoGrowTextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          minLines: 1,
                          maxLines: 6,
                          enabled: !widget.isLoading,
                          hintText: widget.taggedFiles.isEmpty
                              ? 'Ask about your files... (@ to tag)'
                              : 'Ask about tagged files...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          onSubmitted: (_) => widget.onSend(),
                        ),
                      ),
                    ),
                    // Attachment button as trailing menu
                    if (!widget.isLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5, right: 8),
                        child: PopupMenuButton<String>(
                          tooltip: 'Attach...',
                          icon: Icon(
                            Icons.attach_file,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          style: IconButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onSelected: (value) {
                            if (value == 'file') {
                              _handleFilePick();
                            } else if (value == 'folder') {
                              _handleDirectoryPick();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'file',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.insert_drive_file_outlined,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text('Files'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'folder',
                              child: Row(
                                children: [
                                  Icon(Icons.folder_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text('Folder'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Character Counter
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, child) {
                  if (value.text.length < 500) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4, right: 12),
                    child: Text(
                      '${value.text.length} characters',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: value.text.length > 1500
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Send button with animation
        Padding(
          padding: const EdgeInsets.only(
            bottom: 2,
          ), // Align with text field better
          child: _SendButton(
            isLoading: widget.isLoading,
            onPressed: widget.onSend,
          ),
        ),
      ],
    );

    if (widget.layerLink != null) {
      return CompositedTransformTarget(
        link: widget.layerLink!,
        child: row,
      );
    }

    return row;
  }
}

class _SendButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SendButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: IconButton.filled(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.arrow_upward_rounded),
        tooltip: 'Send message',
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }
}
