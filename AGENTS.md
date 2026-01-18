# Commands

## Server (semantic_butler_server)
```bash
cd semantic_butler_server

# Start with migrations
dart run bin/main.dart --apply-migrations

# Start without migrations
dart run bin/main.dart

# Docker (Postgres + Redis)
docker compose up --build --detach  # Start
docker compose down -v                    # Stop and clean volumes

# Generate Serverpod code (after model changes)
dart pub global activate serverpod_cli 3.1.0
serverpod generate

# Apply database migrations only
dart run bin/main.dart --apply-migrations
```

## Flutter App (semantic_butler_flutter)
```bash
cd semantic_butler_flutter

# Run on Windows
flutter run -d windows

# Run on macOS
flutter run -d macos

# Run on Linux
flutter run -d linux

# Run web build
flutter build web --base-href /app/

# Check Flutter version
flutter --version
```

## Website (React)
```bash
cd website

# Development server
npm run dev

# Build production
npm run build

# Preview production build
npm run preview

# Test
npm test                          # All tests
npm test -- path/to/test.jsx -t "test name"  # Single test
npm run test:ui                  # UI test mode

# Lint
npm run lint                     # Check
npm run lint:fix                  # Fix auto-fixable issues

# Format
npm run format                   # Format all files
npm run format -- --check        # Check formatting only
```

## Testing

### Dart Tests
```bash
cd semantic_butler_server

# All tests
dart test

# Single test
dart test test/unit/auth_service_test.dart --name "test_name"

# Integration tests
dart test test/integration/

# With coverage
dart test --coverage
```

### Flutter Tests
```bash
cd semantic_butler_flutter

# Widget tests
flutter test

# Specific test file
flutter test test/widget_test.dart

# With coverage
flutter test --coverage
```

## Code Quality

### Dart Analysis
```bash
# Server
cd semantic_butler_server
dart analyze --fatal-infos

# Flutter
cd semantic_butler_flutter
flutter analyze

# Format (Dart)
dart format --set-exit-if-changed .
```

### Website Analysis
```bash
cd website

# Lint
npm run lint

# Format
npm run format
```

## Project Structure

