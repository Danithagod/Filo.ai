# Manual Testing Checklist

## Overview
This checklist covers manual testing for the Semantic Butler application including the website, Flutter frontend, and backend functionality.

---

## 1. Website Frontend Testing

### 1.1 Home Page
- [ ] **Hero Section**
  - [ ] Verify hero badge displays correctly ("v2.0 Now Available")
  - [ ] Check hero title gradient effect
  - [ ] Test "Get Started Free" button navigates to Pricing page
  - [ ] Test "View GitHub" button opens GitHub in new tab
  - [ ] Verify hero visual animation (scan line, pulse effect)
  - [ ] Check side dynamic panels collapse on scroll

- [ ] **Trust Ticker**
  - [ ] Verify ticker animation scrolls smoothly
  - [ ] Check text is readable and properly formatted
  - [ ] Test ticker continues scrolling indefinitely

- [ ] **Features Section**
  - [ ] Verify horizontal scroll works with mouse wheel/touch
  - [ ] Check all 6 feature cards are displayed
  - [ ] Test feature cards have proper hover effects
  - [ ] Verify feature icons (Search, Cpu, Shield, Database, Tags, Zap)
  - [ ] Check feature numbers (01-06) display correctly

- [ ] **Agent Flow Section**
  - [ ] Verify 3 flow steps are displayed
  - [ ] Check step icons (Brain, Search, Zap)
  - [ ] Test animations on scroll (steps appear sequentially)
  - [ ] Verify connector lines between steps
  - [ ] Check highlight effect on step 3 ("Local Execution")

- [ ] **Integration Section**
  - [ ] Verify code block displays correctly
  - [ ] Check CLI commands are properly formatted
  - [ ] Test integration list items display with checkmarks
  - [ ] Verify glass card styling

### 1.2 Features Page
- [ ] **Features Hero**
  - [ ] Verify page title and subtitle display
  - [ ] Check animation on page load

- [ ] **Feature Groups**
  - [ ] Test "Intelligent Search" group displays correctly
    - [ ] Semantic Embedding card
    - [ ] Hybrid Search card
    - [ ] Contextual Awareness card
  - [ ] Test "Local AI Orchestration" group displays correctly
    - [ ] Task Automation card
    - [ ] Local LLM Integration card
    - [ ] Zero Cloud Reliance card
  - [ ] Test "Security & Performance" group displays correctly
    - [ ] Rust Core card
    - [ ] End-to-End Privacy card
    - [ ] Hardware Acceleration card

- [ ] **CTA Section**
  - [ ] Verify CTA card styling
  - [ ] Test "Get Started Now" button navigation

### 1.3 About Page
- [ ] Verify page content loads correctly
- [ ] Test all internal links
- [ ] Check responsive layout on mobile

### 1.4 Pricing Page
- [ ] Verify pricing tiers display correctly
- [ ] Test plan selection
- [ ] Check CTA buttons work

### 1.5 404 Page (NotFound)
- [ ] Verify 404 message displays
- [ ] Test "Back to Home" button

### 1.6 Navigation
- [ ] **Navbar**
  - [ ] Test all navigation links (Home, Features, About, Pricing)
  - [ ] Verify mobile menu opens/closes
  - [ ] Check active state highlighting
  - [ ] Test logo returns to home page

### 1.7 Responsive Design
- [ ] Test on desktop (1920x1080)
- [ ] Test on tablet (768x1024)
- [ ] Test on mobile (375x667)
- [ ] Verify animations work across screen sizes
- [ ] Check glass cards render correctly on all viewports

### 1.8 Accessibility
- [ ] Verify all images have alt text
- [ ] Test keyboard navigation (Tab, Enter, Esc)
- [ ] Check ARIA labels on interactive elements
- [ ] Verify color contrast ratios meet WCAG AA standards

### 1.9 Performance
- [ ] Measure initial page load time (< 3 seconds)
- [ ] Check Time to Interactive (TTI)
- [ ] Verify animations run at 60fps
- [ ] Test lazy loading for images

---

## 2. Flutter Application Testing

