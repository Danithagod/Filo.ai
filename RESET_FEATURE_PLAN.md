# Database Reset Feature Plan

## Overview

The reset feature provides a comprehensive way to reset all application data stored in the database. Based on inspection, the application uses **Serverpod** with **PostgreSQL** (pgvector) and has **13 application tables** plus **11 Serverpod internal tables**.

---

## Database Tables Summary

### Application Tables (13)

| Table | Purpose | Records to Delete |
|-------|---------|-------------------|
| `document_embedding` | Vector embeddings for semantic search | All |
| `file_index` | Main document index with metadata | All |
| `indexing_job` | Indexing batch jobs tracking | All |
| `indexing_job_detail` | Per-file progress within jobs | All |
| `watched_folders` | Folders monitored for auto-reindexing | All |
| `search_history` | User search queries | All |
| `tag_taxonomy` | Normalized tag storage | All |
| `ignore_patterns` | Patterns to exclude from indexing | Optional |
| `agent_file_command` | File operation audit log | All |
| `error_stats` | Error tracking statistics | All |
| `error_category_count` | Error counts by category | All |
| `health_check` | Health check records | All |
| `database_stats` | Database statistics | All |

### Serverpod Internal Tables (11)

- `serverpod_cloud_storage`, `serverpod_future_call`
- `serverpod_health_connection_info`, `serverpod_health_metric`
- `serverpod_log`, `serverpod_message_log`
- `serverpod_method`, `serverpod_migrations`
- `serverpod_query_log`, `serverpod_session_log`

---

## Feature Requirements

### 1. Reset Service

Create a new service in `lib/src/services/` that handles all reset operations:

**File:** `semantic_butler_server/lib/src/services/reset_service.dart`

```dart
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class ResetService {
  /// Reset options
  enum ResetScope {
    dataOnly,      // Delete all application data
    full,          // Drop and recreate schema
    soft,          // Clear but keep configuration
  }

  /// Reset the database
  static Future<ResetResult> resetDatabase(
    Session session, {
    required ResetScope scope,
    bool dryRun = false,
    bool requireConfirmation = true,
  });

  /// Get reset preview (what will be deleted)
  static Future<ResetPreview> getPreview(Session session);
}
```

### 2. Reset Endpoint

Add a new endpoint for API access:

**File:** `semantic_butler_server/lib/src/endpoints/reset_endpoint.dart`

```dart
class ResetEndpoint extends Endpoint {
  /// Preview reset (what will be deleted)
  Future<ResetPreview> previewReset(Session session);

  /// Execute reset with confirmation
  Future<ResetResult> executeReset(
    Session session, {
    required ResetScope scope,
    required String confirmationCode,
  });

  /// Get database statistics before reset
  Future<Map<String, int>> getDatabaseStats(Session session);
}
```

### 3. CLI Command (optional)

Add a CLI command for server management:

```bash
# Preview what will be reset
dart bin/main.dart --reset-preview

# Execute reset (requires confirmation)
dart bin/main.dart --reset --scope=data

# Force reset without confirmation
dart bin/main.dart --reset --scope=data --force
```

### 4. Docker Volume Reset

For Docker-based deployments:

```bash
# Stop services
docker compose down

# Remove volumes
docker volume rm semantic_butler_semantic_butler_data
docker volume rm semantic_butler_semantic_butler_test_data

# Restart (will apply migrations)
docker compose up --build
```

---

## Implementation Details

### Phase 1: Create Reset Service

**File:** `semantic_butler_server/lib/src/services/reset_service.dart`

```dart
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class ResetService {
  static const List<String> applicationTables = [
    'document_embedding',
    'file_index',
    'indexing_job',
    'indexing_job_detail',
    'watched_folders',
    'search_history',
    'tag_taxonomy',
    'ignore_pattern',
    'agent_file_command',
    'error_stats',
    'error_category_count',
    'health_check',
    'database_stats',
  ];

  static Future<ResetPreview> getPreview(Session session) async {
    final stats = <String, int>{};
    for (final table in applicationTables) {
      final count = await _getTableRowCount(session, table);
      stats[table] = count;
    }
    return ResetPreview(
      tables: stats,
      totalRows: stats.values.fold(0, (a, b) => a + b),
      estimatedTime: _estimateResetTime(stats.values.fold(0, (a, b) => a + b)),
    );
  }

  static Future<ResetResult> resetDatabase(
    Session session, {
    required ResetScope scope,
    bool dryRun = false,
  }) async {
    final startTime = DateTime.now();
    final affectedRows = <String, int>{};

    // Phase 1: Clear data tables (in correct order for foreign keys)
    final deleteOrder = [
      'document_embedding',      // References file_index
      'indexing_job_detail',     // References indexing_job
      'indexing_job',
      'file_index',
      'watched_folders',
      'search_history',
      'tag_taxonomy',
      'ignore_pattern',
      'agent_file_command',
      'error_stats',
      'error_category_count',
      'health_check',
      'database_stats',
    ];

    for (final table in deleteOrder) {
      final count = await _truncateTable(session, table, dryRun: dryRun);
      affectedRows[table] = count;
    }

    // Phase 2: Reset in-memory services
    _resetInMemoryServices();

    return ResetResult(
      success: true,
      affectedRows: affectedRows,
      duration: DateTime.now().difference(startTime),
      scope: scope.name,
    );
  }

  static void _resetInMemoryServices() {
    // Reset metrics
    MetricsService.instance.reset();

    // Reset circuit breakers
    CircuitBreakerRegistry.instance.resetAll();

    // Reset AI service usage stats
    // AIService.resetUsageStats();
  }
}
```

