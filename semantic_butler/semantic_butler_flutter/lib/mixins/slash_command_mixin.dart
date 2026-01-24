import 'package:flutter/material.dart';
import '../widgets/command_palette_overlay.dart';

mixin SlashCommandMixin<T extends StatefulWidget> on State<T> {
  TextEditingController get tagTextController;
  FocusNode get tagFocusNode;
  LayerLink get tagLayerLink;

  bool showCommandOverlay = false;
  String commandQuery = '';
  OverlayEntry? commandOverlayEntry;

  final List<SlashCommand> availableCommands = [
    const SlashCommand(
      command: 'search',
      description: 'Search for files by name or content',
      icon: Icons.search,
    ),
    const SlashCommand(
      command: 'organize',
      description: 'Automatically organize files in a folder',
      icon: Icons.folder_copy_outlined,
    ),
    const SlashCommand(
      command: 'index',
      description: 'Index a folder for faster searching',
      icon: Icons.data_usage_rounded,
    ),
    const SlashCommand(
      command: 'clear',
      description: 'Clear the current conversation',
      icon: Icons.delete_outline,
    ),
  ];

  void initSlashCommands() {
    tagTextController.addListener(_handleCommandTextChange);
  }

  void disposeSlashCommands() {
    try {
      commandOverlayEntry?.remove();
      commandOverlayEntry = null;
    } catch (_) {}
    tagTextController.removeListener(_handleCommandTextChange);
  }

  void _handleCommandTextChange() {
    final text = tagTextController.text;
    final cursorPos = tagTextController.selection.baseOffset;

    if (cursorPos <= 0) {
      hideCommandOverlay();
      return;
    }

    // Only trigger command palette if / is at the very beginning
    if (text.startsWith('/') && !text.contains(' ', 1)) {
      commandQuery = text.substring(1, cursorPos);

      // Hide other overlays (like @ tagging) if they exist
      _hideOtherOverlays();

      showCommandOverlayWidget();
      return;
    }

    hideCommandOverlay();
  }

  void _hideOtherOverlays() {
    try {
      (this as dynamic).hideTagOverlay();
    } catch (_) {}
  }

  void showCommandOverlayWidget() {
    if (!mounted) return;

    if (commandOverlayEntry != null) {
      commandOverlayEntry!.markNeedsBuild();
      return;
    }

    commandOverlayEntry = OverlayEntry(
      builder: (context) => CompositedTransformFollower(
        link: tagLayerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.topLeft,
        followerAnchor: Alignment.bottomLeft,
        offset: const Offset(0, -8),
        child: CommandPaletteOverlay(
          query: commandQuery,
          commands: availableCommands,
          onCommandSelected: onCommandSelected,
          onDismiss: hideCommandOverlay,
        ),
      ),
    );

    try {
      Overlay.of(context).insert(commandOverlayEntry!);
      setState(() => showCommandOverlay = true);
    } catch (e) {
      // If overlay insertion fails, clean up
      commandOverlayEntry = null;
    }
  }

  void hideCommandOverlay() {
    commandOverlayEntry?.remove();
    commandOverlayEntry = null;
    if (showCommandOverlay && mounted) {
      setState(() => showCommandOverlay = false);
      tagFocusNode.requestFocus();
    }
  }

  void onCommandSelected(SlashCommand command) {
    bool shouldAutoSubmit = false;

    if (command.command == 'clear') {
      tagTextController.text = '';
      shouldAutoSubmit = true;
    } else {
      tagTextController.text = '/${command.command} ';
      tagTextController.selection = TextSelection.collapsed(
        offset: command.command.length + 2,
      );
    }

    hideCommandOverlay();
    tagFocusNode.requestFocus();

    if (shouldAutoSubmit) {
      onCommandTriggered(command);
    }
  }

  /// Hook for subclasses to handle triggered slash commands
  void onCommandTriggered(SlashCommand command) {}
}
