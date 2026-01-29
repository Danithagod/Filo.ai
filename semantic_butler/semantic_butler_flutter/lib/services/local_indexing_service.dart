import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:async/async.dart'; // Added for FutureGroup
import 'package:extract_text/extract_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import 'package:flutter/foundation.dart'; // Added for compute
import '../utils/app_logger.dart';

/// Service for client-side file indexing
/// Replicates server-side logic for "Hybrid" architecture
class LocalIndexingService {
  final Client client;
  final String openRouterApiKey;

  /// Maximum file size to process (100MB)
  static const int maxFileSizeBytes = 100 * 1024 * 1024;

  /// Lock for checkpoint file writes to prevent race conditions
  static final _checkpointLock = Lock();

  /// Lock for queue access to prevent concurrent modification
  static final _queueLock = Lock();

  LocalIndexingService({
    required this.client,
    required this.openRouterApiKey,
  });

  /// Rate limiter for OpenRouter API (max 50 requests per minute)
  final _rateLimiter = RateLimiter(
    maxRequests: 50,
    perPeriod: const Duration(minutes: 1),
  );

  /// Index a local file: Extract -> Chunk -> Embed -> Upload
  Future<bool> indexFile(String filePath, {int? jobId}) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    // Check file size limit (100MB max)
    final stat = await file.stat();
    if (stat.size > maxFileSizeBytes) {
      AppLogger.warning(
        'Skipping $filePath: File too large (${(stat.size / 1024 / 1024).toStringAsFixed(1)}MB > 100MB limit)',
        tag: 'Indexing',
      );
      if (jobId != null) {
        await client.indexing.updateJobDetail(
          jobId: jobId,
          filePath: filePath,
          status: 'skipped',
          errorMessage:
              'File too large (${(stat.size / 1024 / 1024).toStringAsFixed(1)}MB exceeds 100MB limit)',
        );
      }
      return true; // Skipped
    }

    // Check for zero-byte files
    if (stat.size == 0) {
      AppLogger.debug('Skipping $filePath: Zero-byte file', tag: 'Indexing');
      if (jobId != null) {
        await client.indexing.updateJobDetail(
          jobId: jobId,
          filePath: filePath,
          status: 'skipped',
          errorMessage: 'Zero-byte file',
        );
      }
      return true; // Skipped
    }

    if (jobId != null) {
      await client.indexing.updateJobDetail(
        jobId: jobId,
        filePath: filePath,
        status: 'extracting',
      );
    }

    // 1. Extract Text & Metadata (In background thread with fallback)
    _ExtractionResult extraction;
    try {
      extraction = await compute(
        _staticExtractText,
        filePath,
      ).timeout(const Duration(seconds: 120));
    } catch (e) {
      AppLogger.warning(
        'Isolate extraction failed for $filePath, using fallback: $e',
        tag: 'Indexing',
      );
      // Fallback: extract in main thread
      try {
        extraction = await _staticExtractText(filePath);
      } catch (fallbackError) {
        AppLogger.error(
          'Fallback extraction also failed for $filePath',
          error: fallbackError,
          tag: 'Indexing',
        );
        if (jobId != null) {
          await client.indexing.updateJobDetail(
            jobId: jobId,
            filePath: filePath,
            status: 'failed',
            errorMessage: 'Text extraction failed: $fallbackError',
            errorCategory: 'ExtractionError',
          );
        }
        rethrow;
      }
    }

    // 2. Hash Verification (Deduplication) - continue indexing on failure
    bool skipEmbedding = false;
    try {
      final existing = await client.indexing.checkHash(
        path: filePath,
        contentHash: extraction.contentHash,
      );
      if (existing != null) {
        // For text files with unchanged content, we can skip completely
        // For media files, we still need to upload metadata even if hash matches
        if (extraction.isTextContent && extraction.content.trim().isNotEmpty) {
          AppLogger.debug(
            'Hash hit for text file $filePath: Skipping completely',
            tag: 'Indexing',
          );
          if (jobId != null) {
            await client.indexing.updateJobDetail(
              jobId: jobId,
              filePath: filePath,
              status: 'skipped',
              errorMessage: 'Hash hit, file already indexed',
            );
          }
          return true; // Successfully skipped
        } else {
          // Media file with hash hit: skip embedding but upload metadata
          AppLogger.debug(
            'Hash hit for media file $filePath: Skipping embedding, uploading metadata',
            tag: 'Indexing',
          );
          skipEmbedding = true;
        }
      }
    } catch (e) {
      // Hash check failed - continue with indexing anyway (no deduplication)
      AppLogger.warning(
        'Hash check failed for $filePath, continuing without deduplication: $e',
        tag: 'Indexing',
      );
    }

