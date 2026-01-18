# Semantic Butler - Implementation Plan for Future Enhancements

**Version**: 2.0
**Created**: January 18, 2026
**Last Updated**: January 18, 2026
**Status**: Research-Complete - Ready for Development

---

## Executive Summary

This document outlines a strategic implementation plan for enhancing the Semantic Butler application. The plan is based on **actual codebase analysis** and prioritizes features based on **business impact**, **user value**, and **development effort**.

**Current State Analysis:**
- Backend: Serverpod + Dart + PostgreSQL with pgvector
- Frontend: Flutter 3.32.0, Dart 3.8.0, flutter_riverpod
- AI: OpenRouter integration (Gemini, Claude, GPT-4o, Llama, Mixtral)
- Platforms: Windows, macOS, Linux (cross-platform)
- Testing: Backend tests exist, minimal frontend tests

### Objectives
- Increase user adoption through better onboarding
- Differentiate from competitors with unique features
- Improve user retention with delight features
- Build sustainable revenue model with premium features

### Success Metrics
- Onboarding completion rate: >85%
- Daily active users (DAU): +40% within 3 months
- Conversion rate (free → paid): >5%
- App store rating: 4.5+ stars

---

## Current Feature Status

| Feature | Status | Implementation Details |
|----------|--------|---------------------|
| Search Result Preview | ✅ Fully Implemented | `contentPreview` (500 chars) stored during indexing in `FileIndex.contentPreview`, displayed in `search_result_card.dart:186-197` |
| Keyboard Shortcuts | 🟡 Partially Implemented | `shortcut_manager.dart` created with cross-platform shortcuts (Ctrl/Cmd+K, Ctrl/Cmd+1-5). **NOT YET INTEGRATED** into HomeScreen. |
| Context Menu Actions | ✅ Fully Implemented | Both "Ask Assistant" (`_openChatWithContext`) and "Summarize" (`_summarizeFile`) fully working in `file_manager_screen.dart:576-714`. Backend `summarizeFile` endpoint exists. |
| Voice Search | ❌ Not Implemented | Feature flag exists: `enableVoiceSearch = false` (per code review). No speech package in pubspec.yaml. |
| Onboarding Wizard | ❌ Not Implemented | `home_screen.dart:204-240` has basic "Welcome back" header. No tutorial, walkthrough, or first-run experience. |
| Smart File Organization | ❌ Not Implemented | `contentHash` computed in indexing (butler_endpoint.dart:652-657). No duplicate detection, naming analysis, or similarity grouping. |

---

## Technology Stack Analysis

### Frontend (Flutter)
- **Framework**: Flutter 3.32.0, Dart SDK ^3.8.0
- **State Management**: flutter_riverpod ^3.0.3
- **Key Dependencies**:
  - `bitsdojo_window: ^0.1.6` - Windows custom title bar
  - `file_picker: ^10.3.7` - File/folder selection
  - `serverpod_flutter: 3.1.0` - Client-server communication
  - `fl_chart: ^0.69.0` - Charts/graphs
  - `shared_preferences: ^2.5.4` - Settings persistence
  - `path_provider: ^2.1.5` - File system paths
  - `url_launcher: ^6.3.2` - Open files/URLs
  - `cupertino_icons: ^1.0.5` - iOS icons

### Backend (Serverpod)
- **Framework**: Serverpod 3.1.0, Dart SDK ^3.8.0
- **Database**: PostgreSQL with pgvector extension (vector similarity search)
- **Key Dependencies**:
  - `serverpod: 3.1.0` - Core framework
  - `crypto: ^3.0.7` - Hash generation
  - `pdf: ^3.11.3` - PDF extraction
  - `http: ^1.6.0` - HTTP client (OpenRouter)
  - `dotenv: ^4.2.0` - Environment variables
  - `watcher: ^1.1.0` - File system watching
  - `path: ^1.9.1` - Path manipulation

### AI Integration (OpenRouter)
- **Models Supported**: 200+ models via OpenRouter
  - **Embeddings**: Google Gemini Embedding, OpenAI text-embedding-3-small/large
  - **Chat**: Claude 3.5 Sonnet, GPT-4o, Gemini 2.5 Flash, Claude 3 Haiku
  - **Agent**: Claude 3.5 Haiku (default), Claude 3.5 Sonnet
- **Routing Strategy**: Task complexity-based model selection (trivial → critical)
- **Cost Tracking**: Built-in token counting and cost estimation

### Testing
- **Frontend**: `widget_test.dart` exists (template only, no tests)
- **Backend**: 18 test files (unit + integration)
  - Services tested: validation, rate_limit, auth, cache, metrics, file_operations, file_extraction
  - Integration tested: ai_search, vector_search, auto_indexing, transactions, lock_service, serverpod_sanity, error_recovery, lock_hardening, greeting_endpoint

### Platforms
- **Windows**: Primary target (custom title bar with bitsdojo_window)
- **macOS**: Fully supported (standard Flutter macOS app)
- **Linux**: Fully supported (standard Flutter Linux app)
- **Web**: Supported (Flutter build web with --wasm flag)

---



### File Tagging Pattern
Existing codebase has `FileTaggingMixin` (`lib/mixins/file_tagging_mixin.dart`) that manages:
- File tagging with `@file` syntax in ChatScreen
- Keyboard navigation through tagged files (up/down arrows)
- Context menu integration
- This pattern should be followed for new context menu features.

### Context Menu Integration Point
The context menu is implemented as `ModalBottomSheet` (Material 3 bottom sheet) in `file_manager_screen.dart`. This is a **Flutter-internal** context menu (right-click on file in app), **not a system-wide** context menu (Windows Explorer/macOS Finder).

**Clarification**: This implementation plan focuses on **internal context menu** to complete existing placeholder features ("Ask Assistant", "Summarize"). System-wide context menu would require significant platform-specific work (separate priority P2 feature).

### Backend Patterns
All backend services follow these patterns:
- Located in `lib/src/services/`
- Use Serverpod's `Session` for database access
- Leverage existing `FileExtractionService` for text extraction
- Use protocol models (`.spy.yaml` → generated Dart)

New features should:
- Add services to `lib/src/services/`
- Add protocol models to `lib/src/models/` with `.spy.yaml`
- Register endpoints in `lib/src/endpoints/` (extend existing ButlerEndpoint or create new)

