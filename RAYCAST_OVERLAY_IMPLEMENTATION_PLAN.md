# Raycast-Style Hotkey Search Overlay - Refined Implementation Plan

## Executive Summary

Build a global hotkey-triggered overlay window (Raycast-style) that provides instant access to Filo's AI-powered natural language search from anywhere on the desktop.

**Key Differentiator from Original Plan**: This refined plan is based on thorough analysis of the existing codebase architecture, identifying actual integration points with existing providers, services, and UI components.

---

## Part 1: Existing Codebase Analysis

### Current Architecture

#### Window Management
- **Package**: `bitsdojo_window` (already in use at `lib/widgets/window_title_bar.dart:1`)
- **Main Window Config**: Located in `main.dart:111-126`
  - Initial size: 1280x720
  - Min size: 800x600
  - Uses `doWhenWindowReady()` for desktop setup
  - **Implication**: Need to migrate from `bitsdojo_window` to `window_manager` for overlay support, OR use `window_manager` alongside existing setup

#### Key Providers to Integrate
| Provider | Location | Purpose for Overlay |
|----------|----------|---------------------|
| `clientProvider` | `main.dart:28-35` | AI chat, search via `agent.streamChat()` |
| `settingsProvider` | `lib/services/settings_service.dart:6-8` | Store hotkey preferences |
| `chatHistoryProvider` | `lib/providers/chat_history_provider.dart:12-15` | Recent queries for suggestions |
| `navigationProvider` | `lib/providers/navigation_provider.dart:108-111` | Navigate to main app from overlay |
| `conversationalSearchProvider` | `lib/providers/conversational_search_provider.dart:274-279` | Search context & suggestions |

#### Existing Reusable Components
| Component | Location | Reuse Potential |
|-----------|----------|-----------------|
| `CommandPaletteOverlay` | `lib/widgets/command_palette_overlay.dart:16` | Base for overlay UI |
| `SlashCommandMixin` | `lib/mixins/slash_command_mixin.dart:4` | Command handling |
| `ChatInputArea` | `lib/widgets/chat/chat_input_area.dart` | Input widget reference |
| `AutoGrowTextField` | `lib/widgets/chat/auto_grow_text_field.dart` | Text input |
| `SearchResultCard` | `lib/widgets/search_result_card.dart` | Result display |

#### API Endpoints Available
```dart
// From semantic_butler_client/lib/src/protocol/client.dart

client.agent.streamChat(message, conversationHistory)  // AI chat (line 83-98)
client.butler.aiSearch(query, strategy, maxResults)     // AI search (line 594-613)
client.butler.hybridSearch(query, ...)                   // Hybrid search (line 524-544)
client.butler.semanticSearchStream(query, ...)           // Semantic search (line 147-168)
client.butler.getSearchFacets(query, filters)            // Faceted search (line 208-218)
```

#### Existing UI Patterns
- **Search Results**: `lib/screens/search_results_screen.dart` - Complete search implementation with AI/semantic/hybrid modes
- **Chat Screen**: `lib/screens/chat_screen.dart` - Streaming chat with tool results
- **Slash Commands**: `/search`, `/organize`, `/index`, `/clear` already defined

---

## Part 2: Technical Approach

### Architecture Decision: Single App with Two Modes

Rather than creating a separate overlay window (which conflicts with `bitsdojo_window`), we'll implement the overlay as an **in-app overlay** that can be shown/hidden via global hotkey.

```
┌─────────────────────────────────────────────────────────────┐
│                 Filo Application (Main Window)              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Normal App Mode                         │   │
│  │         [Home | Chat | Files | Settings]            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │           Overlay Mode (triggered by hotkey)         │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │  🔍  Search files or ask AI...                │   │   │
│  │  ├──────────────────────────────────────────────┤   │   │
│  │  │  📁 Index current folder                      │   │   │
│  │  │  🔎 Recent: "project proposal PDF"           │   │   │
│  │  │  🤖 Ask: "summarize my downloads"            │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Why This Approach?

1. **Compatibility**: Works with existing `bitsdojo_window` setup
2. **Simpler**: No need to manage multiple windows or complex inter-window communication
3. **Performance**: Shared state, single client connection
4. **User Experience**: App can run minimized to tray, overlay appears instantly

### Package Changes

```yaml
# Add to pubspec.yaml
dependencies:
  hotkey_manager: ^0.4.0        # Global hotkey registration
  window_manager: ^0.4.0        # For window control (minimize/hide)
  tray_manager: ^0.2.0          # Optional: Run in system tray
```

**Note**: Keep `bitsdojo_window` for main window, add `window_manager` for additional control.

---

## Part 3: Implementation Plan

### Phase 1: Global Hotkey Service Foundation

**Goal**: Register system-wide hotkey that shows/hides the overlay

#### 1.1 Create Hotkey Service
**File**: `lib/services/global_hotkey_service.dart`

```dart
class GlobalHotkeyService {
  Hotkey? _overlayHotkey;
  bool _isOverlayVisible = false;