    // 3. Chunking (Phase 2)
    final chunks =
        extraction.isTextContent && extraction.content.trim().isNotEmpty && !skipEmbedding
        ? _chunkText(extraction.content)
        : <String>[];

    final embeddings = <DocumentEmbedding>[];

    if (chunks.isNotEmpty && !skipEmbedding) {
      if (jobId != null) {
        await client.indexing.updateJobDetail(
          jobId: jobId,
          filePath: filePath,
          status: 'embedding',
        );
      }

      // 4. Generate Embeddings in batch (single API call - optimized)
      try {
        final embeddingVectors = await _generateEmbeddingsBatch(chunks);

        // 5. Build DocumentEmbedding list
        for (var i = 0; i < chunks.length; i++) {
          embeddings.add(
            DocumentEmbedding(
              fileIndexId: 0, // Server will assign
              chunkIndex: i,
              chunkText: null,
              embedding: Vector(embeddingVectors[i]),
            ),
          );
        }
      } catch (e) {
        AppLogger.warning(
          'Embedding failed for $filePath, falling back to metadata-only: $e',
          tag: 'Indexing',
        );
        // Continue with empty embeddings (metadata only)
      }
    } else {
      if (skipEmbedding) {
        AppLogger.debug(
          'Skipping embedding for $filePath (hash hit)',
          tag: 'Indexing',
        );
      } else {
        AppLogger.debug(
          'Skipping embedding for $filePath (non-text or empty content)',
          tag: 'Indexing',
        );
      }
    }

    // 5. Prepare FileIndex
    final fileIndex = FileIndex(
      path: filePath,
      fileName: extraction.fileName,
      contentHash: extraction.contentHash,
      fileSizeBytes: extraction.fileSizeBytes,
      mimeType: extraction.mimeType,
      contentPreview: extraction.preview,
      isTextContent: extraction.isTextContent,
      documentCategory: extraction.documentCategory,
      status: 'indexed',
      indexedAt: DateTime.now(),
      fileCreatedAt: extraction.fileCreatedAt,
      fileModifiedAt: extraction.fileModifiedAt,
      wordCount: extraction.wordCount,
      embeddingModel: chunks.isNotEmpty
          ? 'openai/text-embedding-3-small'
          : 'none',
    );

    // 7. Upload to Server with retry logic
    await _uploadWithRetry(fileIndex, embeddings);

