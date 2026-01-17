# Auto Indexing Feature Analysis - Gaps & Issues

## Critical Issues

### 1. File Removal Not Implemented
- **Location**: `file_watcher_service.dart:194-201`
- **Issue**: `_handleFileRemoved` only logs removal but doesn't call `removeFromIndex()` or delete from database
- **Impact**: Orphaned embeddings accumulate, database bloats, search returns deleted files
- **Recommendation**: Add database cleanup in `_handleFileRemoved()` to delete FileIndex and associated DocumentEmbedding records

### 2. No pgvector Column in Schema
- **Location**: `migrations/20260116084846600/definition.sql:26-33`
- **Issue**: `document_embedding` table lacks `embedding vector(768)` column
- **Impact**: Vector search falls back to slow Dart-based computation (line 259-295 in butler_endpoint.dart)
- **Recommendation**: Create migration to add vector column and populate from embeddingJson

### 3. Migration Failed
- **Location**: `migrations/20250116_add_vector_index/migration.sql`
- **Issue**: Migration registered in registry but never applied properly (path/permission issues)
- **Impact**: No IVFFlat index exists - O(n) full table scans for every search
- **Recommendation**: Verify migration application, re-run if needed, ensure pgvector extension is installed

### 4. Race Conditions
- **Location**: `butler_endpoint.dart:1009-1016`
- **Issue**: Multiple watcher callbacks can trigger concurrent re-indexing of same files
- **Impact**: Duplicate embeddings, wasted API calls, potential data corruption, contentHash validation bypass
- **Recommendation**: Add mutex/lock around re-indexing to prevent concurrent processing of same file paths

### 5. Ignore Patterns Not Applied to Auto-Index
- **Location**: `file_watcher_service.dart:118-140`, `butler_endpoint.dart:1009-1016`
- **Issue**: File watcher doesn't respect ignore patterns, re-indexes ignored files on change
- **Impact**: Unnecessary processing of .git/, node_modules/, etc., wasted API costs
- **Recommendation**: Fetch and apply ignore patterns in `_handleEvent()` before queuing for re-indexing

## High-Priority Issues

### 6. Memory Leak Risk
- **Location**: `file_watcher_service.dart:143-157`
- **Issue**: `_pendingFiles` set grows unbounded if `onFilesChanged` callback fails
- **Impact**: Server crash under high file change rates, memory exhaustion
- **Recommendation**: Add queue size limits (e.g., 10,000 items) and backpressure handling, implement LRU eviction

### 7. No Retry/Recovery for Failed Re-indexing
- **Location**: `butler_endpoint.dart:1009-1016`
- **Issue**: If re-indexing fails, files are never retried; error only logged
- **Impact**: Stale embeddings for modified files, no recovery mechanism
- **Recommendation**: Implement exponential backoff retry for failed re-index operations, track failed re-index attempts in database

### 8. Session Leaks
- **Location**: `butler_endpoint.dart:56-89`
- **Issue**: Watchers only cleaned up after 30min idle time via cleanupIdleWatchers()
- **Impact**: Resources not released when clients disconnect properly, memory leaks from unused watchers
- **Recommendation**: Add session disconnect handler for immediate cleanup, register hook with Serverpod lifecycle

### 9. No Transactional Updates
- **Location**: `butler_endpoint.dart:626-705`
- **Issue**: FileIndex and embeddings updated in separate operations without transaction
- **Impact**: Inconsistent state on partial failures, orphaned embeddings, missing FileIndex records
- **Recommendation**: Wrap FileIndex + embedding updates in database transaction using session.db.transaction()

### 10. Cache Coherency Issue
- **Location**: `cache_service.dart:100-103`, `cached_ai_service.dart:41-125`
- **Issue**: Cache uses `text.hashCode` for embeddings but `contentHash` for summaries/tags; hash collisions possible
- **Impact**: Wrong cache hits for different content, incorrect embeddings returned
- **Recommendation**: Use SHA-256 hash consistently for all cache keys, not Dart's hashCode

## Medium-Priority Issues

