# ServerPod Deployment Guide

**Project:** Semantic Desktop Butler (Desk-Sense)
**Last Updated:** 2025-01-23
**Target:** Production deployment (Self-hosted or ServerPod Cloud when available)
**ServerPod Version:** 3.2.x (Recommended - current is 3.1.0)

---

## IMPORTANT NOTICE: ServerPod Cloud Availability Status

**ServerPod Cloud is currently in PRIVATE BETA and not publicly available.**

As of January 2025, ServerPod Cloud is in private beta with gradual user onboarding. To get access:
1. Sign up at https://serverpod.dev/cloud
2. Join the Discord and ping the team
3. Participate in hackathons for early access

**This guide includes BOTH:**
- Self-hosted deployment (can be done immediately)
- ServerPod Cloud deployment (when you get beta access)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Why ServerPod Cloud?](#why-serverpod-cloud)
3. [Current State Analysis](#current-state-analysis)
4. [Pre-Migration Checklist](#pre-migration-checklist)
5. [Security Fixes Required](#security-fixes-required)
6. [Configuration Changes](#configuration-changes)
7. [Deployment Setup](#deployment-setup)
8. [Migration Steps](#migration-steps)
9. [Post-Migration Tasks](#post-migration-tasks)
10. [Troubleshooting](#troubleshooting)
11. [Rollback Plan](#rollback-plan)
12. [References](#references)

---

## Executive Summary

This guide outlines the complete migration of the Semantic Desktop Butler backend from a self-hosted deployment (using Neon PostgreSQL + custom hosting) to **ServerPod Cloud** - the managed hosting solution specifically designed for ServerPod applications.

### Key Benefits of Migrating:
- **Managed Infrastructure:** No need to manage servers, databases, or SSL certificates
- **Auto-Scaling:** Automatically scale servers and database as needed
- **Built-in Monitoring:** Serverpod Insights included
- **Simplified Deployment:** Single command deployment via `scloud`
- **Pay-As-You-Go:** Only pay for what you use

### Estimated Timeline: 2-3 days
- Day 1: Security fixes and configuration preparation
- Day 2: Testing deployment in staging/development
- Day 3: Production deployment and validation

---

## Why ServerPod Cloud?

### What is ServerPod Cloud?

ServerPod Cloud is a **managed hosting service** built specifically for ServerPod applications. It provides:

| Feature | Self-Hosted (Current) | ServerPod Cloud |
|---------|----------------------|-----------------|
| Database Management | Manual (Neon AWS) | Automatic |
| SSL Certificates | Manual configuration | Automatic |
| Load Balancing | Manual setup | Built-in |
| Server Scaling | Manual | Auto-scaling |
| Deployment | Docker/manual | `scloud deploy` |
| Monitoring | Custom setup | Built-in Insights |
| Domain | Custom domain setup | `.serverpod.space` subdomain |

### Official Resources
- [ServerPod Cloud Documentation](https://docs.serverpod.cloud/)
- [Deployment Guide](https://docs.serverpod.cloud/guides/deployment/deploying-your-application)
- [scloud CLI Reference](https://docs.serverpod.cloud/references/cli/commands/launch)

---

## Current State Analysis

### Architecture Overview

```
CURRENT (Self-Hosted)
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Flutter App    │────▶│  ServerPod      │────▶│  Neon DB        │
│  (Desktop/Mobile)│     │  (Self-Hosted)  │     │  (AWS us-east-1)│
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌─────────────────┐
                        │  Redis          │
                        │  (Optional)     │
                        └─────────────────┘


TARGET (ServerPod Cloud)
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Flutter App    │────▶│  ServerPod      │────▶│  Managed PG     │
│  (Desktop/Mobile)│     │  Cloud          │     │  (Built-in)     │
└─────────────────┘     │  Auto-scaling   │     │  Auto-backups   │
                        └─────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌─────────────────┐
                        │  Managed Redis  │
                        │  (Built-in)     │
                        └─────────────────┘
```

### Current Configuration Files

| File | Status | Issue |
|------|--------|-------|
| `config/production.yaml` | Exists | Uses localhost, needs domain update |
| `config/development.yaml` | Exists | Correctly configured |
| `config/staging.yaml` | Exists | Uses placeholder domains |
| `config/passwords.yaml` | **IN GIT** | **CRITICAL SECURITY ISSUE** |
| `config/generator.yaml` | Exists | Correctly configured |
| `.scloudignore` | Missing | Needs to be created |
| `.gitignore` | Partial | Missing `.scloud/` entries |

---

## Pre-Migration Checklist

### Phase 1: Account & Project Setup

- [ ] **Create ServerPod Cloud Account**
  - Visit https://serverpod.dev/cloud
  - Sign up for an account
  - Verify email address

- [ ] **Install scloud CLI**
  ```bash
  dart global activate serverpod_cloud_cli
  scloud --version
  ```

- [ ] **Authenticate with ServerPod Cloud**
  ```bash
  scloud login
  ```

- [ ] **Create a New Project**
  ```bash
  scloud launch
  # Follow the prompts to set up your project
  # Note your project ID and URLs
  ```

### Phase 2: Environment Variables Inventory

| Variable | Current Value | Target |
|----------|---------------|--------|
| `OPENROUTER_API_KEY` | In `.env` | Migrate to scloud secrets |
| Database password | In `passwords.yaml` | Will be managed by Cloud |
| Service secret | In `passwords.yaml` | Generate new strong secret |

### Phase 3: Database Assessment

- [ ] **Export current database schema**
  ```bash
  # From your current Neon DB
  pg_dump -h ep-purple-block-ahv7qmg4-pooler.c-3.us-east-1.aws.neon.tech \
    -U neondb_owner -d neondb --schema-only > schema_backup.sql
  ```

- [ ] **Export critical data** (if needed for migration)
  ```bash
  pg_dump -h ep-purple-block-ahv7qmg4-pooler.c-3.us-east-1.aws.neon.tech \
    -U neondb_owner -d neondb --data-only > data_backup.sql
  ```

---

## Security Fixes Required

### CRITICAL: Revoking Exposed Credentials

The following credentials are currently exposed in the repository and MUST be revoked:

#### 1. Database Password
**Location:** `config/passwords.yaml` and `docker-compose.yaml`
```
Current: npg_3mDeWLlIZS8g
```

**Action Required:**
1. Log in to Neon Console (https://console.neon.tech)
2. Navigate to your database
3. Reset the database password
4. Update any local development environments

#### 2. OpenRouter API Key
**Location:** `.env` file
```
Current: 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
```

**Action Required:**
1. Log in to OpenRouter (https://openrouter.ai/keys)
2. Revoke the exposed key
3. Generate a new key
4. Store in scloud secrets (do NOT commit to git)

#### 3. Service Secret
**Location:** `config/passwords.yaml`
```
Current: semanticButlerDevServiceSecret2024
```

**Action Required:**
Generate a new strong secret:
```bash
# Generate a secure random string
openssl rand -base64 32
```

### Removing Secrets from Git History

```bash
# Remove passwords.yaml from git history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch semantic_butler/semantic_butler_server/config/passwords.yaml" \
  --prune-empty --tag-name-filter cat -- --all

# Also remove .env if it was committed
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch semantic_butler/semantic_butler_server/.env" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (WARNING: This rewrites history)
git push origin --force --all
```

---

## Configuration Changes

### 1. Update `.gitignore`

**File:** `semantic_butler/semantic_butler_server/.gitignore`

Add the following entries:

```gitignore
# Files and directories created by pub
.dart_tool/
.packages

# Conventional directory for build outputs
build/

# Ignore the flutter web app directory
web/app

# Directory created by dartdoc
doc/api/

# Passwords file
config/passwords.yaml

# Firebase service account key for Firebase auth
config/firebase_service_account_key.json

# ================================
# SERVERPOD CLOUD ADDITIONS
# ================================

# scloud deployment generated files
**/.scloud/

# Environment files
.env
.env.local
.env.production
.env.*.local

# scloud package cache
.scloud-cache/

# Deployment logs
*.deployment.log
```

### 2. Create `.scloudignore`

**File:** `semantic_butler/semantic_butler_server/.scloudignore`

```gitignore
# ================================
# SERVERPOD CLOUD DEPLOYMENT IGNORE
# ================================

# Test files and directories
test/
testing/
integration_test/
test_integration/

# Documentation
*.md
docs/
README.md
CHANGELOG.md
CONTRIBUTING.md

# Build artifacts (not needed in deployment)
build/
.dart_tool/
.scloud/

# Development tools
.devcontainer/
.vscode/
.idea/
*.iml
*.swp
*.swo

# Migration scripts (keep in git, don't deploy)
bin/migrate_*.dart
bin/check_*.dart
bin/direct_*.dart

# SQL and database files
*.sql
*.sql.backup
*.db
*.sqlite

# Logs
*.log
logs/

# Docker files (not needed for cloud deployment)
docker-compose.yaml
docker-compose.*.yaml
Dockerfile
Dockerfile.*

# CI/CD
.github/
.gitlab-ci.yml
.travis.yml

# Large data files
*.csv
*.json.backup
*.backup

# Temporary files
tmp/
temp/
*.tmp
*.temp
migration_error.log
nul

# Development specific
*.env.example
deployment_*.md
HACKATHON_*.md
CROSS_PLATFORM_*.md
SMART_ORGANIZATION_*.md
INDEXING_*.md
CHAT_*.md
```

### 3. Create Production Configuration

**File:** `semantic_butler/semantic_butler_server/config/production.yaml`

```yaml
# ===========================================
# ServerPod Cloud Production Configuration
# ===========================================
# This file is configured for ServerPod Cloud deployment
# After deployment, update these values with your actual Serverpod Cloud URLs

# Configuration for the main API server.
apiServer:
  port: 8080
  # UPDATE AFTER DEPLOYMENT: Replace with your actual Serverpod Cloud domain
  # Format: <project-id>.api.serverpod.space
  publicHost: semantic-butler-api.serverpod.space
  publicPort: 443
  publicScheme: https

# Configuration for the Insights server.
insightsServer:
  port: 8081
  # UPDATE AFTER DEPLOYMENT: Replace with your actual Serverpod Cloud domain
  # Format: <project-id>.insights.serverpod.space
  publicHost: semantic-butler-insights.serverpod.space
  publicPort: 443
  publicScheme: https

# Configuration for the web server.
webServer:
  port: 8082
  # UPDATE AFTER DEPLOYMENT: Replace with your actual Serverpod Cloud domain
  # Format: <project-id>.serverpod.space
  publicHost: semantic-butler.serverpod.space
  publicPort: 443
  publicScheme: https

# ===========================================
# DATABASE
# ===========================================
# Serverpod Cloud provides a managed PostgreSQL database.
# Connection details are automatically configured by the cloud platform.
# The password should be set via scloud secrets, not in this file.
database:
  # Database host is managed by Serverpod Cloud
  # Update after deployment with actual cloud database host
  host: database.serverpod.cloud
  port: 5432
  name: semantic_butler
  user: serverpod
  requireSsl: true
  # maxConnectionCount: 10

# ===========================================
# REDIS (Optional)
# ===========================================
# Serverpod Cloud provides managed Redis.
# Enable this if you need caching functionality.
redis:
  enabled: false  # Set to true to enable Redis caching
  host: redis.serverpod.cloud
  port: 6379
  # requireSsl: true

# ===========================================
# SERVICE SETTINGS
# ===========================================
maxRequestSize: 524288  # 512KB - Adjust based on file upload needs

sessionLogs:
  consoleEnabled: true
  persistentEnabled: true
  consoleLogFormat: text  # Options: text, json

# Future calls (background tasks)
futureCallExecutionEnabled: true
futureCall:
  concurrencyLimit: 1
  scanInterval: 5000  # milliseconds
```

### 4. Update `passwords.yaml` Template

**File:** `semantic_butler/semantic_butler_server/config/passwords.yaml.template`

Create a template file (committed to git) that shows the structure without actual values:

```yaml
# ===========================================
# PASSWORDS CONFIGURATION TEMPLATE
# ===========================================
# This is a template file. DO NOT use actual values here.
# Copy this file to passwords.yaml and fill in the actual values.
# NEVER commit passwords.yaml to version control.

development:
  # Local development database password
  database: YOUR_DEV_DATABASE_PASSWORD
  # Service secret for development
  serviceSecret: YOUR_DEV_SERVICE_SECRET

test:
  # Test database password
  database: YOUR_TEST_DATABASE_PASSWORD
  # Service secret for testing (can be same as dev)
  serviceSecret: YOUR_TEST_SERVICE_SECRET

production:
  # ===========================================
  # IMPORTANT: ServerPod Cloud manages these
  # ===========================================
  # When deploying to Serverpod Cloud, use scloud config
  # command: scloud config password set database <value>
  # command: scloud config secret set serviceSecret <value>
  #
  # These values below are only used for NON-cloud deployments
  database: YOUR_PRODUCTION_DATABASE_PASSWORD
  serviceSecret: YOUR_PRODUCTION_SERVICE_SECRET

# ===========================================
# GENERATING SECURE PASSWORDS
# ===========================================
# Use openssl to generate secure random passwords:
# openssl rand -base64 32
#
# Or use Dart:
# dart -e "print(List.generate(32, (_) => Random().nextInt(256)).map((e) => e.toRadixString(16).padLeft(2, '0')).join())"
```

### 5. Create `.env.example`

**File:** `semantic_butler/semantic_butler_server/.env.example`

```bash
# ===========================================
# SEMANTIC DESKTOP BUTLER - Environment Variables
# ===========================================
# Copy this file to .env and fill in actual values
# NEVER commit .env to version control

# ===========================================
# OPENROUTER CONFIGURATION
# ===========================================
# Get your API key from: https://openrouter.ai/keys
OPENROUTER_API_KEY=your-openrouter-api-key-here

# Optional: Site URL for OpenRouter rankings
OPENROUTER_SITE_URL=https://your-app.com
OPENROUTER_SITE_NAME=Semantic Desktop Butler

# ===========================================
# SERVER CONFIGURATION
# ===========================================
SERVERPOD_MODE=development
SERVER_PORT=8080

# ===========================================
# OPTIONAL SETTINGS
# ===========================================
LOG_LEVEL=info
MAX_PARALLEL_INDEXING=5
EMBEDDING_BATCH_SIZE=20

# ===========================================
# DATABASE (for local development only)
# ===========================================
# ServerPod Cloud manages database automatically
# These are only for local development
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=semantic_butler
DATABASE_USER=postgres
DATABASE_PASSWORD=your-local-db-password
```

---

## Deployment Setup

### Installing scloud CLI

```bash
# Install the Serverpod Cloud CLI
dart global activate serverpod_cloud_cli

# Verify installation
scloud --version

# Login to your account
scloud login
```

### Setting Up Configuration (Passwords, Secrets, Variables)

ServerPod Cloud provides **three types** of configuration values via the `scloud config` commands:

> **IMPORTANT:** The exact command syntax may vary. Run `scloud --help` or `scloud config --help` after installation to verify the current commands.

```bash
# ===========================================
# CONFIGURATION COMMANDS
# ===========================================
# ServerPod Cloud has three config types:
# 1. config password - For database passwords
# 2. config secret   - For API keys and service secrets
# 3. config variable - For environment variables

# Set database password
scloud config password set database <your-password>

# Set service secret
scloud config secret set serviceSecret <your-secret>

# Set OpenRouter API key as a secret
scloud config secret set openrouter_api_key <your-api-key>

# Set environment variables
scloud config variable set LOG_LEVEL info
scloud config variable set MAX_PARALLEL_INDEXING 5

# List all configurations
scloud config list

# For bulk configuration from file:
scloud config --from-file .env.production
```

**Alternative Commands (may vary by version):**
Some documentation may reference simplified commands. Always check `scloud --help` for current syntax.

### Creating a New Project

```bash
# Launch a new Serverpod Cloud project
scloud launch

# Follow the interactive prompts:
# 1. Enter project name (e.g., semantic-butler)
# 2. Select region
# 3. Choose database tier
# 4. Confirm deployment

# Note the URLs provided after creation:
# - Web:      https://<project>.serverpod.space/
# - API:      https://<project>.api.serverpod.space/
# - Insights: https://<project>.insights.serverpod.space/
```

---

## Migration Steps

### Step 1: Prepare the Codebase

```bash
# Navigate to server directory
cd semantic_butler/semantic_butler_server

# 1. Update dependencies
dart pub get

# 2. Generate code (ensures all models are up to date)
serverpod generate

# 3. Run tests
dart test
```

### Step 2: Create Deployment Package (Dry Run)

```bash
# Test deployment without actually deploying
scloud deploy --dry-run --show-files

# Review the output:
# - Check that all necessary files are included
# - Verify that .gitignore files are excluded
# - Ensure no sensitive files are in the package
```

### Step 3: Initial Deployment

```bash
# Deploy to Serverpod Cloud
scloud deploy

# The CLI will:
# 1. Package your application
# 2. Upload to Serverpod Cloud
# 3. Start the deployment process
# 4. Provide URLs when ready

# Expected output:
# Project uploaded successfully!
#
# When the server has started, you can access it at:
# Web:      https://<project>.serverpod.space/
# API:      https://<project>.api.serverpod.space/
# Insights: https://<project>.insights.serverpod.space/
```

### Step 4: Update Production Configuration

After receiving your Serverpod Cloud URLs, update `config/production.yaml`:

```yaml
apiServer:
  publicHost: <your-project>.api.serverpod.space
  publicPort: 443
  publicScheme: https

insightsServer:
  publicHost: <your-project>.insights.serverpod.space
  publicPort: 443
  publicScheme: https

webServer:
  publicHost: <your-project>.serverpod.space
  publicPort: 443
  publicScheme: https
```

Then redeploy:

```bash
scloud deploy
```

### Step 5: Configure Custom Domain (Optional)

If you have a custom domain:

```bash
# Set up custom domain
scloud domain add semantic-butler.com

# Follow the DNS instructions provided
# Serverpod Cloud will automatically provision SSL certificates

# Verify domain propagation
scloud domain status
```

### Step 6: Migrate Database (if needed)

If you have existing data in Neon that needs to be migrated:

```bash
# 1. Export from Neon
pg_dump -h ep-purple-block-ahv7qmg4-pooler.c-3.us-east-1.aws.neon.tech \
  -U neondb_owner -d neondb --data-only --clean > neon_backup.sql

# 2. Connect to Serverpod Cloud database
# Get connection string from scloud or Serverpod Cloud dashboard

# 3. Import to Serverpod Cloud database
psql -h <cloud-db-host> -U serverpod -d semantic_butler < neon_backup.sql
```

---

## Post-Migration Tasks

### Update Flutter Client Configuration

**File:** `semantic_butler/semantic_butler_flutter/lib/main.dart`

Update the client initialization to use the new Serverpod Cloud URLs:

```dart
// Development
String get serverUrl {
  if (kReleaseMode) {
    // Production: Serverpod Cloud
    return 'https://semantic-butler.api.serverpod.space';
  } else {
    // Development: Local server
    return 'http://localhost:8080';
  }
}

// Initialize client
final client = Client(serverUrl)
  ..connectivityMonitor = FlutterConnectivityMonitor();
```

Or use environment-specific configuration:

```dart
// lib/config/app_config.dart
class AppConfig {
  static String get apiBaseUrl {
    const env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

    switch (env) {
      case 'production':
        return 'https://semantic-butler.api.serverpod.space';
      case 'staging':
        return 'https://semantic-butler-staging.api.serverpod.space';
      default:
        return 'http://localhost:8080';
    }
  }
}
```

### Update Website Configuration

**File:** `website/.env.production`

```bash
# API endpoint for production
VITE_API_BASE_URL=https://semantic-butler.api.serverpod.space
VITE_APP_NAME=Semantic Butler
VITE_ENV=production
```

### Verify Endpoints

After deployment, verify all endpoints are accessible:

```bash
# Health check
curl https://<project>.api.serverpod.space/health

# Test API endpoint
curl -X POST https://<project>.api.serverpod.space/butler/search \
  -H "Content-Type: application/json" \
  -d '{"query": "test"}'
```

### Set Up Monitoring

Serverpod Cloud includes built-in monitoring via Insights:

1. Access Insights at: `https://<project>.insights.serverpod.space`
2. Configure alerts for:
   - Error rates
   - Response times
   - Database connection issues
   - Memory usage

---

## Troubleshooting

### Common Deployment Issues

#### 1. Package Resolution Errors

**Error:** Failed to resolve dependencies

**Solution:**
```bash
# Ensure all dependencies are up to date
dart pub upgrade

# Run with --verbose to see detailed error
scloud deploy --verbose
```

#### 2. Build Errors

**Error:** Compilation failed

**Solution:**
```bash
# Check build logs
scloud deployment build-log

# Fix errors locally first
cd semantic_butler/semantic_butler_server
dart analyze
dart test
```

#### 3. Database Connection Errors

**Error:** Cannot connect to database

**Solution:**
```bash
# Verify database is running on Serverpod Cloud
scloud status

# Check database password is set correctly
scloud config list

# Test connection
psql -h <db-host> -U serverpod -d semantic_butler
```

#### 4. "Forbidden" Errors

**Error:** 403 Forbidden when accessing endpoints

**Solution:**
- Verify service secret is set correctly
- Check that `passwords.yaml` is not included in deployment
- Ensure secrets are set via `scloud config`

### Getting Help

- **Documentation:** https://docs.serverpod.cloud/
- **GitHub Issues:** https://github.com/serverpod/serverpod/issues
- **Community Discord:** https://discord.gg/3YsxVQUN (if available)

### Useful Commands

```bash
# Check deployment status
scloud deployment status

# View detailed logs
scloud deployment show <deployment-id>
scloud deployment logs

# List all deployments
scloud deployment list

# Monitor real-time logs
scloud logs --follow

# Check project status
scloud status

# Restart servers
scloud restart
```

---

## Rollback Plan

If you need to rollback to your self-hosted deployment:

### Immediate Rollback

1. **Switch DNS back to original server** (if using custom domain)

2. **Point Flutter clients back to localhost/original server:**
   ```dart
   // Temporary override in main.dart
   final client = Client('http://localhost:8080');
   ```

3. **Stop Serverpod Cloud deployment:**
   ```bash
   scloud deployment stop
   ```

### Full Rollback Procedure

1. **Stop all traffic to Serverpod Cloud**
   - Remove DNS records pointing to Serverpod Cloud
   - Or disable the deployment: `scloud deployment disable`

2. **Restore original infrastructure**
   - Start local Docker services: `docker-compose up -d`
   - Or restore original cloud deployment

3. **Verify database access**
   - Ensure Neon database is accessible
   - Test database connections

4. **Update client configurations**
   - Revert Flutter app configuration
   - Revert website environment variables

5. **Notify users of any downtime**

---

## References

### Official Documentation
- [ServerPod Cloud](https://serverpod.dev/cloud) - Official Cloud homepage
- [ServerPod Cloud Documentation](https://docs.serverpod.cloud/) - Full documentation
- [Deployment Guide](https://docs.serverpod.cloud/guides/deployment/deploying-your-application) - How to deploy
- [Configuration Management](https://docs.serverpod.cloud/guides/configuration/overview) - Config passwords/secrets/variables
- [scloud CLI - launch command](https://docs.serverpod.cloud/references/cli/commands/launch) - CLI reference
- [Serverpod Getting Started](https://docs.serverpod.dev/3.1.0/get-started) - Latest getting started guide
- [Serverpod Configuration](https://docs.serverpod.dev/concepts/configuration) - Configuration concepts

### CLI Package
- [serverpod_cloud_cli on pub.dev](https://pub.dev/packages/serverpod_cloud_cli) - CLI package
- [serverpod_cloud_cli changelog](https://pub.dev/packages/serverpod_cloud_cli/versions/0.19.1/changelog) - Version history

### Related Guides
- `SERVERPOD_CLOUD_VERIFICATION_REPORT.md` - Detailed verification of current implementation
- `HACKATHON_DEPLOYMENT.md` - Current deployment process

---

## Appendix A: Quick Reference Commands

```bash
# ===========================================
# SCLOUD CLI QUICK REFERENCE
# ===========================================

# Authentication
scloud login                              # Login to Serverpod Cloud
scloud logout                             # Logout

# Project Management
scloud launch                             # Create a new project
scloud status                             # Check project status

# Deployment
scloud deploy                             # Deploy application
scloud deploy --dry-run                   # Test deployment without uploading
scloud deploy --show-files                # Show files in deployment package
scloud deploy --concurrency 5             # Set packaging concurrency

# Deployment Management
scloud deployment status                  # Check deployment status
scloud deployment list                    # List all deployments
scloud deployment show <id>               # Show deployment details
scloud deployment build-log               # View build logs
scloud deployment logs                    # View runtime logs
scloud deployment stop                    # Stop deployment

# Domain Management
scloud domain add <domain>                # Add custom domain
scloud domain list                        # List domains
scloud domain remove <domain>             # Remove domain
scloud domain status                      # Check domain status

# Configuration Management (scloud config)
scloud config password set <key> <value>  # Set a database password
scloud config secret set <key> <value>    # Set an API secret
scloud config variable set <key> <value>  # Set an environment variable
scloud config list                        # List all configurations
# Note: Commands may vary, check scloud config --help

# Logs
scloud logs                               # View recent logs
scloud logs --follow                      # Follow logs in real-time
scloud logs --tail 100                    # Show last 100 log lines

# General
scloud --version                          # Show CLI version
scloud --help                             # Show help
scloud <command> --help                   # Show command-specific help
```

---

## Appendix B: Environment Variables Reference

| Variable | Description | Local Dev | Serverpod Cloud |
|----------|-------------|-----------|-----------------|
| `OPENROUTER_API_KEY` | OpenRouter API key for AI | In `.env` | `scloud config secret` |
| `database` | Database password | In `passwords.yaml` | `scloud config password` |
| `serviceSecret` | Serverpod service secret | In `passwords.yaml` | `scloud config secret` |
| `SERVERPOD_MODE` | Server mode | `development` | `production` |
| `LOG_LEVEL` | Logging level | `info` | `scloud config variable` |

---

## Appendix C: Migration Checklist

### Pre-Migration
- [ ] Serverpod Cloud account created
- [ ] scloud CLI installed
- [ ] Project launched on Serverpod Cloud
- [ ] All exposed credentials revoked
- [ ] New credentials generated
- [ ] `.gitignore` updated
- [ ] `.scloudignore` created
- [ ] `production.yaml` updated
- [ ] Configuration set via scloud config (passwords, secrets, variables)

### Migration
- [ ] Code generated with `serverpod generate`
- [ ] Dry run deployment tested
- [ ] Initial deployment completed
- [ ] Production config updated with Cloud URLs
- [ ] Data migrated (if needed)
- [ ] Flutter client config updated
- [ ] Website config updated

### Post-Migration
- [ ] All endpoints tested
- [ ] Health checks passing
- [ ] Monitoring configured
- [ ] Custom domain set up (if needed)
- [ ] Old infrastructure decommissioned
- [ ] Documentation updated
- [ ] Team notified of new deployment process

---

**Document Version:** 1.0
**Last Review:** 2025-01-23
**Next Review:** After initial deployment completion