### 2.1 Initial Setup
- [ ] **Environment Configuration**
  - [ ] Verify `config.json` has correct `apiUrl` (http://localhost:8080)
  - [ ] Test application launches successfully on Windows/macOS/Linux
  - [ ] Verify no build errors in console

### 2.2 Connection to Backend
- [ ] Test initial connection to server
- [ ] Verify authentication handshake works
- [ ] Test reconnection after server restart
- [ ] Check error handling when server is unavailable

### 2.3 Semantic Search Feature
- [ ] **Search UI**
  - [ ] Verify search bar displays on main screen
  - [ ] Test typing in search field
  - [ ] Check search button/enter triggers search
  - [ ] Verify loading indicator shows during search

- [ ] **Search Results**
  - [ ] Test searching with a natural language query
    - [ ] Example: "Find documents about React"
  - [ ] Verify results display with:
    - [ ] File name
    - [ ] File path
    - [ ] Relevance score
    - [ ] Content preview
    - [ ] Tags
  - [ ] Test clicking a result opens file details
  - [ ] Verify empty query returns recent documents
  - [ ] Check search results update pagination works (if applicable)
  - [ ] Test threshold parameter affects result relevance

### 2.4 Document Indexing
- [ ] **Start Indexing**
  - [ ] Test selecting a folder path
  - [ ] Verify "Start Indexing" button works
  - [ ] Check indexing job is created
  - [ ] Test indexing status updates in real-time

- [ ] **Indexing Progress**
  - [ ] Verify progress bar updates correctly
  - [ ] Check processed/failed/skipped file counts
  - [ ] Test percentage calculation
  - [ ] Verify estimated time remaining displays
  - [ ] Check current file being processed (if shown)

- [ ] **Indexing Completion**
  - [ ] Verify job status changes to "completed"
  - [ ] Test failed indexing job (invalid path)
  - [ ] Check error messages display correctly
  - [ ] Verify multiple jobs can run (or queue)

- [ ] **File Types**
  - [ ] Test indexing text files (.txt)
  - [ ] Test indexing markdown files (.md)
  - [ ] Test indexing PDF files (if supported)
  - [ ] Test indexing Word documents (if supported)
  - [ ] Test ignored files (node_modules, .git, etc.)

### 2.5 Smart Indexing (File Watching)
- [ ] Test enabling smart indexing for a folder
- [ ] Verify file watcher starts successfully
- [ ] Test creating a new file triggers auto-index
- [ ] Test modifying a file triggers re-index
- [ ] Test deleting a file removes from index
- [ ] Verify watched folders list updates
- [ ] Test disabling smart indexing
- [ ] Check auto-index respects ignore patterns

### 2.6 AI Agent / Chat Interface
- [ ] **Chat UI**
  - [ ] Verify chat interface displays
  - [ ] Test typing messages in chat input
  - [ ] Verify send button works
  - [ ] Test streaming responses appear in real-time
  - [ ] Check message history displays

- [ ] **Agent Capabilities**
  - [ ] Test search tool: "Search for my React notes"
  - [ ] Test summarize: "Summarize document ID 123"
  - [ ] Test find related: "Find documents similar to ID 123"
  - [ ] Test get indexing status: "What's the indexing status?"
  - [ ] Test file operations:
    - [ ] "Rename file X to Y"
    - [ ] "Move file X to folder Y"
    - [ ] "Delete file X"
    - [ ] "Create folder X"
  - [ ] Test terminal commands: "List directory X"
  - [ ] Test grep search: "Search for 'pattern' in folder X"
  - [ ] Test find files: "Find all PDF files"
  - [ ] Test batch operations
  - [ ] Test get drives

- [ ] **Streaming Behavior**
  - [ ] Verify "thinking" status shows
  - [ ] Check tool execution messages display
  - [ ] Test tool results show correctly
  - [ ] Verify error messages appear when tools fail
  - [ ] Test conversation context is maintained across messages

### 2.7 Dashboard & Statistics
- [ ] **Indexing Status**
  - [ ] Verify total documents count displays
  - [ ] Check indexed documents count
  - [ ] Verify pending documents count
  - [ ] Check failed documents count
  - [ ] Test active jobs count updates
  - [ ] Verify last activity timestamp

- [ ] **Database Stats**
  - [ ] Check database size displays (MB)
  - [ ] Verify file count matches
  - [ ] Test embedding count matches
  - [ ] Check average embedding time displays

- [ ] **AI Usage Stats**
  - [ ] Verify total input tokens tracked
  - [ ] Check total output tokens tracked
  - [ ] Test estimated cost calculation
  - [ ] Verify cost tracking persists across sessions

- [ ] **Error Stats**
  - [ ] Test error stats display by category
  - [ ] Check time range filter (24h, 7d, 30d, all)
  - [ ] Verify category breakdown shows percentages
  - [ ] Test filtering by job ID

### 2.8 File Operations
- [ ] **Browse Files**
  - [ ] Test list_directory tool works
  - [ ] Verify folder navigation works
  - [ ] Check drive listing works (get_drives)

- [ ] **File Actions**
  - [ ] Test rename_file: File renamed successfully
  - [ ] Test rename_folder: Folder renamed successfully
  - [ ] Test move_file: File moved to new location
  - [ ] Test delete_file: File deleted (index updated)
  - [ ] Test create_folder: Folder created at path

- [ ] **Index Synchronization**
  - [ ] Verify index updates after rename
  - [ ] Verify index updates after move
  - [ ] Verify index updates after delete
  - [ ] Test file not found in index (no error)

### 2.9 Settings & Configuration
- [ ] **Ignore Patterns**
  - [ ] Test adding ignore pattern (e.g., "*.log")
  - [ ] Verify pattern appears in list
  - [ ] Test removing ignore pattern
  - [ ] Check patterns apply during indexing

- [ ] **Clear Index**
  - [ ] Test clear index functionality
  - [ ] Verify all documents removed
  - [ ] Check database is empty after clear

### 2.10 Error Handling
- [ ] **Network Errors**
  - [ ] Test behavior when server is offline
  - [ ] Verify error message displays
  - [ ] Check reconnection attempts

- [ ] **Validation Errors**
  - [ ] Test empty search query
  - [ ] Test invalid file path
  - [ ] Test malformed input in chat
  - [ ] Test exceeding message length limit

- [ ] **Timeout Errors**
  - [ ] Test long-running operation timeout
  - [ ] Verify timeout message displays
  - [ ] Check operation is cancelled properly

---

## 3. Backend Integration Testing

### 3.1 Authentication
- [ ] Verify API calls require authentication
- [ ] Test session management
- [ ] Verify rate limiting works
  - [ ] Search: 60 requests/minute
  - [ ] Indexing: 10 requests/minute
  - [ ] Agent chat: 30 requests/minute
  - [ ] Auto-index: 30 requests/minute

### 3.2 Search Functionality
- [ ] **Semantic Search**
  - [ ] Test query generates embedding via OpenRouter
  - [ ] Verify vector search uses pgvector operator
  - [ ] Check cosine similarity calculation
  - [ ] Test threshold filtering
  - [ ] Verify pagination (limit, offset)
  - [ ] Test empty query returns recent docs
  - [ ] Check search history is logged

- [ ] **Fallback Search**
  - [ ] Test Dart fallback when pgvector fails
  - [ ] Verify results still returned

### 3.3 Indexing Operations
- [ ] **File Extraction**
  - [ ] Test text file extraction
  - [ ] Test markdown file extraction
  - [ ] Test PDF extraction (if supported)
  - [ ] Verify content hash calculation
  - [ ] Check file metadata extraction

- [ ] **AI Processing**
  - [ ] Test summary generation for long docs (>500 words)
  - [ ] Verify embedding generation
  - [ ] Test tag generation
  - [ ] Check caching reduces duplicate API calls

- [ ] **Batch Processing**
  - [ ] Test batch size of 25 files
  - [ ] Verify transaction wrapping
  - [ ] Check failed files don't stop batch
  - [ ] Test retry logic (3 attempts)

- [ ] **Long Documents**
  - [ ] Test document chunking (>1000 words)
  - [ ] Verify multiple embeddings created
  - [ ] Check chunk overlap (100 words)

- [ ] **Smart Indexing**
  - [ ] Test file watcher detects changes
  - [ ] Verify race condition prevention (processing paths)
  - [ ] Check duplicate file detection (hash comparison)
  - [ ] Test auto-index rate limiting

### 3.4 File Operations
- [ ] Verify rename operation updates index
- [ ] Test move operation updates index
- [ ] Check delete operation removes from index
- [ ] Verify audit logging for operations
- [ ] Test batch operations with rollback

### 3.5 Terminal Operations
- [ ] **Read-Only Commands**
  - [ ] Test `dir` / `ls` works
  - [ ] Test `find` / `findstr` works
  - [ ] Test `grep` works
  - [ ] Test `cat` / `type` works

- [ ] **Security**
  - [ ] Verify destructive commands are blocked
  - [ ] Test command whitelist enforcement
  - [ ] Verify path traversal protection
  - [ ] Check output truncation (10MB limit)

### 3.6 Error Categorization
- [ ] Test timeout errors categorized correctly
- [ ] Verify permission denied errors
- [ ] Check corrupt file errors
- [ ] Test network errors
- [ ] Verify unknown errors categorized properly

---

## 4. Integration Testing

### 4.1 End-to-End Workflows
- [ ] **Workflow 1: Search & Summarize**
  - [ ] Index a folder with test documents
  - [ ] Search for a specific topic
  - [ ] Click a result to view details
  - [ ] Ask agent to summarize the document
  - [ ] Verify summary is accurate

- [ ] **Workflow 2: File Organization**
  - [ ] List directory with unorganized files
  - [ ] Ask agent to organize files by type
  - [ ] Verify files moved/renamed correctly
  - [ ] Check index updated with new paths

- [ ] **Workflow 3: Find Related Docs**
  - [ ] Search for a document
  - [ ] Click result to view details
  - [ ] Use "Find Related" feature
  - [ ] Verify related docs are semantically similar

- [ ] **Workflow 4: Smart Indexing**
  - [ ] Enable smart indexing on a folder
  - [ ] Create a new file in that folder
  - [ ] Wait for auto-index to complete
  - [ ] Search for the new file
  - [ ] Verify file appears in results

### 4.2 Cross-Platform Testing
- [ ] Test Flutter app on Windows
- [ ] Test Flutter app on macOS
- [ ] Test Flutter app on Linux
- [ ] Verify behavior is consistent across platforms
- [ ] Test file paths work for each OS

---

## 5. Edge Cases & Stress Testing

### 5.1 Large Data Sets
- [ ] Index 1000+ files
- [ ] Test search performance with large index
- [ ] Verify pagination handles large result sets
- [ ] Check database size estimation accuracy

### 5.2 Large Files
- [ ] Index a file > 10MB
- [ ] Index a file with > 10,000 words
- [ ] Test search returns relevant chunk
- [ ] Verify memory usage remains stable

### 5.3 Special Characters
- [ ] Test file paths with spaces
- [ ] Test file paths with unicode characters
- [ ] Test file names with special chars (%, #, @, etc.)
- [ ] Search queries with special characters

### 5.4 Concurrent Operations
- [ ] Start multiple indexing jobs simultaneously
- [ ] Perform search while indexing
- [ ] Use agent chat while indexing
- [ ] Verify no race conditions occur

### 5.5 API Rate Limits
- [ ] Exceed search rate limit (60/min)
- [ ] Exceed indexing rate limit (10/min)
- [ ] Exceed chat rate limit (30/min)
- [ ] Verify rate limit errors display

### 5.6 Network Issues
- [ ] Disconnect network while streaming chat
- [ ] Server restart during indexing
- [ ] Connection timeout scenarios
- [ ] Verify graceful degradation

### 5.7 Invalid Inputs
- [ ] Empty search query
- [ ] Very long search query (>1000 chars)
- [ ] Invalid file paths
- [ ] Non-existent document IDs
- [ ] Malformed JSON in requests

---

## 6. Security Testing

### 6.1 Authentication & Authorization
- [ ] Verify unauthenticated requests are rejected
- [ ] Test session hijacking prevention
- [ ] Verify rate limiting prevents abuse

### 6.2 Input Validation
- [ ] Test SQL injection attempts
- [ ] Verify path traversal attacks are blocked
- [ ] Test XSS in chat messages
- [ ] Verify command injection is prevented

### 6.3 File System Security
- [ ] Test accessing files outside allowed paths
- [ ] Verify no access to system files
- [ ] Test deletion of protected files is blocked
- [ ] Verify file operations respect OS permissions

### 6.4 Data Privacy
- [ ] Verify no sensitive data in logs
- [ ] Test error messages don't expose paths
- [ ] Verify API keys are not exposed
- [ ] Check search queries are not logged with user data

---

## 7. Performance Testing

### 7.1 Response Times
- [ ] Search query completes in < 2 seconds
- [ ] Indexing processes 25 files in < 30 seconds
- [ ] Agent chat starts streaming in < 1 second
- [ ] Page load < 3 seconds

### 7.2 Memory Usage
- [ ] Check Flutter app memory stays < 500MB
- [ ] Verify no memory leaks during long sessions
- [ ] Test memory cleanup after closing app

### 7.3 Database Performance
- [ ] Query performance with 1000+ documents
- [ ] Vector search with pgvector enabled
- [ ] Verify query optimization

---

## 8. Browser Compatibility (Website)

- [ ] **Chrome**
  - [ ] Latest version
  - [ ] Test all features
- [ ] **Firefox**
  - [ ] Latest version
  - [ ] Test all features
- [ ] **Safari**
  - [ ] Latest version
  - [ ] Test all features
- [ ] **Edge**
  - [ ] Latest version
  - [ ] Test all features

---

## 9. Mobile Testing (Website)

- [ ] Test on iOS (Safari)
- [ ] Test on Android (Chrome)
- [ ] Verify touch interactions work
- [ ] Check mobile menu functions
- [ ] Test scroll animations on mobile

---

## 10. Regression Testing

After any code changes, re-run:
- [ ] Basic search functionality
- [ ] Indexing workflow
- [ ] Agent chat
- [ ] File operations
- [ ] Website navigation

---

## Test Results

| Test Category | Passed | Failed | Blocked | Notes |
|--------------|--------|--------|---------|-------|
| Website Frontend | [ ] | [ ] | [ ] | |
| Flutter App | [ ] | [ ] | [ ] | |
| Backend API | [ ] | [ ] | [ ] | |
| Integration | [ ] | [ ] | [ ] | |
| Edge Cases | [ ] | [ ] | [ ] | |
| Security | [ ] | [ ] | [ ] | |
| Performance | [ ] | [ ] | [ ] | |
| Browser Compatibility | [ ] | [ ] | [ ] | |

---

## Known Issues

| ID | Description | Severity | Status |
|----|-------------|----------|--------|
| | | | |

---

## Notes

Add any additional observations or issues found during testing:
