# Semantic Butler Desktop Application

The Flutter desktop application for Semantic Butler (Filo). Provides a native interface for semantic search, AI chat, file management, and indexing dashboard.

## Quick Start - For Users

### Option 1: Use Pre-built Installer

1. Download **Filo Desktop App** from the [website](../../../website)
2. Install the MSIX package
3. Download and run the **Backend Server** package
4. Launch Filo - it connects to `http://localhost:8080` automatically

### Option 2: Build from Source

```bash
# Install dependencies
flutter pub get

# Run (requires backend server running on localhost:8080)
flutter run -d windows

# Build for release
flutter build windows --release
```

## Overview

Built with Flutter 3.24+ using Riverpod for state management. Communicates with the local Serverpod backend via the generated client library. Supports Windows, macOS, and Linux.

## Features

- **Conversational Search** — AI-powered chat interface for finding files naturally
- **File Manager** — Browse, search, and manage local files with rich previews
- **Indexing Dashboard** — Monitor indexing progress, database health, and errors
- **Saved Searches** — Create and reuse search presets
- **Chat History** — Persistent conversation history with export support
- **Advanced Filters** — Filter by file type, date range, tags, and more
- **Keyboard Shortcuts** — Power-user friendly command palette (`Ctrl+K`)

## Server Connection

The app connects to a local Serverpod backend. To configure:

```dart
// Set environment variable
flutter run -d windows --dart-define=SERVER_URL=http://localhost:8080

// Or edit lib/config/app_config.dart
const String serverUrl = 'http://localhost:8080';
```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── config/                   # Configuration files
├── constants/                # App constants
├── models/                   # Data models
│   ├── chat/                # Chat-related models
│   ├── search_result_models.dart
│   └── tagged_file.dart
├── providers/                # Riverpod state providers
│   ├── chat_history_provider.dart
│   ├── conversational_search_provider.dart
│   ├── indexing_status_provider.dart
│   ├── search_controller.dart
│   ├── file_system_provider.dart
│   ├── watched_folders_provider.dart
│   └── ...
├── screens/                  # Screen widgets
│   ├── splash_landing_screen.dart
│   ├── search_results_screen.dart
│   └── file_manager_screen.dart
├── services/                 # Business logic services
│   ├── chat_database.dart
│   ├── chat_storage_service.dart
│   ├── permission_manager.dart
│   ├── shortcut_manager.dart
│   └── reset_service.dart
├── theme/                    # App theming
│   └── app_theme.dart
├── utils/                    # Utility functions
│   ├── app_logger.dart
│   ├── file_content_loader.dart
│   ├── syntax_highlighter.dart
│   └── ...
└── widgets/                  # Reusable widgets
    ├── chat/                 # Chat interface widgets
    ├── file_manager/         # File browser widgets
    ├── home/                 # Dashboard widgets
    ├── search/               # Search-related widgets
    ├── markdown/             # Markdown rendering
    ├── onboarding/           # Onboarding flow
    └── common/               # Shared widgets
```

## Key Screens

### Home / Dashboard
- Index Health Dashboard — Shows document count, database size, recent activity
- Indexing Progress — Real-time indexing status with progress bars
- Error Breakdown — Categorized indexing errors with diagnostics
- Compact Index Cards — Quick overview of indexed folders

### Search Results
- Advanced Search Bar — Natural language query input with autocomplete
- Search Result Cards — Rich previews with tags, scores, and snippets
- Bulk Actions — Select multiple results for batch operations
- Filter Panel — Filter by type, date, tags, and custom facets

### Chat Interface
- Message Bubbles — Rendered markdown with syntax highlighting
- Agent Thoughts — Expandable AI reasoning steps
- Tool Results — Structured display of search/file operations
- File Drop Zone — Attach files directly to conversations

### File Manager
- Breadcrumb Navigation — Easy path traversal
- Grid/List Views — Toggle between visual layouts
- Summary Dialog — Quick file content preview
- Sidebar Navigation — Quick access to watched folders

## State Management

| Provider | Purpose |
|----------|---------|
| `ConversationalSearchProvider` | Manages chat-based search state |
| `IndexingStatusProvider` | Tracks indexing progress and health |
| `SearchController` | Handles search queries and results |
| `ChatHistoryProvider` | Manages saved conversations |
| `FileSystemProvider` | Provides file system access |
| `WatchedFoldersProvider` | Manages indexed folder list |

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+K` / `Cmd+K` | Open command palette |
| `Ctrl+P` / `Cmd+P` | Quick file search |
| `Ctrl+Shift+F` | Advanced search |
| `Escape` | Close overlays/modals |
| `Ctrl+H` | Open chat history sidebar |

## Platform-Specific Notes

### Windows
- Requires Windows 10 1809+ for MSIX packaging
- Permission handling via `permission_manager_windows.dart`
- Creates start menu shortcut on install

### macOS
- Requires macOS 10.15+ (Catalina)
- Sandbox entitlements in `macos/Runner/DebugProfile.entitlements`
- File system bookmarks for persistent access

### Linux
- Tested on Ubuntu 20.04+, Debian 11+, Fedora 35+
- Uses `file_picker` package for folder selection
- Creates `.desktop` entry on installation

## Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `serverpod_flutter` | Backend communication |
| `fl_chart` | Charts and graphs |
| `markdown` | Markdown rendering |
| `highlight` | Syntax highlighting |
| `file_picker` | File/folder selection |
| `path_provider` | System paths |
| `shared_preferences` | Local settings |
| `window_manager` | Window controls |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Connection refused" | Ensure backend server is running on port 8080 |
| Indexing stuck at 0% | Verify database has `pgvector` extension enabled |
| File picker not working (macOS) | Check Sandbox entitlements |
| File picker not working (Windows) | Run as administrator for system folders |

## Related Documentation

- [Server README](../semantic_butler_server/README.md)
- [Main Project README](../README.md)

## License

MIT