### Search Result Preview (Already Documented)
**Status**: ✅ Fully Implemented

This feature is **already complete** and working:
- **Backend**: `FileExtractionService.extractText()` generates preview (first 500 characters) during indexing
- **Database**: Stored in `FileIndex.contentPreview` column
- **Protocol**: `SearchResult.contentPreview` field in client model
- **Frontend**: Displayed in `search_result_card.dart:186-197` (up to 3 lines with ellipsis)

**Implementation Plan Change**: No development work needed. Feature documented for reference only.

---

## Phase 1: Quick Wins (Week 1-2)

**Goal**: Deliver immediate user value by completing partially-implemented features and adding missing UX enhancements.

**Quick Wins Overview**:
| Feature | Status | Notes |
|----------|--------|-------|
| Search result preview | ✅ Already Done | Fully implemented, no work needed |
| Global keyboard shortcuts | 🔴 Not Started | Partially implemented (file tag overlay only) |
| Complete context menu actions | 🔴 Not Started | Placeholder features need implementation |                

### 1.1 Global Keyboard Shortcuts

**Priority**: P0 (Critical)
**Effort**: 2 hours (service exists, needs integration only)
**Impact**: High UX improvement
**Developer**: Frontend
**Status**: 🟡 Service Created - Needs Integration

**User Value**: Power users can navigate and perform actions 3x faster.

**Current State Analysis**:
- ✅ `shortcut_manager.dart` EXISTS with all shortcut definitions
- ✅ `FocusSearchIntent` and `NavigateTabIntent` intents defined
- ✅ Cross-platform shortcuts (Ctrl+K/Cmd+K, Ctrl/Cmd+1-5)
- ❌ NOT integrated into HomeScreen (no Shortcuts widget wrapper)
- ❌ No shortcut hints in UI

**Current State Analysis**:
- `file_tag_overlay.dart` uses `KeyboardListener` with `FocusNode` for local shortcuts
- Arrow keys (up/down), Enter to select, Escape to dismiss, Backspace to navigate up
- **No global shortcuts** for search focus, navigation, or actions

**Implementation Steps**:

1. **Create global shortcut manager using flutter_riverpod**
   ```dart
   // semantic_butler_flutter/lib/services/shortcut_manager.dart
   // Uses existing riverpod pattern from providers/
   import 'package:flutter/material.dart';

   final shortcutProvider = Provider<ShortcutManager>((ref) {
     return ShortcutManager();
   });

   class ShortcutManager {
     static const Map<LogicalKeySet, Intent> globalShortcuts = {
       // Search shortcuts (cross-platform)
       LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
         FocusSearchIntent(),
       LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
         FocusSearchIntent(),

       // Navigation rail shortcuts
       LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit1):
         NavigateToIndexIntent(0), // Home
       LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit2):
         NavigateToIndexIntent(1), // Index
       LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit3):
         NavigateToIndexIntent(2), // Chat
       LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit4):
         NavigateToIndexIntent(3), // Files
       LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit5):
         NavigateToIndexIntent(4), // Settings
     };

     Intent? handleKeyPress(KeyEvent event) {
       // Implementation matching existing pattern from file_tag_overlay.dart
       if (event is! KeyDownEvent) return null;
       // ... handler logic
       return null;
     }
   }
   ```

2. **Integrate into existing HomeScreen navigation**
   ```dart
   // Modify existing semantic_butler_flutter/lib/screens/home_screen.dart
   class _HomeScreenState extends ConsumerState<HomeScreen> {
     // Add shortcut handling to existing _selectedIndex state

     @override
     Widget build(BuildContext context) {
       return Shortcuts(
         shortcuts: ShortcutManager.globalShortcuts,
         child: Actions(
           actions: <Type, Action<Intent>>{
             FocusSearchIntent: CallbackAction<FocusSearchIntent>(
               onInvoke: (_) => _showQuickSearch(context),
             ),
             NavigateToIndexIntent: CallbackAction<NavigateToIndexIntent>(
               onInvoke: (intent) => setState(() => _selectedIndex = intent!.index),
             ),
           },
           child: Focus(
             autofocus: true,
             child: Scaffold(/* existing structure */),
           ),
         ),
       );
     }
   }
   ```

3. **Add shortcut hints to existing UI elements**
   ```dart
   // Update semantic_butler_flutter/lib/widgets/search_bar_widget.dart
   // Add tooltip showing Ctrl+K/Meta+K
   trailing: [
     Tooltip(
       message: 'Focus search (Ctrl/Cmd+K)',
       child: Icon(Icons.search),
     ),
     // ... existing AI search button
   ]
   ```

4. **Create shortcut cheat sheet modal** (integrate into existing SettingsScreen)
   ```dart
   // Add to semantic_butler_flutter/lib/screens/settings_screen.dart
   showDialog(
     context: context,
     builder: (context) => AlertDialog(
       title: Text('Keyboard Shortcuts'),
       content: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           _ShortcutRow('Search', 'Ctrl/Cmd + K'),
           _ShortcutRow('Navigate Home', 'Ctrl/Cmd + 1'),
           _ShortcutRow('Navigate Index', 'Ctrl/Cmd + 2'),
           _ShortcutRow('Navigate Chat', 'Ctrl/Cmd + 3'),
         ],
       ),
     ),
   )
   ```

**Deliverables**:
- [ ] `shortcut_manager.dart` service (following riverpod patterns)
- [ ] Global shortcuts integrated into HomeScreen
- [ ] Shortcut hints in search bar tooltip
- [ ] Keyboard shortcuts modal in Settings
- [ ] Unit tests for shortcut actions
- [ ] Documentation update

**Acceptance Criteria**:
- All shortcuts work on Windows (Ctrl), macOS (Cmd), Linux (Ctrl)
- Search focuses with Ctrl+K/Cmd+K from any tab
- Navigation rail shortcuts (Ctrl/Cmd + 1-5) work
- Cheat sheet displays correctly with platform-specific shortcuts

---

### 1.2 Context Menu Actions (Complete Placeholder Features)

**Priority**: P0 (Critical)
**Effort**: ~~12 hours~~ **0 hours - COMPLETE**
**Impact**: High user value, complete existing features
**Developer**: Frontend + Backend
**Status**: ✅ **FULLY IMPLEMENTED**

**User Value**: Users can ask AI about files and get summaries directly from file manager.