```
desk-sense/
├── website/                              # React marketing website
│   ├── src/
│   │   ├── components/                   # Reusable UI components
│   │   ├── pages/                       # Route pages (Home, Features, etc.)
│   │   └── hooks/                       # Custom React hooks
│   ├── public/                          # Static assets
│   ├── test/                            # Vitest tests
│   ├── package.json
│   ├── vite.config.js
│   └── vitest.config.js
│
├── semantic_butler/                     # Main application
│   ├── semantic_butler_server/           # Serverpod backend (Dart)
│   │   ├── lib/src/
│   │   │   ├── endpoints/                # API endpoints
│   │   │   │   ├── agent_endpoint.dart  # AI agent (tool use, streaming)
│   │   │   │   ├── butler_endpoint.dart # Search, indexing, file ops
│   │   │   │   ├── file_system_endpoint.dart # File system operations
│   │   │   │   ├── health_endpoint.dart # Health checks
│   │   │   │   └── greetings/             # Example greeting endpoint
│   │   │   ├── services/                # Business logic
│   │   │   │   ├── ai_service.dart            # Unified AI operations
│   │   │   │   ├── cached_ai_service.dart     # Cached AI responses
│   │   │   │   ├── openrouter_client.dart     # OpenRouter API client
│   │   │   │   ├── file_extraction_service.dart # PDF, DOCX extraction
│   │   │   │   ├── file_operations_service.dart # File CRUD operations
│   │   │   │   ├── file_watcher_service.dart  # File system watching
│   │   │   │   ├── auth_service.dart         # API key authentication
│   │   │   │   ├── cache_service.dart        # Redis caching
│   │   │   │   ├── metrics_service.dart      # AI cost/metrics tracking
│   │   │   │   ├── rate_limit_service.dart   # Rate limiting
│   │   │   │   ├── terminal_service.dart     # Shell command execution
│   │   │   │   ├── tag_taxonomy_service.dart # Tag management
│   │   │   │   ├── search_preset_service.dart # Saved searches
│   │   │   │   ├── ai_cost_service.dart      # AI cost tracking and budgeting
│   │   │   │   ├── index_health_service.dart # Index health monitoring
│   │   │   │   ├── summarization_service.dart # Document summarization
│   │   │   │   ├── ai_search_service.dart    # AI-powered search
│   │   │   │   ├── lock_service.dart         # PostgreSQL advisory locks
│   │   │   │   ├── file_system_service.dart  # File system operations
│   │   │   │   └── circuit_breaker.dart      # Circuit breaker pattern for resilience
│   │   │   ├── config/                  # Configuration
│   │   │   │   └── ai_models.dart         # AI model routing/costs
│   │   │   ├── models/                  # Database models (.spy.yaml)
│   │   │   │   ├── indexing_job.spy.yaml
│   │   │   │   ├── file_index.spy.yaml
│   │   │   │   ├── document_embedding.spy.yaml
│   │   │   │   ├── indexing_progress.spy.yaml
│   │   │   │   ├── indexing_status.spy.yaml
│   │   │   │   ├── indexing_job_detail.spy.yaml
│   │   │   │   ├── watched_folder.spy.yaml
│   │   │   │   ├── ignore_pattern.spy.yaml
│   │   │   │   ├── tag_taxonomy.spy.yaml
│   │   │   │   ├── search_history.spy.yaml
│   │   │   │   ├── search_result.spy.yaml
│   │   │   │   ├── ai_search_progress.spy.yaml
│   │   │   │   ├── ai_search_result.spy.yaml
│   │   │   │   ├── error_stats.spy.yaml
│   │   │   │   ├── error_category_count.spy.yaml
│   │   │   │   ├── database_stats.spy.yaml
│   │   │   │   ├── health_check.spy.yaml
│   │   │   │   ├── drive_info.spy.yaml
│   │   │   │   ├── file_system_entry.spy.yaml
│   │   │   │   ├── file_operation_result.spy.yaml
│   │   │   │   ├── agent_message.yaml
│   │   │   │   ├── agent_response.yaml
│   │   │   │   ├── agent_stream_message.spy.yaml
│   │   │   │   └── agent_file_command.spy.yaml
│   │   │   ├── generated/                # Serverpod generated code
│   │   │   │   ├── protocol.dart       # Protocol definitions
│   │   │   │   ├── endpoints.dart      # Generated endpoints
│   │   │   │   └── ...
│   │   │   ├── utils/                   # Utilities
│   │   │   │   ├── error_sanitizer.dart # Security: sanitize errors
│   │   │   │   ├── validation.dart      # Input validation
│   │   │   │   └── path_utils.dart     # Path handling
│   │   │   └── constants/
│   │   │       └── error_categories.dart
│   │   ├── migrations/                  # Database migrations
│   │   ├── config/                     # Server config
│   │   │   ├── development.yaml
│   │   │   ├── generator.yaml
│   │   │   └── test.yaml
│   │   ├── test/                      # Tests
│   │   │   ├── unit/                 # Unit tests
│   │   │   └── integration/          # Integration tests
│   │   ├── pubspec.yaml
│   │   ├── analysis_options.yaml
│   │   └── docker-compose.yaml        # Postgres + Redis
│   │
│   ├── semantic_butler_client/           # Generated API client (shared)
│   │   ├── lib/src/protocol/
│   │   │   ├── client.dart
│   │   │   └── ... (mirrors server protocol)
│   │   └── pubspec.yaml
│   │
│   ├── semantic_butler_flutter/         # Flutter desktop app
│   │   ├── lib/
│   │   │   ├── screens/              # Full-screen routes
│   │   │   │   ├── home_screen.dart
│   │   │   │   ├── chat_screen.dart
│   │   │   │   ├── search_results_screen.dart
│   │   │   │   ├── file_manager_screen.dart
│   │   │   │   └── settings_screen.dart
│   │   │   ├── widgets/              # Reusable components
│   │   │   │   ├── chat/            # Chat-related widgets
│   │   │   │   │   ├── chat_app_bar.dart
│   │   │   │   │   ├── chat_input_area.dart
│   │   │   │   │   ├── chat_message_bubble.dart
│   │   │   │   │   ├── structured_response_widget.dart
│   │   │   │   │   ├── tool_result_badge.dart
│   │   │   │   │   ├── tool_result_card.dart
│   │   │   │   │   └── typing_indicator.dart
│   │   │   │   ├── home/            # Home dashboard widgets
│   │   │   │   │   ├── stats_card.dart
│   │   │   │   │   ├── ai_cost_dashboard.dart      # AI cost tracking dashboard
│   │   │   │   │   ├── index_health_dashboard.dart   # Index health monitoring
│   │   │   │   │   ├── compact_index_card.dart
│   │   │   │   │   ├── indexing_job_card.dart
│   │   │   │   │   ├── saved_search_presets_panel.dart
│   │   │   │   │   ├── error_breakdown_widget.dart
│   │   │   │   │   ├── fade_in_animation.dart
│   │   │   │   │   └── tag_manager_dialog.dart
│   │   │   │   ├── file_manager/    # File manager widgets
│   │   │   │   │   ├── breadcrumb_navigation.dart
│   │   │   │   │   ├── file_grid_item.dart
│   │   │   │   │   ├── file_list_item.dart
│   │   │   │   │   ├── file_manager_sidebar.dart
│   │   │   │   │   ├── file_manager_toolbar.dart
│   │   │   │   │   └── summary_dialog.dart
│   │   │   │   ├── common/          # Shared widgets
│   │   │   │   │   └── shimmer_effect.dart
│   │   │   │   ├── search_bar_widget.dart
│   │   │   │   ├── search_result_card.dart
│   │   │   │   ├── search_result_preview.dart
│   │   │   │   ├── recent_searches.dart
│   │   │   │   ├── file_tag_overlay.dart
│   │   │   │   ├── loading_skeletons.dart
│   │   │   │   ├── app_background.dart
│   │   │   │   ├── window_title_bar.dart
│   │   │   │   └── stats_card.dart
│   │   │   ├── models/               # Data models
│   │   │   │   ├── tagged_file.dart
│   │   │   │   └── chat/
│   │   │   │       ├── chat_message.dart
│   │   │   │       ├── message_role.dart
│   │   │   │       └── tool_result.dart
│   │   │   ├── providers/            # Riverpod state
│   │   │   │   ├── indexing_status_provider.dart
│   │   │   │   ├── watched_folders_provider.dart
│   │   │   │   ├── directory_cache_provider.dart
│   │   │   │   └── navigation_provider.dart
│   │   │   ├── services/            # Flutter-specific services
│   │   │   │   └── shortcut_manager.dart         # Global keyboard shortcuts
│   │   │   ├── config/
│   │   │   │   └── app_config.dart
│   │   │   ├── theme/
│   │   │   │   └── app_theme.dart
│   │   │   ├── utils/
│   │   │   │   ├── app_logger.dart
│   │   │   │   ├── file_content_loader.dart
│   │   │   │   ├── tool_name_mapper.dart
│   │   │   │   ├── xml_response_parser.dart
│   │   │   │   └── rate_limiter.dart
│   │   │   ├── constants/
│   │   │   │   └── app_constants.dart
│   │   │   ├── mixins/
│   │   │   │   └── file_tagging_mixin.dart
│   │   │   └── main.dart
│   │   ├── test/
│   │   │   └── widget_test.dart
│   │   ├── assets/
│   │   │   └── config.json          # API URL config
│   │   ├── pubspec.yaml
│   │   └── analysis_options.yaml
│   │
│   └── .env.example                    # Environment template
│
├── AGENTS.md                          # This file
└── .gitignore
```

# Code Style

## Versions
- **Dart**: 3.8.0+
- **Flutter**: 3.32.0+
- **React**: 18.2.0+
- **Serverpod**: 3.1.0

## Import Ordering

### Dart/Flutter
1. `dart:` imports (core SDK)
2. `package:` imports (third-party, semantic_butler_client)
3. Relative imports (within same package)

### React
1. `react` (if used directly)
2. Third-party libraries (lucide-react, gsap, etc.)
3. Local imports (relative paths)

Example:
```dart
import 'dart:async';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';

import '../services/auth_service.dart';
import 'config/ai_models.dart';
```

## Logging

### Never use `print()`
Use `AppLogger` (Flutter) or `session.log()` (Serverpod server):

```dart
// Flutter
import '../utils/app_logger.dart';

AppLogger.debug('Debug message', tag: 'MyWidget');
AppLogger.info('Info message', tag: 'MyWidget');
AppLogger.warning('Warning message', tag: 'MyWidget');
AppLogger.error('Error message', tag: 'MyWidget', error: e, stackTrace: stack);
AppLogger.network('GET', '/api/search', statusCode: 200);
AppLogger.lifecycle('resumed');

// Serverpod
session.log('Info message', level: LogLevel.info);
session.log('Warning message', level: LogLevel.warning);
session.log('Error message', level: LogLevel.error, stackTrace: stack);
```

