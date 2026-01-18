# Search Issues Analysis - Flutter App

## Overview

This document tracks remaining search-related issues across the Semantic Butler Flutter application and server.

**Version 4.0:** Cleaned up to show only remaining/unimplemented issues. All fixed issues removed.

**Date:** 2026-01-18
**Analyzed Components:** SearchResultsScreen, SearchBarWidget, RecentSearches, SavedSearchPresetsPanel, FileManagerScreen, FileManagerToolbar, SearchResultCard, ButlerEndpoint, Main.dart, DirectoryCacheProvider, RateLimitService

---

## Remaining Issues

### 1. SearchResultsScreen.dart

**File:** `semantic_butler/semantic_butler_flutter/lib/screens/search_results_screen.dart`

#### Issue 1.1: Hardcoded Search Threshold (LOW)
- **Severity:** Low
- **Location:** Lines 196, 202, 261, 267
- **Problem:** The search threshold is hardcoded to `0.3` with no UI control for users to adjust sensitivity.
- **Impact:** Users cannot fine-tune search results based on their preferences.
- **Code:**
```dart
await client.butler.hybridSearch(
  widget.query,
  limit: _pageSize,
  threshold: 0.3, // Hardcoded!
  offset: 0,
)
```
- **Fix Required:**
  1. Add `double searchThreshold` to app settings/state
  2. Expose threshold parameter in settings UI with slider (0.0 to 1.0)
  3. Pass threshold as parameter to search methods instead of hardcoding

---

### 2. SavedSearchPresetsPanel.dart

**File:** `semantic_butler/semantic_butler_flutter/lib/widgets/home/saved_search_presets_panel.dart`

#### Issue 2.1: Type Mismatch Between API and UI (MEDIUM)
- **Severity:** Medium
- **Location:** Lines 17, 447-449
- **Problem:** `getSavedPresets()` returns `List<Map<String, dynamic>>` but the UI should ideally use typed objects.
- **Impact:** Type safety issues and maintenance burden. Manual type casting required in widget code.
- **Fix Required:**
  1. Create `search_preset.spy.yaml` in server models directory
  2. Add model fields: `id`, `name`, `query`, `category`, `usageCount`, `createdAt`
  3. Update `getSavedPresets()` endpoint to return `List<SearchPreset>`
  4. Regenerate client protocol with `serverpod generate`
  5. Update Flutter widget to use typed `SearchPreset` model instead of `Map<String, dynamic>`

---

### 3. ButlerEndpoint.dart (Server-side)

**File:** `semantic_butler/semantic_butler_server/lib/src/endpoints/butler_endpoint.dart`

#### Issue 3.1: No Search Cancellation (MEDIUM)
- **Severity:** Medium
- **Problem:** Search methods don't support cancellation tokens, so cancelled searches (from client-side mode switching) continue processing server-side.
- **Impact:** Wasted server resources and potential slow responses for new searches.
- **Fix Required:**
  1. Create `CancellationToken` class with `isCancelled` flag
  2. Add optional `CancellationToken` parameter to search methods
  3. Check cancellation flag during long-running operations:
     - Before pgvector queries
     - Before AI embedding generation
     - During result merging
  4. Implement server-side cancellation tracking for active searches
  5. Add endpoint for client to request cancellation: `cancelSearch(sessionId, searchId)`

---

### 4. Main.dart

**File:** `semantic_butler/semantic_butler_flutter/lib/main.dart`

#### Issue 4.1: Zone-Level Error Handling Masks Individual Errors (LOW)
- **Severity:** Low
- **Location:** Lines 127-134
- **Problem:** The `runZonedGuarded` wrapper catches all errors globally but doesn't distinguish between recoverable and fatal errors for specific reporting.
- **Impact:** Cannot track error severity separately, making debugging difficult.
- **Fix Required:**
  1. Add error categorization logic to distinguish error types
  2. Create categories: `RecoverableError` (network timeout, rate limit) vs `FatalError` (critical system failure)
  3. Implement separate handling based on error severity:
     - Recoverable: Show user-friendly toast, retry automatically if appropriate
     - Fatal: Log critical error, show error screen, restart app
  4. Add structured error tracking/analytics based on severity
  5. Update error logging to include severity information

---

## Issue Statistics

| Category | Remaining | Severity Breakdown |
|-----------|-------------|-------------------|
| **SearchResultsScreen** | 1 | 1 Low |
| **SavedSearchPresetsPanel** | 1 | 1 Medium |
| **ButlerEndpoint** | 1 | 1 Medium |
| **Main.dart** | 1 | 1 Low |
| **TOTAL** | **4** | 2 Low, 2 Medium |

---

## Priority Recommendations

### High Priority
None remaining - all critical search issues have been resolved.

### Medium Priority
1. **Issue 2.1:** Type Mismatch - Improves type safety and reduces maintenance burden
2. **Issue 3.1:** No Search Cancellation - Improves server resource efficiency

### Low Priority
1. **Issue 1.1:** Hardcoded Search Threshold - Nice-to-have user preference
2. **Issue 4.1:** Zone Error Handling - Improves debugging and error tracking
