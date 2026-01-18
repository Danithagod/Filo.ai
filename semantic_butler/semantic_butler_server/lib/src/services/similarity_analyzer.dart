import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Service for finding semantically similar documents using vector similarity
///
/// Uses the existing DocumentEmbedding table with pgvector for efficient
/// similarity search. This helps identify:
/// - Related documents that users might want to consolidate
/// - Potential duplicates that have different content but similar meaning
/// - Documents that could be organized together
class SimilarityAnalyzer {
  /// Find groups of semantically similar documents
  ///
  /// [threshold] - Minimum similarity score (0.0-1.0). Default 0.85 means
  ///               documents must be 85% similar to be grouped.
  /// [maxGroups] - Maximum number of groups to return
  /// [minGroupSize] - Minimum files per group (default 2)
  Future<List<SimilarContentGroup>> findSimilar(
    Session session, {
    double threshold = 0.85,
    int maxGroups = 20,
    int minGroupSize = 2,
  }) async {
    final groups = <SimilarContentGroup>[];

    try {
      // Use pgvector to find similar document pairs
      // Query: Find pairs of documents with cosine similarity > threshold
      final rows = await session.db.unsafeQuery(
        '''
        WITH similar_pairs AS (
          SELECT 
            de1."fileIndexId" as file1_id,
            de2."fileIndexId" as file2_id,
            1 - (de1.embedding <=> de2.embedding) as similarity
          FROM document_embedding de1
          CROSS JOIN document_embedding de2
          WHERE de1.id < de2.id
            AND de1.embedding IS NOT NULL
            AND de2.embedding IS NOT NULL
            AND 1 - (de1.embedding <=> de2.embedding) > \$1
          ORDER BY similarity DESC
          LIMIT 100
        )
        SELECT 
          sp.file1_id,
          sp.file2_id,
          sp.similarity,
          f1.path as file1_path,
          f1."fileName" as file1_name,
          f1."contentPreview" as file1_preview,
          f1."documentCategory" as file1_category,
          f2.path as file2_path,
          f2."fileName" as file2_name,
          f2."contentPreview" as file2_preview,
          f2."documentCategory" as file2_category
        FROM similar_pairs sp
        JOIN file_index f1 ON sp.file1_id = f1.id
        JOIN file_index f2 ON sp.file2_id = f2.id
        ''',
        parameters: QueryParameters.positional([threshold]),
      );

      // Group similar pairs together
      // Use Union-Find algorithm to cluster related documents
      final parent = <int, int>{};

      int find(int x) {
        if (!parent.containsKey(x)) parent[x] = x;
        if (parent[x] != x) parent[x] = find(parent[x]!);
        return parent[x]!;
      }

      void union(int x, int y) {
        final px = find(x);
        final py = find(y);
        if (px != py) parent[px] = py;
      }

      // Map to store file info
      final fileInfo = <int, Map<String, dynamic>>{};

      for (final row in rows) {
        final file1Id = row[0] as int;
        final file2Id = row[1] as int;
        final similarity = row[2] as double;

        // Store file info
        fileInfo[file1Id] = {
          'path': row[3] as String,
          'fileName': row[4] as String,
          'preview': row[5] as String?,
          'category': row[6] as String?,
          'similarity': similarity,
        };

        fileInfo[file2Id] = {
          'path': row[7] as String,
          'fileName': row[8] as String,
          'preview': row[9] as String?,
          'category': row[10] as String?,
          'similarity': similarity,
        };

        // Union the two files
        union(file1Id, file2Id);
      }

      // Group files by their root parent
      final groupedFiles = <int, List<int>>{};
      for (final fileId in fileInfo.keys) {
        final root = find(fileId);
        groupedFiles.putIfAbsent(root, () => []).add(fileId);
      }

      // Build SimilarContentGroup for each cluster
      for (final entry in groupedFiles.entries) {
        final filesInGroup = entry.value;
        if (filesInGroup.length < minGroupSize) continue;

        // Calculate average similarity for the group
        double totalSimilarity = 0;
        int pairCount = 0;

        // Get similarity from stored file info (use first file's similarity)
        for (final fileId in filesInGroup) {
          final info = fileInfo[fileId];
          if (info != null && info['similarity'] != null) {
            totalSimilarity += info['similarity'] as double;
            pairCount++;
          }
        }

        final avgSimilarity = pairCount > 0 ? totalSimilarity / pairCount : 0.0;

        // Convert to SimilarFile list
        final similarFiles = filesInGroup.map((fileId) {
          final info = fileInfo[fileId]!;
          return SimilarFile(
            path: info['path'] as String,
            fileName: info['fileName'] as String,
            contentPreview: info['preview'] as String?,
            category: info['category'] as String?,
          );
        }).toList();

        groups.add(
          SimilarContentGroup(
            similarityScore: avgSimilarity,
            files: similarFiles,
            fileCount: similarFiles.length,
            similarityReason:
                'These documents share similar content and concepts',
          ),
        );
      }

      // Sort by similarity score (highest first)
      groups.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));

      // Limit to maxGroups
      return groups.take(maxGroups).toList();
    } catch (e) {
      // pgvector might not be available - return empty list
      session.log(
        'SimilarityAnalyzer: Failed to find similar documents: $e',
        level: LogLevel.warning,
      );
      return [];
    }
  }

  /// Check if pgvector extension is available
  Future<bool> isPgvectorAvailable(Session session) async {
    try {
      final result = await session.db.unsafeQuery(
        "SELECT 1 FROM pg_extension WHERE extname = 'vector'",
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