## Error Handling

### Custom Exceptions
Create exceptions extending `Exception` with a `toString()` override:

```dart
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

// Usage
throw UnauthorizedException('Invalid API key');
```

### Error Sanitization (Server Security)
**CRITICAL**: Never expose raw exceptions to clients. Use `ErrorSanitizer`:

```dart
import '../utils/error_sanitizer.dart';

// Sanitize error messages for client responses
final safeMessage = ErrorSanitizer.sanitizeException(e);
final safeDetails = ErrorSanitizer.sanitizeErrorDetails(errorMap);

// Create safe API error response
final response = ErrorSanitizer.createSafeErrorResponse(
  message: 'Operation failed',
  errorType: 'ValidationError',
  details: {'field': 'value'},
);
```

`ErrorSanitizer` removes:
- File system paths
- Stack traces
- Package paths
- API keys/tokens
- Environment variables

### Serverpod Error Responses
For endpoint errors, throw exceptions or return error objects:

```dart
// Throw exception (will be returned as 500)
throw Exception('Internal error');

// Return structured error
return {'error': 'Invalid input', 'code': 400};
```

## State Management

### Flutter: Riverpod
Use `flutter_riverpod` for all state:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider definition
final counterProvider = StateProvider<int>((ref) => 0);

// In widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return ElevatedButton(
      onPressed: () => ref.read(counterProvider.notifier).state++,
      child: Text('Count: $count'),
    );
  }
}
```

**WARNING**: The Flutter app currently uses a global `client` variable (`main.dart:15`). This should be wrapped in a Provider for better testability.

### Serverpod: Built-in Session State
Serverpod manages session state automatically. Use `session` parameter in endpoints:

```dart
class MyEndpoint extends Endpoint {
  Future<String> myMethod(Session session, String input) async {
    // Session provides logging, caching, authentication
    session.log('Processing...', level: LogLevel.info);

    // Access cache
    await session.cache.set('key', 'value');
    final value = await session.cache.get('key');

    return 'result';
  }
}
```

### React: Hooks
Use `useState`, `useEffect`, `useRef`, etc.:

```jsx
import React, { useState, useEffect, useRef } from 'react';

const MyComponent = ({ show }) => {
  const [isOpen, setIsOpen] = React.useState(false);
  const ref = useRef(null);

  useEffect(() => {
    if (show) {
      // Animation setup
    }
  }, [show]);

  return <div ref={ref}>...</div>;
};
```

## Type Annotations

### Dart
- **Required on public APIs**: All public methods, parameters, return types
- **Inferred where obvious**: Local variables, private methods

```dart
// Public API - types required
class MyService {
  Future<String> fetchData(String url) async {
    // Implementation
    return 'result';
  }
}

// Local - type inferred
Future<void> main() async {
  final data = await fetchSomething();
  print(data); // Type inferred
}
```

### React/TypeScript
- **Use TypeScript types**: Avoid `any`
- **Define interfaces** for props/data shapes

```tsx
interface MyComponentProps {
  show: boolean;
  title: string;
  onClick?: () => void;
}

