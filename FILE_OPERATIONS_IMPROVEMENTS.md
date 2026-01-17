# File Operations Improvements

This document outlines potential improvements to the file operations system in Semantic Butler's agentic features.

## Current Implementation

The `FileOperationsService` handles move, copy, rename, delete, and create operations using Dart's `dart:io` API:

- **Rename**: Uses `file.rename()` / `dir.rename()`
- **Move**: Uses `file.rename()` (Dart's rename works across directories)
- **Copy**: Uses `file.copy()`
- **Delete**: Uses `file.delete()` or `dir.delete(recursive: true)`

### Cross-Platform Support
The service works on macOS, Linux, and Windows:

1. **Path Normalization**: Uses `path.normalize()` to handle both `/` and `\`
2. **Shell Commands**:
   - Windows: `cmd.exe` with `/c` flag
   - Unix/macOS/Linux: `/bin/sh` with `-c` flag
3. **Platform Detection**: `Platform.isWindows` determines shell and command selection

### Error Handling
Multiple safety layers:

1. **Path Validation**:
   - Null byte detection
   - URL decoding checks
   - Path traversal prevention (`..`, `%2e%2e`)
   - Protected system paths (`/System`, `/usr`, `C:\Windows`)
   - Max path length (4096 chars) and depth (50 levels)

2. **Operation Validation**: Invalid character checks, existence verification, destination collision detection

3. **Structured Errors**: All errors return `FileOperationResult` with descriptive messages

### Output Structure

**FileOperationResult**:
```dart
{
  success: bool,
  newPath: String?,      // For successful operations
  error: String?,        // For failures
  command: String,       // What was attempted
  output: String?        // For list operations
}
```

**AgentFileCommand** - Audit log:
```dart
{
  id: int?,
  operation: String,           // rename, move, delete, create
  sourcePath: String,
  destinationPath: String?,
  newName: String?,
  executedAt: DateTime,
  success: bool,
  errorMessage: String?,
  reversible: bool,
  wasUndone: bool
}
```

## Proposed Improvements

### 1. Undo Functionality ✅ **IMPLEMENTED**

Currently only `delete` is marked as non-reversible. Add actual undo capability for all operations:

```dart
Future<FileOperationResult> undoRename(
  String oldPath,
  String currentPath,
) async {
  try {
    await Directory(currentPath).rename(oldPath);
    return FileOperationResult(
      success: true,
      newPath: oldPath,
      command: 'undo rename $currentPath -> $oldPath',
    );
  } catch (e) {
    return FileOperationResult(
      success: false,
      error: 'Failed to undo: $e',
      command: 'undo rename $currentPath -> $oldPath',
    );
  }
}
```

**Benefits**:
- Users can recover from mistakes
- Reduces risk of accidental data loss
- Enables safer experimentation with AI agent

**Complexity**: Medium - Requires tracking previous states

**Status**: ✅ Implemented in `file_operations_service.dart` with `undoOperation()`, `undoRenameOrMove()`, `undoCopy()`, and `undoCreate()` methods

---

### 2. Cross-Platform Trash/Recycle Bin ⚠️ **PARTIALLY IMPLEMENTED**

Currently delete is permanent on macOS/Linux. Use native trash APIs:

```dart
Future<FileOperationResult> moveToTrash(String filePath) async {
  if (Platform.isWindows) {
    // Use Windows shell to move to recycle bin
    return await _moveToWindowsRecycleBin(filePath);
  } else if (Platform.isMacOS) {
    // Use AppleScript via osascript
    return await _moveToMacOSTrash(filePath);
  } else if (Platform.isLinux) {
    // Use gio (GNOME) or trash-cli
    return await _moveToLinuxTrash(filePath);
  }
  return deleteFile(filePath); // Fallback
}
```

**Implementation Options**:
- Windows: COM interop with `IFileOperation` shell interface
- macOS: AppleScript `tell application "Finder" to move...`
- Linux: `gio trash` or FreeDesktop Trash specification

**Benefits**:
- Safer deletion operations
- Users can restore files from system trash
- Better user experience across platforms

**Complexity**: High - Requires platform-specific native code

**Status**: ⚠️ Partially implemented - Windows recycle bin supported via PowerShell, macOS/Linux fallback to permanent delete

---

### 3. Atomic Operations & Rollback ✅ **IMPLEMENTED**

Add transaction-like safety for bulk operations:

```dart
Future<List<FileOperationResult>> moveFiles(
  List<MoveOperation> operations,
) async {
  final results = <FileOperationResult>[];
  final completed = <String, String>{}; // source -> dest mapping

  for (final op in operations) {
    final result = await moveFile(op.source, op.destination);
    results.add(result);

    if (result.success && result.newPath != null) {
      completed[op.source] = result.newPath!;
    } else {
      // Rollback completed operations
      await _rollbackMoves(completed);
      break;
    }
  }

  return results;
}

Future<void> _rollbackMoves(Map<String, String> completed) async {
  for (final entry in completed.entries) {
    try {
      await File(entry.value).rename(entry.key);
    } catch (e) {
      // Log but continue rollback
    }
  }
}
```

**Benefits**:
- Bulk operations are either all succeed or all fail
- No partial/inconsistent states
- Better reliability for AI agent operations

**Complexity**: Medium-High

**Status**: ✅ Implemented with `batchOperations()` method supporting rollback on failure

---

### 4. Progress Tracking for Large Files

Add streaming progress for copy/move of large files:

```dart
Future<FileOperationResult> copyFileWithProgress(
  String sourcePath,
  String destFolder,
  void Function(int copied, int total)? onProgress,
) async {
  final source = File(sourcePath);
  final destPath = path.join(destFolder, path.basename(sourcePath));
  final dest = File(destPath);

  final raf = await source.open(mode: FileMode.read);
  final waf = await dest.open(mode: FileMode.write);

  const chunkSize = 1024 * 1024; // 1MB chunks
  final fileSize = await source.length();
  var copied = 0;

  while (copied < fileSize) {
    final chunk = await raf.read(chunkSize);
    await waf.writeFrom(chunk);
    copied += chunk.length;
    onProgress?.call(copied, fileSize);
  }

  await raf.close();
  await waf.close();

  return FileOperationResult(success: true, newPath: destPath, command: 'copy');
}
```

**Benefits**:
- Users see progress for large file operations
- Better UX with estimated time remaining
- Can cancel long-running operations

**Complexity**: Medium

---

### 5. Dry-Run Mode for Safety ✅ **IMPLEMENTED**

Add preview mode before executing operations:

```dart
Future<FileOperationResult> renameFolder(
  String currentPath,
  String newName, {
  bool dryRun = false,
}) async {
  final validation = _validatePath(currentPath);
  if (!validation.success) return validation;

  final newPath = path.join(path.dirname(currentPath), newName);

  if (dryRun) {
    return FileOperationResult(
      success: true,
      newPath: newPath,
      command: 'rename (dry-run) "$currentPath" to "$newPath"',
      output: 'Would rename: $currentPath -> $newPath',
    );
  }

  // Existing implementation...
}
```

**Benefits**:
- Users can preview AI agent's planned operations
- Reduces risk of unintended changes
- Enables confirmation workflows

**Complexity**: Low

**Status**: ✅ Implemented across all file operations with `dryRun` parameter

---

### 6. Enhanced Path Validation ✅ **IMPLEMENTED**

Add filesystem-specific checks and permission validation:

```dart
static FileOperationResult _validatePath(String filePath) {
  // ... existing checks ...

  // Case-sensitive filesystem check (Linux vs macOS)
  if (Platform.isLinux) {
    final parent = Directory(path.dirname(filePath));
    if (parent.existsSync()) {
      final exists = parent.listSync().any(
        (e) => path.basename(e.path) == path.basename(filePath),
      );
      // This would help with case-related issues
    }
  }

  // Check for permission issues before attempting operation
  try {
    final parent = Directory(path.dirname(filePath));
    final testFile = File(path.join(parent.path, '._test_permission'));
    testFile.createSync(recursive: true);
    testFile.deleteSync();
  } catch (e) {
    return FileOperationResult(
      success: false,
      error: 'No write permission: $e',
      command: 'validate permissions',
    );
  }

  // ... rest of validation ...
}
```

**Benefits**:
- Catch permission errors before attempting operations
- Handle case-sensitivity differences between OSes
- Better error messages for users

**Complexity**: Medium

**Status**: ✅ Implemented with comprehensive `_validatePath()` including null byte detection, URL decoding, path traversal prevention, protected path checks, and case-sensitive handling

---

### 7. Bulk Operations API ✅ **IMPLEMENTED**

Add batch support with atomicity options:

```dart
Future<BatchFileOperationResult> batchOperations(
  List<FileOperation> operations, {
  bool stopOnError = true,
  bool rollbackOnError = false,
}) async {
  final results = <FileOperationResult>[];
  final history = <String>{}; // Track completed for rollback

  for (final op in operations) {
    final result = await _executeOperation(op);
    results.add(result);

    if (result.success) {
      history.add(result.command);
    } else if (stopOnError) {
      if (rollbackOnError) {
        await _rollbackOperations(history);
      }
      break;
    }
  }

  return BatchFileOperationResult(
    operations: operations.length,
    succeeded: results.where((r) => r.success).length,
    failed: results.where((r) => !r.success).length,
    results: results,
  );
}
```

**Benefits**:
- Efficient processing of multiple operations
- Configurable error handling
- Better performance for AI agent workflows

**Complexity**: Medium-High

**Status**: ✅ Implemented with `batchOperations()`, `FileOperationRequest`, and `BatchFileOperationResult`

---

### 8. Symbolic Link & Special File Handling

Add support for symlinks (important for macOS/Linux):

```dart
Future<FileOperationResult> copyFile(
  String sourcePath,
  String destFolder,
) async {
  // ... existing validation ...

  final source = File(sourcePath);

  // Handle symbolic links
  if (await isSymbolicLink(sourcePath)) {
    final link = Link(sourcePath);
    final target = await link.target();
    final destLink = Link(path.join(destFolder, path.basename(sourcePath)));
    await destLink.create(target);
    return FileOperationResult(
      success: true,
      newPath: destLink.path,
      command: 'copy symlink',
    );
  }

  // ... rest of implementation ...
}

Future<bool> isSymbolicLink(String path) async {
  final type = await FileSystemEntity.type(path);
  return type == FileSystemEntityType.link;
}
```

**Benefits**:
- Proper handling of symbolic links
- Prevents link resolution errors
- Better support for development workflows

**Complexity**: Low-Medium

---

### 9. Metadata Preservation

Preserve file attributes across platforms:

```dart
Future<FileOperationResult> copyWithMetadata(
  String sourcePath,
  String destFolder,
) async {
  final source = File(sourcePath);
  final destPath = path.join(destFolder, path.basename(sourcePath));
  final dest = File(destPath);

  await source.copy(destPath);

  // Preserve timestamps
  final stat = await source.stat();
  await dest.setLastAccessed(stat.accessed);
  await dest.setLastModified(stat.modified);

  // On Unix, preserve permissions
  if (!Platform.isWindows) {
    // Use Process.run with 'chmod' to preserve mode
  }

  return FileOperationResult(success: true, newPath: destPath, command: 'copy');
}
```

**Benefits**:
- Maintain file metadata across operations
- Better preserve user expectations
- Important for version control and backups

**Complexity**: Medium

---

### 10. Better Error Classification ✅ **IMPLEMENTED**

Categorize errors for better UI handling:

```dart
enum FileOperationErrorType {
  permissionDenied,
  pathNotFound,
  pathTooLong,
  protectedPath,
  diskFull,
  fileInUse,
  invalidCharacters,
  other,
}

class FileOperationResult {
  final bool success;
  final String? newPath;
  final String? error;
  final FileOperationErrorType? errorType;
  final String command;
  final String? output;

  // Add error type classification in operations
}
```

**Benefits**:
- Better error messages for users
- AI agent can suggest appropriate remedies
- Simplifies UI error handling

**Complexity**: Low-Medium

**Status**: ✅ Implemented with `FileOperationErrorType` class defining 12 error types and usage across all operations

---

### 11. Add Monitoring & Metrics ✅ **IMPLEMENTED**

Track operation performance:

```dart
class FileOperationsService {
  final _metrics = <String, List<int>>{};

  Future<FileOperationResult> renameFile(
    String currentPath,
    String newName,
  ) async {
    final stopwatch = Stopwatch()..start();

    final result = await _renameFileImpl(currentPath, newName);

    stopwatch.stop();
    _recordMetric('rename', stopwatch.elapsedMilliseconds);

    return result;
  }

  void _recordMetric(String operation, int duration) {
    _metrics.putIfAbsent(operation, () => <int>[]);
    _metrics[operation]!.add(duration);

    if (_metrics[operation]!.length > 100) {
      _metrics[operation]!.removeAt(0);
    }
  }

  Map<String, dynamic> getMetrics() {
    return _metrics.map((op, times) => MapEntry(
      op,
      {
        'count': times.length,
        'avg': times.reduce((a, b) => a + b) / times.length,
        'min': times.reduce(min),
        'max': times.reduce(max),
      },
    ));
  }
}
```

**Benefits**:
- Monitor performance issues
- Identify slow operations
- Data-driven optimization

**Complexity**: Low

**Status**: ✅ Implemented with `MetricsService` providing latency tracking, counters, gauges, percentiles (p50, p95, p99)

---

### 12. Smart Path Handling ✅ **IMPLEMENTED**

Handle case-sensitivity and normalization issues:

```dart
static String normalizePathForOS(String path) {
  if (Platform.isWindows) {
    // Windows paths are case-insensitive, normalize to uppercase drive letters
    return path.replaceFirst(RegExp(r'^[a-zA-Z]:'), (match) => match[0].toUpperCase());
  } else if (Platform.isMacOS) {
    // macOS is usually case-insensitive but case-preserving
    // Normalize Unicode (important for accented characters)
    return path.normalize();
  } else {
    // Linux is case-sensitive, preserve case
    return path.normalize();
  }
}

static bool pathsEqual(String p1, String p2) {
  if (Platform.isWindows) {
    return p1.toLowerCase() == p2.toLowerCase();
  }
  return p1 == p2;
}
```

**Benefits**:
- Handle path comparison correctly per OS
- Prevent duplicate operations due to case differences
- Better cross-platform consistency

**Complexity**: Low

**Status**: ✅ Implemented with path normalization, `~` expansion, case-sensitive handling for rename/move, and canonical path comparisons

---

### 13. Hierarchical Summarization for Indexing

Generate document summaries before embedding to reduce token usage and improve search relevance:

```dart
Future<String> generateDocumentSummary(String content) async {
  final prompt = '''
  Generate a concise summary of this document (max 200 words):

  $content
  ''';

  final summary = await aiService.generateText(prompt, model: 'gpt-4o-mini');
  return summary;
}

Future<void> indexFile(String filePath) async {
  final content = await readFileContent(filePath);

  // Generate summary first for token efficiency
  final summary = await generateDocumentSummary(content);

  // Embed summary instead of full document
  final embedding = await aiService.getEmbedding(summary);

  // Store both full content (for preview) and summary (for search)
  await database.storeDocument(
    filePath: filePath,
    summary: summary,
    embedding: embedding,
    fullContent: content,
  );
}
```

**Benefits**:
- Reduces embedding costs by 70-90%
- Improves search relevance by focusing on key concepts
- Faster search with smaller vectors
- Summary available for quick previews

**Complexity**: Medium - Requires AI service integration

---

### 14. Incremental Indexing ✅ **IMPLEMENTED**

Only reindex changed files using modification timestamps and content hashing:

```dart
class IncrementalIndexer {
  final Map<String, FileMetadata> _indexedFiles = {};

  Future<bool> needsReindex(String filePath) async {
    final file = File(filePath);
    final stat = await file.stat();
    final hash = await _computeFileHash(filePath);

    final metadata = _indexedFiles[filePath];

    if (metadata == null) return true;

    // Check if modified or content changed
    return metadata.modified != stat.modified || metadata.hash != hash;
  }

  Future<String> _computeFileHash(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> updateIndex(String filePath) async {
    if (!await needsReindex(filePath)) return;

    await indexFile(filePath);
    final stat = await File(filePath).stat();
    final hash = await _computeFileHash(filePath);

    _indexedFiles[filePath] = FileMetadata(
      modified: stat.modified,
      hash: hash,
      indexedAt: DateTime.now(),
    );
  }
}
```

**Benefits**:
- Dramatically reduces indexing time for large file sets
- Reduces API costs by only processing changed files
- Faster feedback for users adding new documents
- Can run in background as files change

**Complexity**: Medium - Requires hash computation and state management

**Status**: ✅ Fully implemented - Content hashing in `FileIndex`, hash comparison check in `butler_endpoint.dart:534-538`, file watcher service detects changes and queues re-indexing

---

### 15. Hybrid Search (Semantic + Keyword)

Combine vector similarity with traditional keyword search for best results:

```dart
Future<List<SearchResult>> hybridSearch(
  String query, {
  double semanticWeight = 0.7,
  double keywordWeight = 0.3,
}) async {
  // Parallel execution for speed
  final results = await Future.wait([
    semanticSearch(query),
    keywordSearch(query),
  ]);

  final semanticResults = results[0] as List<SearchResult>;
  final keywordResults = results[1] as List<SearchResult>;

  // Combine scores with weights
  final combined = <String, SearchResult>{};

  for (final result in semanticResults) {
    combined[result.filePath] = result.copyWith(
      score: result.score * semanticWeight,
    );
  }

  for (final result in keywordResults) {
    final existing = combined[result.filePath];
    if (existing != null) {
      combined[result.filePath] = existing.copyWith(
        score: existing.score + (result.score * keywordWeight),
      );
    } else {
      combined[result.filePath] = result.copyWith(
        score: result.score * keywordWeight,
      );
    }
  }

  // Sort by combined score
  final sorted = combined.values.toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  return sorted.take(20).toList();
}

Future<List<SearchResult>> keywordSearch(String query) async {
  // Use PostgreSQL full-text search or similar
  return await database.execute('''
    SELECT file_path, ts_rank(document_vector, plainto_tsquery($1)) as score
    FROM documents
    WHERE document_vector @@ plainto_tsquery($1)
    ORDER BY score DESC
    LIMIT 20
  ''', [query]);
}
```

**Benefits**:
- Best of both worlds: semantic understanding + exact matching
- Better results for technical queries with specific terms
- Handles queries like "React hooks tutorial" more accurately
- Faster fallback when AI API is slow

**Complexity**: Medium - Requires full-text search integration

---

### 16. Real-time Document Preview ✅ **IMPLEMENTED**

Show document excerpts in search results before opening:

```dart
class SearchResult {
  final String filePath;
  final double score;
  final String summary;
  final List<PreviewSnippet> snippets;
}

class PreviewSnippet {
  final String text;
  final int startOffset;
  final int endOffset;
  final List<String> matchedTerms;
}

Future<List<PreviewSnippet>> generatePreviewSnippets(
  String content,
  String query,
) async {
  final terms = extractSearchTerms(query);
  final sentences = content.split(RegExp(r'[.!?]+\s+'));

  final snippets = <PreviewSnippet>[];

  for (final sentence in sentences) {
    final matchedTerms = terms.where(
      (term) => sentence.toLowerCase().contains(term.toLowerCase()),
    ).toList();

    if (matchedTerms.isNotEmpty) {
      snippets.add(PreviewSnippet(
        text: sentence.trim(),
        startOffset: content.indexOf(sentence),
        endOffset: content.indexOf(sentence) + sentence.length,
        matchedTerms: matchedTerms,
      ));
    }

    if (snippets.length >= 3) break;
  }

  return snippets;
}
```

**Benefits**:
- Users can verify relevance before opening files
- Highlights matching terms in context
- Saves time by reducing unnecessary file opens
- Better UX for document-heavy workflows

**Complexity**: Low - Simple text processing

**Status**: ✅ Fully implemented - `contentPreview` field in `FileIndex` model, first 500 characters generated in `file_extraction_service.dart:212`, included in `SearchResult` and returned in search results

---

### 17. Tag Management System ⚠️ **PARTIALLY IMPLEMENTED**

Allow manual tag editing, merging, and hierarchy creation:

```dart
class TagManager {
  Future<void> mergeTags(List<String> sourceTags, String targetTag) async {
    // Find all files with source tags
    final files = await database.getFilesByTags(sourceTags);

    // Remove source tags and add target tag
    for (final file in files) {
      final tags = file.tags..removeAll(sourceTags);
      tags.add(targetTag);
      await database.updateFileTags(file.path, tags);
    }

    // Delete merged tags
    await database.deleteTags(sourceTags);
  }

  Future<void> createTagHierarchy(String parentTag, String childTag) async {
    await database.createTagRelationship(parentTag, childTag);
  }

  Future<List<String>> getRelatedTags(String tag) async {
    return await database.getRelatedTags(tag);
  }
}
```

**Benefits**:
- Users can organize tags to match their mental model
- Clean up AI-generated tag noise
- Create taxonomies for better organization
- Support for broader/narrower tag relationships

**Complexity**: Medium - Requires database schema changes

**Status**: ⚠️ Partially implemented - `TagTaxonomyService` provides tag recording, frequency tracking, search, autocomplete, and stats, but missing: mergeTags(), createTagHierarchy(), getRelatedTags(), and manual editing/merging UI

---

### 18. Search History & Saved Queries ⚠️ **PARTIALLY IMPLEMENTED**

Save and categorize recent searches with filters:

```dart
class SearchHistoryManager {
  Future<void> saveSearch(
    String query,
    SearchFilters filters,
    String? category,
  ) async {
    await database.insertSearchHistory(
      query: query,
      filters: filters,
      category: category,
      timestamp: DateTime.now(),
    );
  }

  Future<List<SearchQuery>> getRecentSearches({int limit = 10}) async {
    return await database.getRecentSearches(limit);
  }

  Future<void> createSavedSearch(
    String name,
    String query,
    SearchFilters filters,
  ) async {
    await database.saveSearchPreset(
      name: name,
      query: query,
      filters: filters,
    );
  }
}

class SearchFilters {
  final List<String> tags;
  final List<String> fileTypes;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? minSize;
  final int? maxSize;
}
```

**Benefits**:
- Quick access to frequently used searches
- Save complex filter combinations
- Analytics on what users search for
- Can suggest relevant saved searches

**Complexity**: Low - Simple database operations

**Status**: ⚠️ Partially implemented - `SearchHistory` model and `getSearchHistory()` endpoint exist, automatically saves searches, but missing: categorization, saved search presets, named saved queries, and filter combination saving

---

### 19. Context-Aware Agent ⚠️ **PARTIALLY IMPLEMENTED**

Maintain conversation context and learn user patterns:

```dart
class ConversationalAgent {
  final List<ConversationMessage> _history = {};
  final UserPreferences _preferences;

  Future<String> chat(String message) async {
    _history.add(ConversationMessage(
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    ));

    // Build context from history and preferences
    final context = _buildContext();

    final response = await aiService.generateChat(
      messages: [...context, ..._history],
      systemPrompt: _buildSystemPrompt(),
    );

    _history.add(ConversationMessage(
      role: 'assistant',
      content: response,
      timestamp: DateTime.now(),
    ));

    // Learn from user's choices
    await _learnFromInteraction(message, response);

    return response;
  }

  String _buildSystemPrompt() {
    return '''
    You are Semantic Butler, an intelligent file assistant.

    User preferences:
    - Organizes by: ${_preferences.organizationStrategy}
    - Preferred language: ${_preferences.language}
    - Risk tolerance: ${_preferences.riskTolerance}

    Always ask for confirmation before performing file operations.
    ''';
  }
}
```

**Benefits**:
- More natural conversations with memory
- Agent learns user's preferences over time
- Better suggestions based on past interactions
- Reduced repetitive explanations

**Complexity**: Medium-High - Requires conversation management

**Status**: ⚠️ Partially implemented - `conversationHistory` parameter exists in `chat()` method with 20 message limit, but missing: persistent storage across sessions, preference learning, and user-specific pattern detection

---

### 20. Smart File Organization Suggestions

Proactively suggest file organization based on usage patterns:

```dart
class OrganizationAnalyzer {
  Future<List<OrganizationSuggestion>> analyzeStructure() async {
    final suggestions = <OrganizationSuggestion>[];

    // Detect duplicate content across folders
    final duplicates = await _findDuplicates();
    suggestions.addAll(duplicates.map((dup) =>
      OrganizationSuggestion(
        type: 'merge_duplicates',
        description: 'Merge ${dup.paths.length} duplicate files',
        files: dup.paths,
        action: () => _mergeDuplicates(dup),
      ),
    ));

    // Detect inconsistent naming
    final namingIssues = await _findNamingInconsistencies();
    suggestions.addAll(namingIssues);

    // Detect similar content that could be grouped
    final similarContent = await _findSimilarContent();
    suggestions.addAll(similarContent);

    return suggestions;
  }

  Future<List<DuplicateGroup>> _findDuplicates() async {
    // Use content hashing to find exact duplicates
    return await database.query('''
      SELECT content_hash, array_agg(file_path) as paths
      FROM files
      GROUP BY content_hash
      HAVING count(*) >1
    ''');
  }
}
```

**Benefits**:
- Proactively improve file organization
- Reduce storage waste from duplicates
- Suggest better folder structures
- Learn from how user actually works

**Complexity**: Medium-High

---

### 21. AI Cost Dashboard ⚠️ **PARTIALLY IMPLEMENTED**

Real-time AI API usage with cost projections:

```dart
class CostTracker {
  Future<CostSummary> getDailyCost() async {
    final today = DateTime.now();
    final todayCalls = _calls.where((call) =>
      call.timestamp.day == today.day &&
      call.timestamp.month == today.month &&
      call.timestamp.year == today.year,
    ).toList();

    return CostSummary(
      totalCost: todayCalls.fold(0.0, (sum, call) => sum + call.cost),
      totalTokens: todayCalls.fold(0, (sum, call) => sum + call.tokens),
      callCount: todayCalls.length,
      breakdown: _calculateBreakdown(todayCalls),
    );
  }

  Future<CostProjection> projectMonthlyCost() async {
    final dailyAverage = _calculateDailyAverage();
    final daysRemaining = DateTime.now().difference(
      DateTime(DateTime.now().year, DateTime.now().month + 1, 1),
    ).inDays.abs();

    return CostProjection(
      estimatedTotal: dailyAverage * (daysRemaining + DateTime.now().day),
      remainingBudget: dailyAverage * daysRemaining,
    );
  }
}
```

**Benefits**:
- Monitor AI spending in real-time
- Set budget alerts and limits
- Optimize model selection based on cost/benefit
- Track usage per feature (search, indexing, agent)

**Complexity**: Low - Simple tracking and aggregation

**Status**: ⚠️ Partially implemented - `getAIUsageStats()` endpoint returns total input/output tokens and estimated cost USD, but missing: per-feature breakdown, budget limits, alerts, projections, and UI dashboard

---

### 22. Index Health Monitoring

Track document quality, embedding clusters, and search relevance:

```dart
class IndexHealthMonitor {
  Future<HealthReport> generateReport() async {
    return HealthReport(
      totalDocuments: await _countDocuments(),
      averageEmbeddingLength: await _calculateAvgEmbeddingLength(),
      orphanedFiles: await _findOrphanedFiles(),
      staleIndexEntries: await _findStaleEntries(),
      duplicateContent: await _findDuplicateContent(),
      clusterQuality: await _evaluateClusterQuality(),
      searchRelevance: await _evaluateSearchRelevance(),
    );
  }

  Future<List<String>> _findOrphanedFiles() async {
    // Find indexed files that no longer exist on disk
    return await database.query('''
      SELECT file_path
      FROM documents
      WHERE file_path NOT IN (SELECT path FROM file_system_scan)
    ''');
  }

  Future<double> _evaluateSearchRelevance() async {
    // Use test queries and measure click-through rate
    final testQueries = await _getTestQueries();
    var totalClicks = 0;
    var totalResults = 0;

    for (final query in testQueries) {
      final results = await semanticSearch(query.query);
      totalResults += results.length;
      totalClicks += query.clickedResults.intersection(results.toSet()).length;
    }

    return totalResults > 0 ? totalClicks / totalResults : 0.0;
  }
}
```

**Benefits**:
- Detect and fix index quality issues
- Proactively identify problems before users notice
- Optimize indexing parameters based on data
- Track improvements over time

**Complexity**: Medium - Requires metrics collection

---

### 23. Performance Profiling

Monitor search latency, indexing speed, and API response times:

```dart
class PerformanceProfiler {
  Future<T> profile<T>(String operation, Future<T> Function() fn) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await fn();
    } finally {
      stopwatch.stop();
      _recordTiming(operation, stopwatch.elapsed);
    }
  }

  PerformanceReport getReport() {
    return PerformanceReport(
      operations: _timings.map((op, timings) => OperationMetrics(
        name: op,
        count: timings.length,
        average: _average(timings),
        min: timings.reduce(min),
        max: timings.reduce(max),
        p95: _percentile(timings, 0.95),
        p99: _percentile(timings, 0.99),
      )).toList()..sort((a, b) => b.average.compareTo(a.average)),
    );
  }
}
```

**Benefits**:
- Identify performance bottlenecks
- Track SLA compliance
- Optimize based on real usage data

**Complexity**: Low - Simple timing instrumentation

---

### 24. Caching Layer ✅ **IMPLEMENTED**

Cache frequent search queries and embeddings:

```dart
class QueryCache {
  final Map<String, CachedResult> _cache = {};

