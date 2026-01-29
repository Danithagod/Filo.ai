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

    // 1. Tag Suggestions (High priority for structured search)
    try {
      final tags = await TagTaxonomy.db.find(
        session,
        where: (t) => t.tagValue.ilike('%$query%'),
        limit: 5,
        orderBy: (t) => t.frequency,
        orderDescending: true,
      );
      for (final tag in tags) {
        suggestions.add(
          SearchSuggestion(
            text: tag.tagValue,
            type: 'tag',
            score: 1.0,
            metadata: 'Tag (${tag.category})',
          ),
        );
      }
    } catch (e) {
      // Fallback to mocked tags if table doesn't exist or error
    }

    // 2. Preset Suggestions (Saved Searches)
    try {
      final presets = await SavedSearchPreset.db.find(
        session,
        where: (t) => t.name.ilike('%$query%'),
        limit: 3,
        orderBy: (t) => t.usageCount,
        orderDescending: true,
      );
      for (final p in presets) {
        suggestions.add(
          SearchSuggestion(
            text: p.name,
            type: 'preset',
            score: 0.9,
            metadata: 'Saved Search',
          ),
        );
      }
    } catch (e) {
      // Ignore
    }

    // 3. History Suggestions
    try {
      final history = await SearchHistory.db.find(
        session,
        where: (t) => t.query.ilike('%$query%'),
        limit: 5,
        orderBy: (t) => t.searchedAt,
        orderDescending: true,
      );

      final uniqueQueries = <String>{};
      for (final h in history) {
        if (uniqueQueries.contains(h.query)) continue;
        uniqueQueries.add(h.query);

        suggestions.add(
          SearchSuggestion(
            text: h.query,
            type: 'history',
            score: 0.8,
            metadata: 'Recent Search',
          ),
        );
      }
    } catch (e) {
      // Ignore
    }

    // 4. Filename Suggestions (Discoverability)
    try {
      final files = await FileIndex.db.find(
        session,
        where: (t) => t.fileName.ilike('%$query%'),
        limit: 5,
        orderBy: (t) => t.indexedAt,
        orderDescending: true,
      );
      for (final f in files) {
        suggestions.add(
          SearchSuggestion(
            text: f.fileName,
            type: 'file',
            score: 0.7,
            metadata: 'File Match',
          ),
        );
      }
    } catch (e) {
      // Ignore
    }

    // Sort by score and unique text
    final seen = <String>{};
    final finalSuggestions = <SearchSuggestion>[];

    suggestions.sort((a, b) => b.score.compareTo(a.score));

    for (final s in suggestions) {
      if (seen.contains(s.text.toLowerCase())) continue;
      seen.add(s.text.toLowerCase());
      finalSuggestions.add(s);
    }

    return finalSuggestions.take(limit).toList();
  }
}