const MyComponent: React.FC<MyComponentProps> = ({ show, title, onClick }) => {
  return <div onClick={onClick}>{title}</div>;
};
```

## Trailing Commas

- **Preserve trailing commas** in all code (Dart formatter, Prettier)
- **Enables cleaner diffs** in version control

## File Organization

### Large Files
Several files exceed 800 lines and should be refactored:
- `semantic_butler_flutter/lib/screens/chat_screen.dart` (~1,300 lines)
- `semantic_butler_flutter/lib/screens/home_screen.dart` (~1,100 lines)
- `semantic_butler_flutter/lib/screens/file_manager_screen.dart` (~1,200 lines)

**Refactoring pattern**:
```
Large file (1000+ lines)
├── extracted_widget_1.dart (200 lines)
├── extracted_widget_2.dart (200 lines)
├── extracted_widget_3.dart (200 lines)
└── original_file.dart (400 lines - now focused)
```

## Linting Configurations

### Dart Server
- **Package**: `lints` (recommended)
- **Analysis options**: `analysis_options.yaml`
- **Rules**:
  - `avoid_print`: enabled (use AppLogger instead)
  - `unawaited_futures`: enabled
  - Generated code excluded: `lib/src/generated/**`

### Flutter
- **Package**: `flutter_lints`
- **Analysis options**: `analysis_options.yaml`
- **Formatter**: Trailing commas preserved

### Website (React)
- **ESLint**: `eslint:recommended`, `plugin:react/recommended`, `plugin:react-hooks/recommended`
- **Prettier**: Semi-colons off, single quotes, 100 char line width
- **Extensions**: `.js`, `.jsx`

# Testing

## Dart Tests

### Test Structure
Use `group()` for organization, `test()` for individual tests:

```dart
import 'package:test/test.dart';
import 'package:semantic_butler_server/src/services/auth_service.dart';

void main() {
  group('AuthService', () {
    group('validateApiKey', () {
      test('returns true for valid key', () {
        expect(AuthService.validateApiKey(session, providedApiKey: 'valid'), isTrue);
      });

      test('returns false for invalid key', () {
        expect(AuthService.validateApiKey(session, providedApiKey: 'invalid'), isFalse);
      });
    });
  });
}
```

### Mocking
Use `mockito` for mocking in tests:

```dart
import 'package:mockito/mockito.dart';

class MockClient extends Mock implements SomeClient {}

void main() {
  test('uses client correctly', () {
    final mockClient = MockClient();
    when(mockClient.fetch()).thenAnswer((_) async => 'result');

    // Test code

    verify(mockClient.fetch()).called(1);
  });
}
```

### Test Environment
- Uses `config/test.yaml` for database connection
- Test database: `semantic_butler_test` (different port: 9090)
- Test Redis: Port 9091

## Flutter Tests

### Widget Tests
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('MyWidget displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyWidget(),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Clicked'), findsOneWidget);
  });
}
```

### Test Status
- `test/widget_test.dart` exists but minimal implementation
- Add tests for critical widgets: SearchBar, chat components, file manager

## React Tests (Vitest)

### Test Structure
```jsx
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import Home from '../src/pages/Home/Home';

describe('Home Page', () => {
  it('renders without crashing', () => {
    render(<Home show={true} />);
    expect(screen.getByText(/Your Second Brain/i)).toBeInTheDocument();
  });

  it('renders Get Started button', () => {
    render(<Home show={true} />);
    expect(screen.getByText(/Get Started Free/i)).toBeInTheDocument();
  });
});
```

### Test Environment
- `vitest.config.js`: jsdom environment, globals enabled
- Setup file: `test/setup.js`
- Test files: `**/*.test.jsx`, `**/*.test.js`

# Architecture Patterns

## Serverpod Code Generation

### Protocol Files
Models are defined in `.spy.yaml` files in `lib/src/models/`:

```yaml
### FileIndex model - tracks indexed documents
class: FileIndex
table: file_index
fields:
  ### Full file path
  path: String
  ### File name
  fileName: String
  ### MIME type
  mimeType: String
  ### File size in bytes
  fileSizeBytes: int
  ### Document status
  status: String
indexes:
  file_index_path:
    fields: path
  file_index_status:
    fields: status
```

### Generation Steps
After modifying `.spy.yaml` files:

```bash
cd semantic_butler_server

# 1. Activate Serverpod CLI
dart pub global activate serverpod_cli 3.1.0

# 2. Generate code
serverpod generate

# This updates:
# - lib/src/generated/protocol.dart (server)
# - ../semantic_butler_client/lib/src/protocol/ (client)
```

### Generated Code Excluded
From analysis: `lib/src/generated/**`, `test/integration/test_tools/**`

## AI Integration (OpenRouter)

### Model Configuration
AI models are configured in `lib/src/config/ai_models.dart`:

```dart
class AIModels {
  // Embeddings
  static const String embeddingGemini = 'google/gemini-embedding-001';
  static const String embeddingOpenAISmall = 'openai/text-embedding-3-small';

  // Fast models
  static const String chatGeminiFlash = 'google/gemini-2.5-flash';
  static const String chatGpt4oMini = 'openai/gpt-4o-mini';

  // Quality models
  static const String chatClaudeSonnet = 'anthropic/claude-3.5-sonnet';
  static const String chatGpt4o = 'openai/gpt-4o';

  // Agent (default)
  static const String agentDefault = chatClaudeSonnet;

  // Embedding dimensions
  static const Map<String, int> embeddingDimensions = {
    'google/gemini-embedding-001': 768,
    'openai/text-embedding-3-small': 1536,
  };
}
```

### AI Service Pattern
Use `AIService` for all AI operations:

```dart
import '../services/ai_service.dart';

// Singleton pattern in endpoints
AIService get aiService {
  _aiService ??= AIService(client: client);
  return _aiService!;
}

// Generate embeddings
final embeddings = await aiService.generateEmbeddings(texts);

// Chat completion
final response = await aiService.chat(
  prompt: 'Summarize this...',
  systemPrompt: 'You are a helpful assistant...',
  complexity: TaskComplexity.simple,
);
```

### OpenRouter Client
`OpenRouterClient` handles API communication:

```dart
final client = OpenRouterClient(apiKey: getEnv('OPENROUTER_API_KEY'));

// Chat completion
final response = await client.chatCompletion(
  model: AIModels.agentDefault,
  messages: messages,
  tools: tools,
);

// Streaming
await for (final chunk in client.streamChatCompletion(...)) {
  // Process chunks
}

// Embeddings
final response = await client.createEmbeddings(
  model: AIModels.embeddingGemini,
  input: texts,
);
```

### Client Disposal
**IMPORTANT**: Dispose HTTP clients when no longer needed:

```dart
OpenRouterClient? _client;
static final List<OpenRouterClient> _allClients = [];

OpenRouterClient get client {
  _client ??= OpenRouterClient(apiKey: getEnv('OPENROUTER_API_KEY'));
  _allClients.add(_client!);
  return _client!;
}

void disposeClient() {
  _client?.dispose();
  _client = null;
}

// On server shutdown
static void disposeAll() {
  for (final client in _allClients) {
    client.dispose();
  }
  _allClients.clear();
}
```

## Agent Endpoint (Tool Use)

### Tool Definition Pattern
```dart
List<Tool> get tools => [
  Tool(
    function: ToolFunction(
      name: 'search_files',
      description: 'Search indexed documents semantically',
      parameters: {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'Natural language search query',
          },
          'limit': {
            'type': 'integer',
            'description': 'Max results (default: 10)',
          },
        },
        'required': ['query'],
      },
    ),
  ),
  // ... more tools
];
```

### Tool Execution Pattern
```dart
Future<Map<String, dynamic>> _executeTool(
  Session session,
  ToolCall toolCall,
) async {
  final function = toolCall.function;
  final args = function.parsedArguments;

  switch (function.name) {
    case 'search_files':
      return await _toolSearchFiles(
        session,
        args['query'] as String,
        limit: args['limit'] as int? ?? 10,
      );
    case 'rename_file':
      return await _toolRenameFile(
        session,
        args['current_path'] as String,
        args['new_name'] as String,
      );
    // ... more cases
    default:
      return {'error': 'Unknown tool: ${function.name}'};
  }
}
```

### Streaming Chat Pattern
```dart
Stream<AgentStreamMessage> streamChat(
  Session session,
  String message, {
  List<AgentMessage>? conversationHistory,
}) async* {
  yield AgentStreamMessage(type: 'thinking', content: 'Processing...');

  final messages = <ChatMessage>[
    ChatMessage.system(systemPrompt),
    ...conversationHistory.map((m) => ChatMessage(role: m.role, content: m.content)),
    ChatMessage.user(message),
  ];

  int iteration = 0;
  const maxIterations = 15;

  while (iteration < maxIterations) {
    iteration++;

    // Stream response
    final contentBuffer = StringBuffer();
    final List<ToolCall> toolCalls = [];

    await for (final chunk in client.streamChatCompletion(...)) {
      if (chunk.deltaContent != null) {
        contentBuffer.write(chunk.deltaContent);
        yield AgentStreamMessage(type: 'text', content: chunk.deltaContent);
      }

      if (chunk.hasToolCalls) {
        toolCalls.addAll(chunk.toolCalls!);
      }
    }

    // Execute tools if present
    if (toolCalls.isNotEmpty) {
      for (final toolCall in toolCalls) {
        yield AgentStreamMessage(
          type: 'tool_start',
          tool: toolCall.function?.name,
          content: 'Executing...',
        );

        final result = await _executeTool(session, toolCall);

        yield AgentStreamMessage(
          type: 'tool_result',
          tool: toolCall.function?.name,
          result: jsonEncode(result),
        );
      }
      continue; // Next iteration for AI to process tool results
    }

    // Done
    yield AgentStreamMessage(type: 'complete', content: contentBuffer.toString());
    return;
  }
}
```

## Database

### Postgres with pgvector
- **Database**: Supabase or local Postgres with pgvector extension
- **Migrations**: In `migrations/` folder, auto-applied on server start
- **Models**: Defined in `.spy.yaml` files

### Connection Configuration
Edit `config/development.yaml`:

```yaml
database:
  host: localhost
  port: 8090
  name: semantic_butler
  user: postgres
  requireSsl: false

redis:
  enabled: true
  host: localhost
  port: 8091
```

## Security

### Authentication (Server)
Uses API key-based authentication:

```dart
import '../services/auth_service.dart';

// At start of protected endpoint
AuthService.requireAuth(session, apiKey: providedApiKey);

// Or manual validation
if (!AuthService.validateApiKey(session, providedApiKey: apiKey)) {
  throw UnauthorizedException('Invalid API key');
}
```

**Development mode**: If `API_KEY` is not set and `FORCE_AUTH` is not set, authentication is disabled (with warning).

### Rate Limiting
Use `RateLimitService`:

```dart
final rateLimiter = RateLimitService.instance;

// Require rate limit (throws if exceeded)
rateLimiter.requireRateLimit(clientId, 'agentChat');

// Or check without throwing
if (rateLimiter.isAllowed(clientId, 'someOperation')) {
  // Execute operation
}
```

### Terminal Service Security
`TerminalService` only allows read-only commands:

- **Allowed**: `dir`, `ls`, `find`, `grep`, `cat`, `type`, `where`, `which`
- **Blocked**: `rm`, `del`, `mv`, `copy`, `echo` with redirections, etc.

```dart
try {
  final result = await terminal.execute(command, workingDirectory: dir);
  // Use result.stdout, result.exitCode, etc.
} on TerminalSecurityException catch (e) {
  // Command was blocked
  return {'error': 'Security violation: ${e.message}'};
}
```

### Input Validation
Use `Validation` utility:

```dart
import '../utils/validation.dart';

// Validate file path
final error = Validation.validateFilePath(path);
if (error != null) {
  throw ArgumentError(error);
}

// Validate search query
if (!Validation.isValidSearchQuery(query)) {
  throw ArgumentError('Invalid search query');
}
```

# Important Gotchas

## Serverpod Configuration

### Client-Server Generator Path
In `config/generator.yaml`:

```yaml
type: server
client_package_path: ../semantic_butler_client
server_test_tools_path: test/integration/test_tools
```

**Never change** these paths without understanding the implications.

### Generated Code
- **Do not edit** files in `lib/src/generated/` - they will be overwritten
- **Protocol**: Mirrored to `semantic_butler_client/lib/src/protocol/`
- **After model changes**: Always run `serverpod generate` to update both sides

## Flutter Global Client

The Flutter app currently uses a global `client` variable:

```dart
// main.dart
late final Client client;

void main() async {
  final config = await AppConfig.loadConfig();
  client = Client(config.apiUrl!);

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

**Problem**: Makes testing difficult and lifecycle management unclear.
**Fix needed**: Wrap `client` in a `Provider`.

## Hardcoded Colors and Values

Several places in Flutter use hardcoded colors/text instead of theme:

```dart
// BAD
style: const TextStyle(color: Colors.white70),
value: '1,248',  // Mock data

// GOOD
style: TextStyle(color: colorScheme.onSurfaceVariant),
value: stats.documentCount.toString(),  // Real API data
```

## Path Separators

**Windows vs Unix** path separators:

```dart
import 'dart:io';

// BAD
final parts = path.split('/');  // Unix only

// GOOD
import 'package:path/path.dart' as p;
final parts = p.split(path);  // Platform-aware
final filename = p.basename(path);
```

## React State

Some React components don't properly use `useState` or `useEffect` dependencies:

```jsx
// BAD - won't rebuild when controller.text changes
if (controller.text.isNotEmpty) {
  return <ClearButton />;
}

// GOOD - reactive
ValueListenableBuilder<TextEditingValue>(
  valueListenable: controller,
  builder: (context, value, child) {
    if (value.text.isNotEmpty) {
      return <ClearButton />;
    }
    return null;
  },
)
```

## File Watching

File watchers in `ButlerEndpoint` are per-session and need cleanup:

```dart
// Track watchers for each session
static final Map<String, FileWatcherService> _fileWatchers = {};
static final Map<String, DateTime> _fileWatcherLastAccess = {};

// Cleanup idle watchers (call periodically)
static Future<void> cleanupIdleWatchers() async {
  final now = DateTime.now();
  final expiredSessions = <String>[];

  for (final entry in _fileWatcherLastAccess.entries) {
    if (now.difference(entry.value) > Duration(minutes: 30)) {
      expiredSessions.add(entry.key);
    }
  }

  for (final sessionId in expiredSessions) {
    await _cleanupWatcherForSession(sessionId);
  }
}
```

## Flutter App Lifecycle

Polling continues even when app is not active. Use `WidgetsBindingObserver`:

```dart
class _MyWidgetState extends State<MyWidget>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start polling
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Resume polling
    } else {
      // Stop polling
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

## Docker Compose

Development database and Redis are in `semantic_butler_server/docker-compose.yaml`:

```yaml
services:
  postgres:
    image: pgvector/pgvector:pg16
    ports:
      - "8090:5432"      # Development DB

  postgres_test:
    image: pgvector/pgvector:pg16
    ports:
      - "9090:5432"      # Test DB
```

**Note**: Development and test databases use different ports to avoid conflicts.

# API Call Patterns

## Serverpod Client (Flutter)

### Basic Call
```dart
final result = await client.butler.semanticSearch(
  query: 'my documents',
  limit: 10,
);
```

### Streaming (Agent)
```dart
final stream = client.agent.streamChat(
  message: 'Find my files',
  conversationHistory: previousMessages,
);

await for (final message in stream) {
  // Handle: 'thinking', 'text', 'tool_start', 'tool_result', 'complete'
  switch (message.type) {
    case 'text':
      // Update UI with tokens
      break;
    case 'tool_start':
      // Show tool executing
      break;
    case 'complete':
      // Stream finished
      break;
  }
}
```

### Error Handling
```dart
try {
  final result = await client.butler.startIndexing(folderPath);
} catch (e) {
  AppLogger.error('Indexing failed', error: e);
  // Show user-friendly message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to start indexing')),
  );
}
```

### Timeout Configuration
```dart
// In main.dart or when creating client
final client = Client(
  serverUrl,
  connectionTimeout: Duration(minutes: 2),  // Connection timeout
);
```

## React HTTP Calls

The website uses React Router for navigation, no direct API calls observed in marketing pages.

# Environment Variables

## Server (.env)

Copy from `.env.example`:

```bash
OPENROUTER_API_KEY=sk-or-v1-...
DATABASE_URL=postgresql://...
SERVERPOD_MODE=development
```

## Flutter (config.json)

In `semantic_butler_flutter/assets/config.json`:

```json
{
    "apiUrl": "http://localhost:8080"
}
```

Load with `AppConfig`:

```dart
final config = await AppConfig.loadConfig();
final apiUrl = config.apiUrl;
```

# Naming Conventions

## Dart
- **Variables/Functions**: `camelCase`
- **Classes/Enums/Types**: `PascalCase`
- **Constants**: `lowerCamelCase` (private) or `UPPER_CASE` (public static)
- **Private members**: Prefix with `_`
- **Files**: `snake_case.dart`
- **Folders**: `snake_case`

```dart
class MyService {
  static const String _privateConstant = 'value';
  static const String PUBLIC_CONSTANT = 'value';

  final String _privateField;
  final String publicField;

  String _privateMethod() => 'value';
  String publicMethod() => 'value';
}
```

## Flutter Widgets
- **Stateless widgets**: `PascalCase` (no suffix)
- **Stateful widgets**: `PascalCase` + state class `_PascalCaseState`
- **Widget files**: `snake_case.dart` with `PascalCase` widget export
- **Widget variables**: `camelCase` starting with lowercase (e.g., `myWidget`)

```dart
class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // Implementation
}
```

## React Components
- **Components**: `PascalCase`
- **Props interfaces**: `PascalCase` + `Props`
- **Files**: `PascalCase.jsx` or `PascalCase.js`
- **Hooks**: `useCamelCase` (custom hooks)

```jsx
interface MyComponentProps {
  show: boolean;
  title: string;
}

const MyComponent: React.FC<MyComponentProps> = ({ show, title }) => {
  return <div>{title}</div>;
};
```

# Project-Specific Patterns

## File Indexing Workflow

1. **Start indexing**: `ButlerEndpoint.startIndexing(path)`
2. **File watching**: `FileWatcherService` monitors folder
3. **Extraction**: `FileExtractionService` extracts text from PDF, DOCX
4. **Embedding**: `AIService.generateEmbeddings(text)`
5. **Storage**: `FileIndex` table with embeddings (pgvector)
6. **Progress updates**: `IndexingJob` table tracks status

## Agent Memory Pattern

The AI agent remembers file operations within a conversation:

```dart
// After renaming file
await _syncIndexAfterRename(session, oldPath, newPath);

// Log operation to database
await AgentFileCommand.db.insertRow(
  session,
  AgentFileCommand(
    operation: 'rename',
    sourcePath: oldPath,
    destinationPath: newPath,
    success: true,
  ),
);
```

## Search History

Searches are tracked in `SearchHistory` table for recent searches and presets.

## Tag Taxonomy

Tags are managed through `TagTaxonomyService` for consistent categorization.

## Error Categories

Errors are categorized in `constants/error_categories.dart`:
- File system errors
- AI service errors
- Authentication errors
- Database errors
- Network errors

Categories are tracked in `ErrorStats` for dashboard display.

# Documentation

## Inline Documentation
Use `///` for public APIs:

```dart
/// Authenticate user with API key
///
/// Throws [UnauthorizedException] if API key is invalid.
///
/// Returns [User] object on success.
Future<User> authenticate(String apiKey) async {
  // Implementation
}
```

## Comments
- **Keep comments minimal** - code should be self-documenting
- **Explain "why", not "what"** - comments should explain reasoning, not restate code

```dart
// BAD
// Increment the counter
counter++;

// GOOD
// Counter must be incremented before sending to avoid race condition
counter++;
```

# Testing Gotchas

## Serverpod Test Configuration
- Test database: `semantic_butler_test` (port 9090)
- Test Redis: Port 9091
- Tests require Docker to be running: `docker compose up --build -d`

## Flutter Test Status
- `test/widget_test.dart` exists but minimal implementation
- Add tests for critical widgets before production

## React Test Environment
- Uses `jsdom` for DOM simulation
- `@testing-library/react` for component testing
- `vitest.config.js` configures test environment

---

# New Features & Services (Updated)

## New Backend Services

### IndexHealthService
Monitors and maintains the integrity of the document index.

**Capabilities:**
- Detect orphaned files (indexed but deleted from disk)
- Find stale entries (not updated in 180+ days)
- Detect duplicate content
- Evaluate index quality metrics
- Find missing embeddings
- Detect corrupted data

**Usage:**
```dart
final report = await IndexHealthService.generateReport(session);
// Returns IndexHealthReport with:
// - healthScore (0-100)
// - orphanedFiles
// - staleEntries
// - duplicateGroups
// - statistics
// - missingEmbeddings
// - corrupted
```

### AICostService
Tracks AI API costs and provides budgeting features.

**Capabilities:**
- Track token usage and costs per model
- Calculate daily/monthly costs
- Budget checking with warnings
- Cost projections based on usage history
- Daily cost breakdowns

**Usage:**
```dart
// Get cost summary
final summary = await client.butler.getAICostSummary(
  startDate: startDate,
  endDate: endDate,
);

// Check budget
final budget = await client.butler.checkBudget(
  budgetLimit: 50.0,
  periodStart: startDate,
  periodEnd: endDate,
);

// Get projections
final projection = await client.butler.getProjectedCosts(
  lookbackDays: 30,
  forecastDays: 30,
);
```

### CircuitBreaker
Implements the Circuit Breaker pattern for external service resilience.

**Purpose:**
- Prevents cascading failures
- Temporarily stops calls to failing services
- Automatically recovers when service is healthy

**States:**
- **Closed**: Normal operation, requests allowed
- **Open**: Failure threshold exceeded, requests blocked
- **Half-Open**: Testing if service has recovered

**Usage:**
```dart
final circuitBreaker = CircuitBreaker(
  name: 'openrouter',
  failureThreshold: 5,
  resetTimeout: Duration(minutes: 1),
);

// Check if call is allowed
if (circuitBreaker.allowRequest) {
  try {
    final result = await riskyOperation();
    circuitBreaker.recordSuccess();
    return result;
  } catch (e) {
    circuitBreaker.recordFailure();
    rethrow;
  }
}
```

### SummarizationService
Provides document summarization with configurable length.

**Capabilities:**
- Brief (3-5 sentences)
- Medium (10-15 sentences)
- Detailed (full summary)
- Hierarchical summarization for long documents
- Content-aware chunking

**Usage:**
```dart
final summary = await SummarizationService.generateSummary(
  session,
  content,
  openRouterClient,
  maxWords: 50,  // Brief
);
```

### AISearchService
AI-powered search that combines vector similarity with keyword matching.

**Capabilities:**
- Hybrid search (vector + keyword)
- Relevance scoring
- Multiple filter support (date, type, tag)
- AI query understanding and refinement

**Usage:**
```dart
final results = await AISearchService.search(
  session,
  query: 'meeting notes',
  filters: SearchFilters(
    fileTypes: ['pdf', 'docx'],
    dateRange: DateRange(start: ..., end: ...),
  ),
);
```

### LockService
Manages PostgreSQL advisory locks for concurrent operations.

**Purpose:**
- Prevent race conditions during file indexing
- Ensure only one process indexes a file at a time
- Lock timeout handling with retry

**Usage:**
```dart
final lock = LockService(session);
await lock.acquireLock('file:${filePath}');
try {
  // Perform indexing
} finally {
  await lock.releaseLock('file:${filePath}');
}
```

### FileSystemService
Provides file system operations and directory traversal.

**Capabilities:**
- List directories with filtering
- Get drive information
- Recursive directory scanning
- File metadata retrieval

**Usage:**
```dart
final drives = await FileSystemService.getDrives(session);
final entries = await FileSystemService.listDirectory(
  session,
  path: '/path/to/folder',
  recursive: true,
);
```

## New Endpoints & Methods

### ButlerEndpoint (New Methods)

**AI Cost Tracking:**
- `getAICostSummary(startDate, endDate)` - Get total costs and token usage
- `checkBudget(budgetLimit, periodStart, periodEnd)` - Check if budget exceeded
- `getProjectedCosts(lookbackDays, forecastDays)` - Project future costs
- `getDailyCosts(startDate, endDate)` - Daily cost breakdown for charts

**Index Health:**
- `getIndexHealthReport()` - Generate comprehensive health report
- `cleanupOrphanedFiles()` - Remove indexed files that no longer exist
- `reindexStaleFiles(days)` - Re-index files not updated in N days
- `cleanupMissingEmbeddings()` - Find and fix files without embeddings

**Search & Presets:**
- `saveSearchPreset(name, query, filters)` - Save search configuration
- `getSearchPresets()` - Get all saved presets
- `deleteSearchPreset(id)` - Remove saved preset

**File Operations:**
- `getDocumentDetails(documentId)` - Get indexed document information
- `batchFileOperations(operations)` - Execute multiple operations atomically

### HealthEndpoint

**Health Check:**
- `check()` - Returns `HealthCheck` with:
  - Overall status (healthy/degraded/unhealthy)
  - Database connectivity
  - pgvector extension status
  - Watcher health
  - Cache hit rate
  - API response time

**Usage:**
```dart
final health = await client.health.check();
if (health.status == 'healthy') {
  // System is operational
}
```

## New Flutter Widgets & Features

### Keyboard Shortcuts (Global)

**Implemented Shortcuts:**
- `Ctrl/Cmd + K` - Focus search bar
- `Ctrl/Cmd + 1` - Navigate to Home tab
- `Ctrl/Cmd + 2` - Navigate to Index tab
- `Ctrl/Cmd + 3` - Navigate to Chat tab
- `Ctrl/Cmd + 4` - Navigate to Files tab
- `Ctrl/Cmd + 5` - Navigate to Settings tab

**Usage:**
```dart
import '../services/shortcut_manager.dart';

// In widget tree
Shortcuts(
  shortcuts: ShortcutManager.shortcuts,
  child: Actions(
    actions: <Type, Action<Intent>>{
      FocusSearchIntent: CallbackAction<FocusSearchIntent>(
        onInvoke: (_) => _focusSearchBar(),
      ),
      NavigateTabIntent: CallbackAction<NavigateTabIntent>(
        onInvoke: (intent) => setState(() => _selectedIndex = intent.index),
      ),
    },
    child: /* app content */,
  ),
)
```

### AI Cost Dashboard

**Location:** `lib/widgets/home/ai_cost_dashboard.dart`

**Features:**
- Cost summary cards (total, daily average, budget status)
- Line chart showing daily costs (using fl_chart)
- Budget progress bar with color-coded status
- Cost breakdown by model type
- Budget limit configuration
- Time period selection (7, 30, 90 days)

### Index Health Dashboard

**Location:** `lib/widgets/home/index_health_dashboard.dart`

**Features:**
- Health score display (0-100) with color-coded indicator
- Orphaned files count with cleanup button
- Stale entries count with reindex button
- Duplicate content groups
- Missing embeddings indicator
- Corrupted data warnings
- Index statistics (total files, average file size, etc.)

### Summary Dialog

**Location:** `lib/widgets/file_manager/summary_dialog.dart`

**Features:**
- Display AI-generated document summary
- Configurable summary length (brief/medium/detailed)
- Option to ask assistant about the document
- Copy summary to clipboard
- Loading state for summary generation

### Tool Result Cards

**Location:** `lib/widgets/chat/tool_result_card.dart`

**Features:**
- Display structured tool execution results
- Expand/collapse details
- Syntax highlighting for command output
- Copy result to clipboard
- Error state display with retry option

### Tag Manager Dialog

**Location:** `lib/widgets/home/tag_manager_dialog.dart`

**Features:**
- View all tags by category
- Edit tag taxonomy
- Merge similar tags
- Delete unused tags
- Tag frequency visualization

### Error Breakdown Widget

**Location:** `lib/widgets/home/error_breakdown_widget.dart`

**Features:**
- Categorized error counts (file system, AI, database, network)
- Bar chart showing error distribution
- Drill-down to view error details
- Error trend over time

### Saved Search Presets Panel

**Location:** `lib/widgets/home/saved_search_presets_panel.dart`

**Features:**
- List all saved search presets
- Quick-click to execute preset
- Edit preset name and filters
- Delete presets
- Create new preset from current search

## New Architectural Patterns

### Resource Cleanup Pattern

**Purpose:** Prevent memory leaks by properly disposing resources.

**Implementation:**
```dart
// Track all instances
static final List<OpenRouterClient> _allClients = [];