**Implementation Complete**:
- ✅ "Ask Assistant" - `_openChatWithContext()` navigates to Chat with file context
- ✅ "Summarize" - `_summarizeFile()` calls backend, shows `SummaryDialog`
- ✅ Backend `summarizeFile` endpoint in `butler_endpoint.dart`
- ✅ Loading states and error handling implemented
- ✅ `SummaryDialog` widget shows formatted summary with "Ask Assistant" button

**No further work needed on this feature.**

**Current State Analysis**:
- Context menu exists in `file_manager_screen.dart:429-522`
- Uses `ModalBottomSheet` with `showModalBottomSheet()`
- **Implemented actions**: Remove from Index / Add to Index, Rename, Delete
- **Placeholder actions** (show snackbar "Feature coming soon"):
  - "Ask Assistant" - should open ChatScreen with file context
  - "Summarize" - should use existing summarization endpoint

**Implementation Steps**:

1. **Integrate "Ask Assistant" with ChatScreen**
   ```dart
   // Modify semantic_butler_flutter/lib/screens/file_manager_screen.dart
   void _askAssistant(FileSystemEntry entry) async {
     Navigator.pop(context); // Close context menu

     // Navigate to ChatScreen (tab index 2 in HomeScreen navigation)
     // Pass file context via state management or query parameters
     final homeScreenContext = context.findAncestorStateOfType<HomeScreenState>();
     if (homeScreenContext != null) {
       homeScreenContext!.setState(() {
         homeScreenContext!._selectedIndex = 2; // Navigate to Chat
       });

       // Add file context message
       final chatScreen = _getChatScreen(homeScreenContext!);
       if (chatScreen != null) {
         chatScreen.addFileContextMessage(entry);
       }
     }
   }
   ```

2. **Integrate "Summarize" with existing backend**
   ```dart
   // SummarizationService already exists in backend
   // Add to file_manager_screen.dart:
   void _summarizeFile(FileSystemEntry entry) async {
     Navigator.pop(context);

     // Show loading dialog
     showDialog(
       context: context,
       barrierDismissible: false,
       builder: (context) => Center(child: CircularProgressIndicator()),
     );

     try {
       // Call existing summarization endpoint (butler_endpoint.dart)
       // Note: SummarizationService.generateSummary() is internal
       // We need to expose it via endpoint
       final summary = await client.butler.summarizeFile(entry.path);

       // Show summary dialog
       Navigator.pop(context); // Close loading
       showDialog(
         context: context,
         builder: (context) => SummaryDialog(
           fileName: entry.name,
           summary: summary,
           onAsk: () => _askAssistant(entry),
         ),
       );
     } catch (e) {
       Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Failed to summarize: $e')),
       );
     }
   }
   ```

3. **Backend: Add summarizeFile endpoint**
   ```dart
   // Add to semantic_butler_server/lib/src/endpoints/butler_endpoint.dart
   Future<String> summarizeFile(
     Session session,
     String filePath,
   ) async {
     AuthService.requireAuth(session);

     // Get file content (reuse existing extraction service)
     final extraction = await _extractionService.extractText(filePath);

     // Use existing summarization service
     final summary = await SummarizationService.generateSummary(
       session,
       extraction.content,
       openRouterClient,
       fileName: extraction.fileName,
     );

     return summary.toJson();
   }
   ```

4. **Create summary dialog widget**
   ```dart
   // semantic_butler_flutter/lib/widgets/summary_dialog.dart
   class SummaryDialog extends StatelessWidget {
     final String fileName;
     final String summary;
     final VoidCallback onAsk;

     @override
     Widget build(BuildContext context) {
       return AlertDialog(
         title: Row(
           children: [
             Icon(Icons.summarize),
             SizedBox(width: 8),
             Expanded(child: Text('Summary: $fileName')),
           ],
         ),
         content: SingleChildScrollView(
           child: Text(summary),
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text('Close'),
           ),
           FilledButton(
             onPressed: () {
               Navigator.pop(context);
               onAsk();
             },
             child: Text('Ask Assistant'),
           ),
         ],
       );
     }
   }
   ```

**Deliverables**:
- [ ] "Ask Assistant" integration with ChatScreen
- [ ] "Summarize" endpoint in butler_endpoint.dart
- [ ] Summary dialog widget
- [ ] Error handling for large files
- [ ] Loading states for summarization

**Acceptance Criteria**:
- "Ask Assistant" opens Chat with file context added
- "Summarize" shows summary of file content
- Summary includes key points (1-3 sentences)
- Users can follow up with "Ask Assistant" from summary
- Errors handled gracefully with user-friendly messages

**Dependencies**:
- Uses existing `SummarizationService`
- Uses existing `FileExtractionService`
- Integrates with existing `ChatScreen` navigation (HomeScreen tab 2)

---

### 1.3 Search Result Preview Pane

**Priority**: P1 (High)
**Effort**: 8 hours
**Impact**: High UX improvement
**Developer**: Frontend

**User Value**: Users can view document content without leaving search results.

**Implementation Steps**:

1. **Create preview pane widget**
   ```dart
   // semantic_butler_flutter/lib/widgets/search/preview_pane.dart

   class PreviewPane extends ConsumerWidget {
     final String filePath;
     final String mimeType;

     @override
     Widget build(BuildContext context, WidgetRef ref) {
       return FutureBuilder<String>(
         future: _loadPreview(filePath),
         builder: (context, snapshot) {
           if (!snapshot.hasData) {
             return const Center(child: CircularProgressIndicator());
           }
           return _buildPreviewContent(snapshot.data!);
         },
       );
     }

     Widget _buildPreviewContent(String content) {
       if (mimeType.startsWith('image/')) {
         return Image.file(File(filePath));
       } else if (mimeType == 'application/pdf') {
         return PDFPreview(filePath: filePath);
       } else {
         return SelectableText(content);
       }
     }
   }
   ```

2. **Integrate into search results screen**
   ```dart
   // semantic_butler_flutter/lib/screens/search_results_screen.dart

   Row(
     children: [
       // Results list (takes 40% width)
       Expanded(
         flex: 4,
         child: ListView.builder(
           itemBuilder: (context, index) {
             return SearchResultCard(
               result: _results[index],
               isSelected: _selectedIndex == index,
               onTap: () => setState(() {
                 _selectedIndex = index;
               }),
             );
           },
         ),
       ),

       // Preview pane (takes 60% width)
       Expanded(
         flex: 6,
         child: _selectedIndex != null
           ? PreviewPane(
               filePath: _results[_selectedIndex!].path,
               mimeType: _results[_selectedIndex!].mimeType,
             )
           : Center(child: Text('Select a result to preview')),
       ),
     ],
   )
   ```

