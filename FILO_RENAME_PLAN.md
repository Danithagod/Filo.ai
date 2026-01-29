# Filo.ai Rename Plan

**Project:** Semantic Butler → **Filo**
**Domain:** Filo.ai
**Date:** 2025-01-23

---

## Overview

This plan outlines the safe renaming of "Semantic Butler" to "Filo" across the codebase. Changes are categorized by risk level and should be executed in phases.

---

## Phase 1: Safe Cosmetic Changes ✅

*No breaking changes. Can be done immediately.*

### 1.1 Flutter App Display Names

| File | Line | Old Value | New Value |
|------|------|-----------|-----------|
| `semantic_butler_flutter/lib/main.dart` | 120 | `"Semantic Butler"` | `"Filo"` |
| `semantic_butler_flutter/lib/main.dart` | 151 | `'Semantic Butler'` | `'Filo'` |
| `semantic_butler_flutter/lib/main.dart` | 159 | `'Semantic Butler'` | `'Filo'` |
| `semantic_butler_flutter/lib/main.dart` | 186 | `'Semantic Butler'` | `'Filo'` |

### 1.2 UI Widget Titles

| File | Line | Old Value | New Value |
|------|------|-----------|-----------|
| `lib/widgets/chat/chat_app_bar.dart` | 49 | `'Semantic Butler'` | `'Filo'` |
| `lib/screens/home_screen.dart` | 316 | `'Semantic Butler'` | `'Filo'` |
| `lib/widgets/window_title_bar.dart` | 31 | `'Semantic Butler'` | `'Filo'` |

### 1.3 Native App Display Names

| File | Line | Old Value | New Value |
|------|------|-----------|-----------|
| `semantic_butler_flutter/macos/Runner/Info.plist` | 8 | `Semantic Butler Flutter` | `Filo` |
| `semantic_butler_flutter/ios/Runner/Info.plist` | 8 | `Semantic Butler Flutter` | `Filo` |
| `semantic_butler_flutter/android/app/src/main/AndroidManifest.xml` | 3 | `semantic_butler_flutter` | `Filo` |

### 1.4 Website / Marketing

| File | Line | Old Value | New Value |
|------|------|-----------|-----------|
| `marketing-site/src/App.jsx` | 102 | `Semantic Butler` | `Filo` |
| `marketing-site/src/App.jsx` | 126 | `Semantic Butler` | `Filo` |
| `marketing-site/src/App.jsx` | 115 | `https://docs.semanticbutler.com` | `https://filo.ai/docs` |

### 1.5 Documentation

| File | Action |
|------|--------|
| `README.md` | Replace all "Semantic Butler" with "Filo" |
| `HACKATHON_DEPLOYMENT.md` | Replace all "Semantic Butler" with "Filo" |
| All inline comments | Replace "Semantic Butler" references |

---

## Phase 2: Package & Folder Renaming ⚠️

*Requires proper refactoring. Test thoroughly after each step.*

### 2.1 Directory Structure

```
semantic_butler/
├── semantic_butler_client/   → filo_client/
├── semantic_butler_flutter/  → filo_app/
└── semantic_butler_server/   → filo_server/
```

### 2.2 Package Names (pubspec.yaml)

| File | Old Name | New Name |
|------|----------|----------|
| `semantic_butler_client/pubspec.yaml` | `semantic_butler_client` | `filo_client` |
| `semantic_butler_flutter/pubspec.yaml` | `semantic_butler_flutter` | `filo_app` |
| `semantic_butler_server/pubspec.yaml` | `semantic_butler_server` | `filo_server` |

### 2.3 Import Statements (~20+ files)

All imports must be updated:

```dart
// Old
import 'package:semantic_butler_client/semantic_butler_client.dart';

// New
import 'package:filo_client/filo_client.dart';
```

Affected files include:
- All files in `semantic_butler_flutter/lib/`
- All files in `semantic_butler_server/lib/`

### 2.4 Android Package Name

| File | Old Value | New Value |
|------|-----------|-----------|
| `android/app/build.gradle` | `com.example.semantic_butler_flutter` | `ai.filo.app` |
| `android/app/src/main/AndroidManifest.xml` | `com.example.semantic_butler_flutter` | `ai.filo.app` |

**Steps:**
1. Use Android Studio → Refactor → Rename Package
2. Update `applicationId` in build.gradle
3. Clean and rebuild

### 2.5 iOS Bundle Identifier

| File | Old Value | New Value |
|------|-----------|-----------|
| `ios/Runner.xcodeproj/project.pbxproj` | `com.example.semanticButlerFlutter` | `ai.filo.app` |
| `ios/Runner/Info.plist` | `com.example.semanticButlerFlutter` | `ai.filo.app` |

**Steps:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → General → Bundle Identifier
3. Change to `ai.filo.app`
4. Clean and rebuild

---

## Phase 3: Infrastructure & External 🔒

*Only change if creating fresh deployment. Migrate existing data if needed.*

### 3.1 Database (Keep for existing deployments)

| File | Old Value | New Value |
|------|-----------|-----------|
| `docker-compose.yaml` | `semantic_butler` | `filo` |
| `docker-compose.yaml` | `semantic_butler_test` | `filo_test` |
| `docker-compose.yaml` | `semantic_butler_data` | `filo_data` |

**Note:** For existing deployments, keep old database name or write migration script.

### 3.2 Docker Volumes

```yaml
# Old
volumes:
  semantic_butler_data:
  semantic_butler_test_data:

# New
volumes:
  filo_data:
  filo_test_data:
```

### 3.3 Serverpod Module

The internal Serverpod module name is tied to:
- Generated protocol code
- Migration files
- API endpoint namespaces

**Recommendation:** Keep internally for compatibility. Only change outward-facing API documentation.

---

## Phase 4: Brand & Assets 🎨

### 4.1 New Assets Needed

| Asset | Location | Notes |
|-------|----------|-------|
| App icon | `flutter/assets/app-icon.png` | New logo for Filo |
| Favicon | `marketing-site/public/favicon.ico` | Filo branding |
| Logo | `marketing-site/src/assets/logo.svg` | New logo SVG |

### 4.2 App Icon Sizes

Generate icons for:
- macOS (512x512)
- Windows (256x256)


---

## Execution Checklist

- [x] Phase 1.1: Update Flutter app display names
- [x] Phase 1.2: Update UI widget titles
- [x] Phase 1.3: Update native app display names
- [x] Phase 1.4: Update website/marketing site
- [x] Phase 1.5: Update documentation and README
- [ ] **Test build**: Run Flutter app to verify Phase 1 changes
- [ ] Phase 2.1: Rename directories
- [ ] Phase 2.2: Update pubspec.yaml package names
- [ ] Phase 2.3: Update all import statements
- [ ] Phase 2.4: Rename Android package
- [ ] Phase 2.5: Rename iOS bundle identifier
- [ ] **Test build**: Full clean build for all platforms
- [ ] Phase 3.1: Update docker-compose (if fresh deployment)
- [ ] Phase 4.1: Design and create new logo
- [ ] Phase 4.2: Generate app icons for all platforms

---

## Rollback Plan

If anything breaks:
1. Git revert each phase individually
2. Keep the internal package names if refactoring proves too complex
3. Consider keeping `semantic_butler` as internal package name and only changing display names

---

## Notes

- The internal package name (`semantic_butler`) doesn't need to match the public app name (`Filo`)
- Many successful apps have different internal vs external names
- Focus on Phase 1 for immediate branding update
- Tackle Phase 2 when you have dedicated testing time

