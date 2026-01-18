# Security Improvements Checklist

**Project:** Semantic Desktop Butler  
**Date:** January 17, 2026  
**Purpose:** Fix all security issues before hackathon submission and production deployment

---

## Critical Issues - Do Immediately ⛔

### 1. Remove Exposed API Keys
- [ ] Revoke the exposed OpenRouter API key
- [ ] Generate new API key at https://openrouter.ai/keys
- [ ] Update `.env` file with new key
- [ ] Remove hardcoded key from `.env.example`
- [ ] Commit changes to remove key from git history

**Commands:**
```bash
# Generate new key at: https://openrouter.ai/keys
# Update semantic_butler/.env.example
OPENROUTER_API_KEY=your-openrouter-api-key-here

# Remove from git history (careful with this!)
git filter-repo --path semantic_butler/.env.example --invert-paths
```

---

### 2. Replace Hardcoded Database Passwords
- [ ] Generate secure PostgreSQL passwords
- [ ] Generate secure Redis passwords
- [ ] Update `docker-compose.yaml` to use Docker secrets or environment variables
- [ ] Remove hardcoded passwords from version control

**Commands:**
```bash
# Generate secure passwords
openssl rand -base64 32 > semantic_butler/semantic_butler_server/secrets/postgres_password.txt
openssl rand -base64 32 > semantic_butler/semantic_butler_server/secrets/redis_password.txt

# Update docker-compose.yaml
# See example below in "Docker Secrets Configuration"
```

---

### 3. Generate Secure Service Secrets
- [ ] Generate cryptographically strong service secret
- [ ] Update `config/passwords.yaml` or use environment variables
- [ ] Ensure file is properly `.gitignore`'d

**Commands:**
```bash
# Generate service secret
openssl rand -base64 32

# Update .env
echo "SERVICE_SECRET=$(openssl rand -base64 32)" >> semantic_butler/semantic_butler_server/.env

# Remove config/passwords.yaml if using env vars
rm semantic_butler/semantic_butler_server/config/passwords.yaml
```

---

### 4. Fix Logging to Not Leak Credentials
- [ ] Remove or secure the API key logging in `lib/server.dart:26-28`
- [ ] Review all logging statements for sensitive data
- [ ] Ensure production logs don't contain secrets

**Code Change:**
```dart
// In semantic_butler/semantic_butler_server/lib/server.dart
// Remove lines 26-28 or replace with:
final apiKey = getEnv('OPENROUTER_API_KEY');
if (apiKey.isEmpty && getEnv('SERVERPOD_MODE') == 'production') {
  throw Exception('OPENROUTER_API_KEY must be set in production');
}
```

---

## High Priority - Fix Before Production 🔴

### 5. Enable Authentication
- [ ] Set `API_KEY` environment variable
- [ ] Set `FORCE_AUTH=true` for production mode
- [ ] Call `AuthService.requireAuth()` at start of protected endpoints
- [ ] Test authentication with invalid keys

**Code Changes:**

```dart
// In lib/server.dart
final isProduction = getEnv('SERVERPOD_MODE') == 'production';
if (isProduction && getEnv('API_KEY', defaultValue: '').isEmpty) {
  throw Exception('API_KEY must be set in production mode');
}
```

```dart
// In ButlerEndpoint (butler_endpoint.dart)
@override
Future<void> indexFolder(Session session, String folderPath) async {
  // Add at the beginning of endpoint methods
  AuthService.requireAuth(session);
  
  // ... rest of the code
}
```

**Environment Variables:**
```bash
# In .env
API_KEY=your-secure-api-key-here-32-characters-long
FORCE_AUTH=true  # For production
SERVERPOD_MODE=production
```

---

### 6. Disable Source Maps in Production
- [ ] Update `vite.config.js` to disable source maps
- [ ] Remove sourcemap files if they exist
- [ ] Rebuild the website

