# Filo - Private AI Assistant

A semantic search application for your local files, powered by Flutter, Serverpod, and OpenRouter.

## Prerequisites

- **Flutter 3.0+** - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart 3.0+** - Comes with Flutter
- **Supabase account** - [Sign up free](https://supabase.com)
- **OpenRouter API key** - [Get API key](https://openrouter.ai/keys)

## Quick Start

### 1. Set Up Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Enable the **pgvector** extension:
   - Go to **Database** > **Extensions**
   - Search for "vector" and enable it
3. Get your database credentials from **Project Settings** > **Database**

### 2. Get OpenRouter API Key

1. Go to [openrouter.ai/keys](https://openrouter.ai/keys)
2. Create a new API key
3. Note: OpenRouter provides access to 200+ AI models including GPT-4, Claude, Gemini, Llama, and more

### 3. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env and add your credentials:
# - OPENROUTER_API_KEY (from OpenRouter)
# - DATABASE_URL (from Supabase)
```

### 4. Apply Database Migrations

```bash
cd semantic_butler_server

# Update the config/development.yaml with your Supabase credentials
# Create config/passwords.yaml with your database password
# Then run migrations
dart run bin/main.dart --apply-migrations
```

### 5. Run the Server

```bash
cd semantic_butler_server
dart run bin/main.dart
```

### 6. Run the Flutter App

```bash
cd semantic_butler_flutter
flutter run -d windows  # or macos, linux
```

## Project Structure

```
semantic_butler/
├── semantic_butler_server/     # Serverpod backend
│   ├── lib/src/
│   │   ├── endpoints/          # API endpoints
│   │   │   ├── butler_endpoint.dart    # Search & indexing
│   │   │   └── agent_endpoint.dart     # Natural language agent
│   │   ├── services/           # Business logic
│   │   │   ├── openrouter_client.dart  # OpenRouter API client
│   │   │   ├── ai_service.dart         # Unified AI operations
│   │   │   └── file_extraction_service.dart
│   │   ├── config/             # Configuration
│   │   │   └── ai_models.dart          # Model routing & costs
│   │   └── models/             # Database models
│   └── config/                 # Server configuration
├── semantic_butler_client/     # Generated API client
├── semantic_butler_flutter/    # Flutter desktop app
└── .github/                    # CI/CD workflows
```

## Features

- 🔍 **Semantic Search** - Find files by meaning, not just keywords
- 🤖 **AI Agent** - Natural language interface for file operations
- 🏷️ **Auto-Tagging** - AI-generated tags for all documents
- 📊 **Dashboard** - Monitor indexing progress and database health
- ⚡ **Multi-Provider** - Access 200+ AI models via OpenRouter
- 💰 **Cost Tracking** - Monitor AI usage and costs

## AI Models (via OpenRouter)

| Task | Default Model | Alternatives |
|------|---------------|--------------|
| Embeddings | `text-embedding-3-small` | `text-embedding-3-large` |
| Tag Generation | `gemini-2.5-flash` | `gpt-4o-mini`, `claude-3-haiku` |
| Agent/Complex | `claude-3.5-sonnet` | `gpt-4o`, `claude-3-opus` |

## Agent Capabilities

The AI agent can understand natural language requests:

```
"Find all my notes about React and summarize the key points"
"What's the indexing status?"
"Find documents related to my architecture notes"
"Index my Projects folder"
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `butler.semanticSearch` | Search documents semantically |
| `butler.startIndexing` | Start folder indexing |
| `butler.getIndexingStatus` | Get indexing progress |
| `agent.chat` | Natural language agent interface |

## Documentation

- [Implementation Plan](../.plan/implementation_plan.md)
- [Phase 1 MVP](../.plan/phase-1-mvp-implementation.md)
- [Phase 2 Enhanced](../.plan/phase-2-enhanced-implementation.md)
- [Phase 3 Enterprise](../.plan/phase-3-enterprise-implementation.md)

## License

MIT