  Future<SearchResult?> get(String query) async {
    final cached = _cache[query];
    if (cached == null) return null;

    if (DateTime.now().difference(cached.timestamp) > Duration(hours: 1)) {
      _cache.remove(query);
      return null;
    }

    return cached.result;
  }

  Future<void> set(String query, SearchResult result) async {
    if (_cache.length >= _maxSize) {
      _evictOldest();
    }

    _cache[query] = CachedResult(
      result: result,
      timestamp: DateTime.now(),
    );
  }

  void _evictOldest() {
    final oldest = _cache.entries
      .reduce((a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b);
    _cache.remove(oldest.key);
  }
}
```

**Benefits**:
- Faster response times for repeated queries
- Reduced API costs for common searches
- Better user experience for power users
- Lower server load during peak usage

**Complexity**: Low - Simple in-memory cache

**Status**: ✅ Implemented with `CacheService` providing LRU caching with TTL for embeddings, summaries, and tags; includes hit/miss statistics

---

### 25. Background Job Queue ✅ **IMPLEMENTED**

Separate indexing from search for better responsiveness:

```dart
class JobQueue {
  final List<Job> _queue = [];
  bool _isProcessing = false;

  Future<void> enqueue(Job job) async {
    _queue.add(job);
    _queue.sort((a, b) => b.priority.compareTo(a.priority));
    if (!_isProcessing) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final job = _queue.removeAt(0);
      try {
        await job.execute();
        await database.updateJobStatus(job.id, 'completed');
      } catch (e) {
        await database.updateJobStatus(job.id, 'failed', error: e.toString());
      }
    }

