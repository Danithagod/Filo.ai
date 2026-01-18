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

  /// Merge multiple tags into a single target tag
  /// Updates all files using source tags to use the target tag instead
  static Future<int> mergeTags(
    Session session,
    List<String> sourceTags,
    String targetTag, {
    String? category,
  }) async {
    int filesUpdated = 0;

    // Normalize tags
    final normalizedSources = sourceTags
        .map((t) => t.trim().toLowerCase())
        .toList();
    final normalizedTarget = targetTag.trim().toLowerCase();

    // Find all files with tags
    final files = await FileIndex.db.find(
      session,
      where: (t) => t.tagsJson.notEquals(null),
    );

    for (final file in files) {
      if (file.tagsJson == null) continue;

      bool modified = false;
      var tags = DocumentTags.fromJson(file.tagsJson!);

      // Check if any source tags are present
      for (final sourceTag in normalizedSources) {
        if (tags.containsTag(sourceTag)) {
          tags = tags.removeTag(sourceTag);
          modified = true;
        }
      }

      // Add target tag if modified and not already present
      if (modified && !tags.containsTag(normalizedTarget)) {
        tags = tags.addTag(normalizedTarget);
      }

      // Update file if modified
      if (modified) {
        await FileIndex.db.updateRow(
          session,
          file.copyWith(tagsJson: tags.toJson()),
        );
        filesUpdated++;
      }
    }

    // Update tag taxonomy - combine frequencies
    int totalFrequency = 0;
    DateTime? earliestSeen;
    DateTime? latestSeen;

    for (final sourceTag in normalizedSources) {
      final existing = await TagTaxonomy.db.findFirstRow(
        session,
        where: (t) {
          if (category != null) {
            return t.category.equals(category) & t.tagValue.equals(sourceTag);
          }
          return t.tagValue.equals(sourceTag);
        },
      );

      if (existing != null) {
        totalFrequency += existing.frequency;
        if (earliestSeen == null ||
            existing.firstSeenAt.isBefore(earliestSeen)) {
          earliestSeen = existing.firstSeenAt;
        }
        if (latestSeen == null || existing.lastSeenAt.isAfter(latestSeen)) {
          latestSeen = existing.lastSeenAt;
        }

        // Delete source tag
        await TagTaxonomy.db.deleteRow(session, existing);
      }
    }

    // Update or create target tag
    final targetTagEntry = await TagTaxonomy.db.findFirstRow(
      session,
      where: (t) {
        if (category != null) {
          return t.category.equals(category) &
              t.tagValue.equals(normalizedTarget);
        }
        return t.tagValue.equals(normalizedTarget);
      },
    );

    if (targetTagEntry != null) {
      targetTagEntry.frequency += totalFrequency;
      if (earliestSeen != null &&
          earliestSeen.isBefore(targetTagEntry.firstSeenAt)) {
        targetTagEntry.firstSeenAt = earliestSeen;
      }
      if (latestSeen != null && latestSeen.isAfter(targetTagEntry.lastSeenAt)) {
        targetTagEntry.lastSeenAt = latestSeen;
      }
      await TagTaxonomy.db.updateRow(session, targetTagEntry);
    } else if (category != null) {
      // Create new target tag
      await TagTaxonomy.db.insertRow(
        session,
        TagTaxonomy(
          category: category,
          tagValue: normalizedTarget,
          frequency: totalFrequency,
          firstSeenAt: earliestSeen ?? DateTime.now(),
          lastSeenAt: latestSeen ?? DateTime.now(),
        ),
      );
    }

    return filesUpdated;
  }

  /// Get related tags based on co-occurrence in files
  /// Returns tags that frequently appear together with the given tag
  static Future<List<RelatedTag>> getRelatedTags(
    Session session,
    String tagValue, {
    int limit = 10,
  }) async {
    final normalizedTag = tagValue.trim().toLowerCase();
    final cooccurrence = <String, int>{};

    // Find all files containing this tag
    final files = await FileIndex.db.find(
      session,
      where: (t) => t.tagsJson.notEquals(null),
    );

    for (final file in files) {
      if (file.tagsJson == null) continue;

      final tags = DocumentTags.fromJson(file.tagsJson!);
      if (!tags.containsTag(normalizedTag)) continue;

      // Count co-occurring tags
      final allTags = tags.toTagList();
      for (final otherTag in allTags) {
        final normalizedOther = otherTag.trim().toLowerCase();
        if (normalizedOther != normalizedTag) {
          cooccurrence[normalizedOther] =
              (cooccurrence[normalizedOther] ?? 0) + 1;
        }
      }
    }

    // Sort by frequency and return top N
    final sorted = cooccurrence.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(limit)
        .map(
          (e) => RelatedTag(
            tagValue: e.key,
            cooccurrenceCount: e.value,
          ),
        )
        .toList();
  }

  /// Rename a tag across all files and taxonomy
  static Future<int> renameTag(
    Session session,
    String oldTag,
    String newTag, {
    String? category,
  }) async {
    final normalizedOld = oldTag.trim().toLowerCase();
    final normalizedNew = newTag.trim().toLowerCase();

    if (normalizedOld == normalizedNew) return 0;

    int filesUpdated = 0;

    // Update all files
    final files = await FileIndex.db.find(
      session,
      where: (t) => t.tagsJson.notEquals(null),
    );

    for (final file in files) {
      if (file.tagsJson == null) continue;

      var tags = DocumentTags.fromJson(file.tagsJson!);
      if (tags.containsTag(normalizedOld)) {
        tags = tags.removeTag(normalizedOld);
        if (!tags.containsTag(normalizedNew)) {
          tags = tags.addTag(normalizedNew);
        }

        await FileIndex.db.updateRow(
          session,
          file.copyWith(tagsJson: tags.toJson()),
        );
        filesUpdated++;
      }
    }

    // Update taxonomy
    final oldTagEntry = await TagTaxonomy.db.findFirstRow(
      session,
      where: (t) {
        if (category != null) {
          return t.category.equals(category) & t.tagValue.equals(normalizedOld);
        }
        return t.tagValue.equals(normalizedOld);
      },
    );

    if (oldTagEntry != null) {
      // Check if new tag already exists
      final newTagEntry = await TagTaxonomy.db.findFirstRow(
        session,
        where: (t) {
          if (category != null) {
            return t.category.equals(category) &
                t.tagValue.equals(normalizedNew);
          }
          return t.tagValue.equals(normalizedNew);
        },
      );

      if (newTagEntry != null) {
        // Merge frequencies
        newTagEntry.frequency += oldTagEntry.frequency;
        if (oldTagEntry.firstSeenAt.isBefore(newTagEntry.firstSeenAt)) {
          newTagEntry.firstSeenAt = oldTagEntry.firstSeenAt;
        }
        if (oldTagEntry.lastSeenAt.isAfter(newTagEntry.lastSeenAt)) {
          newTagEntry.lastSeenAt = oldTagEntry.lastSeenAt;
        }
        await TagTaxonomy.db.updateRow(session, newTagEntry);
      } else {
        // Rename existing tag
        oldTagEntry.tagValue = normalizedNew;
        await TagTaxonomy.db.updateRow(session, oldTagEntry);
      }

      // Delete old tag if we merged
      if (newTagEntry != null) {
        await TagTaxonomy.db.deleteRow(session, oldTagEntry);
      }
    }

    return filesUpdated;
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

/// Related tag with co-occurrence information
class RelatedTag {
  final String tagValue;
  final int cooccurrenceCount;

  RelatedTag({
    required this.tagValue,
    required this.cooccurrenceCount,
  });

  Map<String, dynamic> toJson() => {
    'tagValue': tagValue,
    'cooccurrenceCount': cooccurrenceCount,
  };
}