// Add when created
_allClients.add(client);

// Dispose on endpoint destruction
void disposeClient() {
  _client?.dispose();
}

// Global cleanup on server shutdown
static Future<void> disposeAll() async {
  for (final client in _allClients) {
    client.dispose();
  }
  _allClients.clear();
}
```

### Idle Watcher Cleanup

**Purpose:** Automatically cleanup file watchers that haven't been used.

**Implementation:**
```dart
static final Map<String, DateTime> _fileWatcherLastAccess = {};

// Update last access on each operation
void _markAccess(String sessionId) {
  _fileWatcherLastAccess[sessionId] = DateTime.now();
}

// Periodic cleanup (every 10 minutes)
static Future<void> cleanupIdleWatchers() async {
  final now = DateTime.now();
  final expired = _fileWatcherLastAccess.entries
      .where((e) => now.difference(e.value) > Duration(minutes: 30));

  for (final entry in expired) {
    await _cleanupWatcherForSession(entry.key);
  }
}
```

### Path Claiming Pattern (Race Condition Prevention)

**Purpose:** Prevent duplicate processing of the same file.

**Implementation:**
```dart
static final Set<String> _processingPaths = {};

static Future<List<String>> _claimPathsForProcessing(List<String> paths) async {
  // Wait for lock
  while (_processingPathsLock != null) {
    await _processingPathsLock!.future;
  }

  _processingPathsLock = Completer<void>();
  try {
    // Atomically filter and claim paths
    final claimedPaths = paths
        .where((p) => !_processingPaths.contains(p))
        .toList();
    _processingPaths.addAll(claimedPaths);
    return claimedPaths;
  } finally {
    _processingPathsLock?.complete();
    _processingPathsLock = null;
  }
}
```

### Streaming Response Pattern

**Purpose:** Real-time streaming of AI responses for better UX.

**Implementation:**
```dart
Stream<AgentStreamMessage> streamChat(Session session, String message) async* {
  // Emit thinking state
  yield AgentStreamMessage(type: 'thinking', content: 'Processing...');

  // Stream text tokens
  await for (final chunk in client.streamChatCompletion(...)) {
    yield AgentStreamMessage(type: 'text', content: chunk.deltaContent);
  }

  // Execute tools if present
  for (final toolCall in toolCalls) {
    yield AgentStreamMessage(type: 'tool_start', tool: toolCall.function?.name);
    final result = await _executeTool(session, toolCall);
    yield AgentStreamMessage(type: 'tool_result', result: jsonEncode(result));
  }

  // Emit completion
  yield AgentStreamMessage(type: 'complete', content: buffer.toString());
}
```

## New Security Features

### Enhanced Path Validation

**Additional Checks:**
- Null byte detection (`\x00`)
- URL encoding attack prevention (`%2e%2e`)
- Hex encoding bypass detection
- Unicode normalization attack detection
- Protected system paths (Windows: `C:\Windows`, Unix: `/usr`, `/bin`)

### Command Whitelist Expansion

**New Allowed Commands:**
- `find` - Unix file search
- `where` - Windows command location
- `which` - Unix command location
- `powershell` (restricted mode) - For deep searches

**New Blocked Patterns:**
- `rm -rf` - Force recursive delete
- `del /f` - Force delete (Windows)
- `format` - Disk formatting
- `curl` / `wget` - File download (blocked)
- `powershell` (unrestricted mode) - Arbitrary code execution

### Error Sanitization

**Removed from Error Messages:**
- File system paths
- Stack traces
- Package paths
- API keys/tokens
- Environment variables
- Internal server details

## Database Models

### New Models

**IndexHealthReport:**
- `generatedAt` - Timestamp
- `healthScore` - 0-100
- `orphanedFiles` - List<String>
- `staleEntries` - List<FileIndex>
- `duplicateGroups` - List<DuplicateGroup>
- `statistics` - IndexStatistics
- `missingEmbeddings` - List<FileIndex>
- `corrupted` - List<FileIndex>

**DuplicateGroup:**
- `hash` - Content hash
- `files` - List<FileIndex>
- `totalSize` - Total bytes
- `potentialSavings` - Bytes saved by deduplication
- `createdAt` - Timestamp

**IndexStatistics:**
- `totalIndexed` - Total file count
- `averageFileSize` - Average bytes
- `totalSize` - Total bytes
- `fileTypeDistribution` - Map<String, int>
- `indexedAt` - Most recent timestamp

**HealthCheck:**
- `status` - 'healthy' | 'degraded' | 'unhealthy'
- `databaseHealthy` - bool
- `pgvectorHealthy` - bool
- `watcherHealthy` - bool
- `activeWatcherCount` - int
- `cacheHitRate` - double?
- `apiResponseTimeMs` - double
- `checkedAt` - DateTime
- `watcherDetails` - String?

**AICostSummary:**
- `totalCost` - double
- `totalTokens` - int
- `modelBreakdown` - Map<String, ModelCostInfo>
- `startDate` - DateTime
- `endDate` - DateTime

**BudgetStatus:**
- `budgetLimit` - double
- `currentSpend` - double
- `remaining` - double
- `percentageUsed` - double
- `isOverBudget` - bool

**CostProjection:**
- `projectedCost` - double
- `dailyAverage` - double
- `confidence` - 'low' | 'medium' | 'high'

## Important Notes

### Circuit Breaker Integration
All AI operations should use `CircuitBreaker` to prevent cascading failures:
- `AIService` - Chat completions
- `OpenRouterClient` - Direct API calls
- `CachedAIService` - Cache misses

### Health Check Integration
Health checks should be run periodically (every 5 minutes) to monitor system status.

### Idle Resource Cleanup
File watchers are automatically cleaned up after 30 minutes of inactivity.

### File Watching Debouncing
- File change events are debounced for 2 seconds
- File move detection has 500ms delay
- Queue limit: 10,000 pending files with LRU eviction