3. **Add preview toggle**
   - Button to show/hide preview pane
   - Remember user preference
   - Keyboard shortcut: `Ctrl+P` to toggle

4. **Enhance preview content**
   - Highlight search terms in preview
   - Show file metadata (size, modified date)
   - Add "Open in default app" button

**Deliverables**:
- [ ] `preview_pane.dart` widget
- [ ] Integration into search results screen
- [ ] Preview toggle functionality
- [ ] Search term highlighting
- [ ] Support for PDF, code, text, images

**Acceptance Criteria**:
- Preview pane loads within 500ms
- Selected result is highlighted
- Keyboard shortcut toggles preview
- Search terms are highlighted in preview

---

### 1.4 Animated Dashboard Metrics

**Priority**: P1 (High)
**Effort**: 4 hours
**Impact**: Visual polish, delight
**Developer**: Frontend

**User Value**: Dashboard feels more alive and responsive.

**Implementation Steps**:

1. **Create animated counter widget**
   ```dart
   // semantic_butler_flutter/lib/widgets/common/animated_counter.dart

   class AnimatedCounter extends StatefulWidget {
     final int value;
     final Duration duration;

     @override
     _AnimatedCounterState createState() => _AnimatedCounterState();
   }

   class _AnimatedCounterState extends State<AnimatedCounter>
       with SingleTickerProviderStateMixin {
     late AnimationController _controller;
     late Animation<double> _animation;

     @override
     void initState() {
       super.initState();
       _controller = AnimationController(
         duration: widget.duration,
         vsync: this,
       );
       _animation = Tween<double>(begin: 0, end: widget.value.toDouble())
           .animate(_controller);
       _controller.forward();
     }

     @override
     Widget build(BuildContext context) {
       return AnimatedBuilder(
         animation: _animation,
         builder: (context, child) {
           return Text(
             _animation.value.toInt().toString(),
             style: TextStyle(
               fontSize: 32,
               fontWeight: FontWeight.bold,
             ),
           );
         },
       );
     }
   }
   ```

2. **Apply to stats cards**
   ```dart
   // semantic_butler_flutter/lib/widgets/home/stats_card.dart

   StatsCard(
     title: 'Total Documents',
     value: AnimatedCounter(
       value: documentCount,
       duration: Duration(seconds: 1),
     ),
     icon: Icons.description,
   )
   ```

3. **Add progress circle animations**
   ```dart
   // Animated circular progress for indexing status
   AnimatedCircularProgressIndicator(
     value: _indexingProgress,
     duration: Duration(milliseconds: 500),
   )
   ```

4. **Add entrance animations**
   - Stagger fade-in for dashboard cards
   - Slide-up animation for sections
   - Use `FadeInAnimation` widget (already exists)

**Deliverables**:
- [ ] `animated_counter.dart` widget
- [ ] Animated circular progress indicator
- [ ] Applied to all dashboard metrics
- [ ] Smooth entrance animations

**Acceptance Criteria**:
- Numbers animate from 0 to value smoothly
- Progress bars animate smoothly
- Animations don't cause layout jank
- Performance: 60 FPS

---



**Goal**: Add high-value features that differentiate from competitors and increase user engagement.

**Phase 2 Overview**:
| Feature | Effort | Impact | Developer | Status |
|----------|--------|--------|-----------|--------|
| Interactive onboarding wizard | 16h | High conversion | Frontend | 🔴 Not Started |
| Voice search | 16h | High delight, accessibility | Frontend | 🔴 Not Started |
| Smart file organization | 24h | High unique value | Backend + Frontend | 🔴 Not Started |



**Priority**: P1 (High)
**Effort**: 16 hours
**Impact**: High delight, accessibility
**Developer**: Frontend + Platform-specific
**Status**: Not Implemented (feature flag disabled)

**User Value**: Users can search hands-free, which is faster and more accessible.

**Current State Analysis**:
- Feature flag exists: `enableVoiceSearch = false` (from code review)
- No speech recognition packages in `pubspec.yaml`
- Existing dependencies: `bitsdojo_window`, `file_picker`, `flutter_riverpod`, `fl_chart`

**Implementation Steps**:

1. **Add speech recognition package** (research needed - find best Flutter package for 2025)
   ```yaml
   # semantic_butler_flutter/pubspec.yaml

   dependencies:
     # Research needed: Best speech package for cross-platform support
     # Options to evaluate:
     # - speech_to_text (widely used, platform-specific)
     # - speech_to_text_pro (maintained fork)
     speech_to_text: ^6.6.0
   ```

2. **Create voice search widget** (following existing widget patterns)
   ```dart
   // semantic_butler_flutter/lib/widgets/voice_search_button.dart
   // Follow existing widget structure from widgets/search_bar_widget.dart
   import 'package:speech_to_text/speech_to_text.dart';

   class VoiceSearchButton extends StatefulWidget {
     final Function(String) onTranscript;

     @override
     _VoiceSearchButtonState createState() => _VoiceSearchButtonState();
   }

   class _VoiceSearchButtonState extends State<VoiceSearchButton> {
     SpeechToText _speech = SpeechToText();
     bool _isListening = false;
     String _transcript = '';

     @override
     void initState() {
       super.initState();
       _initSpeech();
     }

     void _initSpeech() async {
       final available = await _speech.initialize(
         onStatus: (status) {
           if (!mounted) return;
           setState(() {
             _isListening = status == SpeechToText.listening;
           });
         },
         onResult: (result) {
           if (!mounted) return;
           setState(() {
             _transcript = result.recognizedWords;
           });
           if (result.finalResult) {
             widget.onTranscript(_transcript);
           }
         },
         onError: (error) {
           // Handle permission denied, no speech detected
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Voice error: $error')),
           );
         },
       );

       if (!available) {
         // Show error if not available on platform
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Voice recognition not available')),
         );
       }
     }

     void _toggleListening() {
       if (_isListening) {
         _speech.stop();
       } else {
         _speech.listen(
           onResult: (result) {
             setState(() => _transcript = result.recognizedWords);
           },
           listenFor: Duration(seconds: 30),
           pauseFor: Duration(seconds: 3),
           partialResults: true,
           localeId: 'en_US',
         );
       }
     }

     @override
     Widget build(BuildContext context) {
       final colorScheme = Theme.of(context).colorScheme;

       return AnimatedContainer(
         duration: Duration(milliseconds: 200),
         decoration: BoxDecoration(
           shape: BoxShape.circle,
           color: _isListening
             ? colorScheme.errorContainer
             : Colors.transparent,
         ),
         child: IconButton(
           icon: Icon(
             Icons.mic,
             color: _isListening
               ? colorScheme.error
               : colorScheme.onSurfaceVariant,
           ),
           onPressed: _toggleListening,
           tooltip: 'Voice search',
         ),
       );
     }
   }
   ```