### 11. No Duplicate Detection in Queue
- **Location**: `file_watcher_service.dart:143-157`
- **Issue**: Same file can be added to queue multiple times rapidly before debounce fires
- **Impact**: Unnecessary API calls, processing overhead, potential duplicate embeddings
- **Recommendation**: Check `_pendingFiles` before adding, use Set more effectively, add per-file lock

### 12. Silent pgvector Failures
- **Location**: `butler_endpoint.dart:694-705`
- **Issue**: Vector column update errors silently swallowed (empty catch block)
- **Impact**: No indication that vector search is degraded, performance issues not detected
- **Recommendation**: Log pgvector failures once per session, surface in health metrics, add monitoring

### 13. Single Chunk Only
- **Location**: `butler_endpoint.dart:681-690`
- **Issue**: Only one embedding per file (chunkIndex=0 always used)
- **Impact**: Long documents can't be properly indexed for relevant content sections, poor search relevance
- **Recommendation**: Implement chunking for documents > 1000 words with multiple embeddings, incremental chunkIndex

### 14. No File Move Detection
- **Location**: `file_watcher_service.dart:118-140`, `butler_endpoint.dart:534-538`
- **Issue**: Moved files detected as REMOVE + ADD, creating duplicate embeddings despite contentHash check
- **Impact**: Database bloat, duplicate search results, wasted storage
- **Recommendation**: Detect moves by matching contentHash, update path instead of delete+insert, implement short delay before processing REMOVE events

### 15. No Resource Limits
- **Location**: `butler_endpoint.dart:450-477`
- **Issue**: Batch size fixed at 25, no CPU/memory-based throttling
- **Impact**: Server overload under high load, no dynamic scaling
- **Recommendation**: Implement dynamic batch sizing based on available resources, add circuit breaker for indexing

### 16. No Server Shutdown Hook
- **Location**: `server.dart:69`, `butler_endpoint.dart:44-53`
- **Issue**: `ButlerEndpoint.disposeAll()` called but never triggered by server shutdown
- **Impact**: File watchers not stopped cleanly, resources leaked on restart, database connections not closed
- **Recommendation**: Register shutdown hook with Serverpod's lifecycle, call `disposeAllWatchers()` in `server.dart`

### 17. Watcher Health Not Monitored
- **Location**: `file_watcher_service.dart:49-54`, `51-53`
- **Issue**: Watcher stream errors only logged, no reconnection or health check
- **Impact**: Silent failures, files not re-indexed after watcher dies, no alerting
- **Recommendation**: Add periodic health checks, auto-restart failed watchers, implement ping mechanism

### 18. No Rate Limiting on Auto-Index API Calls
- **Location**: `butler_endpoint.dart:1009-1016`, `rate_limit_service.dart`
- **Issue**: Auto-index re-indexing bypasses rate limiter (only applied to startIndexing at line 348-354)
- **Impact**: API rate limits exceeded during bulk file operations, billing spikes
- **Recommendation**: Apply same rate limiting to re-indexing, add separate quota for auto-index operations

## Low-Priority Issues

### 19. Inconsistent Hash Function Usage
- **Location**: `cache_service.dart:102`, `file_extraction_service.dart:297-302`
- **Issue**: Cache uses `text.hashCode` (32-bit, not cryptographically secure) while file extraction uses SHA-256
- **Impact**: Hash collisions in cache, incorrect data returned
- **Recommendation**: Use SHA-256 consistently throughout for cache keys

### 20. No Max File Size Validation
- **Location**: `file_watcher_service.dart:118-140`, `file_extraction_service.dart:368-395`
- **Issue**: No size limit check before attempting to index large files
- **Impact**: Memory exhaustion, slow processing, OOM crashes on large files
- **Recommendation**: Add configurable max file size (e.g., 50MB), skip files exceeding limit

### 21. Debounce Timer Memory Leak
- **Location**: `file_watcher_service.dart:143-157`
- **Issue**: Debounce timers stored in Map but never cleaned if parent directory stops being watched
- **Impact**: Timer objects accumulate in memory
- **Recommendation**: Clear timers for parent directories when stopping watchers

### 22. No Progress Tracking for Auto-Index
- **Location**: `butler_endpoint.dart:1009-1016`
- **Issue**: Auto-index operations don't create IndexingJob records or emit progress events
- **Impact**: Users can't see auto-indexing status, no way to monitor progress
- **Recommendation**: Create transient job records for auto-index batches, expose through status endpoint