    if (jobId != null) {
      await client.indexing.updateJobDetail(
        jobId: jobId,
        filePath: filePath,
        status: 'complete',
      );
    }
    return false; // Not skipped
  }

  /// Upload index with exponential backoff retry
  Future<void> _uploadWithRetry(
    FileIndex fileIndex,
    List<DocumentEmbedding> embeddings, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        await client.indexing.uploadIndex(
          fileIndex: fileIndex,
          embeddings: embeddings,
        );
        return; // Success
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          AppLogger.error(
            'Upload failed after $maxRetries attempts: ${fileIndex.path}',
            error: e,
            tag: 'Indexing',
          );
          rethrow;
        }
        final delay = Duration(seconds: pow(2, attempt).toInt());
        AppLogger.warning(
          'Upload attempt $attempt failed for ${fileIndex.path}. Retrying in ${delay.inSeconds}s...',
          tag: 'Indexing',
        );
        await Future.delayed(delay);
      }
    }
  }

  /// Chunk text into overlapping segments
  List<String> _chunkText(
    String text, {
    int chunkSize = 2000,
    int overlap = 200,
  }) {
    if (text.isEmpty) return [''];
    if (text.length <= chunkSize) return [text];

    final chunks = <String>[];
    int start = 0;
    while (start < text.length) {
      int end = start + chunkSize;
      if (end > text.length) end = text.length;

      chunks.add(text.substring(start, end));
      if (end == text.length) break;
      start = end - overlap;
    }
    return chunks;
  }

  /// Recursively index a directory
  Future<IndexingResultStats> indexDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      AppLogger.error('Directory does not exist: $dirPath', tag: 'Indexing');
      return IndexingResultStats();
    }

    AppLogger.info('Starting local indexing for $dirPath', tag: 'Indexing');

    // 1. Scan for files first to get total count
    final files = <File>[];
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          // Skip hidden files/folders (standard Unix/Dotfile check)
          if (path.basename(entity.path).startsWith('.')) continue;
          // Skip folders that start with . (like .git, .dart_tool)
          if (entity.path
              .split(path.separator)
              .any((p) => p.startsWith('.') && p != '.'))
            continue;

          // Index ALL non-hidden files (Metadata-only if unsupported)
          files.add(entity);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to scan directory: $e', tag: 'Indexing');
      return IndexingResultStats();
    }

    if (files.isEmpty) {
      AppLogger.info('No indexable files found in $dirPath', tag: 'Indexing');
      return IndexingResultStats();
    }

    // 2. Register job in backend
    IndexingJob? job;
    try {
      job = await client.indexing.createClientJob(dirPath, files.length);
      AppLogger.info('Registered backend job: ${job?.id}', tag: 'Indexing');
    } catch (e) {
      AppLogger.error(
        'Failed to register job in backend. UI might not update, but indexing will proceed.',
        error: e,
        tag: 'Indexing',
      );
    }

    int processed = 0;
    int failed = 0;
    int skipped = 0;

    // --- Checkpoint Logic ---
    final supportDir = await getApplicationSupportDirectory();
    final checkpointDir = Directory(
      path.join(supportDir.path, 'indexing_checkpoints'),
    );
    if (!await checkpointDir.exists()) {
      await checkpointDir.create(recursive: true);
    }

    // Hash the path to create a unique but consistent filename
    final pathHash = sha256
        .convert(utf8.encode(dirPath))
        .toString()
        .substring(0, 10);
    final checkpointFile = File(
      path.join(checkpointDir.path, 'ckpt_$pathHash.json'),
    );

    Set<String> indexedInCheckpoint = {};
    if (await checkpointFile.exists()) {
      try {
        final json = jsonDecode(await checkpointFile.readAsString());
        indexedInCheckpoint = Set<String>.from(json['indexed'] ?? []);
        AppLogger.info(
          'Resuming from checkpoint: ${indexedInCheckpoint.length} files already indexed',
          tag: 'Indexing',
        );
      } catch (e) {
        AppLogger.debug('Failed to load checkpoint: $e', tag: 'Indexing');
      }
    }

    final filesToIndex = files
        .where((f) => !indexedInCheckpoint.contains(f.path))
        .toList();
    skipped += files.length - filesToIndex.length;

    // 3. Process files with concurrency
    const concurrency = 5;
    final group = FutureGroup<void>();
    final queue = List<File>.from(filesToIndex);

    Future<void> processNext() async {
      while (true) {
        // Thread-safe queue access
        final file = await _queueLock.synchronized(() async {
          if (queue.isEmpty) return null;
          return queue.removeAt(0);
        });
        if (file == null) break;
        try {
          final wasSkipped = await indexFile(file.path, jobId: job?.id);
          if (wasSkipped) {
            skipped++;
          } else {
            processed++;
          }
        } catch (e) {
          failed++;
          if (job != null) {
            await client.indexing.updateJobDetail(
              jobId: job.id!,
              filePath: file.path,
              status: 'failed',
              errorMessage: e.toString(),
              errorCategory: 'ProcessingError',
            );
          }
          AppLogger.error(
            'Failed to index ${file.path}',
            error: e,
            tag: 'Indexing',
          );
        }

        // 4. Periodically update backend and checkpoint
        if ((processed + failed + skipped) % 5 == 0) {
          if (job != null) {
            try {
              await client.indexing.updateJobStatus(
                jobId: job.id!,
                status: 'running',
                processedFiles: processed,
                failedFiles: failed,
                skippedFiles: skipped,
              );
            } catch (e) {
              AppLogger.debug(
                'Failed to update job progress: $e',
                tag: 'Indexing',
              );
            }
          }

          // Save checkpoint with file lock to prevent race conditions
          await _checkpointLock.synchronized(() async {
            try {
              final indexedFiles = files
                  .where((f) => !queue.contains(f))
                  .map((f) => f.path)
                  .toList();
              await checkpointFile.writeAsString(
                jsonEncode({
                  'indexed': indexedFiles,
                  'timestamp': DateTime.now().toIso8601String(),
                }),
              );
            } catch (e) {
              AppLogger.debug('Failed to save checkpoint: $e', tag: 'Indexing');
            }
          });
        }
      }
    }

    // Start initial workers
    for (var i = 0; i < min(concurrency, filesToIndex.length); i++) {
      group.add(processNext());
    }

    group.close();
    await group.future;

    // 5. Final update
    if (job != null) {
      try {
        await client.indexing.updateJobStatus(
          jobId: job.id!,
          status: failed == files.length ? 'failed' : 'completed',
          processedFiles: processed,
          failedFiles: failed,
          skippedFiles: skipped,
          errorMessage: failed > 0 ? '$failed files failed to index' : null,
        );
        AppLogger.info('Finalized backend job: ${job.id}', tag: 'Indexing');
      } catch (e) {
        AppLogger.error('Failed to finalize job: $e', tag: 'Indexing');
      }
    }

    AppLogger.info(
      'Completed indexing $dirPath. Processed: $processed, Failed: $failed, Skipped: $skipped',
      tag: 'Indexing',
    );

    // Clean up checkpoint on success
    if (failed == 0 && filesToIndex.isNotEmpty) {
      try {
        if (await checkpointFile.exists()) await checkpointFile.delete();
      } catch (e) {
        AppLogger.debug(
          'Failed to delete checkpoint file: $e',
          tag: 'Indexing',
        );
      }
    }

    return IndexingResultStats(
      processed: processed,
      failed: failed,
      skipped: skipped,
      total: files.length,
    );
  }

  // --- Extraction Logic (Offloaded to Isolate) ---

  static Future<_ExtractionResult> _staticExtractText(String filePath) async {
    final file = File(filePath);
    final fileName = path.basename(filePath);
    final ext = path.extension(filePath).toLowerCase();
    final stat = await file.stat();
    final fileSize = stat.size;

    String content = '';
    bool isTextContent = true;

    try {
      if (ext == '.pdf') {
        content = await _staticExtractPdfText(file);
      } else if (ext == '.docx') {
        content = await _staticExtractDocxText(file);
      } else if (_supportedExtensions.contains(ext)) {
        content = await file.readAsString();
      } else {
        // Generic metadata-only for all other unsupported/binary formats
        content = '';
        isTextContent = false;
      }
    } catch (e) {
      // Note: Can't use AppLogger here as it might not be initialized in Isolate
      content = 'Extraction Failed';
      isTextContent = false;
    }

    // Hash the FULL content (before trimming) for deduplication
    // For media files (empty content), use fileSize + modifiedAt to match server-side calculation
    final contentHash = sha256
        .convert(utf8.encode(content.isEmpty 
            ? '${fileSize}_${stat.modified.millisecondsSinceEpoch}' 
            : content))
        .toString();

    String preview = content.length > 200 ? content.substring(0, 200) : content;
    if (!isTextContent && content.isEmpty) {
      preview = '[File Metadata] $fileName';
    }

    return _ExtractionResult(
      content: content,
      fileName: fileName,
      fileSizeBytes: fileSize,
      mimeType: _getMimeType(filePath),
      documentCategory: _getCategoryString(_getDocumentCategory(filePath)),
      wordCount: content
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .length,
      preview: preview,
      contentHash: contentHash,
      fileCreatedAt: stat.changed,
      fileModifiedAt: stat.modified,
      isTextContent: isTextContent,
    );
  }

  static Future<String> _staticExtractPdfText(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final pdfSource = String.fromCharCodes(bytes);
      final textBuffer = StringBuffer();

      final btPattern = RegExp(r'\(([^)]+)\)');
      final matches = btPattern.allMatches(pdfSource);

      for (final match in matches) {
        final text = match.group(1);
        if (text != null && text.length > 2) {
          final cleaned = text.replaceAll(RegExp(r'[^\x20-\x7E\s]'), '');
          if (cleaned.length > 2) {
            textBuffer.write(cleaned);
            textBuffer.write(' ');
          }
        }
      }
      return textBuffer.toString().trim();
    } catch (e) {
      return '[PDF Extraction Failed]';
    }
  }

  static Future<String> _staticExtractDocxText(File file) async {
    try {
      final text = await ExtractText.fromFile(file.path);
      return text.isEmpty ? '[No text found in DOCX]' : text;
    } catch (e) {
      return '[DOCX Extraction Failed]';
    }
  }

  // --- Parity Helpers (matching backend) ---

  static const _supportedExtensions = {
    '.txt',
    '.md',
    '.markdown',
    '.rtf',
    '.pdf',
    '.dart',
    '.js',
    '.ts',
    '.jsx',
    '.tsx',
    '.py',
    '.java',
    '.kt',
    '.swift',
    '.go',
    '.rs',
    '.cpp',
    '.c',
    '.h',
    '.hpp',
    '.cs',
    '.rb',
    '.php',
    '.html',
    '.css',
    '.scss',
    '.sass',
    '.less',
    '.json',
    '.yaml',
    '.yml',
    '.xml',
    '.sql',
    '.sh',
    '.bash',
    '.zsh',
    '.ps1',
    '.bat',
    '.cmd',
    '.env',
    '.gitignore',
    '.dockerignore',
    '.editorconfig',
    '.toml',
    '.ini',
    '.cfg',
    '.conf',
    '.docx',
    '.csv',
  };

  static const _mediaExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.tiff',
    '.webp',
    '.svg',
    '.ico',
    '.heic',
    '.heif',
    '.raw',
    '.mp4',
    '.avi',
    '.mov',
    '.mkv',
    '.wmv',
    '.flv',
    '.webm',
    '.mp3',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.m4a',
  };

  static String _getMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    const mimeTypes = {
      '.txt': 'text/plain',
      '.md': 'text/markdown',
      '.pdf': 'application/pdf',
      '.json': 'application/json',
      '.dart': 'application/dart',
      '.html': 'text/html',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
  }

  static String _getCategoryString(String? category) {
    if (category == null) return 'document';
    return category.split('.').last;
  }

  static String _getDocumentCategory(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    if (['.dart', '.js', '.ts', '.py', '.java', '.go', '.rs'].contains(ext)) {
      return 'code';
    }
    if (['.json', '.xml', '.csv'].contains(ext)) {
      return 'data';
    }
    if ([
      '.env',
      '.yaml',
      '.yml',
      '.toml',
      '.ini',
      '.cfg',
      '.conf',
    ].contains(ext)) {
      return 'config';
    }
    if (_mediaExtensions.contains(ext)) {
      return 'media_metadata';
    }
    return 'other';
  }

  // --- Embedding Logic ---

  /// Generate embeddings for multiple chunks in a single API call (batch mode)
  /// This is more efficient than calling _generateEmbedding for each chunk
  Future<List<List<double>>> _generateEmbeddingsBatch(
    List<String> texts,
  ) async {
    if (openRouterApiKey.isEmpty) {
      throw Exception(
        'OpenRouter API Key is required for client-side embedding. Please set it in Settings.',
      );
    }

    if (texts.isEmpty) return [];

    // For single text, use the regular method
    if (texts.length == 1) {
      return [await _generateEmbedding(texts[0])];
    }

    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        await _rateLimiter.acquire();

        // OpenRouter/OpenAI supports batch input as an array
        final response = await http
            .post(
              Uri.parse('https://openrouter.ai/api/v1/embeddings'),
              headers: {
                'Authorization': 'Bearer $openRouterApiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': 'openai/text-embedding-3-small',
                'input': texts, // Array of texts for batch processing
              }),
            )
            .timeout(
              const Duration(seconds: 120), // Longer timeout for batch
              onTimeout: () => throw TimeoutException(
                'Batch embedding API request timed out after 120s',
              ),
            );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final dataList = data['data'] as List;
          // Sort by index to ensure correct order
          dataList.sort(
            (a, b) => (a['index'] as int).compareTo(b['index'] as int),
          );
          return dataList
              .map((item) => List<double>.from(item['embedding']))
              .toList();
        }

        if (response.statusCode == 429) {
          final retryAfter = _parseRetryAfter(response);
          final delay =
              retryAfter ?? Duration(seconds: pow(2, attempt).toInt());
          AppLogger.warning(
            'Rate limited (429) on batch. Retrying in ${delay.inSeconds}s...',
            tag: 'Indexing',
          );
          await Future.delayed(delay);
          attempt++;
          continue;
        }

        if (response.statusCode >= 500 && attempt < maxRetries - 1) {
          final delay = Duration(seconds: pow(2, attempt).toInt());
          AppLogger.warning(
            'Server error (${response.statusCode}) on batch. Retrying in ${delay.inSeconds}s...',
            tag: 'Indexing',
          );
          await Future.delayed(delay);
          attempt++;
          continue;
        }

        throw Exception(
          'Failed to generate batch embeddings: ${response.statusCode} ${response.body}',
        );
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          AppLogger.error(
            'Max retries exceeded for batch embedding: $e',
            tag: 'Indexing',
          );
          // Fallback to individual requests
          AppLogger.warning(
            'Falling back to individual embedding requests',
            tag: 'Indexing',
          );
          final results = <List<double>>[];
          for (final text in texts) {
            results.add(await _generateEmbedding(text));
          }
          return results;
        }
        final delay = Duration(seconds: pow(2, attempt).toInt());
        AppLogger.debug(
          'Batch embedding attempt $attempt failed: $e. Retrying in ${delay.inSeconds}s...',
          tag: 'Indexing',
        );
        await Future.delayed(delay);
      }
    }

    throw Exception('Max retries exceeded for batch embedding generation');
  }

  Future<List<double>> _generateEmbedding(String text) async {
    if (openRouterApiKey.isEmpty) {
      throw Exception(
        'OpenRouter API Key is required for client-side embedding. Please set it in Settings.',
      );
    }

    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        await _rateLimiter.acquire();

        final response = await http
            .post(
              Uri.parse('https://openrouter.ai/api/v1/embeddings'),
              headers: {
                'Authorization': 'Bearer $openRouterApiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': 'openai/text-embedding-3-small',
                'input': text,
              }),
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () => throw TimeoutException(
                'Embedding API request timed out after 60s',
              ),
            );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final embedding = List<double>.from(data['data'][0]['embedding']);
          return embedding;
        }

        if (response.statusCode == 429) {
          final retryAfter = _parseRetryAfter(response);
          final delay =
              retryAfter ?? Duration(seconds: pow(2, attempt).toInt());
          AppLogger.warning(
            'Rate limited (429). Retrying in ${delay.inSeconds}s...',
            tag: 'Indexing',
          );
          await Future.delayed(delay);
          attempt++;
          continue;
        }

        if (response.statusCode >= 500 && attempt < maxRetries - 1) {
          final delay = Duration(seconds: pow(2, attempt).toInt());
          AppLogger.warning(
            'Server error (${response.statusCode}). Retrying in ${delay.inSeconds}s...',
            tag: 'Indexing',
          );
          await Future.delayed(delay);
          attempt++;
          continue;
        }

        throw Exception(
          'Failed to generate embedding: ${response.statusCode} ${response.body}',
        );
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          AppLogger.error(
            'Max retries exceeded for embedding: $e',
            tag: 'Indexing',
          );
          rethrow;
        }
        final delay = Duration(seconds: pow(2, attempt).toInt());
        AppLogger.debug(
          'Embedding attempt $attempt failed: $e. Retrying in ${delay.inSeconds}s...',
          tag: 'Indexing',
        );
        await Future.delayed(delay);
      }
    }

    throw Exception('Max retries exceeded for embedding generation');
  }

  Duration? _parseRetryAfter(http.Response response) {
    final retryAfter = response.headers['retry-after'];
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) return Duration(seconds: seconds);
    }
    return null;
  }
}