3. **Integrate into existing search bar widget**
   ```dart
   // Modify semantic_butler_flutter/lib/widgets/search_bar_widget.dart
   // Add to existing trailing array

   trailing: [
     if (widget.controller.text.isNotEmpty)
       IconButton(/* existing clear button */),
     if (widget.onAISearch != null)
       IconButton(/* existing AI search button */),

     // NEW: Voice search button
     VoiceSearchButton(
       onTranscript: (transcript) {
         widget.controller.text = transcript;
         widget.onSearch(transcript);
       },
     ),

     FilledButton(/* existing search button */),
     const SizedBox(width: 8),
   ]
   ```

4. **Add platform-specific permission handling**
   ```dart
   // Windows: No permissions needed
   // macOS: Add to macos/Runner/Info.plist
   // Linux: No permissions needed

   // macos/Runner/Info.plist
   <key>NSMicrophoneUsageDescription</key>
   <string>Semantic Butler needs microphone access for voice search</string>
   ```

5. **Add real-time transcript display**
   ```dart
   // Show while speaking (overlay or tooltip)
   Overlay(
     child: _isListening
       ? Positioned(
           bottom: 80,
           left: 20,
           right: 20,
           child: Material(
             elevation: 4,
             borderRadius: BorderRadius.circular(8),
             child: Padding(
               padding: EdgeInsets.all(12),
               child: Row(
                 children: [
                   CircularProgressIndicator(strokeWidth: 2),
                   SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       _transcript.isEmpty
                         ? 'Listening...'
                         : _transcript,
                       style: TextStyle(color: Colors.grey),
                     ),
                   ),
                 ],
               ),
             ),
           ),
         )
       : null,
   )
   ```

**Deliverables**:
- [ ] Add `speech_to_text` package to pubspec.yaml
- [ ] Voice search button widget
- [ ] Integration into search bar
- [ ] Real-time transcript overlay
- [ ] Platform permissions (macOS Info.plist)
- [ ] Error handling for permission denied
- [ ] Language detection (en-US default, allow user to change)

**Acceptance Criteria**:
- Voice search works on Windows, macOS, Linux
- Transcription accuracy >85% (subject to platform)
- Users can see real-time transcript while speaking
- Microphone permission requested correctly on first use
- Error messages are clear and actionable

**Dependencies**:
- Requires platform-specific speech recognition
- May need fallback for platforms without support

**Known Issues**:
- Linux support varies by distribution/DE
- Windows support depends on speech APIs (Win10/11 better)

---

### 2.3 Smart File Organization Suggestions

**Priority**: P1 (High)
**Effort**: 24 hours
**Impact**: High value, unique feature
**Developer**: Backend + Frontend
**Status**: Not Implemented

**User Value**: Proactive organization reduces manual work and storage waste.

**Current State Analysis**:
- Existing services in `semantic_butler_server/lib/src/services/`:
  - `FileExtractionService` - extracts text and computes contentHash
  - `FileIndex` model stores: path, fileName, contentHash, fileSizeBytes, tagsJson
- `contentHash` already computed during indexing (see butler_endpoint.dart:652-657)
- No duplicate detection, naming analysis, or similarity detection exists
- OpenRouter AI integration available (can use for semantic grouping)

**Implementation Steps**:

1. **Backend: Duplicate detection service** (reuse existing contentHash)
   ```dart
   // semantic_butler_server/lib/src/services/duplicate_detector.dart
   // Follows existing service patterns from services/

   import 'package:serverpod/serverpod.dart';
   import '../generated/protocol.dart';

   class DuplicateDetector {
     /// Find duplicate files by contentHash
     /// Uses existing contentHash from FileIndex (computed during indexing)
     Future<List<DuplicateGroup>> findDuplicates(
       Session session, {
       String? rootPath,
     }) async {
       // Get all files (or filter by root path)
       var query = FileIndex.db.find(session);

       if (rootPath != null) {
         query = query.where((t) => t.path.like('$rootPath%'));
       }

       final files = await query;

       // Group by contentHash
       final hashGroups = <String, List<FileIndex>>{};
       for (final file in files) {
         hashGroups.putIfAbsent(file.contentHash, () => []).add(file);
       }

       // Filter for duplicates (groups with >1 file)
       final duplicates = <DuplicateGroup>[];
       for (final entry in hashGroups.entries) {
         if (entry.value.length > 1) {
           final totalSize = entry.value
               .fold<int>(0, (sum, f) => sum + f.fileSizeBytes);

           duplicates.add(DuplicateGroup(
             hash: entry.key,
             files: entry.value,
             totalSize: totalSize,
             potentialSavings: totalSize - entry.value.first.fileSizeBytes,
             createdAt: DateTime.now(),
           ));
         }
       }

       // Sort by potential savings (largest duplicates first)
       duplicates.sort((a, b) => b.potentialSavings.compareTo(a.potentialSavings));

       return duplicates;
     }
   }

   // Models needed (add to models/ directory)
   class DuplicateGroup {
     final String hash;
     final List<FileIndex> files;
     final int totalSize;
     final int potentialSavings;
     final DateTime createdAt;
   }
   ```