### 23. Path Case Sensitivity on Windows
- **Location**: Multiple locations using `path.equals()` (file_watcher_service.dart:36, butler_endpoint.dart:524)
- **Issue**: Windows case-insensitivity not handled (file moved/reindexed when only case changes)
- **Impact**: Unnecessary re-indexing on Windows, database duplicates
- **Recommendation**: Normalize paths for comparison based on OS, use case-insensitive comparison on Windows

### 24. No Cleanup of Failed Jobs
- **Location**: `butler_endpoint.dart:794-804`, migrations
- **Issue**: IndexingJob records for failed jobs persist forever, no cleanup mechanism
- **Impact**: Database bloat, stale job data
- **Recommendation**: Add background cleanup job to archive/delete jobs older than 30 days

### 25. No Throttling for Concurrent Batches
- **Location**: `butler_endpoint.dart:450-477`
- **Issue**: Multiple concurrent auto-index batches can run simultaneously (unawaited calls)
- **Impact**: System overload, resource contention
- **Recommendation**: Limit concurrent indexing batches to 1-2, implement queue for additional batches

### 26. Circuit Breaker Not Applied to Auto-Index
- **Location**: `cached_ai_service.dart:41-72`, `butler_endpoint.dart:1009-1016`
- **Issue**: Auto-indexing calls cached_ai_service but circuit breaker may not prevent cascading failures
- **Impact**: AI API failures can cause rapid depletion of rate limits
- **Recommendation**: Ensure circuit breaker wraps all auto-index AI calls, add fallback behavior

## Implementation Priority Matrix

| Priority | Issue | Effort | Impact |
|----------|-------|--------|--------|
| P0 | File Removal | Low | Critical |
| P0 | pgvector Column | Medium | Critical |
| P0 | Migration Fix | Low | Critical |
| P0 | Race Conditions | Medium | Critical |
| P0 | Ignore Patterns | Low | High |
| P1 | Memory Leak | Low | High |
| P1 | Retry Mechanism | Medium | High |
| P1 | Session Leaks | Medium | High |
| P1 | Transactions | Low | High |
| P1 | Cache Coherency | Low | High |
| P2 | Duplicate Detection | Low | Medium |
| P2 | Silent Failures | Low | Medium |
| P2 | Chunking | High | Medium |
| P2 | Move Detection | Medium | Medium |
| P2 | Resource Limits | Medium | Medium |
| P2 | Shutdown Hook | Low | Medium |
| P2 | Watcher Health | Medium | Medium |
| P2 | Auto-Index Rate Limit | Low | Medium |
| P3 | Hash Function | Low | Low |
| P3 | Max File Size | Low | Low |
| P3 | Debounce Timer Leak | Low | Low |
| P3 | Auto-Index Progress | High | Low |
| P3 | Path Case Sensitivity | Low | Low |
| P3 | Failed Job Cleanup | Low | Low |
| P3 | Concurrent Batch Throttling | Medium | Low |
| P3 | Circuit Breaker Auto-Index | Low | Low |

## Summary Statistics

- **Total Issues Identified**: 26
- **Critical (P0)**: 5
- **High (P1)**: 5
- **Medium (P2)**: 6
- **Low (P3)**: 10

## Recommended Action Plan

### Phase 1 - Critical Fixes (Week 1)
1. Implement file removal in `_handleFileRemoved()`
2. Add pgvector column migration and populate from embeddingJson
3. Verify and re-run vector index migration
4. Add mutex/lock for concurrent re-indexing
5. Apply ignore patterns to file watcher

### Phase 2 - High Priority (Week 2)
6. Add queue size limits and LRU eviction
7. Implement retry mechanism with exponential backoff
8. Add session disconnect handlers
9. Wrap updates in database transactions
10. Fix cache key hashing (use SHA-256 consistently)

### Phase 3 - Medium Priority (Week 3-4)
11-17. Address duplicate detection, monitoring, chunking, move detection, resource limits, shutdown hook, watcher health, and rate limiting

### Phase 4 - Low Priority (Ongoing)
18-26. Implement remaining quality-of-life improvements and cleanup mechanisms
