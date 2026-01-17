import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'ai_service.dart' show DocumentTags;

/// Service for managing tag taxonomy
///
/// Provides methods for:
/// - Recording tags from newly indexed documents
/// - Getting popular/frequent tags
/// - Tag suggestions/autocomplete
/// - Tag analytics by category
class TagTaxonomyService {
  /// Record tags from a document, updating frequency counts
  ///
  /// [tags] - Map of category -> list of tag values
  static Future<void> recordTags(
    Session session,
    Map<String, List<String>> tags,
  ) async {
    final now = DateTime.now();

    for (final entry in tags.entries) {
      final category = entry.key;
      final values = entry.value;

      for (final value in values) {
        await _upsertTag(session, category, value, now);
      }
    }
  }

  /// Record tags from DocumentTags object
  static Future<void> recordDocumentTags(
    Session session,
    DocumentTags tags,
  ) async {
    await recordTags(session, {
      'topic': [tags.primaryTopic],
      'document_type': [tags.documentType],
      'entity': tags.entities,
      'keyword': tags.keywords,
      if (tags.language != null && tags.language != 'natural')
        'language': [tags.language!],
    });
  }

  /// Upsert a single tag, incrementing frequency if exists
  static Future<void> _upsertTag(
    Session session,
    String category,
    String tagValue,
    DateTime timestamp,
  ) async {
    // Normalize tag value
    final normalizedValue = tagValue.trim().toLowerCase();
    if (normalizedValue.isEmpty) return;

    // Find existing tag
    final existing = await TagTaxonomy.db.findFirstRow(
      session,
      where: (t) =>
          t.category.equals(category) & t.tagValue.equals(normalizedValue),
    );

    if (existing != null) {
      // Update frequency and lastSeenAt
      existing.frequency++;
      existing.lastSeenAt = timestamp;
      await TagTaxonomy.db.updateRow(session, existing);
    } else {
      // Create new tag
      await TagTaxonomy.db.insertRow(
        session,
        TagTaxonomy(
          category: category,
          tagValue: normalizedValue,
          frequency: 1,
          firstSeenAt: timestamp,
          lastSeenAt: timestamp,
        ),
      );
    }
  }

  /// Get most frequent tags for a category
  static Future<List<TagTaxonomy>> getTopTags(
    Session session, {
    String? category,
    int limit = 20,
  }) async {
    return await TagTaxonomy.db.find(
      session,
      where: category != null ? (t) => t.category.equals(category) : null,
      orderBy: (t) => t.frequency,
      orderDescending: true,
      limit: limit,
    );
  }

  /// Search tags for autocomplete
  static Future<List<TagTaxonomy>> searchTags(
    Session session,
    String query, {
    String? category,
    int limit = 10,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return getTopTags(session, category: category, limit: limit);
    }

    // Simple prefix search - in production, use full-text search
    final results = await TagTaxonomy.db.find(
      session,
      where: category != null
          ? (t) =>
                t.category.equals(category) &
                t.tagValue.like('$normalizedQuery%')
          : (t) => t.tagValue.like('$normalizedQuery%'),
      orderBy: (t) => t.frequency,
      orderDescending: true,
      limit: limit,
    );

    return results;
  }

  /// Get tag statistics by category
  static Future<Map<String, TagCategoryStats>> getCategoryStats(
    Session session,
  ) async {
    final categories = ['topic', 'entity', 'keyword'];
    final stats = <String, TagCategoryStats>{};

    for (final category in categories) {
      final count = await TagTaxonomy.db.count(
        session,
        where: (t) => t.category.equals(category),
      );

      final top = await getTopTags(session, category: category, limit: 5);

      stats[category] = TagCategoryStats(
        category: category,
        uniqueCount: count,
        topTags: top.map((t) => t.tagValue).toList(),
      );
    }

    return stats;
  }

  /// Cleanup low-frequency tags (housekeeping)
  static Future<int> cleanupRareTags(
    Session session, {
    int minFrequency = 2,
    Duration minAge = const Duration(days: 30),
  }) async {
    final cutoffDate = DateTime.now().subtract(minAge);

    // Find and delete tags with frequency=1 that are older than cutoff
    // Note: Serverpod uses different comparison operators
    final rareTags = await TagTaxonomy.db.find(
      session,
      where: (t) => t.frequency.equals(1),
    );

    final toDelete = rareTags
        .where((t) => t.lastSeenAt.isBefore(cutoffDate))
        .toList();

    for (final tag in toDelete) {
      await TagTaxonomy.db.deleteRow(session, tag);
    }

    return toDelete.length;
  }
}

/// Statistics for a tag category
class TagCategoryStats {
  final String category;
  final int uniqueCount;
  final List<String> topTags;

  TagCategoryStats({
    required this.category,
    required this.uniqueCount,
    required this.topTags,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'uniqueCount': uniqueCount,
    'topTags': topTags,
  };
}