2. **Backend: Naming inconsistency detection**
   ```dart
   // semantic_butler_server/lib/src/services/naming_analyzer.dart

   class NamingAnalyzer {
     Future<List<NamingIssue>> detectIssues(
       Session session, {
       String? rootPath,
     }) async {
       // Get all files (or filter by root path)
       var query = FileIndex.db.find(session);

       if (rootPath != null) {
         query = query.where((t) => t.path.like('$rootPath%'));
       }

       final files = await query;
       final issues = <NamingIssue>[];

       // Check 1: Mixed case (camelCase vs snake_case vs kebab-case)
       final camelCase = <FileIndex>[];
       final snakeCase = <FileIndex>[];
       final kebabCase = <FileIndex>[];
       final pascalCase = <FileIndex>[];

       for (final file in files) {
         final name = file.fileName;
         if (RegExp(r'[a-z][A-Z]').hasMatch(name)) {
           camelCase.add(file);
         } else if (name.contains('_') && name.contains('_')) {
           snakeCase.add(file);
         } else if (name.contains('-') && name.contains('-')) {
           kebabCase.add(file);
         } else if (RegExp(r'^[A-Z]').hasMatch(name) &&
             name.contains(RegExp(r'[A-Z][a-z]'))) {
           pascalCase.add(file);
         }
       }

       final caseTypes = [
         if (camelCase.isNotEmpty) 'camelCase',
         if (snakeCase.isNotEmpty) 'snake_case',
         if (kebabCase.isNotEmpty) 'kebab-case',
         if (pascalCase.isNotEmpty) 'PascalCase',
       ];

       if (caseTypes.length > 1) {
         issues.add(NamingIssue(
           type: 'inconsistent_case',
           description: 'Mix of naming conventions: ${caseTypes.join(", ")}',
           severity: 'warning',
           affectedFiles: [...camelCase, ...snakeCase, ...kebabCase, ...pascalCase]
               .map((f) => f.path)
               .toList(),
           suggestedFix: 'Standardize on one naming convention',
           createdAt: DateTime.now(),
         ));
       }

       // Check 2: Spaces in filenames
       final withSpaces = files.where((f) => f.fileName.contains(' ')).toList();
       final withoutSpaces = files.where((f) => !f.fileName.contains(' ')).toList();

       if (withSpaces.isNotEmpty && withoutSpaces.isNotEmpty) {
         // Issue if more than 20% have spaces (some is expected)
         final spaceRatio = withSpaces.length / files.length;
         if (spaceRatio > 0.2) {
           issues.add(NamingIssue(
             type: 'inconsistent_spacing',
             description: '${(spaceRatio * 100).toInt()}% of files contain spaces',
             severity: 'info',
             affectedFiles: withSpaces.map((f) => f.path).toList(),
             suggestedFix: 'Replace spaces with underscores or dashes',
             createdAt: DateTime.now(),
           ));
         }
       }

       // Check 3: Reserved characters or patterns
       final withReservedChars = files.where((f) {
         final name = f.fileName;
         return name.contains(RegExp(r'[<>:"|?*]')) ||
             name.contains(RegExp(r'^\.+$')) ||
             name.endsWith('.');
       }).toList();

       if (withReservedChars.isNotEmpty) {
         issues.add(NamingIssue(
           type: 'invalid_characters',
           description: '${withReservedChars.length} files contain reserved characters',
           severity: 'warning',
           affectedFiles: withReservedChars.map((f) => f.path).toList(),
           suggestedFix: 'Remove reserved characters: <>:"|?*',
           createdAt: DateTime.now(),
         ));
       }

       return issues;
     }
   }

   class NamingIssue {
     final String type;
     final String description;
     final String severity; // 'info', 'warning', 'error'
     final List<String> affectedFiles;
     final String? suggestedFix;
     final DateTime createdAt;
   }
   ```

3. **Backend: Similar content detection** (use existing embeddings)
   ```dart
   // semantic_butler_server/lib/src/services/similarity_analyzer.dart
   // Uses existing DocumentEmbedding and vector search (pgvector)

   class SimilarityAnalyzer {
     /// Find semantically similar documents using vector similarity
     /// Threshold: 0.85 (15% difference or less = similar)
     Future<List<SimilarContentGroup>> findSimilar(
       Session session, {
       double threshold = 0.85,
       int maxResults = 50,
     }) async {
       // Get all embeddings
       final embeddings = await DocumentEmbedding.db.find(session);

       final groups = <SimilarContentGroup>[];
       final processed = <int>{};

       // Use existing vector search from butler_endpoint.dart
       // Reuse pgvector operator: 1 - (a <=> b)
       for (final embedding in embeddings) {
         if (processed.contains(embedding.id)) continue;

         // Find similar using pgvector
         final similar = await _findSimilarViaPgvector(
           session,
           embedding.id,
           threshold,
         );

         if (similar.length > 1) {
           groups.add(SimilarContentGroup(
             similarityScore: similar.first.similarity,
             files: similar.map((s) => s.filePath).toList(),
             embeddingIds: similar.map((s) => s.id).toList(),
             createdAt: DateTime.now(),
           ));

           processed.addAll(similar.map((s) => s.id));
         }
       }

       // Sort by similarity (highest first)
       groups.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));

       return groups.take(maxResults).toList();
     }

     /// Find similar documents using pgvector
     /// Matches existing vector search pattern in butler_endpoint.dart:335-346
     Future<List<_SimilarFile>> _findSimilarViaPgvector(
       Session session,
       int embeddingId,
       double threshold,
     ) async {
       // Get the embedding vector
       final embedding = await DocumentEmbedding.db.findById(session, embeddingId);
       if (embedding == null) return [];

       // Query using pgvector cosine similarity
       final rows = await session.db.unsafeQuery('''
         SELECT
           de2.id,
           de2."fileIndexId",
           1 - (de1.embedding <=> de2.embedding) as similarity
         FROM document_embedding de1
         CROSS JOIN document_embedding de2
         WHERE de1.id = $1
           AND de1.id != de2.id
           AND 1 - (de1.embedding <=> de2.embedding) > $2
         ORDER BY de1.embedding <=> de2.embedding
         LIMIT 10
       ''', QueryParameters.positional([
         embeddingId,
         threshold,
       ]));

       return rows.map((row) => _SimilarFile(
         id: row['id'] as int,
         fileIndexId: row['fileIndexId'] as int,
         similarity: row['similarity'] as double,
       )).toList();
     }
   }

   class _SimilarFile {
     final int id;
     final int fileIndexId;
     final double similarity;
   }

   class SimilarContentGroup {
     final double similarityScore;
     final List<String> files;
     final List<int> embeddingIds;
     final DateTime createdAt;
   }
   ```

