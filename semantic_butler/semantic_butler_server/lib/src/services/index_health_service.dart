import 'package:serverpod/serverpod.dart';
import 'dart:io';
import 'dart:math';
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

    // Run all checks in parallel with error handling for each
    final results = await Future.wait<dynamic>([
      _findOrphanedFiles(session).catchError((e) {
        session.log(
          'IndexHealth: Orphaned files check failed: $e',
          level: LogLevel.error,
        );
        return <String>[];
      }),
      _findStaleEntries(session, staleThresholdDays: 180).catchError((e) {
        session.log(
          'IndexHealth: Stale entries check failed: $e',
          level: LogLevel.error,
        );
        return <FileIndex>[];
      }),
      _findDuplicateContent(session).catchError((e) {
        session.log(
          'IndexHealth: Duplicate content check failed: $e',
          level: LogLevel.error,
        );
        return <InternalDuplicateGroup>[];
      }),
      _getIndexStatistics(session).catchError((e) {
        session.log(
          'IndexHealth: Statistics calculation failed: $e',
          level: LogLevel.error,
        );
        return IndexStatistics(
          totalIndexed: 0,
          totalPending: 0,
          totalFailed: 0,
          totalEmbeddings: 0,
          averageFileSizeBytes: 0,
        );
      }),
      _findMissingEmbeddings(session).catchError((e) {
        session.log(
          'IndexHealth: Missing embeddings check failed: $e',
          level: LogLevel.error,
        );
        return <FileIndex>[];
      }),
      _detectCorruptedData(session).catchError((e) {
        session.log(
          'IndexHealth: Corrupted data detection failed: $e',
          level: LogLevel.error,
        );
        return <FileIndex>[];
      }),
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
    int avgSize = 0;
    try {
      final result = await session.db.unsafeQuery(
        'SELECT AVG("fileSizeBytes") FROM file_index WHERE status = \'indexed\'',
      );
      if (result.isNotEmpty &&
          result.first.isNotEmpty &&
          result.first.first != null) {
        // Handle different numeric types from various drivers (double, int, BigInt, etc.)
        final rawVal = result.first.first;
        avgSize = (double.tryParse(rawVal.toString()) ?? 0).toInt();
      }
    } catch (e) {
      session.log(
        'Failed to calculate average file size: $e',
        level: LogLevel.debug,
      );
    }

    return IndexStatistics(
      totalIndexed: totalIndexed,
      totalPending: totalPending,
      totalFailed: totalFailed,
      totalEmbeddings: totalEmbeddings,
      averageFileSizeBytes: avgSize,
    );
  }

  static Future<List<FileIndex>> _findMissingEmbeddings(Session session) async {
    // Files indexed but having no entries in DocumentEmbedding
    final result = await session.db.unsafeQuery(
      'SELECT id FROM file_index f WHERE status = \'indexed\' '
      'AND NOT EXISTS (SELECT 1 FROM document_embedding de WHERE de."fileIndexId" = f.id)',
    );

    if (result.isEmpty) return [];

    final ids = result
        .map((row) => int.tryParse(row.first.toString()) ?? -1)
        .where((id) => id != -1)
        .toList();
    if (ids.isEmpty) return [];
    return await FileIndex.db.find(
      session,
      where: (t) => t.id.inSet(ids.toSet()),
    );
  }

  static Future<List<FileIndex>> _detectCorruptedData(Session session) async {
    // Files with invalid content or missing critical metadata
    return await FileIndex.db.find(
      session,
      where: (t) =>
          t.status.equals('indexed') &
          (t.contentHash.equals('') |
              t.fileName.equals('') |
              t.path.equals('')),
    );
  }

  static double _calculateHealthScore({
    required int totalFiles,
    required int orphanedCount,
    required int staleCount,
    required int duplicateCount,
    required int missingEmbeddingsCount,
    required int corruptedCount,
  }) {
    if (totalFiles == 0) return 0.0; // No files = no index health to measure

    // Use exponential penalties for critical issues (orphans, corruption, missing embeddings)
    // These penalties scale so that even a few issues significantly impact the score
    double orphanedPenalty = orphanedCount > 0
        ? 50 * (1 - (pow(0.9, orphanedCount) as double))
        : 0;
    double corruptedPenalty = corruptedCount > 0
        ? 100 * (1 - (pow(0.8, corruptedCount) as double))
        : 0;
    double missingEmbeddingsPenalty = missingEmbeddingsCount > 0
        ? 40 * (1 - (pow(0.95, missingEmbeddingsCount) as double))
        : 0;

    // Linear penalties for less critical issues
    double stalePenalty = totalFiles > 0 ? (staleCount / totalFiles) * 10 : 0;
    double duplicatePenalty = totalFiles > 0
        ? (duplicateCount / totalFiles) * 15
        : 0;

    double totalPenalty =
        orphanedPenalty +
        stalePenalty +
        duplicatePenalty +
        missingEmbeddingsPenalty +
        corruptedPenalty;

    return (100 - totalPenalty).clamp(0.0, 100.0);
  }

  /// Clean up orphaned files from index (using batch operations for scale)
  static Future<int> cleanupOrphanedFiles(Session session) async {
    final orphanedPaths = await _findOrphanedFiles(session);
    if (orphanedPaths.isEmpty) return 0;

    // 1. Find all FileIndex records in a single query
    final filesToRemove = await FileIndex.db.find(
      session,
      where: (t) => t.path.inSet(orphanedPaths.toSet()),
    );
    if (filesToRemove.isEmpty) return 0;

    final fileIds = filesToRemove.map((f) => f.id!).toList();

    // 2. Perform deletions in a single transaction
    await session.db.transaction((transaction) async {
      // Deletions from DocumentEmbedding and FileIndex will handle everything.
      // SQL CASCADE or explicit deleteWhere below.

      // Batch delete from DocumentEmbedding
      await DocumentEmbedding.db.deleteWhere(
        session,
        where: (t) => t.fileIndexId.inSet(fileIds.toSet()),
        transaction: transaction,
      );

      // Batch delete from FileIndex
      await FileIndex.db.deleteWhere(
        session,
        where: (t) => t.id.inSet(fileIds.toSet()),
        transaction: transaction,
      );
    });

    return filesToRemove.length;
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

  /// Delete duplicate files (keep one, remove others - using batch operations)
  static Future<int> removeDuplicates(
    Session session, {
    bool keepNewest = true,
  }) async {
    final duplicates = await _findDuplicateContent(session);
    if (duplicates.isEmpty) return 0;

    final fileIdsToRemove = <int>{};

    for (final group in duplicates) {
      final sorted = group.files.toList()
        ..sort((a, b) {
          if (a.indexedAt == null && b.indexedAt == null) return 0;
          if (a.indexedAt == null) return keepNewest ? 1 : -1;
          if (b.indexedAt == null) return keepNewest ? -1 : 1;
          return keepNewest
              ? b.indexedAt!.compareTo(a.indexedAt!)
              : a.indexedAt!.compareTo(b.indexedAt!);
        });

      // Keep first, mark rest for removal
      for (int i = 1; i < sorted.length; i++) {
        fileIdsToRemove.add(sorted[i].id!);
      }
    }

    if (fileIdsToRemove.isEmpty) return 0;

    // Perform deletions in batches to avoid extremely large transaction logs
    final idsList = fileIdsToRemove.toList();
    const batchSize = 100;
    int totalRemoved = 0;

    for (var i = 0; i < idsList.length; i += batchSize) {
      final currentBatch = idsList.sublist(
        i,
        i + batchSize > idsList.length ? idsList.length : i + batchSize,
      );
      final batchSet = currentBatch.toSet();

      await session.db.transaction((transaction) async {
        // Managed table deletions handle the cleanup.

        await DocumentEmbedding.db.deleteWhere(
          session,
          where: (t) => t.fileIndexId.inSet(batchSet),
          transaction: transaction,
        );

        await FileIndex.db.deleteWhere(
          session,
          where: (t) => t.id.inSet(batchSet),
          transaction: transaction,
        );
      });
      totalRemoved += currentBatch.length;
    }

    return totalRemoved;
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
