import 'package:flutter/material.dart';
import '../models/tagged_file.dart';
import '../widgets/file_tag_overlay.dart';

/// Mixin for handling @-mention file tagging functionality
mixin FileTaggingMixin<T extends StatefulWidget> on State<T> {
  /// Text controller for monitoring @-mentions (must be provided by implementing class)
  TextEditingController get tagTextController;

  /// Focus node for input field (must be provided by implementing class)
  FocusNode get tagFocusNode;

  /// List of currently tagged files
  final List<TaggedFile> taggedFiles = [];

  /// Whether tag overlay is currently shown
  bool showTagOverlay = false;

  /// Current tag query string
  String tagQuery = '';

  /// Overlay entry for tag suggestions
  OverlayEntry? tagOverlayEntry;

  /// Initialize tag listening
  void initFileTagging() {
    tagTextController.addListener(_handleTagTextChange);
  }

  /// Clean up tag resources
  void disposeFileTagging() {
    hideTagOverlay();
    tagTextController.removeListener(_handleTagTextChange);
  }

  /// Handle text changes to detect @-mentions
  void _handleTagTextChange() {
    final text = tagTextController.text;
    final cursorPos = tagTextController.selection.baseOffset;

    if (cursorPos <= 0) {
      hideTagOverlay();
      return;
    }

    // Find @ before cursor
    final beforeCursor = text.substring(0, cursorPos);
    final lastAtIndex = beforeCursor.lastIndexOf('@');

    if (lastAtIndex >= 0) {
      // Check if there's a space between @ and cursor (meaning tag is complete)
      final afterAt = beforeCursor.substring(lastAtIndex + 1);
      if (!afterAt.contains(' ') && !afterAt.contains('\n')) {
        // Show overlay with query
        tagQuery = afterAt;
        showTagOverlayWidget();
        return;
      }
    }

    hideTagOverlay();
  }

  /// Show tag overlay widget
  void showTagOverlayWidget() {
    if (tagOverlayEntry != null) {
      // Update existing overlay
      tagOverlayEntry!.markNeedsBuild();
      return;
    }

    // Position overlay above input field, to the right of sidebar
    final position = const Offset(280, 80);

    tagOverlayEntry = OverlayEntry(
      builder: (context) => FileTagOverlay(
        query: tagQuery,
        position: position,
        onFileSelected: onFileTagged,
        onDismiss: hideTagOverlay,
      ),
    );

    Overlay.of(context).insert(tagOverlayEntry!);
    setState(() => showTagOverlay = true);
  }

  /// Hide tag overlay
  void hideTagOverlay() {
    tagOverlayEntry?.remove();
    tagOverlayEntry = null;
    if (showTagOverlay) {
      setState(() => showTagOverlay = false);
    }
  }

  /// Handle file being tagged
  void onFileTagged(TaggedFile file) {
    // Add to tagged files list
    if (!taggedFiles.contains(file)) {
      setState(() => taggedFiles.add(file));
    }

    // Replace @query with @filename in text
    final text = tagTextController.text;
    final cursorPos = tagTextController.selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPos);
    final lastAtIndex = beforeCursor.lastIndexOf('@');

    if (lastAtIndex >= 0) {
      final newText =
          '${text.substring(0, lastAtIndex)}@${file.displayName} ${text.substring(cursorPos)}';
      tagTextController.text = newText;
      tagTextController.selection = TextSelection.collapsed(
        offset: lastAtIndex + file.displayName.length + 2,
      );
    }

    hideTagOverlay();
    tagFocusNode.requestFocus();
  }

  /// Remove a tagged file
  void removeTaggedFile(TaggedFile file) {
    setState(() => taggedFiles.remove(file));
  }

  /// Clear all tagged files
  void clearTaggedFiles() {
    setState(() => taggedFiles.clear());
  }
}
