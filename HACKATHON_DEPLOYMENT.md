# Hackathon Deployment Guide - Filo (Flutter Butler)

**Last Updated:** January 28, 2026
**Hackathon:** Build your Flutter Butler with Serverpod
**Submission Deadline:** January 30, 2026 (5:00 PM CET)
**Devpost:** https://serverpod.devpost.com/

> **IMPORTANT:** This guide is for the "Build your Flutter Butler with Serverpod" hackathon. All submissions must use Flutter + Serverpod and be newly created during the hackathon period (December 9, 2025 - January 30, 2026).

---

## Table of Contents

1. [Hackathon Overview](#hackathon-overview)
2. [Devpost Submission Checklist](#devpost-submission-checklist)
3. [Judging Criteria](#judging-criteria)
4. [Quick Start (Development/Demo)](#quick-start-developmentdemo)
5. [Building the Desktop Installer](#building-the-desktop-installer)
6. [Deploying Installer to Website](#deploying-installer-to-website)
7. [Automated Installer Deployment (CI/CD)](#automated-installer-deployment-cicd)
8. [Version Management](#version-management)
9. [Critical Security Fixes](#critical-security-fixes-required-before-demo)
10. [Hackathon Demo Configuration](#hackathon-demo-configuration)
11. [Demo Video Script](#demo-video-script-3-minutes)
12. [Deployment Options](#deployment-options)
13. [Download Analytics](#download-analytics--tracking)
14. [Quick Deploy for Hackathon](#quick-deploy-for-hackathon-one-command)
15. [Updated Website CI/CD](#updated-website-cicd-with-downloads)
16. [Environment Variables](#environment-variables-reference)
17. [Performance Tuning](#performance-tuning-for-demo)
18. [Troubleshooting](#troubleshooting)
19. [Monitoring](#monitoring-for-demo)
20. [Backup & Recovery](#backup--recovery)
21. [Post-Hackathon Actions](#post-hackathon-actions)

---

## Hackathon Overview

### Key Dates
| Event | Date (CET) |
|-------|------------|
| Registration Opens | December 9, 2025 (5:00 PM) |
| Submission Period | December 9, 2025 - January 30, 2026 (5:00 PM) |
| Feedback Period | December 9, 2025 - January 30, 2026 (5:00 PM) |
| Popular Choice Voting | February 9, 2026 (5:00 PM) - February 13, 2026 (5:00 PM) |
| Judging Period | February 9, 2026 (8:00 AM) - February 20, 2026 (5:00 PM) |
| Winners Announced | On or around March 2, 2026 (5:00 PM) |

### Prizes
| Place | Prize |
|-------|-------|
| 1st Place | $5,000 Cash + $2,500 Serverpod Cloud Credits |
| 2nd Place | $3,000 Cash + $2,000 Serverpod Cloud Credits |
| 3rd Place | $1,000 Cash + $1,500 Serverpod Cloud Credits |
| 4th Place | $500 Cash + $1,500 Serverpod Cloud Credits |
| 5th Place | $1,500 Serverpod Cloud Credits |
| Most Valuable Feedback | $500 Cash + $500 Serverpod Cloud Credits |
| Popular Choice | $500 Serverpod Cloud Credits |

### Free Resources for Participants
- **Serverpod Cloud Credits** - Free hosting until March 10, 2026
- **Gemini API Credits** - For powering AI features
- **Serverpod Discord Access** - Support and community

### Project Requirements
- Must be a **Flutter app** powered by **Serverpod**
- Must function as a personal assistant, automation, or helpful service (your "Flutter Butler")
- Can be practical, fun, or experimental
- Must be **newly created** during the hackathon period (no existing projects)
- Must integrate third-party SDKs/APIs only if you have proper authorization

---

## Devpost Submission Checklist

### Required Components
- [ ] **Project built with Flutter + Serverpod** - Only new and original projects
- [ ] **Demo video** - Under 3 minutes (judges will NOT watch beyond 3 minutes)
- [ ] **Project description** - Explain features and how it was built
- [ ] **Code repository link** - GitHub or similar
  - If private: Share with viktor@serverpod.dev, alexander@serverpod.dev, isak@serverpod.dev
- [ ] **Build/run instructions** - Clear setup steps
- [ ] **Working project access** - Demo link or test build credentials

### Optional Components
- [ ] Screenshots
- [ ] Design mockups
- [ ] Additional documentation
- [ ] **Feedback form submission** - For Most Valuable Feedback Prize

### Video Requirements
- [ ] Under 3 minutes duration
- [ ] Shows project functioning on target device (desktop)
- [ ] Uploaded to YouTube, Vimeo, Facebook Video, or Youku
- [ ] Public link provided in submission form
- [ ] No third-party trademarks (unless authorized)
- [ ] No copyrighted music or material

### Language
- All submission materials must be in **English**
- Non-English submissions must include English translations

---

## Judging Criteria

### Stage One: Viability Check (Pass/Fail)
- Does the project fit the "Flutter Butler" theme?
- Does it properly use Flutter + Serverpod?

### Stage Two: Detailed Scoring (Equally Weighted)

| Criterion | Description | How Filo Excels |
|-----------|-------------|-----------------|
| **Innovation** | How original or clever is the idea? | Semantic search "by meaning not keywords" - novel approach to file management using vector embeddings |
| **Technical Execution & UX** | Is it technically sound, functional, polished? Is the app intuitive? | Flutter UI with Serverpod backend, streaming AI, real-time indexing, polished Material 3 design |
| **Impact** | Does it meaningfully help users, improve workflows, make life simpler? | Solves universal problem of file clutter; finds files faster, organizes automatically, summarizes documents |

### Tips for High Scores
1. **Innovation**: Emphasize what makes your project unique
2. **Technical**: Show clean code, proper error handling, responsive UI
3. **Impact**: Demonstrate real-world use cases and user benefits

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

## Building the Desktop Installer

### Windows Installer (MSIX/EXE)

```bash
cd semantic_butler/semantic_butler_flutter

# Ensure dependencies are installed
flutter pub get

# Check Flutter installation
flutter doctor

# Build Windows release (creates executable)
flutter build windows --release

# Output location: build/windows/runner/Release/
# Main executable: semantic_butler_flutter.exe

# For MSIX installer (recommended for distribution):
flutter pub add msix
flutter pub run msix:create

# Output location: build/windows/runner/Release/semantic_butler_flutter.msix
```

### macOS Installer (DMG)

```bash
cd semantic_butler/semantic_butler_flutter

# Build macOS release
flutter build macos --release

# Output location: build/macos/Build/Products/Release/
# For DMG creation, use brew install create-dmg
create-dmg "Filo.dmg" build/macos/Build/Products/Release/
```

### Linux Installer (AppImage/Deb)

```bash
cd semantic_butler/semantic_butler_flutter

# Build Linux release
flutter build linux --release

# Output location: build/linux/{}/release/bundle/

# For AppImage (universal Linux package):
# Install appimage-builder from https://appimage-builder.readthedocs.io
```

---

## Deploying Installer to Website

### Step 1: Prepare Download Directory

```bash
# Create downloads directory in website public folder
mkdir -p website/public/downloads

# Copy built installers to downloads directory
# Windows
cp semantic_butler/semantic_butler_flutter/build/windows/runner/Release/*.msix \
   website/public/downloads/filo-windows.msix

# macOS (if built)
cp semantic_butler/semantic_butler_flutter/build/macos/Build/Products/Release/*.dmg \
   website/public/downloads/filo-macos.dmg

# Linux (if built)
cp semantic_butler/semantic_butler_flutter/build/linux/*/release/bundle/*.appimage \
   website/public/downloads/filo-linux.appimage
```

### Step 2: Update Website Download Links

#### Option A: Create a Dedicated Download Page

Create [website/src/pages/Download/Download.jsx](website/src/pages/Download/Download.jsx):

```jsx
import React from 'react';
import { Download, Windows, Apple, Linux } from 'lucide-react';

const Download = () => {
  return (
    <div className="download-page page-content visible">
      <section className="download-hero">
        <div className="container">
          <h1>Download <span className="text-gradient">Filo</span></h1>
          <p>Your AI-powered file assistant, built with Flutter + Serverpod</p>
        </div>
      </section>

      <section className="downloads-grid">
        <div className="container">
          <div className="download-cards">
            {/* Windows */}
            <a href="/downloads/filo-windows.msix" className="download-card">
              <Windows size={48} />
              <h3>Windows</h3>
              <p>Windows 10/11 (MSIX)</p>
              <Download size={20} />
            </a>

            {/* macOS */}
            <a href="/downloads/filo-macos.dmg" className="download-card">
              <Apple size={48} />
              <h3>macOS</h3>
              <p>macOS 12+ (Intel & Apple Silicon)</p>
              <Download size={20} />
            </a>

            {/* Linux */}
            <a href="/downloads/filo-linux.appimage" className="download-card">
              <Linux size={48} />
              <h3>Linux</h3>
              <p>Ubuntu, Fedora, Debian (AppImage)</p>
              <Download size={20} />
            </a>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Download;
```

#### Add Route in App.jsx

Update [website/src/App.jsx](website/src/App.jsx:94-95):

```jsx
import Download from './pages/Download/Download';

// Add route inside Routes:
<Route path="/download" element={<Download show={!loading} />} />
```

### Step 3: Configure Static File Serving

#### Vercel (Automatic)
The `public/` directory is automatically served. No configuration needed.

#### Netlify
Create [website/netlify.toml](website/netlify.toml):

```toml
[[headers]]
  for = "/downloads/*"
  [headers.values]
    Content-Type = "application/octet-stream"
    Content-Disposition = "attachment"
```

---

## Automated Installer Deployment (CI/CD)

### GitHub Actions Workflow

Create [`.github/workflows/release.yml`](../.github/workflows/release.yml):

```yaml
name: Release Installer

on:
  push:
    tags:
      - 'v*'

jobs:
  build-windows:
    name: Build Windows Installer
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.0'
          channel: 'stable'

      - name: Build Windows Release
        run: |
          cd semantic_butler/semantic_butler_flutter
          flutter pub get
          flutter build windows --release

      - name: Create MSIX
        run: |
          cd semantic_butler/semantic_butler_flutter
          flutter pub run msix:create

      - name: Upload to Releases
        uses: softprops/action-gh-release@v1
        with:
          files: |
            semantic_butler/semantic_butler_flutter/build/windows/runner/Release/*.msix
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  build-macos:
    name: Build macOS Installer
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.0'
          channel: 'stable'

      - name: Build macOS Release
        run: |
          cd semantic_butler/semantic_butler_flutter
          flutter pub get
          flutter build macos --release

      - name: Create DMG
        run: |
          brew install create-dmg
          create-dmg "Filo.dmg" \
            semantic_butler/semantic_butler_flutter/build/macos/Build/Products/Release/

      - name: Upload to Releases
        uses: softprops/action-gh-release@v1
        with:
          files: Filo.dmg
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  update-website:
    name: Update Website Downloads
    needs: [build-windows, build-macos]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Download Artifacts
        uses: robinraju/release-downloader@v1
        with:
          repository: ${{ github.repository }}
          tag: ${{ github.ref_name }}
          fileName: "*.msix,*.dmg"

      - name: Copy to Website
        run: |
          mkdir -p website/public/downloads
          mv *.msix website/public/downloads/filo-windows.msix
          mv *.dmg website/public/downloads/filo-macos.dmg

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.ORG_ID }}
          vercel-project-id: ${{ secrets.PROJECT_ID }}
          vercel-args: '--prod'
```

---

## Version Management

### Update App Version

1. Update `pubspec.yaml`:
```yaml
version: 1.0.0+2
```

2. Update Windows Runner.rc:
```rc
FILEVERSION 1,0,0,2
PRODUCTVERSION 1,0,0,2
```

3. Create git tag and push:
```bash
git tag v1.0.0
git push origin v1.0.0
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

## Demo Video Script (3 Minutes)

> **CRITICAL:** Judges will NOT watch beyond 3 minutes. Keep it tight!

### Time Breakdown

| Scene | Duration | Key Focus |
|-------|----------|-----------|
| Opening | 0:25 | Problem statement + Flutter + Serverpod intro |
| Semantic Search | 0:30 | Core value prop - search by meaning |
| AI Chat | 0:35 | AI assistance + file understanding |
| Serverpod Backend | 0:25 | Technical execution - real-time features |
| Dashboard | 0:30 | User experience + control |
| Cross-Platform | 0:20 | Flutter benefits + privacy |
| Closing | 0:15 | Summary + call to action |
| **Total** | **3:00** | |

### Full Script

See [DEMO_VIDEO_SCRIPT.md](./DEMO_VIDEO_SCRIPT.md) for the complete 3-minute demo script.

---

## Deployment Options

### Option 1: Docker (Recommended for Demo)
```bash
cd semantic_butler/semantic_butler_server
docker build -t filo-server .
docker run -p 8080:8080 \
  -e OPENROUTER_API_KEY=your-key \
  -e API_KEY=demo-key \
  filo-server
```

### Option 2: Serverpod Cloud (Free for Hackathon)
```bash
# Deploy to Serverpod Cloud - free until March 10, 2026
# Check your hackathon registration email for credits

serverpod deploy
```

### Option 3: Cloud Deployment (Render)

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
6. **Important**: The `public/downloads/` directory will be automatically served as static files

---

## Download Analytics & Tracking

### Track Download Count

Create [website/public/downloads/track.js](website/public/downloads/track.js):

```javascript
// Redirect with tracking
const platform = localStorage.getItem('platform') || 'unknown';
const version = localStorage.getItem('version') || 'latest';

// Track download event (if using analytics)
if (window.gtag) {
  gtag('event', 'download', {
    'event_category': 'installer',
    'event_label': platform,
    'value': version
  });
}

// Redirect to actual file
window.location.href = window.location.pathname.replace('/track/', '/downloads/');
```

---

## Quick Deploy for Hackathon (One-Command)

### Build All and Copy to Website

```bash
# From project root

# 1. Build Windows installer
cd semantic_butler/semantic_butler_flutter
flutter pub get
flutter build windows --release
flutter pub add msix
flutter pub run msix:create

# 2. Copy to website downloads
mkdir -p ../../website/public/downloads
cp build/windows/runner/Release/*.msix ../../website/public/downloads/

# 3. Deploy website (Vercel CLI)
cd ../../website
npm run build
vercel --prod
```

### Using a Single Script

Create [deploy-hackathon.sh](deploy-hackathon.sh) in project root:

```bash
#!/bin/bash
set -e

echo "🚀 Building Filo for Hackathon Demo..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Step 1: Building Flutter app...${NC}"
cd semantic_butler/semantic_butler_flutter
flutter pub get
flutter build windows --release

echo -e "${BLUE}Step 2: Creating MSIX installer...${NC}"
flutter pub add msix || true
flutter pub run msix:create

echo -e "${BLUE}Step 3: Copying installer to website...${NC}"
mkdir -p ../../website/public/downloads
cp build/windows/runner/Release/*.msix ../../website/public/downloads/filo-windows.msix
echo -e "${GREEN}✅ Installer copied to website/public/downloads/${NC}"

echo -e "${BLUE}Step 4: Building website...${NC}"
cd ../../website
npm install
npm run build

echo -e "${GREEN}✅ Hackathon deployment ready!${NC}"
echo ""
echo "Next steps:"
echo "1. Deploy to Vercel: vercel --prod"
echo "2. Or deploy to Netlify: netlify deploy --prod"
echo "3. Or serve locally: npm run preview"
```

---

## Updated Website CI/CD (With Downloads)

Update [website/.github/workflows/ci-cd.yml](website/.github/workflows/ci-cd.yml) to include downloads deployment:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [18.x, 20.x]

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run formatter check
        run: npm run format -- --check

      - name: Run tests
        run: npm run test

      - name: Build application
        run: npm run build

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-dist-${{ matrix.node-version }}
          path: dist/

      - name: Upload downloads directory
        uses: actions/upload-artifact@v3
        with:
          name: downloads-files
          path: public/downloads/
          if-no-files-found: ignore

  deploy:
    name: Deploy
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20.x'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build application
        run: npm run build

      - name: Deploy to Vercel (Production)
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
          working-directory: ./
```

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
VITE_APP_NAME=Filo
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
docker exec -it postgres_container psql -U postgres semantic_butler
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

- **Hackathon Main Page**: https://serverpod.devpost.com/
- **Hackathon Rules**: https://serverpod.devpost.com/rules
- **Server Documentation**: `semantic_butler/semantic_butler_server/README.md`
- **Flutter Documentation**: `semantic_butler/semantic_butler_flutter/README.md`
- **Demo Script**: `DEMO_VIDEO_SCRIPT.md`
- **Serverpod Discord**: https://serverpod.dev/discord

---

## Contact & Support

- GitHub Issues: https://github.com/your-repo/desk-sense/issues
- Serverpod Discord: #hackathon channel
- Hackathon Support: support@devpost.com

---

**Good luck with the hackathon! 🚀**

> Remember: Submission deadline is **January 30, 2026 at 5:00 PM CET**. Don't wait until the last minute!
