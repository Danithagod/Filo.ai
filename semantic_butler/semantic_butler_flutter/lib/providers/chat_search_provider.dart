import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_history_provider.dart';

class ChatSearchQueryNotifier extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() => '';

  void setQuery(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = query;
    });
  }

  void clear() {
    _debounce?.cancel();
    state = '';
  }
}

final chatSearchQueryProvider =
    NotifierProvider<ChatSearchQueryNotifier, String>(
      ChatSearchQueryNotifier.new,
    );

final chatSearchResultsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final query = ref.watch(chatSearchQueryProvider);
  if (query.isEmpty || query.length < 2) return [];

  final storage = ref.read(chatStorageServiceProvider);
  return await storage.searchMessages(query);
});
