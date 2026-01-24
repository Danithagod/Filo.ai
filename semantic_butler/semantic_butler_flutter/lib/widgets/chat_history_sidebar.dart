import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/chat_history_provider.dart';
import '../providers/chat_search_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/chat/conversation.dart';

class ChatHistorySidebar extends ConsumerWidget {
  const ChatHistorySidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth < 600 ? screenWidth * 0.8 : 320.0;

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: theme.brightness == Brightness.dark ? 20 : 0,
          sigmaY: theme.brightness == Brightness.dark ? 20 : 0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? colorScheme.surface.withValues(alpha: 0.7)
                : colorScheme.surface,
            border: Border(
              left: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                child: Row(
                  children: [
                    Text(
                      'History',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        ref
                            .read(chatHistoryProvider.notifier)
                            .createNewConversation();
                        Navigator.pop(context); // Close drawer on mobile
                      },
                      tooltip: 'New Chat',
                    ),
                  ],
                ),
              ),

              // Search Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (value) => ref
                      .read(chatSearchQueryProvider.notifier)
                      .setQuery(value),
                  decoration: InputDecoration(
                    hintText: 'Search chats...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // List
              Expanded(
                child: _buildMainContent(context, ref),
              ),

              // Bottom Actions (e.g., Clear All)
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear All Status'),
                        content: const Text(
                          'Are you sure you want to delete all chat history?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      ref.read(chatHistoryProvider.notifier).clearHistory();
                    }
                  },
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear All History'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(chatSearchQueryProvider);
    final historyState = ref.watch(chatHistoryProvider);

    if (searchQuery.isNotEmpty) {
      final searchResults = ref.watch(chatSearchResultsProvider);
      return searchResults.when(
        data: (results) {
          if (results.isEmpty) {
            return const Center(child: Text('No messages found'));
          }
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return ListTile(
                leading: const Icon(Icons.search),
                title: Text(
                  result['content'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'In: ${result['conversation_title'] ?? 'Unknown Chat'}',
                ),
                onTap: () {
                  ref
                      .read(chatHistoryProvider.notifier)
                      .selectConversation(
                        result['conversation_id'],
                        initialMessageId: result['id'],
                      );

                  // Switch to chat tab
                  ref
                      .read(navigationProvider.notifier)
                      .navigateTo(NavigationIndex.chat);

                  Navigator.pop(context);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      );
    }

    return historyState.when(
      data: (state) {
        final summaries = state.conversations;
        if (summaries.isEmpty) {
          return const Center(child: Text('No history yet'));
        }

        return ListView.builder(
          itemCount: summaries.length,
          itemBuilder: (context, index) {
            final conversation = summaries[index];
            return _ConversationTile(
              key: ValueKey(conversation.id),
              conversation: conversation,
              isSelected: state.currentConversationId == conversation.id,
              onTap: () {
                ref
                    .read(chatHistoryProvider.notifier)
                    .selectConversation(
                      conversation.id,
                    );

                // Switch to chat tab
                ref
                    .read(navigationProvider.notifier)
                    .navigateTo(NavigationIndex.chat);

                Navigator.pop(context);
              },
              onDelete: () {
                ref
                    .read(chatHistoryProvider.notifier)
                    .deleteConversation(
                      conversation.id,
                    );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _ConversationTile extends StatefulWidget {
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    super.key,
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  bool _isHovering = false;
  bool _isEditing = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.conversation.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submitRename(WidgetRef ref) {
    if (_titleController.text.isNotEmpty &&
        _titleController.text != widget.conversation.title) {
      ref
          .read(chatHistoryProvider.notifier)
          .renameConversation(
            widget.conversation.id,
            _titleController.text,
          );
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer(
      builder: (context, ref, child) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: ListTile(
            selected: widget.isSelected,
            selectedTileColor: colorScheme.primaryContainer,
            selectedColor: colorScheme.onPrimaryContainer,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            title: _isEditing
                ? TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _submitRename(ref),
                  )
                : Text(
                    widget.conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
            subtitle: Text(
              DateFormat.yMMMd().add_jm().format(widget.conversation.updatedAt),
              style: theme.textTheme.bodySmall,
            ),
            onTap: _isEditing ? null : widget.onTap,
            onLongPress: () => setState(() => _isEditing = true),
            trailing: _isEditing
                ? IconButton(
                    icon: const Icon(Icons.check, size: 20),
                    onPressed: () => _submitRename(ref),
                  )
                : (_isHovering || widget.isSelected)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => setState(() => _isEditing = true),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Chat'),
                              content: const Text('Delete this conversation?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            widget.onDelete();
                          }
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }
}
