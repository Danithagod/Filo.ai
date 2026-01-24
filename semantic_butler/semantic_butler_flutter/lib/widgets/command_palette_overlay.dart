import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SlashCommand {
  final String command;
  final String description;
  final IconData icon;

  const SlashCommand({
    required this.command,
    required this.description,
    required this.icon,
  });
}

class CommandPaletteOverlay extends StatefulWidget {
  final String query;
  final List<SlashCommand> commands;
  final Function(SlashCommand) onCommandSelected;
  final VoidCallback onDismiss;

  const CommandPaletteOverlay({
    super.key,
    required this.query,
    required this.commands,
    required this.onCommandSelected,
    required this.onDismiss,
  });

  @override
  State<CommandPaletteOverlay> createState() => _CommandPaletteOverlayState();
}

class _CommandPaletteOverlayState extends State<CommandPaletteOverlay> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<SlashCommand> get _filteredCommands {
    if (widget.query.isEmpty) return widget.commands;
    return widget.commands
        .where(
          (c) => c.command.toLowerCase().contains(widget.query.toLowerCase()),
        )
        .toList();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final filtered = _filteredCommands;
    if (filtered.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % filtered.length;
      });
      _scrollToSelected();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex =
            (_selectedIndex - 1 + filtered.length) % filtered.length;
      });
      _scrollToSelected();
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onCommandSelected(filtered[_selectedIndex]);
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss();
    }
  }

  void _scrollToSelected() {
    if (_scrollController.hasClients) {
      const itemHeight = 48.0; // ListTile height
      final target = _selectedIndex * itemHeight;
      _scrollController.animateTo(
        target.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filtered = _filteredCommands;

    if (filtered.isEmpty) return const SizedBox.shrink();

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surfaceContainerHigh,
        child: Container(
          width: 300,
          constraints: const BoxConstraints(maxHeight: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  'Commands',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final cmd = filtered[index];
                    final isSelected = index == _selectedIndex;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                      leading: Icon(
                        cmd.icon,
                        size: 18,
                        color: isSelected ? colorScheme.primary : null,
                      ),
                      title: Text(
                        '/${cmd.command}',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                      subtitle: Text(cmd.description),
                      onTap: () => widget.onCommandSelected(cmd),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