/// Simple rate limiter using a sliding window
class RateLimiter {
  final int maxRequests;
  final Duration perPeriod;
  final Queue<DateTime> _requests = Queue();

  RateLimiter({required this.maxRequests, required this.perPeriod});

  Future<void> acquire() async {
    final now = DateTime.now();
    _requests.removeWhere((t) => now.difference(t) > perPeriod);

    if (_requests.length >= maxRequests) {
      final waitTime = perPeriod - now.difference(_requests.first);
      if (waitTime > Duration.zero) {
        await Future.delayed(waitTime);
      }
      return acquire(); // Re-check after waiting
    }

    _requests.add(now);
  }
}

class _ExtractionResult {
  final String content;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final String documentCategory;
  final int wordCount;
  final String preview;
  final String contentHash;
  final DateTime fileCreatedAt;
  final DateTime fileModifiedAt;
  final bool isTextContent;

  _ExtractionResult({
    required this.content,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.documentCategory,
    required this.wordCount,
    required this.preview,
    required this.contentHash,
    required this.fileCreatedAt,
    required this.fileModifiedAt,
    required this.isTextContent,
  });
}

/// Simple async lock for synchronizing access to shared resources
class Lock {
  Completer<void>? _completer;

  /// Execute [action] with exclusive access
  Future<T> synchronized<T>(Future<T> Function() action) async {
    while (_completer != null) {
      await _completer!.future;
    }
    _completer = Completer<void>();
    try {
      return await action();
    } finally {
      final c = _completer;
      _completer = null;
      c?.complete();
    }
  }
}

/// Stats for an indexing operation
class IndexingResultStats {
  final int processed;
  final int failed;
  final int skipped;
  final int total;

  IndexingResultStats({
    this.processed = 0,
    this.failed = 0,
    this.skipped = 0,
    this.total = 0,
  });

  bool get isEmpty => total == 0;
  bool get hasFailures => failed > 0;
}