    _isProcessing = false;
  }
}

class IndexingJob implements Job {
  final String filePath;
  final int priority;

  Future<void> execute() async {
    await indexer.indexFile(filePath);
  }
}
```

**Benefits**:
- Search remains fast during indexing
- Users can continue working while files are processed
- Better resource utilization
- Ability to pause/resume indexing

**Complexity**: Medium - Requires job management

**Status**: ✅ Implemented with `IndexingJob` database model tracking job status, file counts, timestamps, and error handling; includes `IndexingStatus` and `IndexingProgress` models

---

### 26. Plugin System

Extensible architecture for custom file processors and AI models:

```dart
class PluginManager {
  final List<FileProcessorPlugin> _processors = [];
  final List<SearchPlugin> _searchPlugins = [];

  Future<void> loadPlugin(Plugin plugin) async {
    await plugin.initialize();

    if (plugin is FileProcessorPlugin) {
      _processors.add(plugin);
    }
    if (plugin is SearchPlugin) {
      _searchPlugins.add(plugin);
    }
  }

  Future<String?> processFile(String filePath) async {
    for (final processor in _processors) {
      if (await processor.canProcess(filePath)) {
        return await processor.process(filePath);
      }
    }
    return null;
  }
}

abstract class Plugin {
  Future<void> initialize();
  String get name;
  String get version;
}

