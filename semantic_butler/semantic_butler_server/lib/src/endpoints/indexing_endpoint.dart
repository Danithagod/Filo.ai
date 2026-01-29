import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/auth_service.dart';
import '../services/indexing_service.dart';
import '../constants/indexing_status.dart';

/// Endpoint for handling hybrid indexing (Client-side indexing, Cloud storage)
class IndexingEndpoint extends Endpoint {
  final _indexingService = IndexingService();

  /// Upload a file index and its embeddings from the client
  /// This allows the client to do local processing (text extraction, embedding generation)
  /// and upload the result to the cloud database.
  Future<void> uploadIndex(
    Session session, {
    required FileIndex fileIndex,
    required List<DocumentEmbedding> embeddings,
  }) async {
    // 1. Security check
    AuthService.requireAuth(session);

    // 2. Validate input with field length constraints
    if (fileIndex.path.isEmpty) {
      throw ArgumentError('File path cannot be empty');
    }
    if (fileIndex.path.length > 4096) {
      throw ArgumentError('File path exceeds maximum length (4096 chars)');
    }
    if (fileIndex.fileName.length > 512) {
      throw ArgumentError('File name exceeds maximum length (512 chars)');
    }
    if (fileIndex.contentHash.length != 64) {
      throw ArgumentError(
        'Content hash must be a valid SHA-256 hash (64 chars)',
      );
    }
    if (fileIndex.contentPreview != null &&
        fileIndex.contentPreview!.length > 2000) {
      // Truncate preview instead of rejecting
      fileIndex.contentPreview = fileIndex.contentPreview!.substring(0, 2000);
    }
    if (fileIndex.summary != null && fileIndex.summary!.length > 5000) {
      // Truncate summary instead of rejecting
      fileIndex.summary = fileIndex.summary!.substring(0, 5000);
    }
    if (!FileIndexStatus.isValid(fileIndex.status)) {
      throw ArgumentError('Invalid status: ${fileIndex.status}. Valid: ${FileIndexStatus.all}');
    }

    // 3. Serialized save with lock
    await _indexingService.withFileLock(fileIndex.path, () async {
      await session.db.transaction((transaction) async {
        // Check if file already exists
        final existing = await FileIndex.db.findFirstRow(
          session,
          where: (t) => t.path.equals(fileIndex.path),
          transaction: transaction,
        );

        int fileIndexId;
        if (existing != null) {
          // Update existing record
          // Preserve ID
          fileIndex.id = existing.id;
          // Ensure status is valid
          fileIndex.status = FileIndexStatus.indexed;
          fileIndex.indexedAt = DateTime.now();

          await FileIndex.db.updateRow(
            session,
            fileIndex,
            transaction: transaction,
          );
          fileIndexId = existing.id!;

          // Clear old embeddings
          await DocumentEmbedding.db.deleteWhere(
            session,
            where: (t) => t.fileIndexId.equals(fileIndexId),
            transaction: transaction,
          );
        } else {
          // Insert new record
          fileIndex.status = FileIndexStatus.indexed;
          fileIndex.indexedAt = DateTime.now();

          final inserted = await FileIndex.db.insertRow(
            session,
            fileIndex,
            transaction: transaction,
          );
          fileIndexId = inserted.id!;
        }

        // Link and save all embeddings
        for (var i = 0; i < embeddings.length; i++) {
          final embedding = embeddings[i];
          embedding.fileIndexId = fileIndexId;
          embedding.chunkIndex = i; // Ensure chunk index is set correctly
          await DocumentEmbedding.db.insertRow(
            session,
            embedding,
            transaction: transaction,
          );
        }
      });
      session.log(
        'Uploaded index for: ${fileIndex.path}',
        level: LogLevel.info,
      );
    });
  }

  /// Batch upload (DEPRECATED: Use uploadIndex for multi-chunk support)
  Future<void> uploadIndexBatch(
    Session session,
    List<FileIndex> files,
    List<DocumentEmbedding> embeddings,
  ) async {
    // This method is currently limited to 1:1 file-to-embedding ratio.
    // For multi-chunk support, use individual uploadIndex calls or a new batch model.
    AuthService.requireAuth(session);
    for (var i = 0; i < files.length; i++) {
      await uploadIndex(
        session,
        fileIndex: files[i],
        embeddings: [embeddings[i]],
      );
    }
  }

  /// Create a indexing job record for client-managed indexing
  Future<IndexingJob?> createClientJob(
    Session session,
    String folderPath,
    int totalFiles,
  ) async {
    AuthService.requireAuth(session);
    return await _indexingService.createClientJob(
      session,
      folderPath,
      totalFiles,
    );
  }

  /// Update the status/progress of a client-managed indexing job
  Future<IndexingJob?> updateJobStatus(
    Session session, {
    required int jobId,
    required String status,
    required int processedFiles,
    required int failedFiles,
    required int skippedFiles,
    String? errorMessage,
  }) async {
    AuthService.requireAuth(session);
    return await _indexingService.updateJobStatus(
      session,
      jobId: jobId,
      status: status,
      processedFiles: processedFiles,
      failedFiles: failedFiles,
      skippedFiles: skippedFiles,
      errorMessage: errorMessage,
    );
  }

  /// Update detailed status for a specific file in a job
  Future<IndexingJobDetail> updateJobDetail(
    Session session, {
    required int jobId,
    required String filePath,
    required String status,
    String? errorMessage,
    String? errorCategory,
  }) async {
    AuthService.requireAuth(session);
    return await _indexingService.updateJobDetail(
      session,
      jobId: jobId,
      filePath: filePath,
      status: status,
      errorMessage: errorMessage,
      errorCategory: errorCategory,
    );
  }

  /// Get all detailed file statuses for a specific job
  Future<List<IndexingJobDetail>> getJobDetails(
    Session session,
    int jobId,
  ) async {
    AuthService.requireAuth(session);
    return await _indexingService.getJobDetails(session, jobId);
  }

  /// Check if a file with the given path and hash already exists in the index
  Future<FileIndex?> checkHash(
    Session session, {
    required String path,
    required String contentHash,
  }) async {
    AuthService.requireAuth(session);
    return await _indexingService.checkHash(session, path, contentHash);
  }

  /// Cancel an active indexing job
  Future<bool> cancelJob(Session session, int jobId) async {
    AuthService.requireAuth(session);
    return await _indexingService.cancelJob(session, jobId);
  }
}