  // Platform-specific defaults
  static const _macHotkey = Hotkey(KeyCode.key Space, modifiers: [KeyCode.option]);
  static const _windowsHotkey = Hotkey(KeyCode.keySpace, modifiers: [KeyCode.alt]);
  static const _linuxHotkey = Hotkey(KeyCode.keySpace, modifiers: [KeyCode.control, KeyCode.alt]);

  Future<void> initialize(VoidCallback onToggle) async {
    final hotkey = _getPlatformHotkey();
    await HotkeyManager.instance.register(
      hotkey,
      keyPressedCallback: (_) => onToggle(),
    );
    _overlayHotkey = hotkey;
  }

  Future<void> unregister() async {
    if (_overlayHotkey != null) {
      await HotkeyManager.instance.unregister(_overlayHotkey!);
    }
  }
}
```

#### 1.2 Update Settings Service
**File**: `lib/services/settings_service.dart`

Add overlay settings to `AppSettings`:
```dart
class AppSettings {
  // ... existing fields
  final bool overlayEnabled;
  final String overlayHotkey;
  final bool startMinimized;
}
```

#### 1.3 Modify Main Entry Point
**File**: `main.dart`

Changes needed:
1. Initialize `GlobalHotkeyService` after `runApp()`
2. Add overlay state management at app root
3. Handle hotkey callback to toggle overlay visibility

---

### Phase 2: Overlay UI Implementation

#### 2.1 Create Overlay Screen
**File**: `lib/screens/overlay_screen.dart`

Based on existing `SearchResultsScreen` pattern:
```dart
class OverlayScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends ConsumerState<OverlayScreen> {
  // Search input controller
  // Query state
  // Results state
  // Integration with clientProvider.agent.streamChat()
}
```

#### 2.2 Overlay Widgets Structure
```
lib/widgets/overlay/
├── overlay_container.dart          # Main backdrop & container
├── overlay_search_bar.dart         # Search input (reuse AutoGrowTextField)
├── overlay_results_list.dart       # Results (reuse SearchResultCard)
├── overlay_quick_actions.dart      # Quick actions row
└── overlay_ai_response.dart        # Streaming AI response view
```

#### 2.3 Integrate with Existing Command Palette
Extend `CommandPaletteOverlay` from `lib/widgets/command_palette_overlay.dart:16`:
- Add overlay-specific commands: `/open`, `/hide`, `/focus`
- Reuse keyboard navigation (arrow keys, enter, escape)

---

### Phase 3: State Management Integration

#### 3.1 Create Overlay Provider
**File**: `lib/providers/overlay_provider.dart`

```dart
class OverlayState {
  final bool isVisible;
  final String searchQuery;
  final List<dynamic> results;
  final bool isLoading;
}

class OverlayNotifier extends Notifier<OverlayState> {
  @override
  OverlayState build() => OverlayState(isVisible: false);

  void show() => state = state.copyWith(isVisible: true);
  void hide() => state = state.copyWith(isVisible: false);
  void toggle() => state = state.copyWith(isVisible: !state.isVisible);
  void setQuery(String query) => state = state.copyWith(searchQuery: query);
}

final overlayProvider = NotifierProvider<OverlayNotifier, OverlayState>(
  OverlayNotifier.new,
);
```

#### 3.2 Connect to Existing Providers
```dart
// In overlay_screen.dart
final client = ref.watch(clientProvider);
final history = ref.watch(chatHistoryProvider);
final settings = ref.watch(settingsProvider);
```

---

### Phase 4: AI & Search Integration

#### 4.1 Natural Language Search
Reuse pattern from `search_results_screen.dart:89-130`:

```dart
Future<void> _performAISearch(String query) async {
  final apiClient = ref.read(clientProvider);

  await for (final event in apiClient.butler.aiSearch(
    query,
    strategy: 'hybrid',
    maxResults: 10,
  )) {
    // Handle AISearchProgress events
    // Update overlay UI
  }
}
```

#### 4.2 Quick Actions Mapping
| Action | Implementation |
|--------|----------------|
| Index current folder | `client.butler.startIndexing(path)` |
| Search recent files | `client.butler.getSearchHistory()` |
| Ask AI | `client.agent.streamChat(message)` |
| Open in app | `ref.read(navigationProvider).navigateTo(index)` |

---

### Phase 5: Window Behavior & Polish

#### 5.1 Window States
```dart
enum AppWindowState {
  normal,      // Full window visible
  minimized,   // Hidden to tray/taskbar
  overlay,     // Overlay mode only (semi-transparent)
}
```

#### 5.2 Animation Controller
```dart
// Smooth fade-in/out
const _overlayAnimationDuration = Duration(milliseconds: 150);