abstract class FileProcessorPlugin extends Plugin {
  Future<bool> canProcess(String filePath);
  Future<String> process(String filePath);
}

class PDFProcessorPlugin extends FileProcessorPlugin {
  @override
  Future<bool> canProcess(String filePath) async {
    return filePath.endsWith('.pdf');
  }

  @override
  Future<String> process(String filePath) async {
    final pdf = await PdfFile.open(filePath);
    return pdf.pages.map((page) => page.text).join('\n');
  }
}
```

**Benefits**:
- Community can contribute custom processors
- Easy to add new file format support
- Experiment with different AI models
- Extensible without modifying core code

**Complexity**: High - Requires plugin architecture

---

### 27. Desktop Tray Integration

Quick search from system tray icon:

```dart
class TrayIconManager {
  late TrayIcon _tray;

  Future<void> initialize() async {
    _tray = TrayIcon(
      icon: _loadIcon(),
      tooltip: 'Semantic Butler',
      onTrayIconMouseDown: () => _showQuickSearch(),
      menu: Menu(items: [
        MenuItem(label: 'Quick Search', onClick: _showQuickSearch),
        MenuItem(label: 'Index Folder', onClick: _showIndexDialog),
        MenuItem.separator(),
        MenuItem(label: 'Settings', onClick: _showSettings),
        MenuItem(label: 'Exit', onClick: _exit),
      ]),
    );
  }

