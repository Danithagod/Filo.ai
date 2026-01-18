import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Service for detecting duplicate files based on content hash
///
/// Uses the contentHash field from FileIndex which is computed during
/// indexing (SHA-256 of file content). Files with identical hashes are
/// true duplicates (byte-for-byte identical content).
class DuplicateDetector {
  /// Find all duplicate file groups in the index
  ///
  /// Returns groups of files that have identical content (same contentHash).
  /// Each group contains at least 2 files.
  ///
  /// [rootPath] - Optional root path to filter files (only analyze files
  ///              within this directory tree)
  Future<List<DuplicateGroup>> findDuplicates(
    Session session, {
    String? rootPath,
  }) async {
    // Get all indexed files (with status 'indexed')
    List<FileIndex> files;

    if (rootPath != null) {
      // Filter by path prefix
      files = await FileIndex.db.find(
        session,
        where: (t) => t.status.equals('indexed') & t.path.like('$rootPath%'),
      );
    } else {
      files = await FileIndex.db.find(
        session,
        where: (t) => t.status.equals('indexed'),
      );
    }

    // Group files by contentHash
    final hashGroups = <String, List<FileIndex>>{};
    for (final file in files) {
      // Skip files without content hash (shouldn't happen but be safe)
      if (file.contentHash.isEmpty) continue;

      hashGroups.putIfAbsent(file.contentHash, () => []).add(file);
    }

    // Build duplicate groups (only groups with 2+ files)
    final duplicateGroups = <DuplicateGroup>[];

    for (final entry in hashGroups.entries) {
      if (entry.value.length < 2) continue;

      final filesInGroup = entry.value;
      final totalSize = filesInGroup.fold<int>(
        0,
        (sum, f) => sum + f.fileSizeBytes,
      );

      // Potential savings = total - (size of one file)
      // Keep the newest file (most recently modified)
      final potentialSavings = totalSize - filesInGroup.first.fileSizeBytes;

      // Convert to DuplicateFile list
      final duplicateFiles = filesInGroup
          .map(
            (f) => DuplicateFile(
              path: f.path,
              fileName: f.fileName,
              sizeBytes: f.fileSizeBytes,
              modifiedAt: f.fileModifiedAt,
              isIndexed: f.status == 'indexed',
            ),
          )
          .toList();

      // Sort by modification date (newest first)
      duplicateFiles.sort((a, b) {
        if (a.modifiedAt == null && b.modifiedAt == null) return 0;
        if (a.modifiedAt == null) return 1;
        if (b.modifiedAt == null) return -1;
        return b.modifiedAt!.compareTo(a.modifiedAt!);
      });

      duplicateGroups.add(
        DuplicateGroup(
          contentHash: entry.key,
          files: duplicateFiles,
          totalSizeBytes: totalSize,
          potentialSavingsBytes: potentialSavings,
          fileCount: duplicateFiles.length,
        ),
      );
    }

    // Sort by potential savings (largest first)
    duplicateGroups.sort(
      (a, b) => b.potentialSavingsBytes.compareTo(a.potentialSavingsBytes),
    );

    return duplicateGroups;
  }

  /// Calculate total potential savings from all duplicates
  int calculateTotalSavings(List<DuplicateGroup> groups) {
    return groups.fold<int>(
      0,
      (sum, group) => sum + group.potentialSavingsBytes,
    );
  }

  /// Get summary statistics about duplicates
  Map<String, dynamic> getDuplicateStats(List<DuplicateGroup> groups) {
    if (groups.isEmpty) {
      return {
        'totalGroups': 0,
        'totalDuplicateFiles': 0,
        'totalWastedBytes': 0,
        'largestGroup': null,
      };
    }

    final totalDuplicateFiles = groups.fold<int>(
      0,
      (sum, g) => sum + g.fileCount - 1, // -1 because we keep one copy
    );

    return {
      'totalGroups': groups.length,
      'totalDuplicateFiles': totalDuplicateFiles,
      'totalWastedBytes': calculateTotalSavings(groups),
      'largestGroup': groups.first.fileCount,
    };
  }
}
