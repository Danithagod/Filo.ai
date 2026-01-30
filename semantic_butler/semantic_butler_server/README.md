# Semantic Butler Server

Serverpod backend for Semantic Butler (Filo). Handles semantic search, document indexing, AI agent operations, and file system management.

## Overview

Built with Serverpod 3.1.0. Integrates with OpenRouter for AI operations and Neon PostgreSQL with pgvector for semantic search.

## Features

- **Semantic Search** — Vector similarity search with ranking
- **Document Indexing** — Async file processing with embeddings
- **AI Agent** — Conversational interface with tool calling
- **File System Operations** — Safe file browsing and manipulation

## Prerequisites

- **Dart 3.5+**
- **Neon PostgreSQL** with pgvector extension (or local Postgres 14+)
- **OpenRouter API key** — [Get API key](https://openrouter.ai/keys)

## Quick Start

### For Hackathon Demo / Local Use

1. **Extract the backend package** and open a terminal in that folder

2. **Add OpenRouter API key** (optional, for AI features):
   ```bash
   # Copy .env.example to .env
   cp .env.example .env

   # Edit .env and add your key:
   OPENROUTER_API_KEY=your-actual-key-here
   ```

3. **Start the server**:
   ```bash
   run-server.bat
   ```

   Or with Dart:
   ```bash
   dart run bin/main.dart --apply-migrations
   ```

4. **The server runs on** `http://localhost:8080`

## Development

### Install Dependencies

```bash
dart pub get
```

### Configure Database

Edit `config/development.yaml` with your database credentials:

```yaml
database:
  host: your-db-host  # e.g., ep-xxx.aws.neon.tech for Neon
  port: 5432
  name: neondb
  user: neondb_owner
  requireSsl: true
```

Create `config/passwords.yaml`:

```yaml
development:
  database: your-db-password
```

### Run Migrations

```bash
dart run bin/main.dart --apply-migrations
```

### Start Development Server

```bash
dart run bin/main.dart
```

### Compile to Executable

```bash
dart compile exe bin/main.dart -o bin/semantic-butler-server
./bin/semantic-butler-server
```

## Project Structure

```
lib/src/
├── endpoints/           # API endpoints (butler, agent, indexing, etc.)
├── services/           # Business logic (AI, indexing, search, etc.)
├── config/             # Configuration (AI models, search settings)
├── prompts/            # AI prompts
├── utils/              # Utilities (path validation, query parsing)
├── constants/          # Constants (error types, indexing status)
└── generated/          # Serverpod generated code
```

## API Endpoints

| Endpoint | Methods | Description |
|----------|---------|-------------|
| `butler` | `semanticSearch()`, `startIndexing()`, `getIndexingStatus()` | Core search & indexing |
| `agent` | `chat()`, `getConversationHistory()` | AI chat |
| `indexing` | `getHealthReport()`, `getWatchedFolders()` | Indexing management |
| `fileSystem` | `listDirectory()`, `readFile()`, `moveFile()` | File operations |
| `health` | `check()`, `database()`, `openrouter()` | Health checks |

## AI Models (via OpenRouter)

| Task | Model |
|------|-------|
| Embeddings | `openai/text-embedding-3-small` |
| Fast Generation | `google/gemini-flash-1.5` |
| Complex Tasks | `anthropic/claude-3.5-sonnet` |

## Building Distribution Package

```bash
# Run the build script
build-package.bat

# Package is created at: ../build/semantic-butler-backend-v1.0.0-stable.zip
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "pgvector extension not found" | Run: `CREATE EXTENSION IF NOT EXISTS vector;` in your database |
| "OPENROUTER_API_KEY is NOT SET" | Create `.env` file with your API key |
| "Connection refused" on port 5432 | Check database host and credentials in config |
| "Directory does not exist" web\static | Ensure `web/static/` directory exists |

## Related Documentation

- [Flutter App README](../semantic_butler_flutter/README.md)
- [Serverpod Documentation](https://docs.serverpod.dev)

## License

MIT
