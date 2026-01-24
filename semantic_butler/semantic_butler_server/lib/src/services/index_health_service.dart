import 'package:serverpod/serverpod.dart';
import 'dart:io';
import '../generated/protocol.dart';

/// Service for monitoring and maintaining index health
///
/// Provides methods for:
/// - Detecting orphaned files (indexed but deleted)
/// - Finding stale entries (not updated in a long time)
/// - Detecting duplicate content
/// - Evaluating index quality metrics
class IndexHealthService {
  /// Generate a comprehensive health report
  static Future<IndexHealthReport> generateReport(Session session) async {
    final now = DateTime.now();

    // Run all checks in parallel
    final results = await Future.wait<dynamic>([
      _findOrphanedFiles(session),
      _findStaleEntries(session, staleThresholdDays: 180),
      _findDuplicateContent(session),
      _getIndexStatistics(session),
      _findMissingEmbeddings(session),
      _detectCorruptedData(session),
    ]);

    final orphanedFiles = results[0] as List<String>;
    final staleEntries = results[1] as List<FileIndex>;
    final duplicates = results[2] as List<InternalDuplicateGroup>;
    final stats = results[3] as IndexStatistics;
    final missingEmbeddings = results[4] as List<FileIndex>;
    final corrupted = results[5] as List<FileIndex>;

    // Calculate health score (0-100)
    final healthScore = _calculateHealthScore(
      totalFiles: stats.totalIndexed,
      orphanedCount: orphanedFiles.length,
      staleCount: staleEntries.length,
      duplicateCount: duplicates.fold(0, (sum, g) => sum + g.files.length),
      missingEmbeddingsCount: missingEmbeddings.length,
      corruptedCount: corrupted.length,
    );

    return IndexHealthReport(
      generatedAt: now,
      healthScore: healthScore,
      orphanedFiles: orphanedFiles,
      staleEntryCount: staleEntries.length,
      duplicateGroupCount: duplicates.length,
      duplicateFileCount: duplicates.fold(0, (sum, g) => sum + g.files.length),
      totalIndexed: stats.totalIndexed,
      totalPending: stats.totalPending,
      totalFailed: stats.totalFailed,
      totalEmbeddings: stats.totalEmbeddings,
      averageFileSizeBytes: stats.averageFileSizeBytes,
      missingEmbeddingsCount: missingEmbeddings.length,
      corruptedDataCount: corrupted.length,
    );
  }

  /// Find files in index that no longer exist on disk
  static Future<List<String>> _findOrphanedFiles(Session session) async {
    final indexed = await FileIndex.db.find(
      session,
      where: (t) => t.status.equals('indexed'),
    );

    final orphaned = <String>[];
    for (final file in indexed) {
      final exists = await File(file.path).exists();
      if (!exists) {
        orphaned.add(file.path);
      }
    }

    return orphaned;
  }

  /// Find entries that haven't been updated in a long time
  static Future<List<FileIndex>> _findStaleEntries(
    Session session, {
    required int staleThresholdDays,
  }) async {
    final threshold = DateTime.now().subtract(
      Duration(days: staleThresholdDays),
    );

    final stale = await FileIndex.db.find(
      session,
      where: (t) => t.status.equals('indexed'),
    );

    return stale.where((file) {
      if (file.indexedAt == null) return true;
      return file.indexedAt!.isBefore(threshold);
    }).toList();
  }

  /// Find files with identical or very similar content
  static Future<List<InternalDuplicateGroup>> _findDuplicateContent(
    Session session,
  ) async {
    final files = await FileIndex.db.find(
      session,
      where: (t) => t.status.equals('indexed') & t.contentHash.notEquals(null),
    );

    // Group by content hash
    final hashGroups = <String, List<FileIndex>>{};
    for (final file in files) {
      if (file.contentHash.isEmpty) continue;
      hashGroups.putIfAbsent(file.contentHash, () => []).add(file);
    }

    // Find groups with multiple files
    final duplicates = <InternalDuplicateGroup>[];
    for (final entry in hashGroups.entries) {
      if (entry.value.length > 1) {
        duplicates.add(
          InternalDuplicateGroup(
            contentHash: entry.key,
            files: entry.value,
            duplicateCount: entry.value.length,
          ),
        );
      }
    }

    // Sort by duplicate count (highest first)
    duplicates.sort((a, b) => b.duplicateCount.compareTo(a.duplicateCount));

    return duplicates;
  }

  /// Get overall index statistics
  static Future<IndexStatistics> _getIndexStatistics(Session session) async {
    final totalIndexed = await FileIndex.db.count(
      session,
      where: (t) => t.status.equals('indexed'),
    );

    final totalPending = await FileIndex.db.count(
      session,
      where: (t) => t.status.equals('pending'),
    );

    final totalFailed = await FileIndex.db.count(
      session,
      where: (t) => t.status.equals('failed'),
    );

    final totalEmbeddings = await DocumentEmbedding.db.count(session);

    // Calculate average file size
    final allFiles = await FileIndex.db.find(
      session,
      where: (t) => t.status.equals('indexed'),
    );

    final totalSize = allFiles.fold<int>(
      0,
      (sum, file) => sum + file.fileSizeBytes,
    );

    final avgSize = totalIndexed > 0 ? totalSize ~/ totalIndexed : 0;

    return IndexStatistics(
      totalIndexed: totalIndexed,
      totalPending: totalPending,
      totalFailed: totalFailed,
      totalEmbeddings: totalEmbeddings,
      averageFileSizeBytes: avgSize,
      oldestIndexedAt: null,
      newestIndexedAt: null,
    );
  }

