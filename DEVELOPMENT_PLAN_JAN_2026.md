# Semantic Butler - Comprehensive Development Plan (Jan 2026)

## Overview
This plan addresses technical debt, indexing efficiency, and the implementation of agentic file operations based on the current state of the `desk-sense` codebase and specific requirements from `TODO.md`.

---

## Phase 1: Indexing Infrastructure & Efficiency (P0)

### 1.1 Rich Previews for Summarized Documents
**Goal**: Display stored summaries in the UI for better user experience.
- **Backend**: ~~Store the full `DocumentSummary` in the `FileIndex` record~~ (DONE - summaries stored)
- **Backend**: ~~Refactor `ButlerEndpoint._processBatch` to skip chunking if a summary is generated~~ (DONE - summaries used for embedding)
- **Frontend**: Add endpoint/method to retrieve rich document previews using the stored summary
- **Frontend**: Display "Document Summary" badge in search results for summarized documents
- **Frontend**: Add option to show full summary when user requests more details

### 1.2 Universal Metadata Indexing (Non-Text Files)
**Goal**: Allow searching for all files by name/type, even if content cannot be extracted.
- **Backend**: Update `FileExtractionService.scanDirectory` to include *all* files (except those explicitly ignored).
- **Backend**: Update `FileExtractionService.extractText` to handle unsupported extensions by returning a "Metadata Only" result (no content, just `fileName`, `mimeType`, and `fileSizeBytes`).
- **Backend**: Ensure "Read-Only" mode is strictly enforced during extraction to prevent file system side effects.

### 1.3 Reactive UI for Indexing Progress
**Goal**: Fix unreliable progress tracking and eliminate polling.
- **Backend**: ~~Refine `processedFiles`, `skippedFiles`, and `failedFiles` logic in `ButlerEndpoint`~~ (DONE - metrics tracked in IndexingJob)
- **Backend**: Fix potential race conditions in `streamIndexingProgress` where status might be reported as `completed` before the DB transaction is fully flushed.
- **Frontend**: Transition `IndexingScreen` and `CompactIndexCard` to use a reactive `StreamProvider` for real-time progress, eliminating the need for manual "Refresh" clicks.

### 1.4 Selective Indexing & Removal
**Goal**: Give users granular control over their indexed data.
- **Backend**: Implement "Ignore Pattern" propagation: adding an ignore pattern should automatically trigger a cleanup of existing matching entries from the `FileIndex` and `DocumentEmbedding` tables.
- **Frontend**: ~~Add "Ignore this file/folder"~~ (DONE - exists in context menu)
- **Frontend**: Add "Wipe Index for Folder" action to the `FileManagerScreen` context menu.

---

## Phase 2: Agentic File Operations (P1)

### 2.1 Human-in-the-Loop Approval
**Goal**: Ensure user consent before destructive operations.
- **Backend**: ~~Implement `AgentService` using OpenRouter with structured output~~ (DONE - AgentService with JSON schema exists)
- **Tooling**: ~~Define "Terminal Tools"~~ (DONE - move/rename/delete/search/create_folder tools available)
- **Frontend**: Implement a mandatory approval UI step for any file operations that modify or delete data
- **Frontend**: Show operation preview before executing batch operations
- **Frontend**: Add progress tracking for large file operations

### 2.2 ~~Advanced Context Injection~~ (DONE)
- **Backend**: ~~Inject search results and file metadata directly into the agent's context~~ (DONE - context injection implemented)

---

## Phase 3: UX Productivity & Polish (P2)

### 3.1 Global Keyboard Shortcuts Refinement
- **Frontend**: ~~Integrate `ShortcutManager` into the root `App` level~~ (DONE - Ctrl+K and Ctrl+1-6 work globally)
- **Frontend**: Add a "Command Palette" (`Ctrl+Shift+P`) for quick access to actions like "Re-index All" or "Clear Cache".

### 3.2 ~~Result Preview & Interaction~~ (DONE)
- **Frontend**: ~~Create a side-by-side "Preview Pane" in `SearchResultsScreen`~~ (DONE - preview pane implemented)
- **Frontend**: ~~Add "Ask about this file" shortcut~~ (DONE - "Ask AI" button in preview pane)

---

## Success Metrics
- **Vector Efficiency**: ~~>70% reduction in `DocumentEmbedding` rows for large document libraries~~ (ACHIEVED - summaries used for embedding)
- **Reliability**: 100% accuracy in indexing progress bars.
- **User Delight**: Seamless "Organize this folder" experience via Chat with proper approval flow.
