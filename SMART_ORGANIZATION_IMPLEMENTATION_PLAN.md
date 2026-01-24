# Smart Organization Feature - Implementation Plan & Status

## Overview
The Smart Organization feature analyzes files and identifies three types of organizational issues:
1. **Duplicate files** - Exact duplicates based on content hash
2. **Naming convention issues** - Inconsistent naming patterns
3. **Semantically similar content** - Files with similar meaning but different content

**Current State**: Feature can **detect** problems but **cannot fix** them (read-only).

---

## ✅ Completed Work

### 1. Backend Models Created (YAML Definitions)
**Location**: `semantic_butler_server/lib/src/models/`

| File | Purpose | Status |
|------|---------|--------|
| `organization_action_request.spy.yaml` | Request model for organization actions | ✅ Created |
| `organization_action_result.spy.yaml` | Result model for single actions | ✅ Created |
| `batch_organization_request.spy.yaml` | Request for multiple actions | ✅ Created |
| `batch_organization_result.spy.yaml` | Result for batch operations | ✅ Created |

**Fields Defined**:
- `OrganizationActionRequest`: actionType, contentHash, keepFilePath, deleteFilePaths, renameOldPaths, renameNewNames, organizeFilePaths, targetFolder, dryRun
- `OrganizationActionResult`: success, actionType, filesProcessed, successCount, failureCount, spaceSavedBytes, results, error, isDryRun
- `BatchOrganizationRequest`: actions (list of OrganizationActionRequest), rollbackOnError, dryRun
- `BatchOrganizationResult`: success, totalActions, successCount, failureCount, results, error, wasRolledBack

### 2. Backend Service Created
**Location**: `semantic_butler_server/lib/src/services/organization_service.dart`

| Method | Purpose | Status |
|--------|---------|--------|
| `applyAction()` | Apply a single organization action | ✅ Implemented |
| `_resolveDuplicates()` | Delete duplicate files, keep one | ✅ Implemented |
| `_fixNaming()` | Rename files with proper naming | ✅ Implemented |
| `_organizeSimilar()` | Move similar files to target folder | ✅ Implemented |
| `applyBatch()` | Execute multiple actions with rollback | ✅ Implemented |
| `_rollbackAction()` | Undo completed actions on failure | ✅ Implemented |

**Features**:
- Dry-run mode (preview without executing)
- Uses `FileOperationsService` for actual file operations
- Transaction/rollback support for batch operations
- Detailed logging and error handling

### 3. Backend Endpoint Methods Added
**Location**: `semantic_butler_server/lib/src/endpoints/butler_endpoint.dart`

| Method | Purpose | Status |
|--------|---------|--------|
| `applyOrganizationAction()` | Generic action endpoint | ✅ Added |
| `applyBatchOrganization()` | Batch action endpoint | ✅ Added |
| `resolveDuplicates()` | Convenience method for duplicates | ✅ Added |
| `fixNamingIssues()` | Convenience method for naming | ✅ Added |
| `organizeSimilarFiles()` | Convenience method for similar files | ✅ Added |

**Security**: All methods include `AuthService.requireAuth(session)`

---

## ❌ Remaining Work

### 1. CRITICAL: Protocol Generation Issue
**Problem**: The YAML model files are not being converted to Dart classes by `serverpod generate`.

**Evidence**:
- `duplicate_group.dart`, `naming_issue.dart`, etc. exist in `lib/src/generated/`
- New models `organization_action_request.dart`, `organization_action_result.dart`, etc. are NOT generated
- Models only generate when referenced in endpoints and successfully compiled

**Root Cause**: The endpoint methods reference these classes, but since they don't exist yet, compilation fails, preventing generation from completing.