  /// Find indexed files missing embeddings
  static Future<List<FileIndex>> _findMissingEmbeddings(
    Session session,
  ) async {
    final indexed = await FileIndex.db.find(
      session,
      where: (t) => t.status.equals('indexed'),
    );

    final missing = <FileIndex>[];
    for (final file in indexed) {
      final embeddings = await DocumentEmbedding.db.find(
        session,
        where: (t) => t.fileIndexId.equals(file.id!),
      );

      if (embeddings.isEmpty) {
        missing.add(file);
      }
    }

    return missing;
  }

  /// Detect corrupted or invalid data
  static Future<List<FileIndex>> _detectCorruptedData(
    Session session,
  ) async {
    final corrupted = <FileIndex>[];

    // Find files with null or empty required fields
    final files = await FileIndex.db.find(session);

    for (final file in files) {
      if (file.path.isEmpty ||
          file.fileName.isEmpty ||
          file.contentHash.isEmpty && file.status == 'indexed') {
        corrupted.add(file);
      }
    }

    return corrupted;
  }

  /// Calculate overall health score (0-100)
  static double _calculateHealthScore({
    required int totalFiles,
    required int orphanedCount,
    required int staleCount,
    required int duplicateCount,
    required int missingEmbeddingsCount,
    required int corruptedCount,
  }) {
    if (totalFiles == 0) return 100.0;

    // Weight different issues
    const orphanedWeight = 0.3;
    const staleWeight = 0.1;
    const duplicateWeight = 0.2;
    const missingEmbeddingsWeight = 0.3;
    const corruptedWeight = 0.1;

    final orphanedPenalty = (orphanedCount / totalFiles) * 100 * orphanedWeight;
    final stalePenalty = (staleCount / totalFiles) * 100 * staleWeight;
    final duplicatePenalty =
        (duplicateCount / totalFiles) * 100 * duplicateWeight;
    final missingEmbeddingsPenalty =
        (missingEmbeddingsCount / totalFiles) * 100 * missingEmbeddingsWeight;
    final corruptedPenalty =
        (corruptedCount / totalFiles) * 100 * corruptedWeight;

    final totalPenalty =
        orphanedPenalty +
        stalePenalty +
        duplicatePenalty +
        missingEmbeddingsPenalty +
        corruptedPenalty;

    return (100 - totalPenalty).clamp(0.0, 100.0);
  }

  /// Clean up orphaned files from index
  static Future<int> cleanupOrphanedFiles(Session session) async {
    final orphaned = await _findOrphanedFiles(session);

    for (final path in orphaned) {
      final files = await FileIndex.db.find(
        session,
        where: (t) => t.path.equals(path),
      );

      for (final file in files) {
        // Delete embeddings first (cascade)
        await DocumentEmbedding.db.deleteWhere(
          session,
          where: (t) => t.fileIndexId.equals(file.id!),
        );

        // Delete file index
        await FileIndex.db.deleteRow(session, file);
      }
    }

    return orphaned.length;
  }

  /// Re-index stale entries
  static Future<int> refreshStaleEntries(
    Session session, {
    required int staleThresholdDays,
  }) async {
    final stale = await _findStaleEntries(
      session,
      staleThresholdDays: staleThresholdDays,
    );

    int refreshed = 0;
    for (final file in stale) {
      // Check if file still exists
      final exists = await File(file.path).exists();
      if (!exists) continue;

      // Mark as pending for re-indexing
      final updated = file.copyWith(status: 'pending');
      await FileIndex.db.updateRow(session, updated);
      refreshed++;
    }

    return refreshed;
  }

  /// Delete duplicate files (keep one, remove others)
  static Future<int> removeDuplicates(
    Session session, {
    bool keepNewest = true,
  }) async {
    final duplicates = await _findDuplicateContent(session);

    int removed = 0;
    for (final group in duplicates) {
      // Sort files by indexed date
      final sorted = group.files.toList()
        ..sort((a, b) {
          if (a.indexedAt == null && b.indexedAt == null) return 0;
          if (a.indexedAt == null) return keepNewest ? 1 : -1;
          if (b.indexedAt == null) return keepNewest ? -1 : 1;
          return keepNewest
              ? b.indexedAt!.compareTo(a.indexedAt!)
              : a.indexedAt!.compareTo(b.indexedAt!);
        });

      // Keep first (newest or oldest based on flag), remove rest
      for (int i = 1; i < sorted.length; i++) {
        final file = sorted[i];

        // Delete embeddings
        await DocumentEmbedding.db.deleteWhere(
          session,
          where: (t) => t.fileIndexId.equals(file.id!),
        );

        // Delete file index
        await FileIndex.db.deleteRow(session, file);
        removed++;
      }
    }

    return removed;
  }

  /// Fix missing embeddings by marking for re-indexing
  static Future<int> fixMissingEmbeddings(Session session) async {
    final missing = await _findMissingEmbeddings(session);

    for (final file in missing) {
      final updated = file.copyWith(status: 'pending');
      await FileIndex.db.updateRow(session, updated);
    }

    return missing.length;
  }
}

/// Internal duplicate file group (not the protocol model)
class InternalDuplicateGroup {
  final String contentHash;
  final List<FileIndex> files;
  final int duplicateCount;

  InternalDuplicateGroup({
    required this.contentHash,
    required this.files,
    required this.duplicateCount,
  });
}

/// Internal statistics holder
class IndexStatistics {
  final int totalIndexed;
  final int totalPending;
  final int totalFailed;
  final int totalEmbeddings;
  final int averageFileSizeBytes;
  final DateTime? oldestIndexedAt;
  final DateTime? newestIndexedAt;

  IndexStatistics({
    required this.totalIndexed,
    required this.totalPending,
    required this.totalFailed,
    required this.totalEmbeddings,
    required this.averageFileSizeBytes,
    this.oldestIndexedAt,
    this.newestIndexedAt,
  });
}