**Code Change:**
```javascript
// In website/vite.config.js
export default defineConfig(({ mode }) => ({
  plugins: [react()],
  build: {
    outDir: 'dist',
    sourcemap: false,  // Or: sourcemap: mode === 'development',
    // ... rest of config
  }
}));
```

---

### 7. Implement Rate Limiting
- [ ] Add rate limiting to `ButlerEndpoint.indexFolder()`
- [ ] Add rate limiting to `ButlerEndpoint.semanticSearch()`
- [ ] Add rate limiting to `AgentEndpoint.chat()`
- [ ] Add rate limiting to `FileSystemEndpoint` methods
- [ ] Configure environment-based rate limiting

**Code Example:**
```dart
// In ButlerEndpoint
@override
Future<SearchResult> semanticSearch(
  Session session,
  String query, {
  int? limit,
  double? threshold,
}) async {
  // Add rate limiting
  RateLimitService.instance.requireRateLimit(
    session.connectionId.toString(),
    'semanticSearch',
    limit: 60,  // 60 requests per minute
  );
  
  // ... rest of the code
}
```

---

### 8. Configure CORS Policy
- [ ] Add CORS configuration to server initialization
- [ ] Configure allowed origins
- [ ] Configure allowed methods and headers
- [ ] Test CORS from different origins

**Code Change:**
```dart
// In lib/server.dart, after pod initialization
final pod = Serverpod(args, Protocol(), Endpoints());

// Configure CORS
pod.apiServer.corsPolicy = CorsPolicy(
  allowedOrigins: [
    'https://semantic-butler.app',
    'http://localhost:3000',  // Development
  ],
  allowedMethods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-api-key'],
  credentials: true,
);
```

---

### 9. Secure Database Configuration
- [ ] Remove hardcoded database host from `development.yaml`
- [ ] Use environment variables for database connection
- [ ] Ensure SSL is enabled for all database connections

**Code Change:**
```yaml
# In semantic_butler/semantic_butler_server/config/development.yaml
database:
  host: ${DATABASE_HOST:-localhost}
  port: ${DATABASE_PORT:-5432}
  name: ${DATABASE_NAME:-semantic_butler}
  user: ${DATABASE_USER:-postgres}
  requireSsl: ${DATABASE_SSL:-true}
```

**Environment Variables:**
```bash
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=semantic_butler
DATABASE_USER=postgres
DATABASE_PASSWORD=your-secure-password
DATABASE_SSL=true
```

---

## Medium Priority - Fix Before Scale 🟡

### 10. Update .gitignore
- [ ] Add comprehensive exclusions
- [ ] Remove sensitive files from git history if needed
- [ ] Verify .gitignore is working

**Add to .gitignore:**
```gitignore
# Environment
.env
.env.local
.env.*.local
*.env

# Build
build/
dist/
node_modules/
.dart_tool/
flutter_build/

# Secrets
*.pem
*.key
secrets/
config/passwords.yaml
config/firebase_service_account_key.json
**/secrets/*
**/*.secret

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
yarn-error.log*
serverpod.log

# Coverage
coverage/
*.lcov
```

---

### 11. Improve Path Validation
- [ ] Make protected paths case-insensitive on Windows
- [ ] Add more system paths to protected list
- [ ] Normalize paths before comparison

**Code Improvement:**
```dart
// In lib/src/services/file_operations_service.dart
static Set<String> _getProtectedPaths() {
  if (Platform.isWindows) {
    return {
      r'C:\Windows',
      r'C:\Program Files',
      r'C:\Program Files (x86)',
      r'C:\ProgramData',
      r'C:\Windows\System32',
      r'C:\Windows\SysWOW64',
    }.map((p) => p.toLowerCase()).toSet();
  } else if (Platform.isMacOS) {
    return {
      '/',
      '/System',
      '/Library',
      '/usr',
      '/bin',
      '/sbin',
      '/etc',
      '/var',
    };
  } else if (Platform.isLinux) {
    return {
      '/',
      '/usr',
      '/bin',
      '/sbin',
      '/etc',
      '/var',
      '/sys',
      '/proc',
    };
  }
  return {};
}

// Update validation to use normalized paths
static bool _isProtectedPath(String path) {
  final normalized = path.normalize(path).toLowerCase();
  final protectedPaths = _getProtectedPaths();
  return protectedPaths.any((protected) => 
    normalized.startsWith(protected.toLowerCase())
  );
}
```