### Phase 2: Add Endpoint Methods

**File:** `semantic_butler_server/lib/src/endpoints/butler_endpoint.dart`

Add new methods to the existing `ButlerEndpoint`:

```dart
/// Get current database statistics
Future<Map<String, dynamic>> getDatabaseStats(Session session) async {
  final preview = await ResetService.getPreview(session);
  return {
    'totalRows': preview.totalRows,
    'tables': preview.tables,
    'scope': 'application_data',
  };
}

/// Preview reset - shows what will be deleted
Future<ResetPreview> previewReset(Session session) async {
  return ResetService.getPreview(session);
}

/// Execute database reset
Future<ResetResult> resetDatabase(
  Session session, {
  required String scope,
  required String confirmationCode,
}) async {
  // Validate confirmation code (e.g., "RESET-MyApp-2024")
  if (!_validateConfirmationCode(confirmationCode)) {
    throw Exception('Invalid confirmation code');
  }

  final resetScope = ResetScope.values.firstWhere(
    (s) => s.name == scope,
    orElse: () => ResetScope.dataOnly,
  );

  return await ResetService.resetDatabase(session, scope: resetScope);
}
```

### Phase 3: Create Response Models

**File:** `semantic_butler_server/lib/src/models/reset_preview.spy.yaml`

```yaml
class: ResetPreview
table: reset_preview
fields:
  tables: Map<String, int>
  totalRows: int
  estimatedTime: String
```

**File:** `semantic_butler_server/lib/src/models/reset_result.spy.yaml`

```yaml
class: ResetResult
table: reset_result
fields:
  success: bool
  affectedRows: Map<String, int>
  duration: int  # milliseconds
  scope: String
  errorMessage: String?
```

### Phase 4: Update Generated Code

After creating model files, run:

```bash
cd semantic_butler_server
dart pub global activate serverpod_cli 3.1.0
serverpod generate
```

---

## Safety Features

### 1. Confirmation Code System

- Generate time-limited confirmation codes
- Require user to type "RESET-DESK-SENSE-{TIMESTAMP}"
- Code expires after 5 minutes

### 2. Dry Run Mode

- Preview what will be deleted without executing
- Shows table counts and estimated time

### 3. Transaction Safety

- Wrap all deletions in transaction
- Rollback on any error

### 4. Audit Logging

- Log reset operations to `agent_file_command` table
- Record who initiated reset (if authenticated)

### 5. Rate Limiting

- Limit reset calls to once per hour
- Require admin authentication

---

## API Contract

### Preview Reset

```
GET /reset/preview

Response:
{
  "tables": {
    "file_index": 1250,
    "document_embedding": 3400,
    "indexing_job": 45,
    ...
  },
  "totalRows": 5800,
  "estimatedTime": "2-5 seconds"
}
```

### Execute Reset

```
POST /reset/execute

Body:
{
  "scope": "data_only",  // or "full"
  "confirmationCode": "RESET-DESK-SENSE-20260118"
}

Response:
{
  "success": true,
  "affectedRows": {
    "file_index": 1250,
    "document_embedding": 3400,
    ...
  },
  "durationMs": 3200
}
```

---

## Docker/Production Reset

For production deployments with Docker:

```bash
# 1. Full database reset (drop volumes)
docker compose down -v
docker compose up -d

# 2. Reset with migrations
docker compose exec server dart bin/main.dart --apply-migrations

# 3. Verify reset
docker compose exec server dart bin/main.dart --health
```

---

## Testing

### 1. Unit Tests

**File:** `test/unit/reset_service_test.dart`

- Test preview returns correct counts
- Test reset deletes all data
- Test dry run doesn't delete anything
- Test confirmation code validation

### 2. Integration Tests

**File:** `test/integration/reset_test.dart`

- Test full reset workflow
- Test error handling during reset
- Test concurrent reset attempts

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `lib/src/services/reset_service.dart` | Create |
| `lib/src/models/reset_preview.spy.yaml` | Create |
| `lib/src/models/reset_result.spy.yaml` | Create |
| `lib/src/endpoints/reset_endpoint.dart` | Create (or add to butler_endpoint.dart) |
| `lib/src/endpoints/butler_endpoint.dart` | Modify - add reset methods |
| `test/unit/reset_service_test.dart` | Create |
| `test/integration/reset_test.dart` | Create |

---

## Estimated Effort

| Task | Hours |
|------|-------|
| Development | 4-6 |
| Testing | 2-3 |
| Documentation | 1 |
| **Total** | **7-10** |

---

## Next Steps

1. Approve this plan
2. Create `lib/src/services/reset_service.dart`
3. Create model files for reset responses
4. Add endpoint methods
5. Generate Serverpod code
6. Write unit tests
7. Write integration tests

---

## Existing Code Reference

The codebase already has a `clearIndex` method in `ButlerEndpoint` (line 1285) that provides partial reset functionality:

```dart
/// Clear all indexed data
Future<void> clearIndex(Session session) async {
  await DocumentEmbedding.db.deleteWhere(session, where: (t) => t.id > 0);
  await FileIndex.db.deleteWhere(session, where: (t) => t.id > 0);
  await IndexingJob.db.deleteWhere(session, where: (t) => t.id > 0);
}
```

This resets the core index but does not clear:
- `indexing_job_detail`
- `watched_folders`
- `search_history`
- `tag_taxonomy`
- `ignore_pattern`
- `agent_file_command`
- Error statistics
- Health checks

The new reset feature should extend this to cover all application tables and provide better safety features.
