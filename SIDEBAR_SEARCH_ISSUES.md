# Sidebar Search Issues Analysis

This document outlines all identified issues in the sidebar search functionality across the Semantic Butler Flutter application.

---

## Table of Contents
1. [FileManagerSidebar Issues](#1-filemanagersidebar-issues)
2. [FileManagerToolbar Issues](#2-filemanagertoolbar-issues)
3. [HomeScreen & SearchDashboard Issues](#3-homescreen--searchdashboard-issues)
4. [BreadcrumbNavigation Issues](#4-breadcrumbnavigation-issues)
5. [FileManagerScreen Issues](#5-filemanagerscreen-issues)
6. [RecentSearches Issues](#6-recentsearches-issues)

---

## 1. FileManagerSidebar Issues

**File:** `lib/widgets/file_manager/file_manager_sidebar.dart`

### Issue 1.4: No Error State Display (MEDIUM)
**Severity:** Medium
**Type:** UX, Error Handling

The sidebar widget does not handle or display errors that may occur during drive loading. When `getDrives()` fails due to file system permissions, network issues, or other exceptions, the sidebar simply appears empty with no indication of what went wrong or how to recover.

**Current Behavior:**
- On loading failure, the `_buildDrivesList()` method returns an empty state
- Users see "No drives found" regardless of whether the error is temporary or permanent
- No retry mechanism is available for transient failures
- Error details are not logged or surfaced to the user

**Location:** `file_manager_sidebar.dart:55-90` in `_buildDrivesList()`

**Impact:**
- Users cannot distinguish between "no drives exist" and "drive loading failed"
- Network/permission errors require full app restart to attempt recovery
- Poor user experience for debugging file system issues

**Proposed Solution:**
1. Add error state tracking to `FileManagerSidebar` widget
2. Display error message with retry button when `getDrives()` fails
3. Implement exponential backoff retry logic for transient errors
4. Add error icons and user-friendly error messages based on exception type
5. Log detailed errors for debugging while showing simplified messages to users

**Implementation Requirements:**
```dart
class FileManagerSidebar extends StatefulWidget {
  // Add error tracking
  final bool hasError;
  final String? errorMessage;
  final VoidCallback onRetry;
}
```

---

### Issue 1.5: Accessibility - No Semantics Labels (LOW)
**Severity:** Low
**Type:** Accessibility, A11y

Drive items lack semantic labels and properties for screen readers and accessibility services. The `InkWell` wrapping each drive item does not provide semantic information about the control's purpose, selected state, or interaction feedback.

**Current Behavior:**
- Screen readers announce "button" without context
- No semantic label indicating "drive" or "storage"
- Selected state is only indicated visually (color change)
- Keyboard focus indicators may be insufficient

**Location:** `file_manager_sidebar.dart:107-143` in the drive list item `InkWell`

**Impact:**
- Screen reader users cannot understand which drives are selected
- VoiceOver/TalkBack announce generic "button" instead of "C drive selected"
- Keyboard navigation provides no audio feedback
- Fails WCAG 2.1 Level AA success criterion 2.4.7 (Focus Visible) and 4.1.2 (Name, Role, Value)

**Proposed Solution:**
1. Wrap drive items with `Semantics` widget
2. Add `label` property: "Drive [name], [selected/not selected]"
3. Add `button` semantic action
4. Include `onTapHint` for additional context
5. Add `excludeSemantics` to decorative icons
6. Ensure proper focus ordering and focus highlight

**Implementation Requirements:**
```dart
Semantics(
  label: 'Drive ${drive.name}, ${isSelected ? 'selected' : 'not selected'}',
  button: true,
  selected: isSelected,
  onTapHint: 'Navigate to ${drive.name}',
  child: InkWell(...),
)
```

---

## 2. FileManagerToolbar Issues

**File:** `lib/widgets/file_manager/file_manager_toolbar.dart`

### Issue 2.3: No Search History for Local File Search (LOW)
**Severity:** Low
**Type:** Feature Gap, UX

Unlike the main semantic search on the home screen, local file searches performed in the file manager toolbar are not tracked in search history. Users cannot see or re-execute previous local searches, creating an inconsistent experience across the application.

**Current Behavior:**
- Typing in the file manager search field filters the current directory
- No record is created in the `SearchHistory` table for local searches
- Users must manually retype searches when navigating between directories
- Search patterns in file manager are lost on app restart

**Location:** `file_manager_toolbar.dart:89-95` in `_onChanged()` debounce handler

**Impact:**
- Inconsistent UX: main search saves history, file manager search does not
- Users cannot recall useful local search patterns
- No way to discover frequently searched directories
- Lost productivity for repeated searches

**Proposed Solution:**
1. Track local file searches in `SearchHistory` table
2. Differentiate between semantic and local searches via `searchType` field
3. Store current directory context with search query
4. Add search history dropdown to file manager search field
5. Allow re-executing previous searches with context

**Implementation Requirements:**
- Extend `SearchHistory` model with `searchType` enum ('semantic', 'local')
- Add `directoryContext` field for local searches
- Update `ButlerEndpoint.search()` to accept search type parameter
- Add "Recent local searches" popup to file manager search field
- When selecting a history item, navigate to directory and apply filter

**Backend Changes:**
```dart
// In ButlerEndpoint
Future<void> recordLocalSearch(Session session, String query, String directoryPath, int resultCount) async {
  await SearchHistory.db.insertRow(
    session,
    SearchHistory(
      query: query,
      directoryContext: directoryPath,
      searchType: 'local',
      resultCount: resultCount,
      searchedAt: DateTime.now(),
    ),
  );
}
```

---

## 3. HomeScreen & SearchDashboard Issues

**File:** `lib/screens/home_screen.dart`

### Issue 3.2: IndexedStack Memory Usage (MEDIUM)
**Severity:** Medium
**Type:** Performance, Memory

The `IndexedStack` widget in `HomeScreen` keeps all five screens (`SearchDashboard`, `IndexingScreen`, `ChatScreen`, `FileManagerScreen`, `SettingsScreen`) in memory simultaneously, even when not visible. This significantly impacts memory usage, particularly problematic for screens with large data sets like `FileManagerScreen` which loads file system entries and caches.

**Current Behavior:**
- `IndexedStack` builds and maintains all children widgets
- Each screen's state, controllers, and cached data remain in memory
- `FileManagerScreen` maintains entire directory tree even when on Home tab
- `ChatScreen` keeps conversation history cached
- No lazy loading or cleanup on tab switch

**Location:** `home_screen.dart:152-163` in `_buildContent()` method

**Impact:**
- Estimated 2-4x higher memory usage than necessary
- Slower app startup due to building all screens
- Background screens may continue polling/updating (wasted CPU)
- Poor scalability as number of tabs grows
- Potential memory leaks if screens don't properly dispose resources

**Proposed Solution:**
1. Replace `IndexedStack` with `PageStorage` + dynamic widget building
2. Implement `AutomaticKeepAliveClientMixin` selectively for state preservation
3. Add lifecycle hooks for screen activation/deactivation
4. Implement proper resource cleanup when screens become inactive
5. Cache only essential state (scroll position, form inputs) not entire UI

**Implementation Options:**

**Option A: PageStorage + Conditional Building**
```dart
Widget _buildContent() {
  final navState = ref.watch(navigationProvider);
  
  return PageStorage(
    bucket: PageStorageBucket(),
    child: _buildScreen(navState.selectedIndex),
  );
}

Widget _buildScreen(int index) {
  switch (index) {
    case 0: return const SearchDashboard();
    case 1: return const IndexingScreen();
    // Only build visible screen
  }
}
```

**Option B: Keep Alive Mixin (Selective)**
```dart
class _SearchDashboardState extends ConsumerState<SearchDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep this one alive
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for mixin
    // ...
  }
}
```

**Memory Savings Expected:**
- `FileManagerScreen`: ~30-50 MB (directory cache, entry lists)
- `ChatScreen`: ~10-20 MB (conversation history, message widgets)
- `IndexingScreen`: ~5-10 MB (indexing jobs, progress tracking)
- **Total savings: ~45-80 MB**

---

### Issue 3.3: Missing Refresh on Return to Dashboard (LOW)
**Severity:** Low
**Type:** UX, Data Freshness

When navigating back to the `SearchDashboard` from another tab, the widget does not automatically refresh data. Recent searches, indexing stats, and other data remain stale until the user manually triggers a refresh or restarts the app.

**Current Behavior:**
- `SearchDashboard` builds once and doesn't rebuild on tab change
- Recent searches show outdated timestamps
- Indexing stats (`totalDocuments`, `activeJobs`) reflect old values
- User sees "5 active jobs" even if indexing completed while away

**Location:** `home_screen.dart:165-513` in `SearchDashboard` widget

**Impact:**
- Users see outdated information after extended time away
- Missed notifications of indexing completion
- Recent searches may not reflect actual recent activity
- Reduced confidence in dashboard accuracy

**Proposed Solution:**
1. Implement `WidgetsBindingObserver` to detect tab visibility changes
2. Add automatic refresh when `SearchDashboard` becomes visible
3. Use debounce to prevent excessive refresh on rapid tab switching
4. Show visual indicator when data is being refreshed
5. Cache refresh timestamps to avoid unnecessary API calls

**Implementation Requirements:**
```dart
class _SearchDashboardState extends ConsumerState<SearchDashboard>
    with WidgetsBindingObserver {
  
  DateTime? _lastRefreshTime;
  Timer? _refreshDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleRefresh();
    }
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_shouldRefresh()) {
        _refreshDashboard();
      }
    });
  }

  bool _shouldRefresh() {
    if (_lastRefreshTime == null) return true;
    final age = DateTime.now().difference(_lastRefreshTime!);
    return age > const Duration(minutes: 5);
  }
}
```

**Additional Considerations:**
- Also need `didChangeDependencies()` to detect tab changes within same lifecycle
- Add pull-to-refresh gesture for manual refresh option
- Show last-updated timestamp to users

---

## 4. BreadcrumbNavigation Issues

**File:** `lib/widgets/file_manager/breadcrumb_navigation.dart`

### Issue 4.2: No Root Navigation Option (LOW)
**Severity:** Low
**Type:** UX, Navigation

Users cannot navigate directly to a root or "My Computer" view from the breadcrumb navigation. To switch drives, users must use the sidebar, breaking the expected breadcrumb pattern where the first item represents the root of the navigation hierarchy.

**Current Behavior:**
- Breadcrumbs start with the first path segment (e.g., "C:" on Windows)
- No "Computer" or "Root" icon at the beginning
- Switching drives requires using the sidebar or navigation back
- On macOS/Unix, there's no "/" root option

**Location:** `breadcrumb_navigation.dart:30-95` in `build()` method

**Impact:**
- Inconsistent with standard file manager behavior (Windows Explorer, Finder)
- Confusing for users expecting first breadcrumb to be root
- Extra clicks required to switch drives
- Poor discoverability of multi-drive navigation

**Proposed Solution:**
1. Add root/Computer icon as first breadcrumb item
2. Clicking root shows drive selection dialog or navigates to first drive
3. Platform-specific root behavior:
   - Windows: "This PC" → shows all drives
   - macOS: "/" or "Macintosh HD" → shows root volumes
   - Linux: "/" → shows root filesystem
4. Add tooltip: "Navigate to root / all drives"

**Implementation Requirements:**
```dart
Widget build(BuildContext context) {
  // Add root item at start
  return Container(
    child: SingleChildScrollView(
      child: Row(
        children: [
          // Root/Computer item
          InkWell(
            onTap: () => onRootTap(), // New callback
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(
                Platform.isWindows ? Icons.computer : Icons.home,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // ... existing breadcrumbs
        ],
      ),
    ),
  );
}
```

---

### Issue 4.3: Very Deep Paths Usability (LOW)
**Severity:** Low
**Type:** UX, UI/UX

For very deep directory structures (10+ levels), the breadcrumb navigation becomes difficult to use even with horizontal scrolling. Long paths require excessive scrolling and reduce usability, especially on smaller screens or when only a few characters are visible at a time.

**Current Behavior:**
- All path segments are shown in full
- Horizontal scrolling required for paths > 5-6 segments
- No visual indication of collapsed segments
- First and last segments may be far apart, losing context

**Location:** `breadcrumb_navigation.dart:52-92` in path segment iteration

**Example Problem Path:**
```
C:\Users\john\Documents\Projects\2024\SemanticButler\semantic_butler_flutter\lib\widgets\file_manager\breadcrumb_navigation.dart
```

**Impact:**
- Requires excessive horizontal scrolling on deep paths
- Difficult to see full path context at once
- Poor experience on tablet/mobile views
- Cognitive load to remember path structure

**Proposed Solution:**
1. Implement smart collapsing for deep paths (>5 segments)
2. Show first 2 segments + "..." + last 2 segments
3. Add tooltip on "..." to show full path on hover
4. Optional: Expandable dropdown for collapsed segments
5. Respect platform conventions (Windows Explorer shows full, macOS collapses)

**Implementation Options:**

**Option A: Simple Collapse**
```dart
List<Widget> _buildBreadcrumbs() {
  if (parts.length <= 5) {
    return _buildAllSegments(parts);
  }
  
  // Collapse middle segments
  return [
    _buildSegment(parts[0], 0),
    _buildSegment(parts[1], 1),
    // Ellipsis with tooltip
    InkWell(
      onHover: (hovered) => _showFullPathTooltip(hovered),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Icon(Icons.more_horiz, size: 16),
      ),
    ),
    _buildSegment(parts[parts.length - 2], parts.length - 2),
    _buildSegment(parts[parts.length - 1], parts.length - 1),
  ];
}
```

**Option B: Expandable Dropdown**
```dart
// "..." becomes a popup menu showing all collapsed segments
PopupMenuButton<String>(
  icon: const Icon(Icons.more_horiz),
  itemBuilder: (context) => parts
      .skip(2)
      .take(parts.length - 4)
      .map((part) => PopupMenuItem(value: part, child: Text(part)))
      .toList(),
  onSelected: (path) => onPathSelected(path),
)
```

**Visual Result:**
```
Before:  C:\Users\john\Documents\Projects\2024\...\lib\widgets\breadcrumb_navigation.dart
After:   C:\Users\...Projects\2024\...\lib\widgets\breadcrumb_navigation.dart
```

---

## 5. FileManagerScreen Issues

**File:** `lib/screens/file_manager_screen.dart`

### Issue 5.7: No Undo for Delete Operation (MEDIUM)
**Severity:** Medium
**Type:** UX, Data Safety

The delete operation in `FileManagerScreen` permanently removes files without any undo mechanism. Users cannot recover accidentally deleted files, creating a high-risk experience for important documents. There is no confirmation preview of what will be deleted, and no soft-delete or trash functionality.

**Current Behavior:**
- `_confirmDelete()` shows a simple confirmation dialog
- Upon confirmation, calls `client.fileSystem.delete(entry.path)`
- File is permanently removed from the file system
- No tracking of deleted files or recovery mechanism
- No bulk delete support or undo for multi-delete operations

**Location:** `file_manager_screen.dart:639-680` in `_confirmDelete()` method

**Impact:**
- High risk of accidental data loss
- Poor user confidence in file management
- No way to recover from mistakes
- Does not meet platform UX standards (Windows Recycle Bin, macOS Trash)

**Proposed Solution:**
1. Implement soft-delete with "Recently Deleted" functionality
2. Add SnackBar with "Undo" option after delete
3. Move files to `.trash` directory instead of permanent deletion
4. Add "Empty Trash" in context menu
5. Provide restore functionality for deleted files
6. Add multi-select bulk delete with undo

**Implementation Requirements:**

**Phase 1: SnackBar Undo**
```dart
Future<void> _confirmDelete(FileSystemEntry entry) async {
  // Move to trash instead of permanent delete
  final trashPath = await _getTrashPath();
  final trashEntryPath = p.join(trashPath, entry.name);
  
  // Cache original path for restoration
  await _cacheOriginalPath(entry.path, trashEntryPath);
  
  // Move file to trash
  await client.fileSystem.move(entry.path, trashEntryPath);
  
  // Show undo SnackBar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Deleted ${entry.name}'),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () => _restoreFromTrash(entry.path, trashEntryPath),
      ),
      duration: const Duration(seconds: 5),
    ),
  );
}

Future<String> _getTrashPath() async {
  // Platform-specific trash location
  if (Platform.isWindows) {
    return r'C:\$Recycle.Bin\SemanticButler';
  } else if (Platform.isMacOS) {
    return '${Platform.environment['HOME']}/.Trash/SemanticButler';
  }
  return '${Platform.environment['HOME']}/.local/share/SemanticButler/trash';
}
```

**Phase 2: Recently Deleted Panel**
- Add "Recently Deleted" option in sidebar or settings
- Show files in trash with restore/delete permanently buttons
- Auto-purge after 30 days
- Implement empty trash functionality

**Phase 3: Multi-select Undo**
- Add checkbox selection mode
- Track batch deletions
- Restore entire batch with single undo

**Database Changes (for tracking):**
```yaml
### File deletion tracking
class: DeletedFile
table: deleted_files
fields:
  originalPath: String, indexed
  trashPath: String, indexed
  deletedAt: DateTime, indexed
  restoredAt: DateTime?
  permanentlyDeletedAt: DateTime?
```

---

## 6. RecentSearches Issues

**File:** `lib/widgets/recent_searches.dart`

### Issue 6.2: No Delete/Clear History Option (LOW)
**Severity:** Low
**Type:** Feature Gap, Privacy

Users cannot delete individual search history items or clear their entire search history. This limits privacy control and prevents users from managing their search data. There is no way to remove sensitive or erroneous search queries.

**Current Behavior:**
- Recent searches are displayed as a list of tiles
- Only interaction is tapping to re-execute a search
- No context menu or delete button on individual items
- No "Clear All History" button in the header
- Users are stuck with all historical searches

**Location:** `recent_searches.dart:159-197` in `_SearchHistoryTile` and build method

**Impact:**
- Privacy concern: search history may contain sensitive information
- No way to remove accidental or typos from history
- Accumulation of irrelevant searches over time
- Users may avoid searching due to privacy concerns

**Proposed Solution:**
1. Add context menu (long-press/right-click) on search history tiles
2. Add delete button to each tile (revealed on hover or swipe)
3. Add "Clear History" button in header with confirmation dialog
4. Implement swipe-to-delete on mobile platforms
5. Add "Delete" option to tile menu with confirmation

**Implementation Requirements:**

**Option A: Context Menu**
```dart
class _SearchHistoryTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(query),
        subtitle: Text('$resultCount results • $time'),
        onTap: onTap,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _showDeleteDialog(context),
        ),
      ),
    );
  }
  
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete search?'),
        content: Text('Remove "$query" from history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              onDelete?.call();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
```

**Option B: Clear All Button**
```dart
// In _RecentSearchesState build method
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('Recent Searches'),
    Row(
      children: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 18),
          onPressed: _loadSearchHistory,
        ),
        TextButton(
          onPressed: _clearAllHistory,
          child: const Text('Clear All'),
        ),
      ],
    ),
  ],
)

Future<void> _clearAllHistory() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear All History?'),
      content: const Text('This will delete all your search history. This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Clear All'),
        ),
      ],
    ),
  );
  
  if (confirmed == true) {
    await client.butler.clearSearchHistory();
    setState(() => _searches = []);
  }
}
```

**Backend Addition:**
```dart
// In ButlerEndpoint
Future<void> clearSearchHistory(Session session) async {
  await SearchHistory.db.deleteWhere(
    session,
    where: (t) => Constant(true),
  );
}

Future<void> deleteSearchHistoryItem(Session session, int searchId) async {
  await SearchHistory.db.deleteRow(session, searchId);
}
```

---

### Issue 6.3: Fixed Limit of 10 Items (LOW)
**Severity:** Low
**Type:** Feature Gap, Configurability

The search history limit is hardcoded to 10 items in the API call `getSearchHistory(limit: 10)`. Users cannot see more of their search history or configure the limit based on their preferences. This creates a one-size-fits-all constraint that may not suit all usage patterns.

**Current Behavior:**
- `_loadSearchHistory()` calls `client.butler.getSearchHistory(limit: 10)`
- Only the 10 most recent searches are loaded and displayed
- No pagination or "Load More" functionality
- No user setting to configure the limit
- Older searches are permanently inaccessible

**Location:** `recent_searches.dart:35` in `_loadSearchHistory()` method

**Impact:**
- Users lose access to searches beyond the 10 most recent
- No way to find an old useful search
- Arbitrary limit doesn't account for different usage patterns
- "Refresh" button doesn't load more, just reloads the same 10

**Proposed Solution:**
1. Make limit configurable via user settings
2. Add "Load More" / "Show All" button at bottom of list
3. Implement pagination for large histories
4. Add search within history functionality
5. Allow users to "pin" important searches

**Implementation Requirements:**

**Phase 1: Load More Button**
```dart
class _RecentSearchesState extends State<RecentSearches> {
  int _limit = 10;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  Future<void> _loadSearchHistory() async {
    setState(() => _isLoading = true);
    
    final history = await client.butler.getSearchHistory(limit: _limit);
    _hasMore = history.length >= _limit;
    
    setState(() {
      _searches = history.map(...).toList();
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() => _isLoadingMore = true);
    _limit += 10;
    await _loadSearchHistory();
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ... existing search tiles
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: _loadMore,
              icon: _isLoadingMore
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.expand_more),
              label: Text(_isLoadingMore ? 'Loading...' : 'Show More'),
            ),
          ),
      ],
    );
  }
}
```

**Phase 2: User Settings**
```dart
// In SettingsScreen
class SearchHistorySettings extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    final historyLimit = ref.watch(searchHistoryLimitProvider);
    
    return ListTile(
      leading: const Icon(Icons.history),
      title: const Text('Search History Limit'),
      subtitle: Text('Show last $historyLimit searches'),
      trailing: DropdownButton<int>(
        value: historyLimit,
        items: [10, 25, 50, 100, -1].map((limit) {
          return DropdownMenuItem(
            value: limit,
            child: Text(limit == -1 ? 'All' : limit.toString()),
          );
        }).toList(),
        onChanged: (value) => ref.read(searchHistoryLimitProvider.notifier).set(value!),
      ),
    );
  }
}
```

**Phase 3: Search Within History**
```dart
// Add search field above RecentSearches
TextField(
  decoration: InputDecoration(
    hintText: 'Search history...',
    prefixIcon: const Icon(Icons.search),
  ),
  onChanged: (query) {
    setState(() {
      _filteredSearches = _searches
          .where((s) => s['query'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  },
)
```

**Backend Changes:**
```dart
// Add limit as optional parameter
Future<List<SearchHistory>> getSearchHistory(
  Session session, {
  int limit = 10,
  int offset = 0,
}) async {
  final results = await SearchHistory.db.find(
    session,
    limit: limit == -1 ? null : limit,
    orderBy: SearchHistory.t.searchedAt,
    orderDescending: true,
    offset: offset,
  );
  return results;
}
```

---

## Summary by Severity

| Severity | Count | Issues |
|----------|-------|--------|
| HIGH     | 0     | - |
| MEDIUM   | 3     | 1.4 Error State Display, 3.2 IndexedStack Memory, 5.7 No Undo for Delete |
| LOW      | 7     | 1.5 Accessibility Labels, 2.3 No Search History, 3.3 Missing Refresh, 4.2 No Root Nav, 4.3 Deep Paths, 6.2 No Delete History, 6.3 Fixed 10 Item Limit |
| **Total**| **10**| |

---

## Implementation Priority

**High Priority (Do First):**
1. **Issue 3.2: IndexedStack Memory** - Critical for performance on resource-constrained devices
2. **Issue 5.7: No Undo for Delete** - High data loss risk, safety-critical

**Medium Priority:**
3. **Issue 1.4: Error State Display** - Improves error handling and user feedback
4. **Issue 6.2: Delete History** - Important for privacy

**Low Priority (Nice to Have):**
5. **Issue 1.5: Accessibility** - Important for A11y compliance
6. **Issue 3.3: Auto Refresh** - UX improvement
7. **Issue 2.3: Search History** - Feature enhancement
8. **Issue 4.2: Root Navigation** - UX consistency
9. **Issue 4.3: Deep Paths** - Edge case improvement
10. **Issue 6.3: Load More** - Minor enhancement