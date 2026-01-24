# Indexing Improvements Implementation Plan

## Table of Contents

1. [Overview](#overview)
2. [Gap Analysis Summary](#gap-analysis-summary)
3. [Phase 0: Critical Infrastructure Fixes](#phase-0-critical-infrastructure-fixes)
4. [Phase 1: Critical File Format Support](#phase-1-critical-file-format-support)
5. [Phase 2: Configuration & Flexibility](#phase-2-configuration--flexibility)
6. [Phase 3: Scanning Performance](#phase-3-scanning-performance)
7. [Phase 4: Error Handling & Recovery](#phase-4-error-handling--recovery)
8. [Phase 5: File Watcher Enhancements](#phase-5-file-watcher-enhancements)
9. [Phase 6: Data Integrity & Health](#phase-6-data-integrity--health)
10. [Phase 7: Advanced Features](#phase-7-advanced-features)
11. [Testing Strategy](#testing-strategy)
12. [Rollout Plan](#rollout-plan)

---

## Overview

This implementation plan addresses the gaps identified in the indexing system analysis. The plan is organized into 8 phases (including Phase 0 for critical infrastructure), prioritized by impact and effort. Each phase includes specific tasks, file locations, and acceptance criteria.

### Priority Legend

| Priority | Description | Typical Timeline |
|----------|-------------|------------------|
| **P0** | Critical - blocks core functionality / data loss risk | 1-2 weeks |
| **P1** | High - significant user impact | 2-3 weeks |
| **P2** | Medium - improves reliability | 1-2 weeks |
| **P3** | Low - nice to have features | 2-4 weeks |

### Summary of All Phases

| Phase | Focus Areas | Priority | Est. Duration |
|-------|-------------|----------|---------------|
| 0 | Job cancellation, transaction consistency | P0 | 1 week |
| 1 | Office/PDF support, proper extraction | P0 | 2 weeks |
| 2 | Configurable limits, settings UI | P1 | 1 week |
| 3 | Incremental scanning, parallel processing | P1 | 2 weeks |
| 4 | Retry logic, dead letter queue | P2 | 1 week |
| 5 | Volume monitoring, directory identity | P2 | 2 weeks |
| 6 | Integrity checks, orphaned cleanup | P2 | 1 week |
| 7 | OCR, thumbnails, language detection | P3 | 4 weeks |

**Total Estimated Duration:** 14 weeks (including testing and buffer)

---

## Gap Analysis Summary

Based on comprehensive code analysis, the following gaps and issues were identified:

### Critical Issues (4)

1. **No Indexing Job Cancellation/Timeout** - Jobs can hang indefinitely
2. **PDF Extraction is Primitive** - Basic regex that fails on most PDFs
3. **Memory Leak in Orphaned File Detection** - N+1 queries on filesystem
4. **No Transaction Rollback on Partial Failures** - Partial embeddings stored when chunk insertion fails

### High Priority Issues (4)

5. **Missing Unique Constraint** - No constraint on FileIndex.contentHash
6. **Watched Folder Restoration** - Doesn't validate paths exist on startup
7. **No Concurrent Job Limiting** - Multiple jobs can run on same directories
8. **Missing Vector Column** - DocumentEmbedding model lacks vector field

### Medium Priority Issues (4)

9. **Inefficient Batch Processing** - Fixed batch size, no adaptive throttling
10. **Limited Glob Pattern Matching** - No character classes or negation
11. **File Size Check Late** - 50MB limit enforced after scanning
12. **No Resume Capability** - Failed jobs must restart from beginning

### Low Priority Issues (5)

13. **No Index Progress Streaming** - UI must poll for updates
14. **No Deduplication Across Sessions** - Same path watched by multiple sessions
15. **Content Preview Truncation** - No word boundary awareness
16. **Embedding Model Version Not Tracked** - Old files not re-embedded on model change
17. **No Retry for Batch Failures** - Entire batch fails on transient errors

### Database Schema Issues (2)

18. **Missing HNSW Index** - No vector similarity index on embedding_vector
19. **Manual Cascade Delete** - No foreign key cascade configured

### Testing Gaps (1)

20. **Limited Integration Coverage** - No tests for large files, rapid changes, network failures

### Security Concerns (1)

21. **Weak Symlink Validation** - No explicit symlink loop prevention

---

## Phase 0: Critical Infrastructure Fixes

**Priority:** P0 (Critical)
**Estimated Duration:** 1 week
**Goal:** Fix critical issues that can cause data corruption or system hangs

### 0.1 Indexing Job Cancellation and Timeout

**Files to Modify:**
- `semantic_butler/semantic_butler_server/lib/src/endpoints/butler_endpoint.dart`
- `semantic_butler/semantic_butler_server/lib/src/models/indexing_job.yaml`

**Update IndexingJob Model:**

```yaml
### Add to indexing_job.yaml
fields:
  # ... existing fields ...
  ### Job cancellation flag
  cancelled: bool
  ### Job timeout in seconds (null for no timeout)
  timeoutSeconds: int?
```

**Implementation:**

```dart
// Add to ButlerEndpoint class
static final Set<int> _cancelledJobs = {};

/// Cancel a running indexing job
Future<bool> cancelIndexingJob(
  Session session,
  int jobId,
) async {
  AuthService.requireAuth(session);

  final job = await IndexingJob.db.findById(session, jobId);
  if (job == null) {
    return false;
  }

  if (job.status == 'running') {
    // Mark as cancelled
    job.cancelled = true;
    await IndexingJob.db.updateRow(session, job);
    _cancelledJobs.add(jobId);
    return true;
  }

  return false;
}

/// Update _processIndexingJob with cancellation support
Future<void> _processIndexingJob(Session session, IndexingJob job) async {
  try {
    job.status = 'running';
    job.startedAt = DateTime.now();
    await IndexingJob.db.updateRow(session, job);

    // ... existing code ...

    // Check for cancellation at key points
    if (_cancelledJobs.contains(job.id)) {
      job.status = 'cancelled';
      job.completedAt = DateTime.now();
      await IndexingJob.db.updateRow(session, job);
      _cancelledJobs.remove(job.id);
      return;
    }

    // Process batches with cancellation check
    for (var i = 0; i < files.length; i += batchSize) {
      if (_cancelledJobs.contains(job.id)) {
        // Cancel job
        job.status = 'cancelled';
        job.completedAt = DateTime.now();
        await IndexingJob.db.updateRow(session, job);
        _cancelledJobs.remove(job.id);
        return;
      }

      // ... process batch ...
    }

    // ... rest of method ...
  } finally {
    _cancelledJobs.remove(job.id);
  }
}
```

### 0.2 Transaction Consistency for Chunk Embeddings

**Files to Modify:**
- `semantic_butler/semantic_butler_server/lib/src/endpoints/butler_endpoint.dart`

**Implementation:**

```dart
// Update chunk embedding section in _processBatch
for (var i = 0; i < chunks.length; i++) {
  DocumentEmbedding? chunkRecord;

  // Use nested transaction for each chunk
  await session.db.transaction((transaction) async {
    try {
      // Generate embedding for this chunk
      final chunkEmbedding = await aiService.generateEmbedding(
        chunks[i],
      );
      final chunkPreview = chunks[i].length > 500
          ? '${chunks[i].substring(0, 500)}...'
          : chunks[i];

      chunkRecord = await DocumentEmbedding.db.insertRow(
        session,
        DocumentEmbedding(
          fileIndexId: savedIndex.id!,
          chunkIndex: i,
          chunkText: chunkPreview,
          embeddingJson: jsonEncode(chunkEmbedding),
          dimensions: aiService.getEmbeddingDimensions(),
        ),
        transaction: transaction,
      );

      // Update vector column
      await session.db.unsafeQuery(
        'INSERT INTO document_vector_store (id, embedding_vector) VALUES (\$2, \$1::vector) ON CONFLICT (id) DO UPDATE SET embedding_vector = EXCLUDED.embedding_vector',
        parameters: QueryParameters.positional([
          jsonEncode(chunkEmbedding),
          chunkRecord.id,
        ]),
        transaction: transaction,
      );
    } catch (e) {
      // Log and rethrow to roll back the transaction
      session.log(
        'Failed to create chunk $i for ${item.path}: $e',
        level: LogLevel.error,
      );
      rethrow;
    }
  });

  // If we get here without exception, all chunks succeeded
  // Partial failures would have rolled back automatically
}
```

### 0.3 Optimized Orphaned File Detection

**Files to Modify:**
- `semantic_butler/semantic_butler_server/lib/src/services/index_health_service.dart`

**Implementation:**

```dart
/// Find files in index that no longer exist on disk (optimized)
static Future<List<String>> _findOrphanedFiles(Session session) async {
  // Use batch processing with LIMIT to avoid memory issues
  const batchSize = 500;
  int offset = 0;
  final orphaned = <String>[];

  while (true) {
    final indexed = await FileIndex.db.find(
      session,
      where: (t) => t.status.equals('indexed'),
      limit: batchSize,
      offset: offset,
    );

    if (indexed.isEmpty) break;

    // Check file existence in parallel
    final existenceChecks = await Future.wait(
      indexed.map((file) async {
        return MapEntry(file.path, await File(file.path).exists());
      }),
    );

    // Add orphaned files
    for (final entry in existenceChecks.entries) {
      if (!entry.value) {
        orphaned.add(entry.key);
      }
    }

    offset += batchSize;
  }

  return orphaned;
}
```

### 0.4 Database Schema Fixes

**New Migration File:**
- `semantic_butler/semantic_butler_server/migrations/[timestamp]/migration.sql`

```sql
-- Add unique constraint on contentHash (excluding old duplicates)
-- First, remove any existing duplicates by keeping the most recent
DELETE FROM file_index
WHERE id IN (
    SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY "contentHash" ORDER BY "indexedAt" DESC) as rn
        FROM file_index
        WHERE "contentHash" IS NOT NULL AND "contentHash" != ''
    ) t
    WHERE rn > 1
);

-- Add unique constraint
ALTER TABLE file_index ADD CONSTRAINT file_index_content_hash_unique UNIQUE ("contentHash");

-- Add cascade delete for embeddings
ALTER TABLE document_embedding DROP CONSTRAINT IF EXISTS document_embedding_fileindexid_fkey;
ALTER TABLE document_embedding
    ADD CONSTRAINT document_embedding_fileindexid_fkey
    FOREIGN KEY ("fileIndexId")
    REFERENCES file_index(id)
    ON DELETE CASCADE;

-- Add HNSW index for vector similarity search
CREATE INDEX IF NOT EXISTS document_embedding_vector_idx
    ON document_embedding
    USING hnsw (embedding_vector vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- Add cancelled column to indexing_job
ALTER TABLE indexing_job ADD COLUMN IF NOT EXISTS "cancelled" BOOL NOT NULL DEFAULT false;
ALTER TABLE indexing_job ADD COLUMN IF NOT EXISTS "timeoutSeconds" INT;
```

**Acceptance Criteria:**
- [ ] Jobs can be cancelled via API call
- [ ] Partial chunk insertions are rolled back on failure
- [ ] Orphaned file detection uses batch processing
- [ ] Database constraints added via migration
- [ ] No data corruption from concurrent operations

---

## Phase 1: Critical File Format Support

**Priority:** P0 (Critical)
**Estimated Duration:** 2 weeks
**Goal:** Enable indexing of the most common document formats

### 1.1 Microsoft Office Document Support

**Files to Modify:**
- `semantic_butler/semantic_butler_server/lib/src/services/file_extraction_service.dart`
- `semantic_butler/semantic_butler_server/pubspec.yaml`

**Dependencies to Add:**
```yaml
dependencies:
  archive: ^3.4.0  # For ZIP extraction (Office files are ZIP archives)
  xml: ^6.5.0       # For parsing XML content within Office files
```

**Implementation Steps:**

1. **Update supported extensions list** (`file_extraction_service.dart:18-29`)
```dart
static const Set<String> supportedExtensions = {
  // ... existing ...
  // Office documents
  '.docx', '.dotx', '.docm',
  '.xlsx', '.xlsm', '.xlsb', '.csv',
  '.pptx', '.pptm', '.potx',
};
```

2. **Create Office document extraction method**
```dart
/// Extract text from Office documents (DOCX, XLSX, PPTX)
Future<String> _extractOfficeText(File file) async {
  final ext = path.extension(file.path).toLowerCase();

  if (ext == '.docx' || ext == '.dotx' || ext == '.docm') {
    return await _extractDocxText(file);
  } else if (ext == '.xlsx' || ext == '.xlsm' || ext == '.xlsb') {
    return await _extractXlsxText(file);
  } else if (ext == '.pptx' || ext == '.pptm' || ext == '.potx') {
    return await _extractPptxText(file);
  }

  throw FileExtractionException('Unsupported Office format: $ext');
}

/// Extract text from DOCX (Word) documents
Future<String> _extractDocxText(File file) async {
  // DOCX is a ZIP archive containing word/document.xml
  final bytes = await file.readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);

  for (final file in archive) {
    if (file.name == 'word/document.xml') {
      final content = file.content as List<int>;
      final xmlDocument = XmlDocument.parse(utf8.decode(content));
      // Extract all <w:t> text elements
      final textNodes = xmlDocument.findAllElements('w:t');
      return textNodes.map((node) => node.innerText).join(' ');
    }
  }

  return '';
}

/// Extract text from XLSX (Excel) spreadsheets
Future<String> _extractXlsxText(File file) async {
  // XLSX contains xl/sharedStrings.xml for shared strings
  final bytes = await file.readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);

  final sharedStrings = <String>[];
  final sharedStringsFile = archive.files.firstWhere(
    (f) => f.name == 'xl/sharedStrings.xml',
    orElse: () => null as ArchiveFile,
  );

  if (sharedStringsFile != null) {
    final content = sharedStringsFile.content as List<int>;
    final xml = XmlDocument.parse(utf8.decode(content));
    for (final si in xml.findAllElements('si')) {
      sharedStrings.add(si.innerText);
    }
  }

  // Parse worksheets
  final text = StringBuffer();
  for (final archiveFile in archive.files) {
    if (archiveFile.name.startsWith('xl/worksheets/') &&
        archiveFile.name.endsWith('.xml')) {
      final content = archiveFile.content as List<int>;
      final xml = XmlDocument.parse(utf8.decode(content));
      // Extract cell references to shared strings
      for (final v in xml.findAllElements('v')) {
        final index = int.tryParse(v.innerText);
        if (index != null && index < sharedStrings.length) {
          text.write(sharedStrings[index]);
          text.write(' ');
        }
      }
      // Also extract inline strings
      for (final is in xml.findAllElements('is')) {
        text.write(is.innerText);
        text.write(' ');
      }
    }
  }

  return text.toString().trim();
}

/// Extract text from PPTX (PowerPoint) presentations
Future<String> _extractPptxText(File file) async {
  // PPTX contains slide XML files in ppt/slides/
  final bytes = await file.readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);

  final text = StringBuffer();
  for (final archiveFile in archive.files) {
    if (archiveFile.name.startsWith('ppt/slides/slide') &&
        archiveFile.name.endsWith('.xml')) {
      final content = archiveFile.content as List<int>;
      final xml = XmlDocument.parse(utf8.decode(content));
      // Extract all <a:t> text elements
      for (final textNode in xml.findAllElements('a:t')) {
        text.write(textNode.innerText);
        text.write(' ');
      }
    }
  }

  return text.toString().trim();
}
```

3. **Update extraction flow** (`file_extraction_service.dart:316-339`)
```dart
Future<ExtractionResult> extractText(String filePath) async {
  final file = File(filePath);

  if (!await file.exists()) {
    throw FileExtractionException('File not found: $filePath');
  }

  final ext = path.extension(filePath).toLowerCase();
  final fileName = path.basename(filePath);
  final fileSize = await file.length();

  // Get file metadata
  final metadata = await getFileMetadata(filePath);
  final category = getDocumentCategory(filePath);

  String content;

  if (pdfExtensions.contains(ext)) {
    content = await _extractPdfText(file);
  } else if (_isOfficeDocument(ext)) {
    content = await _extractOfficeText(file);
  } else if (supportedExtensions.contains(ext)) {
    content = await _extractPlainText(file);
  } else {
    throw FileExtractionException('Unsupported file format: $ext');
  }

  // ... rest of method remains unchanged
}

bool _isOfficeDocument(String ext) {
  return ext.endsWith('.docx') ||
         ext.endsWith('.dotx') ||
         ext.endsWith('.docm') ||
         ext.endsWith('.xlsx') ||
         ext.endsWith('.xlsm') ||
         ext.endsWith('.xlsb') ||
         ext.endsWith('.pptx') ||
         ext.endsWith('.pptm') ||
         ext.endsWith('.potx');
}
```

**Acceptance Criteria:**
- [ ] DOCX files can be indexed and searched
- [ ] XLSX files can be indexed and searched
- [ ] PPTX files can be indexed and searched
- [ ] Content is properly extracted from all three formats
- [ ] File size and modification tracking work correctly
- [ ] Unit tests cover 80% of new extraction code

### 1.2 Proper PDF Extraction

**Files to Modify:**
- `semantic_butler/semantic_butler_server/lib/src/services/file_extraction_service.dart`
- `semantic_butler/semantic_butler_server/pubspec.yaml`

**Dependencies to Add:**
```yaml
dependencies:
  pdf: ^3.10.0  # PDF parsing library
```

**Implementation Steps:**

1. **Replace regex-based PDF extraction** (`file_extraction_service.dart:378-428`)

```dart
/// Extract text from PDF files using proper PDF parsing library
Future<String> _extractPdfText(File file) async {
  try {
    // Read PDF bytes
    final bytes = await file.readAsBytes();

    // Use proper PDF library
    final document = await PdfDocument.openData(bytes);

    final text = StringBuffer();

    // Iterate through all pages
    for (var i = 0; i < document.pagesCount; i++) {
      final page = await document.getPage(i + 1);

      // Extract text from page
      final pageText = await page.text;

      if (pageText != null) {
        text.write(pageText);
        text.write(' '); // Separate pages with space
      }
    }

    await document.close();

    final extracted = text.toString().trim();

    if (extracted.isEmpty) {
      // Return filename as content for indexing
      return 'PDF Document: ${file.path}';
    }

    return extracted;
  } catch (e) {
    // Log error but don't fail completely
    // Return basic info if extraction fails
    return 'PDF Document: ${file.path} (text extraction failed: $e)';
  }
}
```

2. **Add fallback for scanned/image-only PDFs**
```dart
/// Check if PDF might contain only images (no extractable text)
bool _isImageOnlyPdf(String extractedText) {
  // If very little text was extracted relative to typical document size,
  // it might be image-only
  return extractedText.length < 100 &&
       !extractedText.contains('PDF Document:');
}
```

**Acceptance Criteria:**
- [ ] PDF text is correctly extracted using pdf package
- [ ] Multi-page PDFs are fully processed
- [ ] Encrypted PDFs fail gracefully
- [ ] Image-only PDFs are marked appropriately
- [ ] Performance: <2 seconds per 100 pages

### 1.3 Test Files for Document Extraction

**New File:**
- `semantic_butler/semantic_butler_server/test/unit/document_extraction_test.dart`

```dart
import 'package:test/test.dart';
import 'package:semantic_butler_server/src/services/file_extraction_service.dart';

void main() {
  group('Document Extraction Tests', () {
    test('Extract text from DOCX file', () async {
      final service = FileExtractionService();
      final result = await service.extractText('test_data/sample.docx');

      expect(result.content, isNotEmpty);
      expect(result.wordCount, greaterThan(0));
    });

    test('Extract text from XLSX file', () async {
      final service = FileExtractionService();
      final result = await service.extractText('test_data/sample.xlsx');

      expect(result.content, isNotEmpty);
    });

    test('Extract text from PPTX file', () async {
      final service = FileExtractionService();
      final result = await service.extractText('test_data/sample.pptx');

      expect(result.content, isNotEmpty);
    });

    test('Extract text from PDF file', () async {
      final service = FileExtractionService();
      final result = await service.extractText('test_data/sample.pdf');

      expect(result.content, isNotEmpty);
      expect(result.content, isNot(contains('PDF Document:')));
    });

    test('Handle corrupted Office files gracefully', () async {
      final service = FileExtractionService();

      expect(
        () => service.extractText('test_data/corrupted.docx'),
        throwsA(isA<FileExtractionException>()),
      );
    });
  });
}
```

---

## Phase 2: Configuration & Flexibility

**Priority:** P1 (High)
**Estimated Duration:** 1 week
**Goal:** Make indexing behavior configurable without code changes

### 2.1 Indexing Configuration Model

**New File:**
- `semantic_butler/semantic_butler_server/lib/src/models/indexing_config.yaml`

```yaml
### IndexingConfig - User-configurable indexing settings
class: IndexingConfig
table: indexing_config
fields:
  ### User ID for per-user configuration (null for global defaults)
  userId: int?
  ### Folder path for per-folder configuration (null for global)
  folderPath: String?
  ### Maximum file size to index in bytes
  maxFileSizeBytes: int
  ### Number of files to process in each batch
  batchSize: int
  ### Maximum queue size for pending files
  maxQueueSize: int
  ### Directory scan timeout in seconds
  scanTimeoutSeconds: int
  ### Maximum parallel indexing jobs
  maxParallelJobs: int
  ### Whether to use incremental scanning
  enableIncrementalScanning: bool
  ### Number of workers for parallel directory scanning
  scanWorkers: int
  ### Whether to generate thumbnails for images
  enableThumbnailGeneration: bool
  ### Whether to use OCR for images/PDFs
  enableOcr: bool
  ### Custom ignore patterns (JSON array)
  customIgnorePatterns: String?
indexes:
  indexing_config_user:
    fields: userId
  indexing_config_folder:
    fields: folderPath
```

### 2.2 Configuration Service

**New File:**
- `semantic_butler/semantic_butler_server/lib/src/services/indexing_config_service.dart`

```dart
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Service for managing indexing configuration
class IndexingConfigService {
  /// Get configuration for a specific user/folder
  static Future<IndexingConfig> getConfig(
    Session session, {
    int? userId,
    String? folderPath,
  }) async {
    // Try to find specific config first
    final specific = await IndexingConfig.db.findFirstRow(
      session,
      where: (t) =>
          (t.userId.equals(userId ?? 0) | t.userId.isNull()) &
          ((t.folderPath.equals(folderPath ?? '')) | t.folderPath.isNull()),
      orderBy: (t) => t.userId,
      orderDescending: true,
    );

    if (specific != null) return specific;

    // Return default config
    return _defaultConfig();
  }

  /// Get default configuration
  static IndexingConfig _defaultConfig() {
    return IndexingConfig(
      maxFileSizeBytes: 50 * 1024 * 1024, // 50MB
      batchSize: 25,
      maxQueueSize: 10000,
      scanTimeoutSeconds: 300, // 5 minutes
      maxParallelJobs: 5,
      enableIncrementalScanning: true,
      scanWorkers: 4,
      enableThumbnailGeneration: false,
      enableOcr: false,
    );
  }

  /// Update configuration
  static Future<IndexingConfig> updateConfig(
    Session session,
    IndexingConfig config,
  ) async {
    return await IndexingConfig.db.updateRow(session, config);
  }

  /// Create or update configuration
  static Future<IndexingConfig> setConfig(
    Session session, {
    int? userId,
    String? folderPath,
    int? maxFileSizeBytes,
    int? batchSize,
    int? maxQueueSize,
    int? scanTimeoutSeconds,
    int? maxParallelJobs,
    bool? enableIncrementalScanning,
    int? scanWorkers,
    bool? enableThumbnailGeneration,
    bool? enableOcr,
    List<String>? customIgnorePatterns,
  }) async {
    final existing = await IndexingConfig.db.findFirstRow(
      session,
      where: (t) =>
          t.userId.equals(userId ?? 0) &
          t.folderPath.equals(folderPath ?? ''),
    );

    final config = IndexingConfig(
      id: existing?.id,
      userId: userId,
      folderPath: folderPath,
      maxFileSizeBytes: maxFileSizeBytes ?? existing?.maxFileSizeBytes ?? _defaultConfig().maxFileSizeBytes,
      batchSize: batchSize ?? existing?.batchSize ?? _defaultConfig().batchSize,
      maxQueueSize: maxQueueSize ?? existing?.maxQueueSize ?? _defaultConfig().maxQueueSize,
      scanTimeoutSeconds: scanTimeoutSeconds ?? existing?.scanTimeoutSeconds ?? _defaultConfig().scanTimeoutSeconds,
      maxParallelJobs: maxParallelJobs ?? existing?.maxParallelJobs ?? _defaultConfig().maxParallelJobs,
      enableIncrementalScanning: enableIncrementalScanning ?? existing?.enableIncrementalScanning ?? _defaultConfig().enableIncrementalScanning,
      scanWorkers: scanWorkers ?? existing?.scanWorkers ?? _defaultConfig().scanWorkers,
      enableThumbnailGeneration: enableThumbnailGeneration ?? existing?.enableThumbnailGeneration ?? _defaultConfig().enableThumbnailGeneration,
      enableOcr: enableOcr ?? existing?.enableOcr ?? _defaultConfig().enableOcr,
      customIgnorePatterns: customIgnorePatterns?.toJson(),
    );

    if (existing != null) {
      return await IndexingConfig.db.updateRow(session, config);
    } else {
      return await IndexingConfig.db.insertRow(session, config);
    }
  }
}
```

### 2.3 Update Butler Endpoint to Use Configuration

**File to Modify:**
- `semantic_butler/semantic_butler_server/lib/src/endpoints/butler_endpoint.dart`

```dart
// In _processIndexingJob method
Future<void> _processIndexingJob(Session session, IndexingJob job) async {
  try {
    // Get configuration for this folder
    final config = await IndexingConfigService.getConfig(
      session,
      folderPath: job.folderPath,
    );

    job.status = 'running';
    job.startedAt = DateTime.now();
    await IndexingJob.db.updateRow(session, job);

    // ... rest of implementation using config values
    files = await _extractionService.scanDirectory(
      job.folderPath,
      ignorePatterns: ignorePatterns,
    ).timeout(Duration(seconds: config.scanTimeoutSeconds));

    // Use config.batchSize instead of hardcoded 25
    final batchSize = config.batchSize;

    // ...
  }
}
```

### 2.4 Configuration Management API

**Add to ButlerEndpoint:**

```dart
/// Get indexing configuration
Future<IndexingConfig> getIndexingConfig(
  Session session, {
  String? folderPath,
}) async {
  AuthService.requireAuth(session);

  final clientId = _getClientIdentifier(session);
  final userId = await _getUserId(session, clientId);

  return await IndexingConfigService.getConfig(
    session,
    userId: userId,
    folderPath: folderPath,
  );
}

/// Update indexing configuration
Future<IndexingConfig> updateIndexingConfig(
  Session session,
  IndexingConfig config,
) async {
  AuthService.requireAuth(session);

  final clientId = _getClientIdentifier(session);
  final userId = await _getUserId(session, clientId);

  config.userId = userId;
  return await IndexingConfigService.updateConfig(session, config);
}

/// Reset indexing configuration to defaults
Future<IndexingConfig> resetIndexingConfig(
  Session session, {
  String? folderPath,
}) async {
  AuthService.requireAuth(session);

  final clientId = _getClientIdentifier(session);
  final userId = await _getUserId(session, clientId);

  // Delete existing config
  await IndexingConfig.db.deleteWhere(
    session,
    where: (t) =>
        t.userId.equals(userId) &
        (folderPath == null
            ? t.folderPath.isNull()
            : t.folderPath.equals(folderPath)),
  );

  // Return default
  return IndexingConfigService._defaultConfig();
}
```

**Acceptance Criteria:**
- [ ] IndexingConfig model created and migrated
- [ ] Configuration can be retrieved per user/folder
- [ ] Configuration can be updated via API
- [ ] Indexing job uses configuration values
- [ ] Default values work without configuration
- [ ] Configuration UI added to Flutter app (settings screen)

### 2.5 Concurrent Job Limiting

**Files to Modify:**
- `semantic_butler/semantic_butler_server/lib/src/endpoints/butler_endpoint.dart`

```dart
// Add to ButlerEndpoint class
static final Map<String, int> _activeJobsByPath = {};
static final Mutex _jobMutex = Mutex();

/// Start indexing documents from specified folder path
Future<IndexingJob> startIndexing(
  Session session,
  String folderPath,
) async {
  // Security: Validate authentication
  AuthService.requireAuth(session);

  // Security: Rate limiting
  final clientId = _getClientIdentifier(session);
  RateLimitService.instance.requireRateLimit(
    clientId,
    'startIndexing',
    limit: 10,
  );

  // Security: Input validation
  InputValidation.validateFilePath(folderPath);

  // Check concurrent job limit
  final config = await IndexingConfigService.getConfig(
    session,
    folderPath: folderPath,
  );

  await _jobMutex.acquire();
  try {
    final activeCount = _activeJobsByPath.values
        .where((count) => folderPath.startsWith(count) || count.startsWith(folderPath))
        .length;

    if (activeCount >= config.maxParallelJobs) {
      throw Exception('Too many concurrent jobs for this folder');
    }

    // Create a new indexing job
    final job = IndexingJob(
      folderPath: folderPath,
      status: 'queued',
      totalFiles: 0,
      processedFiles: 0,
      failedFiles: 0,
      skippedFiles: 0,
    );

    final insertedJob = await IndexingJob.db.insertRow(session, job);

    // Track active job
    _activeJobsByPath[insertedJob.id.toString()] = folderPath;

    // Start indexing in background
    unawaited(_processIndexingJobSafe(session.serverpod, insertedJob.id!));

    return insertedJob;
  } finally {
    _jobMutex.release();
  }
}
```

**Acceptance Criteria:**
- [ ] Maximum concurrent jobs enforced per folder
- [ ] Job tracking prevents resource exhaustion
- [ ] Configuration controls parallel job limit

---

## Phase 3: Scanning Performance

**Priority:** P1 (High)
**Estimated Duration:** 2 weeks
**Goal:** Make directory scanning faster and more efficient

### 3.1 Incremental Scanning

**Files to Modify:**
- `semantic_butler/semantic_butler_server/lib/src/services/file_extraction_service.dart`
- `semantic_butler/semantic_butler_server/lib/src/endpoints/butler_endpoint.dart`
- `semantic_butler/semantic_butler_server/lib/src/models/indexing_job.yaml`

**Update IndexingJob Model:**

```yaml
### Add to indexing_job.yaml
fields:
  # ... existing fields ...
  ### Last scan time for incremental scanning
  lastScanTime: DateTime?
```

**Implementation:**

```dart
/// Scan a directory incrementally (only modified files)
Future<List<String>> scanDirectoryIncremental(
  String directoryPath, {
  required DateTime? lastScanTime,
  bool recursive = true,
  List<String> ignorePatterns = const [],
}) async {
  final directory = Directory(directoryPath);

  if (!await directory.exists()) {
    throw FileExtractionException('Directory not found: $directoryPath');
  }

  final files = <String>[];

  await for (final entity in directory.list(recursive: recursive)) {
    if (entity is File) {
      // Check ignore patterns first
      if (matchesIgnorePattern(entity.path, ignorePatterns)) {
        continue;
      }

      // If no last scan time, include all files
      if (lastScanTime == null) {
        files.add(entity.path);
        continue;
      }

      // Check modification time
      final stat = await entity.stat();
      if (stat.modified.isAfter(lastScanTime)) {
        files.add(entity.path);
      }
    }
  }

  return files;
}

/// Scan a directory using multiple workers in parallel
Future<List<String>> scanDirectoryParallel(
  String directoryPath, {
  int workers = 4,
  bool recursive = true,
  List<String> ignorePatterns = const [],
}) async {
  final directory = Directory(directoryPath);

  if (!await directory.exists()) {
    throw FileExtractionException('Directory not found: $directoryPath');
  }

  // For parallel scanning, we need to split the directory tree
  final subdirs = await _getSubdirectories(directoryPath, recursive: recursive);

  if (subdirs.isEmpty) {
    // No subdirectories, scan normally
    return scanDirectory(
      directoryPath,
      recursive: recursive,
      ignorePatterns: ignorePatterns,
    );
  }

  // Split subdirectories among workers
  final chunkSize = (subdirs.length / workers).ceil();
  final chunks = <List<String>>[];
  for (var i = 0; i < subdirs.length; i += chunkSize) {
    chunks.add(
      subdirs.sublist(
        i,
        i + chunkSize > subdirs.length ? subdirs.length : i + chunkSize,
      ),
    );
  }

  // Scan chunks in parallel
  final results = await Future.wait(
    chunks.map((chunk) async {
      final files = <String>[];
      for (final dir in chunk) {
        files.addAll(
          await scanDirectory(
            dir,
            recursive: false,
            ignorePatterns: ignorePatterns,
          ),
        );
      }
      return files;
    }),
  );

  return results.expand((e) => e).toList();
}

/// Get all subdirectories for parallel scanning
Future<List<String>> _getSubdirectories(
  String path, {
  bool recursive = true,
  int maxDepth = 3,
}) async {
  final dirs = <String>[];

  await for (final entity in Directory(path).list(recursive: recursive)) {
    if (entity is Directory) {
      // Calculate depth
      final relativePath = entity.path.replaceFirst(path, '');
      final depth = relativePath.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty).length;

      if (depth <= maxDepth) {
        dirs.add(entity.path);
      }
    }
  }

  return dirs;
}
```

**Update Butler Endpoint to Use Incremental Scanning:**

```dart
Future<void> _processIndexingJob(Session session, IndexingJob job) async {
  try {
    // Get configuration
    final config = await IndexingConfigService.getConfig(
      session,
      folderPath: job.folderPath,
    );

    // Get last scan time from job or previous run
    final lastScanTime = job.lastScanTime ??
        await _getLastScanTime(session, job.folderPath);

    job.status = 'running';
    job.startedAt = DateTime.now();
    await IndexingJob.db.updateRow(session, job);

    List<String> files;

    if (config.enableIncrementalScanning && lastScanTime != null) {
      // Incremental scan - only modified files
      files = await _extractionService.scanDirectoryIncremental(
        job.folderPath,
        lastScanTime: lastScanTime,
        ignorePatterns: ignorePatterns,
      ).timeout(Duration(seconds: config.scanTimeoutSeconds));
    } else {
      // Full scan
      if (config.scanWorkers > 1) {
        files = await _extractionService.scanDirectoryParallel(
          job.folderPath,
          workers: config.scanWorkers,
          ignorePatterns: ignorePatterns,
        ).timeout(Duration(seconds: config.scanTimeoutSeconds));
      } else {
        files = await _extractionService.scanDirectory(
          job.folderPath,
          ignorePatterns: ignorePatterns,
        ).timeout(Duration(seconds: config.scanTimeoutSeconds));
      }
    }

    // Update last scan time
    job.lastScanTime = DateTime.now();
    await IndexingJob.db.updateRow(session, job);

    // ... rest of processing
  }
}
```

### 3.2 Symlink Detection and Handling

**Add to FileExtractionService:**

```dart
/// Check if a path is a symbolic link
Future<bool> _isSymlink(String filePath) async {
  try {
    final entity = Link(filePath);
    await entity.resolve(); // Will throw if not a link
    return true;
  } catch (_) {
    return false;
  }
}

/// Get the real path of a file (resolving symlinks)
Future<String> _realPath(String filePath) async {
  final entity = File(filePath);
  try {
    final real = await entity.resolveSymbolicLinks();
    return real;
  } catch (_) {
    return filePath;
  }
}

/// Scan a directory with symlink handling
Future<List<String>> scanDirectory(
  String directoryPath, {
  bool recursive = true,
  List<String> ignorePatterns = const [],
  bool followSymlinks = false,
  Set<String> visitedInodes = const {},
}) async {
  final directory = Directory(directoryPath);

  if (!await directory.exists()) {
    throw FileExtractionException('Directory not found: $directoryPath');
  }

  final files = <String>[];
  final visited = visitedInodes.isEmpty ? <String>{} : visitedInodes;

  await for (final entity in directory.list(recursive: false)) {
    // Check for symlinks
    if (await _isSymlink(entity.path)) {
      if (!followSymlinks) {
        continue; // Skip symlinks
      }

      // Detect circular symlinks
      final realPath = await _realPath(entity.path);
      if (visited.contains(realPath)) {
        continue; // Skip circular reference
      }
      visited.add(realPath);
    }

    if (entity is File) {
      if (matchesIgnorePattern(entity.path, ignorePatterns)) {
        continue;
      }
      files.add(entity.path);
    } else if (entity is Directory && recursive) {
      // Recursively scan subdirectory
      files.addAll(
        await scanDirectory(
          entity.path,
          recursive: true,
          ignorePatterns: ignorePatterns,
          followSymlinks: followSymlinks,
          visitedInodes: visited,
        ),
      );
    }
  }

  return files;
}
```

### 3.3 File Change Detection Improvements

**New File:**
- `semantic_butler/semantic_butler_server/lib/src/services/content_hash_service.dart`

```dart
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service for computing content hashes efficiently
class ContentHashService {
  /// Calculate content hash using xxhash-style approach
  /// For large files, hash first 64KB + last 64KB + size
  static Future<String> calculateContentHash(String filePath) async {
    final file = File(filePath);
    final size = await file.length();

    // For small files (<1MB), read full content
    if (size < 1024 * 1024) {
      final bytes = await file.readAsBytes();
      return _sha256Hash(bytes);
    }

    // For large files, sample start and end
    final raf = await file.open(mode: FileMode.read);

    try {
      final head = await raf.read(64 * 1024);
      await raf.setPosition(size - 64 * 1024);
      final tail = await raf.read(64 * 1024);

      // Combine: head + tail + size
      final combined = [
        ...head,
        ...tail,
        ..._uint64ToBytes(size),
      ];

      return _sha256Hash(combined);
    } finally {
      await raf.close();
    }
  }

  /// Calculate SHA-256 hash
  static String _sha256Hash(List<int> bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Convert uint64 to bytes
  static List<int> _uint64ToBytes(int value) {
    return [
      (value >> 56) & 0xff,
      (value >> 48) & 0xff,
      (value >> 40) & 0xff,
      (value >> 32) & 0xff,
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
  }

  /// Verify that a file's content matches its hash
  static Future<bool> verifyHash(
    String filePath,
    String expectedHash,
  ) async {
    try {
      final actualHash = await calculateContentHash(filePath);
      return actualHash == expectedHash;
    } catch (_) {
      return false;
    }
  }
}
```

**Acceptance Criteria:**
- [ ] Incremental scanning only processes modified files
- [ ] Parallel scanning uses multiple workers
- [ ] Symlinks are detected and handled correctly
- [ ] Circular symlink references don't cause infinite loops
- [ ] Content hashing is accurate for large files
- [ ] Performance: 50% faster scan on 10,000 files

---

## Phase 4: Error Handling & Recovery

**Priority:** P2 (Medium)
**Estimated Duration:** 1 week
**Goal:** Improve error handling and add recovery mechanisms

### 4.1 Error Classification and Retry Strategy

**New File:**
- `semantic_butler/semantic_butler_server/lib/src/services/retry_policy.dart`

```dart
/// Classification of error types for retry logic
enum RetryStrategy {
  /// Transient error - retry with exponential backoff
  transient,

  /// Permanent error - don't retry
  permanent,

  /// Degraded mode - retry with reduced quality
  degraded,
}

/// Retry configuration
class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
  });

  /// Get delay for a specific attempt
  Duration getDelayForAttempt(int attempt) {
    final delay = initialDelay *
        pow(backoffMultiplier, attempt - 1).toInt();
    return delay > maxDelay ? maxDelay : delay;
  }
}

/// Classify error and determine retry strategy
RetryStrategy classifyError(dynamic error) {
  final errorStr = error.toString().toLowerCase();

  // Transient errors
  if (errorStr.contains('timeout') ||
      errorStr.contains('timed out') ||
      errorStr.contains('connection reset') ||
      errorStr.contains('network') ||
      errorStr.contains('temporary') ||
      errorStr.contains('503') ||
      errorStr.contains('502')) {
    return RetryStrategy.transient;
  }

  // Permanent errors
  if (errorStr.contains('not found') &&
      !errorStr.contains('connection') ||
      errorStr.contains('unsupported') ||
      errorStr.contains('invalid format') ||
      errorStr.contains('corrupt') ||
      errorStr.contains('permission denied') ||
      errorStr.contains('401') ||
      errorStr.contains('404')) {
    return RetryStrategy.permanent;
  }

  // Default to transient for unknown errors
  return RetryStrategy.transient;
}

/// Execute function with retry logic
Future<T> executeWithRetry<T>(
  Future<T> Function() action, {
  required RetryPolicy policy,
  RetryStrategy? overrideStrategy,
}) async {
  int attempts = 0;
  dynamic lastError;

  while (attempts < policy.maxAttempts) {
    attempts++;

    try {
      return await action();
    } catch (e) {
      lastError = e;
      final strategy = overrideStrategy ?? classifyError(e);

      if (strategy == RetryStrategy.permanent) {
        rethrow;
      }

      if (attempts >= policy.maxAttempts) {
        rethrow;
      }

      final delay = policy.getDelayForAttempt(attempts);
      await Future.delayed(delay);
    }
  }

  throw lastError;
}
```

### 4.2 Dead Letter Queue for Failed Files

**New File:**
- `semantic_butler/semantic_butler_server/lib/src/models/failed_file_queue.yaml`

```yaml
### FailedFileQueue - Queue of failed files for retry
class: FailedFileQueue
table: failed_file_queue
fields:
  ### File path that failed to index
  path: String
  ### Error message
  errorMessage: String?
  ### Error category
  errorCategory: String?
  ### Number of retry attempts
  retryCount: int
  ### When to retry this file
  retryAt: DateTime
  ### Priority for retry (0=lowest, 10=highest)
  priority: int
indexes:
  failed_file_queue_retry_at:
    fields: retryAt
  failed_file_queue_priority:
    fields: priority
```

**New File:**
- `semantic_butler/semantic_butler_server/lib/src/services/failed_file_queue_service.dart`

```dart
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Service for managing failed file queue
class FailedFileQueueService {
  /// Add a failed file to the queue
  static Future<void> enqueue(
    Session session, {
    required String path,
    String? errorMessage,
    String? errorCategory,
    int retryCount = 0,
    Duration delay = const Duration(minutes: 5),
    int priority = 5,
  }) async {
    final retryAt = DateTime.now().add(delay);

    await FailedFileQueue.db.insertRow(
      session,
      FailedFileQueue(
        path: path,
        errorMessage: errorMessage,
        errorCategory: errorCategory,
        retryCount: retryCount,
        retryAt: retryAt,
        priority: priority,
      ),
    );
  }

  /// Get files ready for retry
  static Future<List<FailedFileQueue>> getReadyForRetry(
    Session session, {
    int limit = 100,
  }) async {
    return await FailedFileQueue.db.find(
      session,
      where: (t) => t.retryAt.lessThanOrEqualTo(DateTime.now()),
      orderBy: (t) => t.priority,
      orderDescending: true,
      limit: limit,
    );
  }

  /// Mark file as successfully processed
  static Future<void> markSuccess(
    Session session,
    String path,
  ) async {
    await FailedFileQueue.db.deleteWhere(
      session,
      where: (t) => t.path.equals(path),
    );
  }

  /// Increment retry count and reschedule
  static Future<void> incrementRetry(
    Session session,
    FailedFileQueue item, {
    Duration? delay,
  }) async {
    // Exponential backoff: 5min, 15min, 45min, 2hr, 6hr
    final nextDelay = delay ??
        Duration(
          minutes: 5 * pow(3, item.retryCount).toInt(),
        );

    await FailedFileQueue.db.updateRow(
      session,
      item.copyWith(
        retryCount: item.retryCount + 1,
        retryAt: DateTime.now().add(nextDelay),
      ),
    );
  }

  /// Clean up old entries (older than 30 days)
  static Future<int> cleanupOld(Session session) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final deleted = await FailedFileQueue.db.deleteWhere(
      session,
      where: (t) => t.retryAt.lessThan(cutoff) & t.retryCount.greaterThan(10),
    );

    return deleted.length;
  }
}
```

### 4.3 Update Butler Endpoint with Retry Logic

**Modify `_processBatch` in butler_endpoint.dart:**

```dart
Future<_BatchResult> _processBatch(
  Session session,
  List<String> filePaths,
) async {
  int indexed = 0;
  int failed = 0;
  int skipped = 0;

  final itemsToProcess = <_BatchItem>[];

  for (final path in filePaths) {
    // Try to acquire lock
    final locked = await LockService.tryAcquireLock(session, path);
    if (!locked) {
      skipped++;
      continue;
    }

    try {
      final existing = await FileIndex.db.findFirstRow(
        session,
        where: (t) => t.path.equals(path),
      );

      // Use retry logic for extraction
      final extraction = await executeWithRetry(
        () => _extractionService.extract(path),
        policy: const RetryPolicy(maxAttempts: 3),
      );

      // Skip if content unchanged
      if (existing != null &&
          existing.contentHash == extraction.contentHash) {
        skipped++;
        continue;
      }

      itemsToProcess.add(
        _BatchItem(
          path: path,
          extraction: extraction,
          existingIndex: existing,
        ),
      );
    } catch (e) {
      failed++;
      final errorCategory = _categorizeError(e);
      final strategy = classifyError(e);

      session.log(
        'Failed to extract $path [$errorCategory]: $e',
        level: LogLevel.warning,
      );

      // Add to retry queue for transient errors
      if (strategy == RetryStrategy.transient) {
        await FailedFileQueueService.enqueue(
          session,
          path: path,
          errorMessage: e.toString(),
          errorCategory: errorCategory,
        );
      }

      await _recordIndexingError(
        session,
        path,
        'Extraction failed: $e',
        errorCategory: errorCategory,
      );
    } finally {
      await LockService.releaseLock(session, path);
    }
  }

  // ... rest of method
}
```

### 4.4 Background Retry Job

**Add to ButlerEndpoint:**

```dart
/// Process failed files from the queue
Future<void> _processFailedFiles(Session session) async {
  final ready = await FailedFileQueueService.getReadyForRetry(
    session,
    limit: 50,
  );

  if (ready.isEmpty) return;

  session.log(
    'Retrying ${ready.length} failed files',
    level: LogLevel.info,
  );

  for (final item in ready) {
    try {
      final extraction = await executeWithRetry(
        () => _extractionService.extract(item.path),
        policy: const RetryPolicy(maxAttempts: 2),
      );

      // Process the extraction
      await _indexSingleFile(session, item.path, extraction);

      // Mark as success
      await FailedFileQueueService.markSuccess(session, item.path);
    } catch (e) {
      // Increment retry count
      await FailedFileQueueService.incrementRetry(session, item);

      session.log(
        'Retry failed for ${item.path}: $e',
        level: LogLevel.warning,
      );
    }
  }
}

/// Start background retry job
static void startRetryJob(Serverpod serverpod) {
  Timer.periodic(const Duration(minutes: 5), (_) async {
    final session = await serverpod.createSession();
    try {
      final endpoint = ButlerEndpoint();
      await endpoint._processFailedFiles(session);
    } catch (e) {
      session.log('Failed file queue processing error: $e', level: LogLevel.error);
    } finally {
      await session.close();
    }
  });
}
```

**Acceptance Criteria:**
- [ ] Errors are classified as transient or permanent
- [ ] Transient errors are retried with exponential backoff
- [ ] Failed files are queued for later retry
- [ ] Background job processes retry queue
- [ ] Old failed entries are cleaned up
- [ ] Retry attempts respect maximum limits

---

## Phase 5: File Watcher Enhancements

**Priority:** P2 (Medium)
**Estimated Duration:** 2 weeks
**Goal:** Improve file watcher reliability and handle edge cases

### 5.1 Volume Monitoring

**New File:**
- `semantic_butler/semantic_butler_server/lib/src/services/volume_monitor_service.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'package:serverpod/serverpod.dart';

/// Service for monitoring volume changes (USB drives, network shares)
class VolumeMonitorService {
  final Session _session;
  final Map<String, int> _volumeChangeCounts = {};
  Timer? _monitorTimer;

  /// Callback when a volume is added
  final Future<void> Function(String mountPoint)? onVolumeAdded;

  /// Callback when a volume is removed
  final Future<void> Function(String mountPoint)? onVolumeRemoved;

  VolumeMonitorService(
    this._session, {
    this.onVolumeAdded,
    this.onVolumeRemoved,
  });

  /// Start monitoring volume changes
  Future<void> start() async {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkVolumeChanges();
    });
  }

  /// Stop monitoring
  void stop() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  /// Check for volume changes
  Future<void> _checkVolumeChanges() async {
    try {
      final currentVolumes = await _getCurrentVolumes();

      // Check for new volumes
      for (final volume in currentVolumes) {
        if (!_volumeChangeCounts.containsKey(volume)) {
          _session.log(
            'Volume detected: $volume',
            level: LogLevel.info,
          );
          if (onVolumeAdded != null) {
            await onVolumeAdded!(volume);
          }
        }
        _volumeChangeCounts[volume] = DateTime.now().millisecondsSinceEpoch;
      }

      // Check for removed volumes
      final removed = <String>[];
      for (final volume in _volumeChangeCounts.keys) {
        if (!currentVolumes.contains(volume)) {
          removed.add(volume);
        }
      }

      for (final volume in removed) {
        _session.log(
          'Volume removed: $volume',
          level: LogLevel.info,
        );
        _volumeChangeCounts.remove(volume);

        if (onVolumeRemoved != null) {
          await onVolumeRemoved!(volume);
        }
      }
    } catch (e) {
      _session.log(
        'Volume monitoring error: $e',
        level: LogLevel.warning,
      );
    }
  }

  /// Get list of current volumes/mount points
  Future<List<String>> _getCurrentVolumes() async {
    final volumes = <String>[];

    if (Platform.isWindows) {
      // Use PowerShell to get drives
      final result = await Process.run(
        'powershell',
        ['-Command', 'Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root'],
      );
      if (result.exitCode == 0) {
        final drives = (result.stdout as String).trim().split('\n');
        volumes.addAll(drives.map((d) => d.trim()).where((d) => d.isNotEmpty));
      }
    } else if (Platform.isMacOS || Platform.isLinux) {
      // Read mount points
      final result = await Process.run('df', ['-l']);
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).split('\n');
        for (final line in lines.skip(1)) {
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 6) {
            volumes.add(parts.last); // Mount point is last column
          }
        }
      }
    }

    return volumes;
  }
}
```

### 5.2 Directory Identity Tracking

**New File:**
- `semantic_butler/semantic_butler_server/lib/src/services/directory_identity_service.dart`

```dart
import 'dart:io';
import 'package:serverpod/serverpod.dart';

/// Identity of a directory (platform-specific)
class DirectoryIdentity {
  final String path;
  final String fileId;
  final int deviceId;

  DirectoryIdentity({
    required this.path,
    required this.fileId,
    required this.deviceId,
  });

  /// Check if two identities refer to the same directory
  bool matches(DirectoryIdentity other) {
    return other.fileId == fileId && other.deviceId == deviceId;
  }

  @override
  bool operator ==(Object other) =>
      other is DirectoryIdentity &&
      other.fileId == fileId &&
      other.deviceId == deviceId;

  @override
  int get hashCode => Object.hash(fileId, deviceId);
}

/// Service for tracking directory identities
class DirectoryIdentityService {
  /// Get the identity of a directory
  static Future<DirectoryIdentity?> getIdentity(String path) async {
    try {
      if (Platform.isWindows) {
        return await _getWindowsIdentity(path);
      } else if (Platform.isMacOS || Platform.isLinux) {
        return await _getUnixIdentity(path);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get Windows directory identity (FILE_ID_INFO)
  static Future<DirectoryIdentity?> _getWindowsIdentity(String path) async {
    // Requires calling Windows API via FFI or subprocess
    // For now, return null
    return null;
  }

  /// Get Unix directory identity (stat.st_dev + stat.st_ino)
  static Future<DirectoryIdentity?> _getUnixIdentity(String path) async {
    try {
      // Use stat command
      final result = await Process.run('stat', ['-c', '%d %i', path]);
      if (result.exitCode == 0) {
        final output = (result.stdout as String).trim();
        final parts = output.split(' ');
        if (parts.length == 2) {
          return DirectoryIdentity(
            path: path,
            fileId: parts[1], // inode
            deviceId: int.parse(parts[0]), // device
          );
        }
      }
    } catch (_) {
      // Fallback: use path as identifier
    }
    return null;
  }

  /// Check if a directory has been renamed
  static Future<bool> isRenamed(
    String oldPath,
    String newPath,
  ) async {
    final oldIdentity = await getIdentity(oldPath);
    final newIdentity = await getIdentity(newPath);

    if (oldIdentity != null && newIdentity != null) {
      return oldIdentity.matches(newIdentity);
    }

    // Fallback: check if files match
    return false;
  }
}
```

### 5.3 Update FileWatcherService

**Modify file_watcher_service.dart:**

```dart
class FileWatcherService {
  // ... existing fields ...

  /// Volume monitor for handling drive changes
  VolumeMonitorService? _volumeMonitor;

  /// Directory identities for rename detection
  final Map<String, DirectoryIdentity?> _directoryIdentities = {};

  Future<WatchedFolder> startWatching(String path) async {
    // ... existing code ...

    // Store directory identity for rename detection
    _directoryIdentities[path] = await DirectoryIdentityService.getIdentity(path);

    // Start volume monitoring if not already started
    if (_volumeMonitor == null) {
      _volumeMonitor = VolumeMonitorService(
        _session,
        onVolumeAdded: _handleVolumeAdded,
        onVolumeRemoved: _handleVolumeRemoved,
      );
      await _volumeMonitor!.start();
    }

    // ... rest of method ...
  }

  /// Handle volume added
  Future<void> _handleVolumeAdded(String mountPoint) async {
    _session.log(
      'Volume added, checking for watched folders: $mountPoint',
      level: LogLevel.info,
    );

    final watchedFolders = await getWatchedFolders();
    for (final folder in watchedFolders) {
      if (folder.path.startsWith(mountPoint)) {
        try {
          await startWatching(folder.path);
          _session.log(
            'Restored watcher for ${folder.path} on volume $mountPoint',
            level: LogLevel.info,
          );
        } catch (e) {
          _session.log(
            'Failed to restore watcher: $e',
            level: LogLevel.warning,
          );
        }
      }
    }
  }

  /// Handle volume removed
  Future<void> _handleVolumeRemoved(String mountPoint) async {
    _session.log(
      'Volume removed, pausing watchers: $mountPoint',
      level: LogLevel.info,
    );

    final watchedFolders = await getWatchedFolders();
    for (final folder in watchedFolders) {
      if (folder.path.startsWith(mountPoint)) {
        final subscription = _watchers.remove(folder.path);
        if (subscription != null) {
          await subscription.cancel();
        }
        _watcherHealth[folder.path] = false;
      }
    }
  }

  /// Detect directory rename
  Future<String?> _detectDirectoryRename(String oldPath) async {
    final oldIdentity = _directoryIdentities[oldPath];
    if (oldIdentity == null) return null;

    // Check all parent directories for matches
    final parentDir = Directory(oldPath).parent.path;

    await for (final entity in Directory(parentDir).list()) {
      if (entity is Directory) {
        final identity = await DirectoryIdentityService.getIdentity(entity.path);
        if (identity != null && identity.matches(oldIdentity)) {
          return entity.path;
        }
      }
    }

    return null;
  }
}
```

**Acceptance Criteria:**
- [ ] Volume changes are detected within 10 seconds
- [ ] Watchers are paused when volume is removed
- [ ] Watchers are restored when volume is reconnected
- [ ] Directory renames are tracked correctly
- [ ] No crashes on USB drive removal

---

## Phase 6: Data Integrity & Health

**Priority:** P2 (Medium)
**Estimated Duration:** 1 week
**Goal:** Ensure index data integrity

### 6.1 Integrity Validation Service

**New File:**
- `semantic_butler/semantic_butler_server/lib/src/services/index_integrity_service.dart`

```dart
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'content_hash_service.dart';

/// Result of integrity validation
class IntegrityReport {
  final int totalSampled;
  final int valid;
  final int invalid;
  final List<String> invalidPaths;

  IntegrityReport({
    required this.totalSampled,
    required this.valid,
    required this.invalid,
    required this.invalidPaths,
  });

  double get validityPercentage =>
      totalSampled > 0 ? (valid / totalSampled) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'totalSampled': totalSampled,
        'valid': valid,
        'invalid': invalid,
        'validityPercentage': validityPercentage,
        'invalidPaths': invalidPaths,
      };
}

/// Service for validating index integrity
class IndexIntegrityService {
  /// Validate integrity of a random sample of indexed files
  static Future<IntegrityReport> validateSample(
    Session session, {
    int sampleSize = 100,
  }) async {
    // Get random sample
    final sampled = await FileIndex.db.find(
      session,
      where: (t) => t.status.equals('indexed'),
      limit: sampleSize,
      // Note: true random sampling would require database-specific approach
      orderBy: () => Function.random(), // If supported
    );

    int valid = 0;
    final invalidPaths = <String>[];

    for (final file in sampled) {
      // Check if file exists
      if (!await File(file.path).exists()) {
        invalidPaths.add('${file.path} (file not found)');
        continue;
      }

      // Verify content hash
      final hashMatch = await ContentHashService.verifyHash(
        file.path,
        file.contentHash,
      );

      if (hashMatch) {
        valid++;
      } else {
        invalidPaths.add('${file.path} (hash mismatch)');
      }
    }

    return IntegrityReport(
      totalSampled: sampled.length,
      valid: valid,
      invalid: invalidPaths.length,
      invalidPaths: invalidPaths,
    );
  }

  /// Validate all indexed files (slow operation)
  static Future<IntegrityReport> validateAll(Session session) async {
    final indexed = await FileIndex.db.find(
      session,
      where: (t) => t.status.equals('indexed'),
    );

    int valid = 0;
    final invalidPaths = <String>[];

    for (final file in indexed) {
      if (!await File(file.path).exists()) {
        invalidPaths.add('${file.path} (file not found)');
        continue;
      }

      final hashMatch = await ContentHashService.verifyHash(
        file.path,
        file.contentHash,
      );

      if (hashMatch) {
        valid++;
      } else {
        invalidPaths.add('${file.path} (hash mismatch)');
      }
    }

    return IntegrityReport(
      totalSampled: indexed.length,
      valid: valid,
      invalid: invalidPaths.length,
      invalidPaths: invalidPaths,
    );
  }

  /// Clean up orphaned embeddings (embeddings without FileIndex)
  static Future<int> cleanupOrphanedEmbeddings(Session session) async {
    final deleted = await session.db.unsafeQuery(
      'DELETE FROM document_embedding '
      'WHERE "fileIndexId" NOT IN (SELECT id FROM file_index)',
    );

    final affectedRows = deleted.first.isNotEmpty
        ? (deleted.first[0] as int)
        : 0;

    session.log(
      'Cleaned up $affectedRows orphaned embeddings',
      level: LogLevel.info,
    );

    return affectedRows;
  }

  /// Fix integrity issues by re-indexing affected files
  static Future<int> fixIssues(
    Session session,
    IntegrityReport report,
  ) async {
    int fixed = 0;

    for (final path in report.invalidPaths) {
      final cleanPath = path.split(' (')[0];

      try {
        // Mark file for re-indexing
        final existing = await FileIndex.db.findFirstRow(
          session,
          where: (t) => t.path.equals(cleanPath),
        );

        if (existing != null) {
          existing.status = 'pending';
          await FileIndex.db.updateRow(session, existing);
          fixed++;
        }
      } catch (e) {
        session.log(
          'Failed to mark file for re-indexing: $cleanPath - $e',
          level: LogLevel.warning,
        );
      }
    }

    return fixed;
  }
}
```

### 6.2 Add Integrity API to ButlerEndpoint

```dart
/// Validate index integrity (sample)
Future<IntegrityReport> validateIndexIntegrity(
  Session session, {
  int sampleSize = 100,
}) async {
  AuthService.requireAuth(session);

  final clientId = _getClientIdentifier(session);
  RateLimitService.instance.requireRateLimit(clientId, 'validateIndexIntegrity');

  return await IndexIntegrityService.validateSample(
    session,
    sampleSize: sampleSize,
  );
}

/// Fix index integrity issues
Future<Map<String, dynamic>> fixIndexIntegrity(
  Session session,
) async {
  AuthService.requireAuth(session);

  final report = await IndexIntegrityService.validateSample(session);
  final fixed = await IndexIntegrityService.fixIssues(session, report);
  final orphanedCleaned = await IndexIntegrityService.cleanupOrphanedEmbeddings(session);

  return {
    'validated': report.totalSampled,
    'fixed': fixed,
    'orphanedCleaned': orphanedCleaned,
  };
}
```

**Acceptance Criteria:**
- [ ] Integrity validation works on random sample
- [ ] Orphaned embeddings are cleaned up
- [ ] Invalid files are marked for re-indexing
- [ ] Full validation works (but may be slow)
- [ ] API endpoints return proper status

---

## Phase 7: Advanced Features

**Priority:** P3 (Low)
**Estimated Duration:** 4 weeks
**Goal:** Add advanced features for improved functionality

### 7.1 OCR for Images and Scanned PDFs

**Dependencies:**
```yaml
dependencies:
  tesseract_ocr: ^0.4.0  # OCR package
```

**Implementation:**
```dart
/// Extract text from images using OCR
Future<String> _extractImageText(File imageFile) async {
  try {
    final text = await TesseractOcr.extractText(imageFile.path);
    return text ?? '';
  } catch (e) {
    return '';
  }
}
```

### 7.2 Thumbnail Generation

**Dependencies:**
```yaml
dependencies:
  image: ^4.1.0
```

**Implementation:**
```dart
/// Generate thumbnail for image file
Future<Uint8List?> generateThumbnail(
  String imagePath, {
  int width = 200,
  int height = 200,
}) async {
  try {
    final command = Platform.isWindows
        ? 'magick'
        : 'convert'; // ImageMagick

    final result = await Process.run(
      command,
      [
        imagePath,
        '-resize',
        '${width}x${height}',
        '-strip',
        'jpg:-', // Output to stdout
      ],
    );

    if (result.exitCode == 0) {
      return result.stdout as Uint8List;
    }

    return null;
  } catch (_) {
    return null;
  }
}
```

### 7.3 Language Detection

**Dependencies:**
```yaml
dependencies:
  language_detector: ^0.1.0
```

**Implementation:**
```dart
/// Detect language of text
Future<String?> detectLanguage(String text) async {
  if (text.length < 50) return null; // Need minimum text

  try {
    final detector = LanguageDetector();
    final language = await detector.detect(text);
    return language;
  } catch (_) {
    return null;
  }
}
```

**Acceptance Criteria:**
- [ ] OCR extracts text from images
- [ ] Scanned PDFs are processed with OCR
- [ ] Thumbnails are generated for images
- [ ] Language is detected for documents
- [ ] Performance impact is minimal

---

## Testing Strategy

### Unit Tests

For each new service/component:

```dart
// Example test structure
void main() {
  group('ServiceName', () {
    late Session session;

    setUp(() {
      // Initialize test session
    });

    test('should handle normal case', () async {
      // Test implementation
    });

    test('should handle edge case', () async {
      // Test implementation
    });

    test('should throw on invalid input', () async {
      // Test implementation
    });
  });
}
```

### Integration Tests

```dart
void main() {
  group('Indexing Integration Tests', () {
    test('Full indexing workflow', () async {
      // 1. Start indexing
      // 2. Wait for completion
      // 3. Verify results
      // 4. Search and verify
    });

    test('Incremental indexing workflow', () async {
      // 1. Initial index
      // 2. Modify files
      // 3. Incremental re-index
      // 4. Verify only modified files re-indexed
    });
  });
}
```

### Performance Tests

```dart
void main() {
  group('Performance Tests', () {
    test('Scan 10,000 files in under 30 seconds', () async {
      final stopwatch = Stopwatch()..start();
      // Scan large directory
      stopwatch.stop();
      expect(stopwatch.elapsedSeconds, lessThan(30));
    });

    test('Index 1000 files in under 5 minutes', () async {
      final stopwatch = Stopwatch()..start();
      // Index files
      stopwatch.stop();
      expect(stopwatch.elapsedMinutes, lessThan(5));
    });
  });
}
```

---

## Rollout Plan

### Week 1: Phase 0 (Critical Infrastructure)
- Implement job cancellation
- Add transaction consistency
- Optimize orphaned file detection
- Create database migration for constraints

### Week 2-3: Phase 1 (Critical File Formats)
- Implement Office document extraction
- Implement proper PDF extraction
- Unit tests for extraction

### Week 4: Phase 2 (Configuration)
- Create IndexingConfig model
- Implement configuration service
- Add configuration API endpoints

### Week 5-6: Phase 3 (Scanning Performance)
- Implement incremental scanning
- Implement parallel scanning
- Add symlink handling
- Performance testing

### Week 7: Phase 4 (Error Handling)
- Implement retry policy
- Create failed file queue
- Add background retry job

### Week 8-9: Phase 5 (File Watcher)
- Implement volume monitoring
- Add directory identity tracking
- Update file watcher service

### Week 10: Phase 6 (Data Integrity)
- Implement integrity validation
- Add orphaned cleanup

### Week 11-14: Phase 7 (Advanced Features)
- Implement OCR support
- Add thumbnail generation
- Implement language detection
- Performance optimization

### Validation Gates

Before each phase deployment to production:
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Code coverage > 80%
- [ ] Performance benchmarks met
- [ ] Security review completed
- [ ] Documentation updated

---

## Dependencies Summary

| Package | Version | Purpose | Phase |
|---------|---------|---------|-------|
| archive | ^3.4.0 | ZIP extraction (Office files) | 1 |
| xml | ^6.5.0 | XML parsing (Office content) | 1 |
| pdf | ^3.10.0 | PDF text extraction | 1 |
| tesseract_ocr | ^0.4.0 | OCR for images | 7 |
| image | ^4.1.0 | Image processing | 7 |
| language_detector | ^0.1.0 | Language detection | 7 |
| mutex | ^3.0.0 | Mutual exclusion for job limiting | 0 |

---

## Success Metrics

### Phase 0 Success Metrics
- Jobs can be cancelled without data corruption
- Transactions prevent partial embedding storage
- Memory usage remains stable with large indexes

### Phase 1 Success Metrics
- Office documents (DOCX, XLSX, PPTX) are indexed correctly
- PDF extraction accuracy > 95%
- Support for 90% of common business documents

### Phase 2 Success Metrics
- Configuration changes applied without restart
- User-configurable limits accessible via UI
- Concurrent jobs properly limited

### Phase 3 Success Metrics
- 50% faster directory scanning on 10,000+ files
- Incremental re-indexing time < 10% of full scan
- Symlink loops don't cause infinite loops

### Phase 4 Success Metrics
- 90% of transient errors recovered via retry
- Failed file queue < 5% of total files
- Batch failures don't affect other files

### Phase 5 Success Metrics
- No crashes on volume removal
- Directory renames tracked correctly
- Watcher restoration works after reconnection

### Phase 6 Success Metrics
- Index integrity > 99%
- Orphaned embeddings < 0.1%
- Integrity validation completes in reasonable time

### Phase 7 Success Metrics
- OCR accuracy > 80% on clear text images
- Thumbnail generation < 1 second per image
- Language detection accuracy > 90%

---

## Backward Compatibility

All changes are backward compatible:
- Existing indexes continue to work
- Old file extraction methods remain as fallback
- Configuration uses sensible defaults
- API endpoints are additive, not breaking
- Database migrations are non-destructive

---

## Future Considerations

Out of scope for this implementation plan:
1. Distributed indexing across multiple servers
2. Real-time collaboration on indexed files
3. Machine learning for content classification
4. Advanced search features (fuzzy matching, phonetic search)
5. Support for proprietary formats (PDF with DRM, etc.)
6. Full-text search indexing with Lucene/Tantiny
7. Differential sync between clients
8. Conflict resolution for concurrent edits

---

## Appendix: Complete Issue Reference

### Critical Issues Reference

| # | Issue | Location | Fix Phase |
|---|-------|----------|-----------|
| 1 | No job cancellation | butler_endpoint.dart:717-819 | 0 |
| 2 | PDF extraction primitive | file_extraction_service.dart:378-428 | 1 |
| 3 | Memory leak orphaned detection | index_health_service.dart:62-76 | 0 |
| 4 | No transaction rollback | butler_endpoint.dart:1057-1147 | 0 |

### High Priority Issues Reference

| # | Issue | Location | Fix Phase |
|---|-------|----------|-----------|
| 5 | Missing unique constraint | file_index.yaml | 0 |
| 6 | Watcher restoration no validation | file_watcher_service.dart:405-426 | 5 |
| 7 | No concurrent job limit | butler_endpoint.dart:651-688 | 2 |
| 8 | Missing vector column | document_embedding.yaml | 0 |

### Medium Priority Issues Reference

| # | Issue | Location | Fix Phase |
|---|-------|----------|-----------|
| 9 | Inefficient batch processing | butler_endpoint.dart:760-790 | 3 |
| 10 | Limited glob matching | file_extraction_service.dart:453-498 | 2 |
| 11 | File size check late | butler_endpoint.dart:741-755 | 3 |
| 12 | No resume capability | butler_endpoint.dart:717-819 | 4 |

### Low Priority Issues Reference

| # | Issue | Location | Fix Phase |
|---|-------|----------|-----------|
| 13 | No progress streaming | butler_endpoint.dart | 7 |
| 14 | No deduplication | file_watcher_service.dart | 5 |
| 15 | Preview truncation | file_extraction_service.dart:345 | 1 |
| 16 | Model version not tracked | file_index.yaml | 7 |
| 17 | No batch retry | butler_endpoint.dart:783-789 | 4 |

### Database Issues Reference

| # | Issue | Location | Fix Phase |
|---|-------|----------|-----------|
| 18 | Missing HNSW index | migrations | 0 |
| 19 | Manual cascade delete | butler_endpoint.dart:1018-1022 | 0 |

### Testing Gaps Reference

| # | Issue | Location | Fix Phase |
|---|-------|----------|-----------|
| 20 | Limited test coverage | auto_indexing_test.dart | All |

### Security Issues Reference

| # | Issue | Location | Fix Phase |
|---|-------|----------|-----------|
| 21 | Weak symlink validation | file_extraction_service.dart:500-527 | 3 |
