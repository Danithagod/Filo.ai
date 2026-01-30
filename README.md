# Filo

> **Your intelligent file search. Understands meaning, not just keywords.**

Filo is a private AI assistant that brings semantic search to your local files. Ask questions in natural language and find documents based on meaning, not just keywords. All processing happens locally—your files never leave your machine.

## What is Filo?

Filo (short for "File Intelligence") is a desktop application that indexes your documents and makes them searchable through AI-powered semantic understanding. Unlike traditional search tools that match keywords, Filo understands the *meaning* of your queries and returns relevant results even when words don't exactly match.

**Key features:**

- **Semantic Search** — Find files by meaning: *"Where did I document Serverpod's architecture?"*
- **AI Agent** — Natural language interface for complex queries and file operations
- **Auto-Tagging** — AI automatically generates descriptive tags for every document
- **Privacy-First** — Local processing means your documents stay on your machine
- **Dashboard** — Monitor indexing progress, database health, and system statistics

---

## How It Works

```
Your Documents → Vector Embeddings → Semantic Search
     ↓                 ↓                    ↓
  Local Files    PostgreSQL/pgvector   Natural Language
```

1. **Indexing**: Filo scans your selected folders, extracts text from documents, and converts the content into vector embeddings using AI models.
2. **Storage**: Embeddings are stored locally in PostgreSQL with the pgvector extension.
3. **Searching**: When you ask a question, Filo converts your query to an embedding and finds semantically similar documents using vector similarity search.

---

## Architecture

This is a monorepo containing three main components:

| Component | Description | Technology |
|-----------|-------------|------------|
| **Filo Desktop App** | Cross-platform desktop application | Flutter 3.24+ |
| **Serverpod Backend** | API server with business logic | Serverpod 3.1.0 |
| **Marketing Website** | Product landing page | React + Vite |

```
desk-sense/
├── semantic_butler/
│   ├── semantic_butler_flutter/    # Desktop app (Windows, macOS, Linux)
│   ├── semantic_butler_server/     # Serverpod backend
│   └── semantic_butler_client/     # Generated API client
├── website/                        # Marketing website (Vite + React)
└── .plan/                          # Product documentation
```

---

## Quick Start

### Prerequisites

- **Flutter 3.24+** — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart 3.5+** — Included with Flutter
- **PostgreSQL 14+** with **pgvector** extension
- **OpenRouter API key** — [Get API key](https://openrouter.ai/keys)

### 1. Database Setup

Enable the pgvector extension in PostgreSQL:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

### 2. Configure Environment

```bash
cd semantic_butler
cp .env.example .env
```

Edit `.env` and add your OpenRouter API key:

```bash
OPENROUTER_API_KEY=your-openrouter-api-key-here
```

### 3. Configure Database

Edit `semantic_butler_server/config/development.yaml` with your database credentials, and create `config/passwords.yaml` with your database password.

### 4. Run Migrations and Start Server

```bash
cd semantic_butler/semantic_butler_server

# Apply database migrations
dart run bin/main.dart --apply-migrations

# Start the server
dart run bin/main.dart
```

### 5. Run the Desktop App

```bash
cd semantic_butler/semantic_butler_flutter
flutter run -d windows    # or macos, linux
```

---

## Features

### Semantic Search

Search using natural language instead of exact keywords:

| Query | Finds |
|-------|-------|
| *"Notes about React architecture"* | Documents about React, frontend, components, even without the word "architecture" |
| *"Financial planning 2024"* | Budget documents, tax files, retirement planning |
| *"How do I handle PostgreSQL connection pooling?"* | Code files, documentation, technical notes |

### AI Agent

The agent understands complex multi-part requests:

```bash
"Find all my notes about React and summarize the key points"
"What's the current indexing status?"
"Find documents related to my architecture notes"
"Index my Projects folder"
```

### Auto-Tagging

Every document is automatically tagged with:

- **Primary Topic** — Main subject (e.g., "Vector Databases", "Product Strategy")
- **Document Type** — Format (e.g., "PDF", "Code", "Meeting Notes")
- **Date** — Extracted or inferred creation date
- **Entities** — Named entities (people, companies, projects)
- **Technical Keywords** — Domain-specific terms

### Dashboard

Monitor your knowledge base:

- Total documents indexed
- Database size and vector count
- Indexing progress and recent activity
- Error logs for failed indexing attempts

---

## Technology Stack

### Desktop Application
- **Flutter 3.24+** — Cross-platform UI framework
- **Riverpod** — State management
- **FL Chart** — Data visualization
- **File Picker** — Folder selection

### Backend
- **Serverpod 3.1.0** — Dart-based backend framework
- **PostgreSQL 14+** — Database with pgvector for vector similarity
- **OpenRouter** — Access to 200+ AI models

### AI Models (via OpenRouter)

| Task | Default Model |
|------|---------------|
| Embeddings | `openai/text-embedding-3-small` |
| Fast Tasks | `google/gemini-flash-1.5` |
| Complex Tasks | `anthropic/claude-3.5-sonnet` |

---

## Development

### Project Structure

```
semantic_butler/
├── semantic_butler_server/
│   ├── lib/src/
│   │   ├── endpoints/          # API endpoints
│   │   │   ├── butler_endpoint.dart      # Search & indexing
│   │   │   ├── agent_endpoint.dart       # AI agent
│   │   │   ├── indexing_endpoint.dart    # Indexing management
│   │   │   └── health_endpoint.dart      # Health checks
│   │   ├── models/             # Database models
│   │   └── services/           # Business logic
│   └── config/                 # Server configuration
├── semantic_butler_flutter/
│   ├── lib/
│   │   ├── screens/           # UI screens
│   │   ├── widgets/           # Reusable widgets
│   │   └── providers/         # State management
│   └── assets/                # Images, config
└── semantic_butler_client/    # Generated API client
```

### Running the Website

```bash
cd website
npm install
npm run dev
```

---

## Documentation

- [Product Requirements Document](.plan/semantic-desktop-butler-prd.md)
- [Implementation Plan](.plan/implementation_plan.md)
- [Phase 1: MVP](.plan/phase-1-mvp-implementation.md)
- [Phase 2: Enhanced](.plan/phase-2-enhanced-implementation.md)
- [Phase 3: Enterprise](.plan/phase-3-enterprise-implementation.md)

---

## License

MIT

---

## Download

**Windows** — [Download installer](website/download)

**macOS / Linux** — Coming soon

---

## Roadmap

| Phase | Features | Status |
|-------|----------|--------|
| **MVP** | Semantic search, auto-tagging, dashboard | In Development |
| **Phase 2** | Real-time monitoring, hybrid search, browser extension | Planned |
| **Phase 3** | Mobile apps, team collaboration, enterprise features | Planned |