  void _showQuickSearch() {
    final window = QuickSearchWindow();
    window.show();
    window.focusSearchBox();
  }
}
```

**Benefits**:
- Instant access to search from anywhere
- Doesn't disrupt current workflow
- Keyboard shortcuts for power users
- Can run in background

**Complexity**: Medium-High - Platform-specific native integration

---

### 28. File Explorer Integration

Context menu for "Search with Semantic Butler" and "AI Organize":

```dart
class ContextMenuIntegration {
  Future<void> register() async {
    if (Platform.isWindows) {
      await _registerWindowsContextMenu();
    } else if (Platform.isMacOS) {
      await _registerMacOSContextMenu();
    } else {
      await _registerLinuxContextMenu();
    }
  }

  Future<void> _registerWindowsContextMenu() async {
    final registryKey = 'HKEY_CLASSES_ROOT\\*\\shell\\Semantic Butler';

    await Process.run('reg', [
      'add',
      registryKey,
      '/v',
      'Icon',
      '/t',
      'REG_SZ',
      '/d',
      appIconPath,
    ]);

    await Process.run('reg', [
      'add',
      '$registryKey\\command',
      '/v',
      '',
      '/t',
      'REG_SZ',
      '/d',
      '"$appExe" search "%1"',
    ]);
  }
}
```

**Benefits**:
- Seamless integration with OS file manager
- Right-click to search or organize files
- Works with folder selections
- Natural workflow for users

**Complexity**: High - Platform-specific shell integration

---

## Priority Recommendations

### High Priority (Safety & Reliability)
1. ~~**Undo Functionality**~~ ✅ - Critical for AI agent operations - **COMPLETED**
2. ~~**Dry-Run Mode**~~ ✅ - Essential for user confidence - **COMPLETED**
3. ~~**Atomic Operations & Rollback**~~ ✅ - Prevents partial states - **COMPLETED**
4. ~~**Better Error Classification**~~ ✅ - Improves error handling - **COMPLETED**

### Medium Priority (User Experience)
5. **Progress Tracking** - Better UX for large operations
6. ~~**Cross-Platform Trash/Recycle Bin**~~ ⚠️ - Safer deletion - **PARTIAL** (Windows only)
7. ~~**Bulk Operations API**~~ ✅ - More efficient workflows - **COMPLETED**
8. **Metadata Preservation** - Maintains file attributes
9. ~~**Real-time Document Preview**~~ ✅ - Faster relevance verification - **COMPLETED**
10. ~~**Incremental Indexing**~~ ✅ - Dramatically faster updates - **COMPLETED**

### Low Priority (Nice to Have)
11. **Symbolic Link Handling** - Better dev workflow support
12. ~~**Enhanced Path Validation**~~ ✅ - Better permission checks - **COMPLETED**
13. ~~**Monitoring & Metrics**~~ ✅ - Performance insights - **COMPLETED**
14. ~~**Smart Path Handling**~~ ✅ - Cross-platform consistency - **COMPLETED**
15. ~~**Tag Management System**~~ ⚠️ - Partially implemented - Has recording, search, autocomplete; missing merge/hierarchy
16. ~~**Search History**~~ ⚠️ - Partially implemented - Auto-save exists; missing categorization/saved presets
17. **Hybrid Search** - Combines semantic + keyword
18. ~~**AI Cost Dashboard**~~ ⚠️ - Partially implemented - Basic tracking exists; missing dashboard features
19. ~~**Context-aware Agent**~~ ⚠️ - Partially implemented - Basic history exists; missing persistence/learning
20. ~~**Caching Layer**~~ ✅ - Faster repeated queries - **COMPLETED**
21. ~~**Background Job Queue**~~ ✅ - Non-blocking indexing - **COMPLETED**

### Future / Experimental
22. **Smart Organization Suggestions** - Proactive improvements
23. **Index Health Monitoring** - Quality metrics
24. **Performance Profiling** - Detailed analytics
25. **Plugin System** - Extensible architecture
26. **Desktop Tray Integration** - Global hotkeys
27. **File Explorer Integration** - Right-click actions
28. **Hierarchical Summarization** - Token-efficient indexing

## Implementation Status Summary

**Fully Implemented (11/28):**
- ✅ Undo Functionality
- ✅ Dry-Run Mode
- ✅ Atomic Operations & Rollback
- ✅ Better Error Classification
- ✅ Bulk Operations API
- ✅ Enhanced Path Validation
- ✅ Monitoring & Metrics
- ✅ Smart Path Handling
- ✅ Real-time Document Preview
- ✅ Caching Layer
- ✅ Background Job Queue
- ✅ Incremental Indexing

**Partially Implemented (4/28):**
- ⚠️ Cross-Platform Trash/Recycle Bin (Windows complete, macOS/Linux fallback)
- ⚠️ Tag Management System (recording, search, autocomplete, stats exist; missing merge, hierarchy, manual editing)
- ⚠️ Search History & Saved Queries (auto-save exists; missing categorization, saved presets, named queries)
- ⚠️ AI Cost Dashboard (basic tracking exists; missing per-feature breakdown, budgets, alerts, projections)
- ⚠️ Context-aware Agent (conversation history with 20 message limit exists; missing persistent storage, preference learning, pattern detection)

**Not Yet Implemented (13/28):**
- Progress Tracking for Large Files
- Metadata Preservation
- Symbolic Link Handling
- Hybrid Search (semantic + keyword combination)
- Smart File Organization Suggestions
- Index Health Monitoring
- Performance Profiling (beyond basic metrics)
- Plugin System
- Desktop Tray Integration
- File Explorer Integration
- Hierarchical Summarization

**Completion: 54% (11 fully implemented, 4 partially implemented out of 28)**

## Implementation Notes

### Dependencies to Consider
- For trash operations:
  - Windows: `ffi` or `win32` packages
  - macOS: Process with `osascript`
  - Linux: Check for `gio` availability
- For metadata: Dart's `FileStat` already provides most needed info

### Testing Strategy
- Add unit tests for each new feature
- Test cross-platform behavior on all supported OSes
- Test edge cases: large files, permissions, network paths
- Test rollback scenarios extensively

### Migration Strategy
- Maintain backward compatibility with existing API
- Add new features as optional parameters
- Deprecate old methods gradually
- Update documentation and examples

## Related Files
- `semantic_butler_server/lib/src/services/file_operations_service.dart`
- `semantic_butler_server/lib/src/endpoints/agent_endpoint.dart`
- `semantic_butler_server/lib/src/endpoints/butler_endpoint.dart`
- `semantic_butler_server/lib/src/services/terminal_service.dart`
- `semantic_butler_server/lib/src/services/ai_service.dart`
- `semantic_butler_server/lib/src/services/cache_service.dart`
- `semantic_butler_server/lib/src/services/metrics_service.dart`
- `semantic_butler_server/lib/src/services/tag_taxonomy_service.dart`
- `semantic_butler_server/lib/src/services/file_watcher_service.dart`
- `semantic_butler_server/lib/src/services/file_extraction_service.dart`
- `semantic_butler_server/lib/src/generated/file_operation_result.dart`
- `semantic_butler_server/lib/src/generated/agent_file_command.dart`
