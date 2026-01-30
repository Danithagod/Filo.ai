# Filo Desktop Application

The cross-platform Flutter desktop application for Filo. Provides a native interface for semantic search, AI chat, file management, and indexing dashboard.

## Overview

Filo Desktop is built with Flutter 3.24+ and uses Riverpod for state management. It communicates with the Serverpod backend via the generated client library. The app supports Windows, macOS, and Linux.

## Features

- **Conversational Search** — AI-powered chat interface for finding files naturally
- **File Manager** — Browse, search, and manage local files with rich previews
- **Indexing Dashboard** — Monitor indexing progress, database health, and errors
- **Saved Searches** — Create and reuse search presets
- **Chat History** — Persistent conversation history with export support
- **Advanced Filters** — Filter by file type, date range, tags, and more
- **Keyboard Shortcuts** — Power-user friendly command palette (`Ctrl+K`)

## Prerequisites

- **Flutter 3.24+**
- **Dart 3.5+**
- **Serverpod backend** running (see [`../semantic_butler_server/`](../semantic_butler_server/))

## Getting Started

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure Server Connection

Edit `lib/config/app_config.dart` or set environment variables to connect to your Serverpod backend:

```dart
const String serverUrl = String.fromEnvironment(
  'SERVER_URL',
  defaultValue: 'http://localhost:8080',
);
```

### 3. Run the Application

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### 4. Build for Release

```bash
# Windows (MSIX installer)
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
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
- **Index Health Dashboard** — Shows document count, database size, recent activity
- **Indexing Progress** — Real-time indexing status with progress bars
- **Error Breakdown** — Categorized indexing errors with diagnostics
- **Compact Index Cards** — Quick overview of indexed folders

### Search Results
- **Advanced Search Bar** — Natural language query input with autocomplete
- **Search Result Cards** — Rich previews with tags, scores, and snippets
- **Bulk Actions** — Select multiple results for batch operations
- **Filter Panel** — Filter by type, date, tags, and custom facets

### Chat Interface
- **Message Bubbles** — Rendered markdown with syntax highlighting
- **Agent Thoughts** — Expandable AI reasoning steps
- **Tool Results** — Structured display of search/file operations
- **File Drop Zone** — Attach files directly to conversations

### File Manager
- **Breadcrumb Navigation** — Easy path traversal
- **Grid/List Views** — Toggle between visual layouts
- **Summary Dialog** — Quick file content preview
- **Sidebar Navigation** — Quick access to watched folders

## State Management

Filo uses Riverpod for reactive state management:

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

## Development Tips

### Hot Reload

The app supports Flutter's hot reload:

```bash
# Press 'r' in the terminal while the app is running
# Or use Ctrl+\ in VS Code
```

### Debug Mode

Enable verbose logging:

```dart
// In main.dart
void main() {
  Logger.root.level = Level.ALL;
  runApp(MyApp());
}
```

### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Dependencies

Key packages used:

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

### "Connection refused" error
- Ensure the Serverpod backend is running on port 8080
- Check firewall settings

### Indexing stuck at 0%
- Verify database has `pgvector` extension enabled
- Check server logs for errors

### File picker not working
- On macOS: Check Sandbox entitlements
- On Windows: Run as administrator if accessing system folders

## Related Documentation

- [Product Requirements Document](../../../.plan/semantic-desktop-butler-prd.md)
- [Server README](../semantic_butler_server/README.md)
- [Serverpod Documentation](https://docs.serverpod.dev)

## License

MIT