**Solution Options**:
1. **Option A**: Manually create the Dart model classes (following Serverpod's pattern)
2. **Option B**: Fix the circular dependency by temporarily using placeholder types
3. **Option C**: Use a different approach (e.g., pass parameters directly without wrapping in request classes)

**Recommended**: Option A - Manually create the model classes in `lib/src/generated/` following the exact pattern of existing models like `duplicate_file.dart`

### 2. Frontend UI Actions
**Location**: `semantic_butler_flutter/lib/screens/organization_screen.dart`

| Component | Current State | Required |
|-----------|---------------|----------|
| Duplicate cards | Display only | Add "Resolve" button with file selection |
| Naming issue cards | Display only | Add "Fix All" / "Fix Individual" buttons |
| Similar content cards | Display only | Add "Organize" button with folder picker |
| Progress indication | None | Add progress indicators for long operations |
| Confirmation dialogs | None | Add confirmation before destructive operations |

**UI Components Needed**:
```dart
// In _DuplicateGroupCard
- "Resolve" button → opens file selection dialog
- "Preview" button → shows dry-run of what would be deleted

// In _NamingIssueCard
- "Fix All" button → applies all suggested fixes
- Individual file fix buttons

// In _SimilarContentCard
- "Organize" button → opens folder picker dialog
- "Preview" button → shows dry-run of moves
```

### 3. Frontend Service Integration
**Location**: `semantic_butler_flutter/lib/`

| File | Required Changes |
|------|------------------|
| `protocol.dart` (client) | Regenerate after server models are fixed |
| Client methods | Add calls to new endpoint methods |
| Error handling | Handle `OrganizationActionResult` errors |
| Progress tracking | Stream progress for long operations |

### 4. Additional Features (Optional but Recommended)

| Feature | Description | Priority |
|---------|-------------|----------|
| **Undo functionality** | Allow users to undo organization operations | High |
| **Bulk select** | Select multiple items to apply actions to | Medium |
| **Auto-fix after confirmation** | One-click fix for all issues | Medium |
| **Operation history** | Show history of organization actions | Low |
| **Scheduling** | Schedule automatic organization | Low |
| **Conflict resolution** | Handle cases where target file/folder exists | High |

---

## Implementation Steps (Remaining)

### Step 1: Fix Model Generation (CRITICAL)
1. Manually create `organization_action_request.dart` in `lib/src/generated/`
2. Manually create `organization_action_result.dart` in `lib/src/generated/`
3. Manually create `batch_organization_request.dart` in `lib/src/generated/`
4. Manually create `batch_organization_result.dart` in `lib/src/generated/`
5. Update `protocol.dart` to export these new classes
6. Run `dart run serverpod generate` to verify

### Step 2: Test Backend Endpoints
1. Start server with new models
2. Test each endpoint method individually
3. Verify dry-run mode works correctly
4. Test rollback functionality

### Step 3: Update Frontend Models
1. Copy/regenerate model classes in client package
2. Update `semantic_butler_client` to include new endpoints

### Step 4: Implement Frontend UI Actions
1. Add action buttons to each card type
2. Implement confirmation dialogs
3. Add progress indicators
4. Handle success/error states

### Step 5: Integration Testing
1. End-to-end test duplicate resolution
2. End-to-end test naming fixes
3. End-to-end test similar file organization
4. Test rollback scenarios

---

## File Reference

### Backend Files
| File | Purpose |
|------|---------|
| `lib/src/models/organization_action_request.spy.yaml` | Request model definition |
| `lib/src/models/organization_action_result.spy.yaml` | Result model definition |
| `lib/src/models/batch_organization_request.spy.yaml` | Batch request definition |
| `lib/src/models/batch_organization_result.spy.yaml` | Batch result definition |
| `lib/src/services/organization_service.dart` | Business logic |
| `lib/src/services/file_operations_service.dart` | File operations (rename, move, delete, trash) |
| `lib/src/endpoints/butler_endpoint.dart` | API endpoints |

### Frontend Files
| File | Purpose |
|------|---------|
| `lib/screens/organization_screen.dart` | Main UI (needs updates) |
| `lib/providers/` | State management (may need updates) |
| `semantic_butler_client/lib/protocol.dart` | Client protocol (needs regeneration) |

---

## Summary

**Completion**: ~60% complete

**What Works**:
- ✅ File analysis (duplicate detection, naming analysis, similarity detection)
- ✅ Backend service logic for applying fixes
- ✅ Backend API endpoint definitions
- ✅ Transaction/undo support in backend
- ✅ Dry-run mode support

**What Doesn't Work Yet**:
- ❌ Model classes not generated (circular dependency)
- ❌ No UI buttons to trigger actions
- ❌ No confirmation dialogs
- ❌ No progress indication
- ❌ Client doesn't have new API methods

**Next Critical Step**: Fix model generation by manually creating the Dart classes in `lib/src/generated/`
