import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Service for managing saved search presets
class SearchPresetService {
  /// Save a search preset
  static Future<SavedSearchPreset> savePreset(
    Session session,
    SavedSearchPreset preset,
  ) async {
    // If ID is set, update. Otherwise insert.
    if (preset.id != null) {
      return await SavedSearchPreset.db.updateRow(session, preset);
    } else {
      return await SavedSearchPreset.db.insertRow(session, preset);
    }
  }

  /// Get all saved presets, optionally filtered by category
  static Future<List<SavedSearchPreset>> getSavedPresets(
    Session session, {
    String? category,
    int limit = 50,
  }) async {
    // Note: Serverpod 'find' returns Future<List<T>>, filtering happens in where clause
    // But since `where` expects an Expression, and we have optional param...
    // We can conditionally construct query if using QueryBuilder, but find() API is simpler.

    return await SavedSearchPreset.db.find(
      session,
      where: category != null ? (t) => t.category.equals(category) : null,
      limit: limit,
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
  }

  /// Delete a saved preset
  static Future<bool> deletePreset(
    Session session,
    int presetId,
  ) async {
    final deleted = await SavedSearchPreset.db.deleteRow(
      session,
      SavedSearchPreset(
        id: presetId,
        name: '',
        query: '',
        createdAt: DateTime.now(),
        usageCount: 0,
      ),
    );
    return deleted.id != null;
  }
}