---

### 12. Add Security Headers
- [ ] Add Content-Security-Policy header
- [ ] Add X-Frame-Options header
- [ ] Add X-Content-Type-Options header
- [ ] Add Strict-Transport-Security header

**Code Change:**
```dart
// In lib/server.dart
pod.apiServer.responseHeaders = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'X-XSS-Protection': '1; mode=block',
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
  'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'",
};
```

---

### 13. Implement Proper HTTPS Enforcement
- [ ] Configure reverse proxy (nginx/Apache) for SSL termination
- [ ] Add HTTPS redirect in production
- [ ] Ensure all API calls use HTTPS in production
- [ ] Update production config URLs

**Nginx Configuration Example:**
```nginx
server {
    listen 80;
    server_name api.semantic-butler.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name api.semantic-butler.com;

    ssl_certificate /etc/ssl/certs/cert.pem;
    ssl_certificate_key /etc/ssl/certs/key.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

### 14. Remove or Fully Implement Auth
- [ ] Decide on authentication strategy
- [ ] Either fully implement Serverpod auth OR use custom AuthService
- [ ] Remove commented-out auth code
- [ ] Document the chosen auth approach

---

## Low Priority - Best Practices 🟢

### 15. Add Dependency Scanning
```bash
# Scan for vulnerabilities
cd semantic_butler/semantic_butler_server
dart pub outdated

cd website
npm audit
```

---

### 16. Add Automated Tests
- [ ] Add unit tests for authentication
- [ ] Add unit tests for rate limiting
- [ ] Add unit tests for input validation
- [ ] Add integration tests for API endpoints

---

### 17. Set Up Monitoring
- [ ] Configure error tracking (Sentry)
- [ ] Set up logging aggregation
- [ ] Add performance monitoring
- [ ] Configure alerts for security events

---

### 18. Add Health Checks
```dart
// In ButlerEndpoint
@override
Future<Map<String, dynamic>> healthCheck(Session session) async {
  return {
    'status': 'healthy',
    'timestamp': DateTime.now().toIso8601String(),
    'version': '1.0.0',
  };
}
```

---

## Docker Secrets Configuration

### docker-compose.yaml Update
```yaml
services:
  postgres:
    image: pgvector/pgvector:pg16
    ports:
      - "8090:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_DB: semantic_butler
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
    secrets:
      - postgres_password
    volumes:
      - semantic_butler_data:/var/lib/postgresql/data

  redis:
    image: redis:6.2.6
    ports:
      - "8091:6379"
    command: redis-server --requirepass $(cat /run/secrets/redis_password)
    environment:
      - REDIS_REPLICATION_MODE=master
    secrets:
      - redis_password

secrets:
  postgres_password:
    file: ./secrets/postgres_password.txt
  redis_password:
    file: ./secrets/redis_password.txt

volumes:
  semantic_butler_data:
```

### Create Secrets Directory and Files
```bash
mkdir -p semantic_butler/semantic_butler_server/secrets

# Generate and store passwords
openssl rand -base64 32 > semantic_butler/semantic_butler_server/secrets/postgres_password.txt
openssl rand -base64 32 > semantic_butler/semantic_butler_server/secrets/redis_password.txt

