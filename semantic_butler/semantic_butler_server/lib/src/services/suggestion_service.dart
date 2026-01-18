import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Service for providing search suggestions
class SuggestionService {
  /// Get suggestions for a query
  Future<List<SearchSuggestion>> getSuggestions(
    Session session,
    String query, {
    int limit = 10,
  }) async {
    final suggestions = <SearchSuggestion>[];
    if (query.trim().isEmpty) return suggestions;

    final lowerQuery = query.toLowerCase();

    // 1. Tag Suggestions (High priority for structured search)
    // In a real implementation, we'd query the DB or TagTaxonomyService
    // For now, we mock some common tags or use what we can get
    final tags = ['important', 'work', 'personal', 'finance', 'project'];
    for (final tag in tags) {
      if (tag.contains(lowerQuery)) {
        suggestions.add(
          SearchSuggestion(
            text: tag,
            type: 'tag',
            score: 1.0,
            metadata: 'Tag',
          ),
        );
      }
    }

    // 2. Preset Suggestions (Saved Searches)
    // We can query SavedSearchPreset if we had the table
    // For now, let's assume we can query existing ones

    /*
    try {
      final presets = await SavedSearchPreset.db.find(
        session,
        where: (t) => t.name.ilike('%$query%'),
        limit: 5,
      );
      for (final p in presets) {
        suggestions.add(SearchSuggestion(
          text: p.name,
          type: 'preset',
          score: 0.9,
          metadata: 'Saved Search',
        ));
      }
    } catch (e) {
      // Ignore if table doesn't exist yet
    }
    */

    // 3. History Suggestions
    // TODO: Query SearchHistory table

    return suggestions.take(limit).toList();
  }
}