4. **Backend: Add endpoint to ButlerEndpoint** (or create new OrganizationEndpoint)
   ```dart
   // Add to semantic_butler_server/lib/src/endpoints/butler_endpoint.dart

   /// Get file organization suggestions (duplicates, naming issues, similar files)
   Future<OrganizationSuggestions> getOrganizationSuggestions(
     Session session, {
     String? rootPath,
   }) async {
     AuthService.requireAuth(session);

     // Run analyses in parallel for performance
     final results = await Future.wait([
       DuplicateDetector().findDuplicates(session, rootPath: rootPath),
       NamingAnalyzer().detectIssues(session, rootPath: rootPath),
       SimilarityAnalyzer().findSimilar(session),
     ]);

     return OrganizationSuggestions(
       duplicates: results[0] as List<DuplicateGroup>,
       namingIssues: results[1] as List<NamingIssue>,
       similarContent: results[2] as List<SimilarContentGroup>,
       analyzedAt: DateTime.now(),
     );
   }

   /// Apply a suggested fix for duplicate files
   Future<FileOperationResult> applyDuplicateFix(
     Session session,
     String fileHash,
     String action,
   ) async {
     // Actions: 'keep_newest', 'keep_oldest', 'delete_all_except_one'
     // This would integrate with existing FileOperationsService
     // Implementation depends on business rules for deletion

     return FileOperationResult(
       success: true,
       message: 'Applied fix: $action for duplicates',
       affectedFiles: 0,
     );
   }

   // Protocol models (add to models/ or generate via .spy.yaml)
   class OrganizationSuggestions {
     final List<DuplicateGroup> duplicates;
     final List<NamingIssue> namingIssues;
     final List<SimilarContentGroup> similarContent;
     final DateTime analyzedAt;
   }
   ```

5. **Frontend: Organization suggestions screen** (add to existing screens/)
   ```dart
   // semantic_butler_flutter/lib/screens/organization_screen.dart
   // Follows existing screen patterns (HomeScreen, SettingsScreen)
   import 'package:flutter/material.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:semantic_butler_client/semantic_butler_client.dart';

   class OrganizationScreen extends ConsumerWidget {
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final colorScheme = Theme.of(context).colorScheme;

       return Scaffold(
         appBar: AppBar(
           title: Text('Organization Suggestions'),
           actions: [
             IconButton(
               icon: Icon(Icons.refresh),
               onPressed: () => _refresh(),
               tooltip: 'Re-analyze',
             ),
           ],
         ),
         body: FutureBuilder<OrganizationSuggestions>(
           future: client.butler.getOrganizationSuggestions(),
           builder: (context, snapshot) {
             if (snapshot.connectionState == ConnectionState.waiting) {
               return Center(child: CircularProgressIndicator());
             }

             if (snapshot.hasError) {
               return Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.error_outline, size: 64),
                     SizedBox(height: 16),
                     Text('Failed to analyze: ${snapshot.error}'),
                   ],
                 ),
               );
             }

             final suggestions = snapshot.data!;

             if (suggestions.duplicates.isEmpty &&
                 suggestions.namingIssues.isEmpty &&
                 suggestions.similarContent.isEmpty) {
               return Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                     SizedBox(height: 16),
                     Text(
                       'Great job!',
                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                     ),
                     SizedBox(height: 8),
                     Text('No organization issues found.'),
                   ],
                 ),
               );
             }

             return ListView(
               padding: EdgeInsets.all(16),
               children: [
                 // Duplicates section
                 if (suggestions.duplicates.isNotEmpty) ...[
                   SectionHeader(
                     title: 'Duplicates (${suggestions.duplicates.length})',
                     icon: Icons.content_copy,
                     color: colorScheme.error,
                   ),
                   SizedBox(height: 8),
                   ...suggestions.duplicates.map((dup) => DuplicateCard(
                     duplicate: dup,
                     onApply: (action) => _applyFix(dup.hash, action),
                   )),
                   SizedBox(height: 24),
                 ],

                 // Naming issues section
                 if (suggestions.namingIssues.isNotEmpty) ...[
                   SectionHeader(
                     title: 'Naming Issues (${suggestions.namingIssues.length})',
                     icon: Icons.edit_note,
                     color: colorScheme.warning,
                   ),
                   SizedBox(height: 8),
                   ...suggestions.namingIssues.map((issue) => NamingIssueCard(
                     issue: issue,
                   )),
                   SizedBox(height: 24),
                 ],

                 // Similar content section
                 if (suggestions.similarContent.isNotEmpty) ...[
                   SectionHeader(
                     title: 'Similar Documents (${suggestions.similarContent.length})',
                     icon: Icons.link,
                     color: colorScheme.primary,
                   ),
                   SizedBox(height: 8),
                   ...suggestions.similarContent.map((group) => SimilarContentCard(
                     group: group,
                   )),
                 ],
               ],
             ],
           );
         },
       ),
       );
     }
   }

   class SectionHeader extends StatelessWidget {
     final String title;
     final IconData icon;
     final Color color;

     @override
     Widget build(BuildContext context) {
       return Row(
         children: [
           Icon(icon, color: color, size: 24),
           SizedBox(width: 8),
           Text(
             title,
             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
           ),
         ],
       );
     }
   }

   // Add to NavigationRail in HomeScreen (new destination)
   NavigationRailDestination(
     icon: Icon(Icons.inventory_2_outlined),
     selectedIcon: Icon(Icons.inventory_2),
     label: Text('Organize'),
   )
   ```

**Deliverables**:
- [ ] `DuplicateDetector` service (in services/)
- [ ] `NamingAnalyzer` service (in services/)
- [ ] `SimilarityAnalyzer` service (in services/, reuses pgvector)
- [ ] `getOrganizationSuggestions` endpoint in ButlerEndpoint
- [ ] `OrganizationSuggestions` protocol model (.spy.yaml)
- [ ] `OrganizationScreen` frontend widget
- [ ] Duplicate cards with potential savings display
- [ ] Naming issue cards with severity indicators
- [ ] Similar content cards showing related files
- [ ] NavigationRail integration (new tab in HomeScreen)

**Acceptance Criteria**:
- Duplicates detected by contentHash (100% accurate for identical files)
- Naming issues identify mixed conventions (>20% threshold)
- Similar content uses vector similarity (>85% threshold)
- Duplicate cards show potential storage savings
- Users can browse duplicate groups and understand which to keep
- Naming suggestions explain the issue and provide fix
- Similar content shows related documents for manual review