# Set proper permissions (Linux/Mac)
chmod 600 semantic_butler/semantic_butler_server/secrets/*.txt
```

---

## Verification Checklist

### After All Fixes:
- [ ] Run `flutter analyze` - no errors
- [ ] Run `dart analyze` - no errors
- [ ] Run tests: `flutter test` and `dart test`
- [ ] Build website: `npm run build` - no errors
- [ ] Build server: `dart compile exe bin/main.dart`
- [ ] Test authentication with valid key
- [ ] Test authentication with invalid key (should fail)
- [ ] Test rate limiting (should limit after threshold)
- [ ] Test input validation with malicious inputs
- [ ] Test path traversal attempts (should be blocked)
- [ ] Verify no secrets in repository
- [ ] Verify no secrets in build artifacts
- [ ] Check source maps are not generated
- [ ] Verify CORS is configured correctly
- [ ] Test HTTPS redirect (if applicable)

---

## Environment Variables Template

### Production (.env.production)
```bash
# Server Configuration
SERVERPOD_MODE=production
API_KEY=your-secure-api-key-here-generate-with-openssl-rand-base64-32
FORCE_AUTH=true

# Database
DATABASE_HOST=your-production-db-host
DATABASE_PORT=5432
DATABASE_NAME=semantic_butler
DATABASE_USER=postgres
DATABASE_PASSWORD=your-secure-password

# AI Services
OPENROUTER_API_KEY=your-openrouter-api-key
EMBEDDING_BATCH_SIZE=20
MAX_PARALLEL_INDEXING=5

# Logging
LOG_LEVEL=info

# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_PER_MINUTE=60
```

### Development (.env)
```bash
# Server Configuration
SERVERPOD_MODE=development
API_KEY=dev-key-only
FORCE_AUTH=false

# Database
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=semantic_butler
DATABASE_USER=postgres
DATABASE_PASSWORD=dev-password

# AI Services
OPENROUTER_API_KEY=your-dev-api-key
EMBEDDING_BATCH_SIZE=10
MAX_PARALLEL_INDEXING=3

# Logging
LOG_LEVEL=debug

# Rate Limiting
RATE_LIMIT_ENABLED=false
```

---

## Testing Commands

```bash
# Test authentication
curl -H "x-api-key: valid-key" http://localhost:8080/api/butler/healthCheck

# Test rate limiting
for i in {1..70}; do
  curl http://localhost:8080/api/butler/healthCheck
done

# Test SQL injection (should be blocked)
curl -X POST http://localhost:8080/api/butler/semanticSearch \
  -H "Content-Type: application/json" \
  -d '{"query": "test'; DROP TABLE file_index; --"}'

# Test path traversal (should be blocked)
curl -X POST http://localhost:8080/api/butler/indexFolder \
  -H "Content-Type: application/json" \
  -d '{"folderPath": "../../../etc/passwd"}'

# Scan for secrets
trufflehog repo https://github.com/your-repo/desk-sense
```

---

## Deployment Sequence

1. **Before Deployment**
   - [ ] Run all security tests
   - [ ] Verify all critical issues are fixed
   - [ ] Generate new secrets
   - [ ] Update environment variables
   - [ ] Backup existing data

2. **Deploy**
   - [ ] Deploy server with new configuration
   - [ ] Verify server is running
   - [ ] Test authentication
   - [ ] Test rate limiting
   - [ ] Verify HTTPS is working
   - [ ] Deploy website
   - [ ] Deploy desktop app

3. **Post-Deployment**
   - [ ] Monitor logs for errors
   - [ ] Verify all endpoints are secured
   - [ ] Test with invalid inputs
   - [ ] Check for any exposed data
   - [ ] Update documentation

---

## Contact

For questions or issues, please refer to:
- **Security Audit Report**: `SECURITY_AUDIT.md`
- **Deployment Guide**: `HACKATHON_DEPLOYMENT.md`
- **GitHub Issues**: https://github.com/your-repo/desk-sense/issues

---

**Remember**: Security is an ongoing process. Regularly review and update these checks.