void _animateOverlayIn() {
  // Scale: 0.95 -> 1.0
  // Opacity: 0 -> 1
  // Curve: Curves.easeOutCubic
}
```

#### 5.3 Keyboard Shortcuts
Reuse from `shortcut_manager.dart:18-51`:
- Add overlay-specific shortcuts
- Handle Escape to hide overlay
- Arrow navigation for results

---

## Part 4: Platform-Specific Configuration

### macOS
**File**: `macos/Runner/Info.plist`

Add accessibility permission description:
```xml
<key>NSAccessibilityUsageDescription</key>
<string>Filo needs accessibility access to respond to global hotkeys.</string>
```

Default hotkey: `Option+Space` (like Raycast)

### Windows
**File**: `windows/runner/main.cpp` or `win32_window.cpp`

Ensure window can be minimized/hidden:
- Add WS_EX_TOOLWINDOW style for background mode
- Handle hotkey via Windows API

Default hotkey: `Alt+Space`

### Linux
**File**: `linux/my_application.cc`

Register X11 hotkey or use GTK keybinder

Default hotkey: `Ctrl+Alt+Space`

---

## Part 5: File Structure Summary

```
lib/
├── services/
│   ├── global_hotkey_service.dart      # NEW: Hotkey registration
│   ├── overlay_window_service.dart     # NEW: Window state mgmt
│   ├── settings_service.dart           # MODIFY: Add overlay settings
│   └── ...
├── providers/
│   ├── overlay_provider.dart           # NEW: Overlay state
│   ├── clientProvider (existing)
│   ├── navigationProvider (existing)
│   └── ...
├── screens/
│   ├── overlay_screen.dart             # NEW: Main overlay
│   ├── search_results_screen.dart      # REFERENCE: Reuse patterns
│   └── ...
├── widgets/
│   ├── overlay/
│   │   ├── overlay_container.dart
│   │   ├── overlay_search_bar.dart
│   │   ├── overlay_results_list.dart
│   │   ├── overlay_quick_actions.dart
│   │   └── overlay_ai_response.dart
│   ├── command_palette_overlay.dart    # EXTEND: Add overlay commands
│   ├── search_result_card.dart         # REUSE: For results
│   ├── chat/auto_grow_text_field.dart  # REUSE: For input
│   └── ...
├── mixins/
│   ├── slash_command_mixin.dart        # EXTEND: Add overlay commands
│   └── ...
└── main.dart                            # MODIFY: Init overlay service
```

---

## Part 6: Success Criteria

### Functional Requirements
- [ ] Global hotkey works when app is in background/minimized
- [ ] Overlay appears centered on active monitor
- [ ] Search input auto-focuses on show
- [ ] Natural language queries return AI responses
- [ ] Results can be opened in main app
- [ ] Quick actions execute successfully
- [ ] Smooth animations (no flicker)
- [ ] Escape key closes overlay
- [ ] Arrow keys navigate results

### Platform Support
- [ ] macOS: Option+Space default
- [ ] Windows: Alt+Space default
- [ ] Linux: Ctrl+Alt+Space default

### Integration Points Verified
- [ ] Reuses `clientProvider` for all API calls
- [ ] Reuses `chatHistoryProvider` for suggestions
- [ ] Reuses `navigationProvider` for app navigation
- [ ] Reuses existing search result widgets
- [ ] Reuses slash command patterns

---

## Part 7: Implementation Order (Priority)

1. **Week 1**: Hotkey service + Settings integration
   - Create `GlobalHotkeyService`
   - Update `AppSettings` with overlay preferences
   - Platform-specific hotkey defaults

2. **Week 2**: Overlay UI scaffold
   - Create `OverlayScreen`
   - Build `OverlayContainer` widget
   - Implement show/hide with animations

3. **Week 3**: Search integration
   - Connect to `clientProvider.agent.streamChat()`
   - Implement result display
   - Add keyboard navigation

4. **Week 4**: Polish & platform testing
   - Multi-monitor positioning
   - Platform-specific testing
   - Performance optimization

---

## Part 8: Open Questions & Decisions Needed

1. **Minimize to Tray**: Should the app support running purely in background?
   - Requires `tray_manager` package
   - User preference: "Start minimized" setting

2. **Single vs Multi-Window**: Proceed with single-window overlay approach?
   - Alternative: Use `window_manager` for separate overlay window
   - Trade-off: Complexity vs. cleaner separation

3. **Result Actions**: When user selects a search result, should it:
   - Open in main app (bring window to front)?
   - Show preview in overlay?
   - Execute action directly (open file)?

4. **Offline Mode**: Should overlay work when server is unavailable?
   - Show cached results only?
   - Display "Connecting..." state?

---

## Sources

- [Raycast Manual - Hotkey](https://manual.raycast.com/hotkey)
- [hotkey_manager package](https://pub.dev/packages/hotkey_manager)
- [window_manager package](https://pub.dev/packages/window_manager)
- [Develop a Global Hotkey Desktop App with Flutter](https://www.kuaiyizhi.cn/en/lessons/build_hotkey_app/)
- [StackOverflow - Flutter overlay window](https://stackoverflow.com/questions/79742665/how-to-create-a-floating-overlay-window-in-flutter-desktop-app-using-window-mana)
