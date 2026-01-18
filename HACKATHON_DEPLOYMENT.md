# Hackathon Deployment Guide - Semantic Desktop Butler

**Last Updated:** January 17, 2026  
**Target Date:** Hackathon Submission

---

## Quick Start (Development/Demo)

### Prerequisites
- Docker and Docker Compose installed
- Node.js 18+ (for website)
- Flutter 3.32+ (for desktop app)
- Dart 3.8+ (for server)

### Local Setup

#### 1. Database & Redis
```bash
cd semantic_butler/semantic_butler_server
docker-compose up -d postgres redis
```

#### 2. Server
```bash
# Copy .env.example to .env
cd semantic_butler/semantic_butler_server
cp ../.env.example .env

# Set your API key
# Edit .env and set OPENROUTER_API_KEY

# Run server
dart pub get
dart run bin/main.dart
```

#### 3. Website
```bash
cd website
npm install
npm run dev
```

#### 4. Desktop App
```bash
cd semantic_butler/semantic_butler_flutter
flutter pub get
flutter run -d windows
```

---

## Critical Security Fixes (Required Before Demo)

### 1. Remove Exposed API Key
```bash
# Revoke the exposed key at: https://openrouter.ai/keys
# Generate a new key and update .env
OPENROUTER_API_KEY=your-new-key-here

# Update .env.example to use placeholder
```

### 2. Enable Authentication
```bash
# In .env, add:
API_KEY=your-secure-random-key-here
FORCE_AUTH=false  # For demo, can be true for strict mode
```

### 3. Fix Docker Secrets
```bash
# Create secrets directory
mkdir -p semantic_butler/semantic_butler_server/secrets

# Generate secure passwords
openssl rand -base64 32 > secrets/postgres_password.txt
openssl rand -base64 32 > secrets/redis_password.txt

# Update docker-compose.yaml to use secrets
```

### 4. Disable Source Maps
```javascript
// In website/vite.config.js
sourcemap: false
```

---

## Hackathon Demo Configuration

### Server Configuration
```bash
# semantic_butler/semantic_butler_server/.env
OPENROUTER_API_KEY=sk-or-v1-your-new-key
API_KEY=demo-secret-key-2024
SERVERPOD_MODE=development
LOG_LEVEL=info
```

### Flutter App Configuration
```json
// semantic_butler/semantic_butler_flutter/assets/config.json
{
    "apiUrl": "http://localhost:8080"
}
```

### Website Configuration
```bash
# website/.env
VITE_API_BASE_URL=http://localhost:8080
VITE_ENABLE_ANALYTICS=false
VITE_ENV=demo
```

---

## Demo Script (5 Minutes)

1. **Introduction (1 min)**
   - "Semantic Butler is an AI-powered file search and organization assistant"
   - "Uses vector embeddings for semantic search across your local files"
   - Built with Dart/Flutter, Serverpod, and pgvector

2. **Semantic Search Demo (2 min)**
   - Show searching for "quarterly financial reports"
   - Demonstrate finding related documents even without exact keywords
   - Show threshold slider for result relevance

3. **AI Agent Demo (1.5 min)**
   - Ask agent to "Find all PDFs about budget"
   - Show agent using tools to search and organize files
   - Demonstrate natural language file operations

4. **File Organization Demo (0.5 min)**
   - Show creating a new folder
   - Show moving files to organized structure
   - Show undo functionality

---

## Deployment Options

### Option 1: Docker (Recommended for Demo)
```bash
cd semantic_butler/semantic_butler_server
docker build -t semantic-butler-server .
docker run -p 8080:8080 \
  -e OPENROUTER_API_KEY=your-key \
  -e API_KEY=demo-key \
  semantic-butler-server
```

### Option 2: Cloud Deployment (Vercel/Render)

#### Server (Render.com)
1. Connect GitHub repository
2. Build command: `dart compile exe bin/main.dart -o bin/server`
3. Start command: `./server --mode=production`
4. Environment variables:
   - `OPENROUTER_API_KEY`
   - `API_KEY`
   - `DATABASE_URL`
   - `REDIS_URL`

#### Website (Vercel)
1. Connect GitHub repository
2. Framework preset: Vite
3. Build command: `npm run build`
4. Output directory: `dist`
5. Environment variables:
   - `VITE_API_BASE_URL`