**Dependencies**:
- Reuses existing `FileIndex` model (contentHash already computed)
- Reuses existing `DocumentEmbedding` model (pgvector already configured)
- Integrates with existing `FileOperationsService` for applying fixes
- Adds to existing navigation structure (HomeScreen NavigationRail)

---

## Phase 3: Medium-Priority Features (Week 5-8)

### 3.1 Advanced Search Features

**Priority**: P2 (Medium)
**Effort**: 20 hours
**Impact**: High UX improvement
**Developer**: Frontend + Backend

**Features**:
1. **Query suggestions/autocomplete**
   - Implement trie-based autocomplete
   - Search history integration
   - Tag-based suggestions

2. **Advanced filters**
   - Date range picker
   - File type filter
   - Tag filter
   - Size filter

3. **Saved searches**
   - Save search queries
   - Quick-access buttons
   - Share saved searches

**Implementation**:
```dart
// semantic_butler_flutter/lib/widgets/search/advanced_filters.dart

class AdvancedFilters extends StatefulWidget {
  @override
  _AdvancedFiltersState createState() => _AdvancedFiltersState();
}

class _AdvancedFiltersState extends State<AdvancedFilters> {
  DateTimeRange? _dateRange;
  List<String> _selectedTypes = [];
  List<String> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text('Advanced Filters'),
        children: [
          // Date range picker
          ListTile(
            title: Text('Date Range'),
            subtitle: _dateRange != null
              ? '${_dateRange!.start} - ${_dateRange!.end}'
              : 'Any time',
            trailing: Icon(Icons.calendar_today),
            onTap: () => _showDatePicker(),
          ),

          // File type filter
          ListTile(
            title: Text('File Types'),
            subtitle: _selectedTypes.join(', '),
            onTap: () => _showTypeSelector(),
          ),

          // Tag filter
          ListTile(
            title: Text('Tags'),
            subtitle: _selectedTags.join(', '),
            onTap: () => _showTagSelector(),
          ),

          // Apply button
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => _applyFilters(),
              child: Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### 3.2 Natural Language File Operations

**Priority**: P2 (Medium)
**Effort**: 24 hours
**Impact**: High value, unique
**Developer**: Backend (Agent endpoint)

**Features**:
- "Move all tax documents to /Finance/Tax2024"
- "Find all PDFs larger than 10MB and move to /Archive"
- "Rename all files with 'Untitled' to 'Document [date]'"
- "Create folder structure by year and move files accordingly"

**Implementation**:
```dart
// semantic_butler_server/lib/services/file_operation_interpreter.dart

class FileOperationInterpreter {
   Future<FileOperationPlan> interpret(
     Session session,
     String command,
   ) async {
     // 1. Parse command with AI
     final intent = await _parseIntent(command);

     // 2. Execute search to find matching files
     final files = await _findMatchingFiles(session, intent);

     // 3. Preview operation
     final plan = FileOperationPlan(
       operation: intent.operation,
       affectedFiles: files,
       previewMessage: _generatePreview(intent, files.length),
     );

     return plan;
   }

   Future<Intent> _parseIntent(String command) async {
     final prompt = '''
       Parse the following command into a structured intent:

       Command: "$command"

       Output JSON:
       {
         "operation": "move|copy|rename|delete",
         "filters": {
           "fileTypes": ["pdf", "docx"],
           "size": {"min": 0, "max": 10485760},
           "namePattern": "*Untitled*"
         },
         "destination": "/path/to/destination",
         "newNamePattern": "Document {date}"
       }
     ''';

     final response = await AIService().generate(prompt);
     return Intent.fromJson(jsonDecode(response));
   }
}
```

---


**Priority**: P2 (Medium)
**Effort**: 32 hours
**Impact**: Delight, unique feature
**Developer**: Frontend

**Implementation**:
```dart
// semantic_butler_flutter/lib/widgets/knowledge/knowledge_graph.dart

class KnowledgeGraph extends StatefulWidget {
   final String? query;

   @override
   _KnowledgeGraphState createState() => _KnowledgeGraphState();
}

class _KnowledgeGraphState extends State<KnowledgeGraph> {
   @override
   Widget build(BuildContext context) {
     return InteractiveViewer(
       constrained: false,
       boundaryMargin: EdgeInsets.all(100),
       child: CustomPaint(
         size: Size.infinite,
         painter: _GraphPainter(
           nodes: _buildNodes(),
           edges: _buildEdges(),
           onNodeTap: _onNodeTap,
         ),
       ),
     );
   }
}

class _GraphPainter extends CustomPainter {
   final List<GraphNode> nodes;
   final List<GraphEdge> edges;
   final Function(GraphNode) onNodeTap;

   _GraphPainter({
     required this.nodes,
     required this.edges,
     required this.onNodeTap,
   });

   @override
   void paint(Canvas canvas, Size size) {
     // Draw edges
     final edgePaint = Paint()
       ..color = Colors.grey.withOpacity(0.3)
       ..strokeWidth = 1;

     for (final edge in edges) {
       final from = nodes.firstWhere((n) => n.id == edge.from);
       final to = nodes.firstWhere((n) => n.id == edge.to);

       canvas.drawLine(
         from.position,
         to.position,
         edgePaint,
       );
     }

     // Draw nodes
     for (final node in nodes) {
       final paint = Paint()
         ..color = node.color
         ..style = PaintingStyle.fill;

       canvas.drawCircle(node.position, node.radius, paint);

       // Draw label
       final textPainter = TextPainter(
         text: TextSpan(
           text: node.label,
           style: TextStyle(fontSize: 12),
         ),
         textDirection: TextDirection.ltr,
       );

       textPainter.layout();
       textPainter.paint(
         canvas,
         node.position - Offset(textPainter.width / 2, node.radius + 8),
       );
     }
   }

   @override
   bool shouldRepaint(_GraphPainter oldDelegate) {
     return true;
   }
}
```

---

## Phase 4: Future-Ready Enhancements (Week 9-12+)

### 4.1 AI-Driven Insights

**Priority**: P3 (Low-Medium)
**Effort**: 40 hours
**Impact**: High delight

**Features**:
- "You search for tax documents most in April"
- "I noticed you have 50 untagged PDFs. Want me to organize them?"
- "You often move invoices to /Finance. Want to automate this?"

