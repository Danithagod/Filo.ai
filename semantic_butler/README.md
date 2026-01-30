# Semantic Butler (Filo) - Private AI Assistant

A semantic search application for your local files, powered by Flutter, Serverpod, and OpenRouter.

## Quick Start - For Hackathon Demo

### 1. Download and Install

Get the apps from the [website](../../website):

1. **Filo Desktop App** (Windows MSIX installer)
2. **Backend Server** (ZIP package)

### 2. Start the Backend

```bash
# Extract the backend ZIP
# Create .env file with your OpenRouter API key
cp .env.example .env
# Edit .env and add: OPENROUTER_API_KEY=your-key-here

# Run the server
run-server.bat
```

### 3. Launch the Desktop App

The app will automatically connect to `http://localhost:8080`

## Development Setup

### Prerequisites

- **Flutter 3.24+** - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart 3.5+** - Comes with Flutter
- **Neon Database** (or any PostgreSQL with pgvector) - [Sign up free](https://neon.tech)
- **OpenRouter API key** - [Get API key](https://openrouter.ai/keys)

### 1. Set Up Database

1. Create a project at [neon.tech](https://neon.tech)
2. Enable the **pgvector** extension in your database
3. Get your database connection string

### 2. Configure Server

```bash
cd semantic_butler_server

# Edit config/development.yaml with your Neon credentials
# Edit config/passwords.yaml with your database password

# Install dependencies
dart pub get

# Run migrations
dart run bin/main.dart --apply-migrations

# Start server
dart run bin/main.dart
```

### 3. Run Flutter App

```bash
cd semantic_butler_flutter
flutter pub get
flutter run -d windows  # or macos, linux
```

## Project Structure

```
semantic_butler/
├── semantic_butler_server/     # Serverpod backend
│   ├── lib/src/
│   │   ├── endpoints/          # API endpoints
│   │   ├── services/           # Business logic
│   │   └── models/             # Database models
│   └── config/                 # Server configuration
├── semantic_butler_client/     # Generated API client
├── semantic_butler_flutter/    # Flutter desktop app
└── build/                      # Distribution packages
```

## Features

- 🔍 **Semantic Search** - Find files by meaning, not just keywords
- 🤖 **AI Agent** - Natural language interface for file operations
- 🏷️ **Auto-Tagging** - AI-generated tags for all documents
- 📊 **Dashboard** - Monitor indexing progress and database health
- ⚡ **Multi-Provider** - Access 200+ AI models via OpenRouter

## AI Models (via OpenRouter)

| Task | Model |
|------|-------|
| Embeddings | `openai/text-embedding-3-small` |
| Fast Generation | `google/gemini-flash-1.5` |
| Complex Tasks | `anthropic/claude-3.5-sonnet` |

## Building Distribution Packages

### Backend Server

```bash
cd semantic_butler_server
.\build-package.bat
# Creates: ../build/semantic-butler-backend-v1.0.0-stable.zip
```

### Flutter Desktop App

```bash
cd semantic_butler_flutter
flutter build windows --release
# Creates MSI installer in build/windows/x64/runner/Release/
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `butler.semanticSearch` | Search documents semantically |
| `butler.startIndexing` | Start folder indexing |
| `butler.getIndexingStatus` | Get indexing progress |
| `agent.chat` | Natural language agent interface |

## License

MIT