---

## Environment Variables Reference

### Server (.env)
```bash
# Required
OPENROUTER_API_KEY=your-openrouter-key
API_KEY=your-api-key

# Database
DATABASE_URL=postgresql://user:pass@host:5432/db

# Optional
LOG_LEVEL=info
MAX_PARALLEL_INDEXING=5
EMBEDDING_BATCH_SIZE=20
```

### Website (.env)
```bash
VITE_API_BASE_URL=https://your-domain.com
VITE_APP_NAME=Semantic Butler
VITE_ENV=production
VITE_ENABLE_ANALYTICS=false
```

### Flutter (config.json)
```json
{
    "apiUrl": "https://your-domain.com"
}
```

---

## Performance Tuning for Demo

### Server
```bash
# Increase connection pool size
DATABASE_MAX_CONNECTIONS=20

# Enable Redis caching
REDIS_ENABLED=true
REDIS_HOST=localhost
REDIS_PORT=6379

# Optimize embedding batch size
EMBEDDING_BATCH_SIZE=50
```

### Flutter
```dart
// In main.dart, set appropriate timeout
client = Client(
  serverUrl,
  connectionTimeout: const Duration(seconds: 30),
);
```

---

## Troubleshooting

### Common Issues

#### Server won't start
```bash
# Check port availability
netstat -ano | findstr :8080

# Check database connection
docker-compose ps
docker-compose logs postgres

# Verify environment variables
dart run bin/main.dart --apply-migrations
```

#### Flutter can't connect
```bash
# Verify server is running
curl http://localhost:8080

# Check config.json
cat semantic_butler/semantic_butler_flutter/assets/config.json

# Disable firewall temporarily for demo
# Windows: Windows Defender Firewall
```

#### Website build fails
```bash
# Clear node_modules
rm -rf node_modules package-lock.json
npm install

# Check Node version
node --version  # Should be 18+
```

---

## Monitoring for Demo

### Server Metrics
```bash
# Check server health
curl http://localhost:8080/health

# View logs
tail -f logs/serverpod.log

# Monitor database
docker exec -it postgres_container psql -U postgres -d semantic_butler
SELECT COUNT(*) FROM file_index;
SELECT status, COUNT(*) FROM indexing_job GROUP BY status;
```

### Performance
```dart
// In code, use MetricsService
final metrics = MetricsService.instance;
final stats = metrics.getStats();
print('Index time: ${stats.averageIndexTime}ms');
print('Search time: ${stats.averageSearchTime}ms');
```

---

## Backup & Recovery

### Database Backup
```bash
# Backup
docker exec postgres_container pg_dump -U postgres semantic_butler > backup.sql

# Restore
docker exec -i postgres_container psql -U postgres semantic_butler < backup.sql
```

### File Index Backup
```bash
# Export embeddings
docker exec postgres_container psql -U postgres semantic_butler \
  -c "COPY document_embedding TO STDOUT WITH CSV" > embeddings.csv
```

---

## Post-Hackathon Actions

### Security Hardening
- [ ] Implement proper JWT authentication
- [ ] Add rate limiting to all endpoints
- [ ] Set up HTTPS with SSL certificates
- [ ] Configure CORS properly
- [ ] Add security headers
- [ ] Set up WAF (Web Application Firewall)

### Scalability
- [ ] Implement horizontal scaling
- [ ] Add load balancing
- [ ] Set up caching layer (Redis)
- [ ] Implement job queue for indexing
- [ ] Add CDN for static assets

### Monitoring
- [ ] Set up application monitoring (Sentry, Datadog)
- [ ] Configure log aggregation
- [ ] Set up alerts for security events
- [ ] Implement health checks
- [ ] Add uptime monitoring

---

## Resources

- **Server Documentation**: `semantic_butler/semantic_butler_server/README.md`
- **Flutter Documentation**: `semantic_butler/semantic_butler_flutter/README.md`
- **Security Report**: `SECURITY_AUDIT.md`
- **API Documentation**: `semantic_butler/semantic_butler_client/doc/endpoint.md`

---

## Contact & Support

- GitHub Issues: https://github.com/your-repo/desk-sense/issues
- Documentation: https://docs.semanticbutler.com (when published)

---

**Good luck with the hackathon! 🚀**
