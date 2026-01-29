# Desktop Build Fixes - Detailed Gap Analysis

**Analysis Date**: January 27, 2026  
**Status**: CRITICAL ISSUES IDENTIFIED  
**Summary**: The DESKTOP_BUILD_FIXES.md document provides good guidance but there are significant gaps between the recommendations and current codebase state.

---

## Executive Summary

| Category | Status | Severity |
|----------|--------|----------|
| macOS Entitlements | ⚠️ INCOMPLETE | Critical |
| Windows App Naming | ❌ NOT DONE | Critical |
| Linux App Naming | ❌ NOT DONE | Critical |
| API URL Configuration | ✅ DONE | Completed |
| Window Title | ⚠️ PARTIAL | High |
| Build Scripts | ❌ NOT CREATED | Medium |
| Version Management | ⚠️ UNCLEAR | Low |

---

## Critical Issues Found

### 1. macOS Entitlements - INCOMPLETE (Critical)

**Current State** (Release.entitlements):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
</dict>
</plist>
```

**Problem**: Missing ALL required entitlements:
- ❌ `com.apple.security.network.client` - REQUIRED for API calls
- ❌ `com.apple.security.network.server` - REQUIRED for local API connections
- ❌ `com.apple.security.files.user-selected.read-write` - REQUIRED for file picker
- ❌ `com.apple.security.files.downloads.read-write` - REQUIRED for downloads folder access
- ❌ `com.apple.security.files.documents.read-write` - REQUIRED for documents folder access

**Impact**: App will **crash or hang** when attempting to:
- Make API calls to Serverpod backend
- Use file picker dialog
- Access user files

**Fix Required**: Apply entitlements from DESKTOP_BUILD_FIXES.md lines 37-77

---

### 2. DebugProfile.entitlements - PARTIALLY CORRECT

**Current State**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.cs.allow-jit</key>
	<true/>
	<key>com.apple.security.network.server</key>
	<true/>
</dict>
</plist>
```

**Problem**: Has `network.server` but missing:
- ❌ `com.apple.security.network.client` - REQUIRED for outgoing API calls
- ❌ File access entitlements (user-selected, downloads, documents)

**Note**: Good that it has `cs.allow-jit` for debug performance.

---

### 3. Windows App Naming - NOT DONE (Critical)

**Current State** (main.cpp line 23 & 33):
```cpp
flutter::DartProject project(L"data");  // Line 23 - WRONG
// ...
if (!window.Create(L"semantic_butler_flutter", origin, size)) {  // Line 33 - WRONG
```

**Current State** (Runner.rc):
```
VALUE "CompanyName", "com.example"
VALUE "FileDescription", "semantic_butler_flutter"
VALUE "InternalName", "semantic_butler_flutter"
VALUE "OriginalFilename", "semantic_butler_flutter.exe"
VALUE "ProductName", "semantic_butler_flutter"
```

**Required Changes**:
- Line 23: `L"data"` → `L"Filo"`
- Line 33: `L"semantic_butler_flutter"` → `L"Filo"`
- Runner.rc needs complete update to use "Filo" branding

**Impact**: 
- Exe file named `semantic_butler_flutter.exe` instead of `Filo.exe`
- Window title shows "semantic_butler_flutter" instead of "Filo"
- File properties show "semantic_butler_flutter" throughout
- Looks unprofessional and confusing

---

### 4. Linux App Naming - NOT DONE (Critical)

**Current State** (my_application.cc lines 48 & 52):
```cc
gtk_header_bar_set_title(header_bar, "semantic_butler_flutter");
// ...
gtk_window_set_title(window, "semantic_butler_flutter");
```

**Required Changes**:
- Both hardcoded strings must be replaced with "Filo"
- Should use a constant defined in a header file for consistency

**Impact**:
- Linux window title shows "semantic_butler_flutter" instead of "Filo"
- Desktop integration shows wrong application name
- User confusion about application identity

**Additional Gap**: No `.desktop` file configuration mentioned in current codebase or DESKTOP_BUILD_FIXES.md. Linux desktop entry files are critical for:
- Application menu integration
- Icon association
- File association
- System integration

---

## High Priority Issues

### 5. Window Title in main.dart - PARTIALLY CORRECT

**Current State** (main.dart line 118):
```dart
win.title = "Semantic Butler";
```

**Status**: ✅ Correct for now, but inconsistent with planned "Filo" branding

**Recommended Change**:
```dart
win.title = "Filo";
```

---

### 6. Flutter App Name Configuration - NOT IN PUBSPEC.yaml

**Current State** (pubspec.yaml):
```yaml
name: semantic_butler_flutter
description: A new Flutter project with Serverpod.
version: 1.0.0+1
```

**Problem**: 
- App internal name is still `semantic_butler_flutter`
- This affects package identity on some platforms
- Should consider if renaming is necessary (breaking change for existing users)

**Recommendation**: Keep as-is for now (internal name), but ensure platform-specific builds use "Filo" display name.

---

## Medium Priority Issues

### 7. Build Scripts Not Created

**Current State**: No build scripts exist at `scripts/build-desktop.sh`

**Status**: ❌ NOT IMPLEMENTED

**Gap**: Document recommends unified build script (DESKTOP_BUILD_FIXES.md lines 437-471) but:
- Script doesn't exist
- No Windows `.bat` equivalent provided
- No integration with CI/CD

**Impact**: 
- Manual build commands required
- Error-prone for developers
- Difficult to maintain consistency across platforms
- No environment variable substitution automation

**Recommended Action**: Create scripts:
1. `scripts/build-desktop.sh` (macOS/Linux)
2. `scripts/build-desktop.bat` (Windows)
3. `scripts/build-desktop.ps1` (PowerShell alternative)

---

### 8. Platform-Specific Icon Configuration - NOT DOCUMENTED

**Current State**: 
- macOS: Empty icon in Info.plist (`<key>CFBundleIconFile</key><string></string>`)
- Windows: References `resources\app_icon.ico` (existence not verified)
- Linux: No icon configuration found

**Gap**: DESKTOP_BUILD_FIXES.md doesn't address:
- Icon asset locations
- Icon dimensions per platform
- Icon format requirements (`.icns`, `.ico`, `.png`)
- App Store/Play Store icon guidelines

**Recommended Icons**:
- macOS: 1024×1024 `.icns` file
- Windows: 256×256 `.ico` file (or multiple resolutions)
- Linux: 512×512 `.png` file

---

## Low Priority Issues

### 9. Version Management - PARTIALLY DOCUMENTED

**Current State** (pubspec.yaml):
```yaml
version: 1.0.0+1
```

**Status**: ✅ Reasonable initial version per DESKTOP_BUILD_FIXES.md

**Gap**: 
- No versioning strategy documented for CI/CD
- No automated version bump mechanism
- No changelog file (`CHANGELOG.md`)

**Recommendation**: Create `CHANGELOG.md` following [Keep a Changelog](https://keepachangelog.com/) format

---

## Server Configuration

### 10. Server Configuration - CORRECT

**Status**: ✅ Good

**Positive Findings**:
- `app_config.dart` correctly implements environment-based configuration
- Production URL: `https://semantic-butler-api.serverpod.space/`
- Staging URL: `https://semantic-butler-staging-api.serverpod.space/`
- Development fallback: `http://127.0.0.1:8080/`

**Issue**: This is production hardcoded in source. Best practice would be:
- Remove hardcoded production URLs
- Use environment variables in CI/CD only
- Let end users configure via settings (partially done in settings_screen.dart)

---

## API Configuration - CORRECT

### 11. main.dart API Configuration - CORRECT

**Status**: ✅ Good

**Positive Findings**:
- `main.dart` correctly loads config at startup (lines 54-67)
- Supports `SERVER_URL` environment variable override
- Falls back to `AppConfig.loadConfig()`
- Reasonable 120-second timeout for AI calls
- Proper error handling and logging

**Suggestion**: Consider storing last-known-good URL for offline-first scenarios.

---

## Missing Documentation in DESKTOP_BUILD_FIXES.md

### 12. Not Mentioned - Code Signing

**Gap**: No guidance on code signing for:
- macOS app signing (required for distribution)
- Windows Authenticode signing (prevents SmartScreen warnings)
- Linux AppImage signing (optional but recommended)

**Impact**: Distribution will have security warnings.

---

### 13. Not Mentioned - Installer Creation

**Gap**: While mentions exist for `.dmg`, `.msi`, and AppImage, no concrete steps provided for:
- Actual `.dmg` creation (mentions `create-dmg` but no full script)
- `.msi` creation using WiX or MSIX
- AppImage build integration
- Hosting and distribution strategy

---

### 14. Not Mentioned - Auto-Update Mechanism

**Gap**: No discussion of:
- Update checking mechanism
- Delta updates
- Rollback strategy
- Staged rollouts

**Recommendation**: Consider [Sparkle](https://sparkle-project.org/) (macOS) or similar for auto-updates.

---

### 15. Not Mentioned - Telemetry & Crash Reporting

**Gap**: No discussion of:
- Crash reporting (Sentry, Firebase Crashlytics, etc.)
- Usage analytics
- Error reporting to development team
- User consent for telemetry

---

## Inconsistencies Between Platforms

### Platform Window Title Inconsistency

| Platform | Current Title | Should Be |
|----------|---------------|-----------|
| Dart/Flutter | "Semantic Butler" | "Filo" |
| Windows C++ | "semantic_butler_flutter" | "Filo" |
| Linux C++ | "semantic_butler_flutter" | "Filo" |
| macOS | Uses Dart (correct) | "Filo" |

**Action Required**: Update Windows and Linux C++ files, plus Dart main.dart.

---

## Configuration Files Checklist

### macOS
- [ ] Release.entitlements - UPDATE (add network + file access)
- [ ] DebugProfile.entitlements - UPDATE (add network.client)
- [ ] Info.plist - No changes needed (uses variables)
- [x] main.dart title - Correct (update to "Filo")

### Windows
- [ ] main.cpp line 23 - CHANGE `L"data"` → `L"Filo"`
- [ ] main.cpp line 33 - CHANGE window title to `L"Filo"`
- [ ] Runner.rc - CHANGE all references from "semantic_butler_flutter" to "Filo"
- [x] Icon - Exists (needs verification)

### Linux
- [ ] my_application.cc line 48 - CHANGE header bar title to "Filo"
- [ ] my_application.cc line 52 - CHANGE window title to "Filo"
- [ ] Create .desktop file for desktop integration
- [ ] Define APPLICATION_ID constant (appears to be used but not defined)

### Flutter (Cross-platform)
- [x] app_config.dart - Correct (environment variables)
- [x] main.dart - Correct (loads config, proper timeout)
- [ ] main.dart line 118 - UPDATE window title to "Filo"
- [ ] pubspec.yaml - Keep as-is (internal name)

---

## Proposed Action Plan

### Phase 1: Critical (Do Before Any Release)
1. **macOS**: Update Release.entitlements with network + file access
2. **macOS**: Update DebugProfile.entitlements with network.client
3. **Windows**: Update main.cpp - Change app name to "Filo"
4. **Windows**: Update Runner.rc - Change all product names to "Filo"
5. **Linux**: Update my_application.cc - Change window titles to "Filo"
6. **Flutter**: Update main.dart line 118 to "Filo"

### Phase 2: High Priority (Before Beta Release)
1. Create build scripts (`scripts/build-desktop.sh`, `.bat`, `.ps1`)
2. Document icon requirements and verify icon files exist
3. Create `.desktop` file for Linux
4. Set up code signing certificates
5. Create distribution scripts

### Phase 3: Medium Priority (Before Stable Release)
1. Implement crash reporting (Sentry/Firebase)
2. Add auto-update mechanism
3. Create installer packages (.dmg, .msi, AppImage)
4. Write platform-specific installation guides
5. Create `CHANGELOG.md`

### Phase 4: Low Priority (Post-Release)
1. Implement telemetry with user consent
2. Set up staged rollouts
3. Create update distribution infrastructure
4. Document rollback procedures

---

## Testing Validation Checklist

### Before Deployment
```
macOS:
- [ ] Run: flutter build macos --release
- [ ] Verify entitlements: cat build/macos/Build/Products/Release/Filo.app/Contents/entitlements.plist
- [ ] Test API calls work
- [ ] Test file picker works
- [ ] Verify app name in Finder is "Filo"
- [ ] Test code signing: codesign -v --deep build/macos/Build/Products/Release/Filo.app

Windows:
- [ ] Run: flutter build windows --release
- [ ] Verify executable name is "filo.exe"
- [ ] Verify window title is "Filo"
- [ ] Check file properties show "Filo" throughout
- [ ] Test with SmartScreen (may need signing)

Linux:
- [ ] Run: flutter build linux --release
- [ ] Verify window title is "Filo"
- [ ] Test .desktop file integration
- [ ] Verify file manager shows correct app name
```

---

## Files Requiring Immediate Changes

### Priority: CRITICAL (Blocks Release)

1. **File**: `semantic_butler_flutter/macos/Runner/Release.entitlements`
   - **Change**: Add network + file access entitlements
   - **Lines**: Add after line 6
   - **Time Est**: 5 minutes

2. **File**: `semantic_butler_flutter/macos/Runner/DebugProfile.entitlements`
   - **Change**: Add network.client entitlement
   - **Lines**: Add after line 10
   - **Time Est**: 2 minutes

3. **File**: `semantic_butler_flutter/windows/runner/main.cpp`
   - **Change**: Update app name
   - **Lines**: 23, 33
   - **Time Est**: 2 minutes

4. **File**: `semantic_butler_flutter/windows/runner/Runner.rc`
   - **Change**: Update all product/file descriptions
   - **Lines**: 92-99
   - **Time Est**: 5 minutes

5. **File**: `semantic_butler_flutter/linux/runner/my_application.cc`
   - **Change**: Update window titles
   - **Lines**: 48, 52
   - **Time Est**: 2 minutes

6. **File**: `semantic_butler_flutter/lib/main.dart`
   - **Change**: Update window title
   - **Lines**: 118
   - **Time Est**: 1 minute

### Priority: HIGH (Before Beta)

7. **File**: Create `scripts/build-desktop.sh`
   - **Purpose**: Unified build script for all platforms
   - **Time Est**: 15 minutes

8. **File**: Create `semantic_butler_flutter/linux/com.filo.app.desktop`
   - **Purpose**: Linux desktop entry file
   - **Time Est**: 10 minutes

### Priority: MEDIUM (Before Stable)

9. **File**: Create `CHANGELOG.md`
   - **Purpose**: Document version history
   - **Time Est**: 20 minutes

10. **File**: Create icon assets for all platforms
    - **Purpose**: Branding and visual identity
    - **Time Est**: 30-60 minutes (unless already done)

---

## Summary Table

| Issue | File(s) | Current | Required | Difficulty |
|-------|---------|---------|----------|------------|
| macOS entitlements | Release.entitlements | ❌ Missing | Network + Files | Easy |
| macOS debug entitlements | DebugProfile.entitlements | ⚠️ Partial | Add network.client | Easy |
| Windows app name (code) | main.cpp | ❌ Wrong | "Filo" | Easy |
| Windows app name (resources) | Runner.rc | ❌ Wrong | "Filo" | Easy |
| Linux app name | my_application.cc | ❌ Wrong | "Filo" | Easy |
| Flutter window title | main.dart | ⚠️ Wrong | "Filo" | Trivial |
| Build automation | scripts/ | ❌ Missing | Scripts | Medium |
| Linux desktop integration | .desktop | ❌ Missing | File | Easy |
| Code signing | N/A | ❌ Not set up | Certificates | Hard |
| Distribution packages | N/A | ❌ Not created | .dmg/.msi/AppImage | Hard |
| Crash reporting | N/A | ❌ Not implemented | Sentry/Firebase | Medium |
| Auto-updates | N/A | ❌ Not implemented | Sparkle/etc | Hard |

---

## Recommendations

### Immediate (This Sprint)
1. Apply all 6 critical file changes (20 minutes total)
2. Verify changes compile and run
3. Test API connectivity on all platforms

### Short-term (Next Sprint)
1. Create build scripts
2. Set up Linux desktop integration
3. Document icon requirements
4. Plan code signing strategy

### Medium-term (Next Release Cycle)
1. Implement crash reporting
2. Create distribution packages
3. Set up auto-update mechanism
4. Write comprehensive build/release documentation

### Long-term
1. Implement telemetry (with consent)
2. Set up staged rollout infrastructure
3. Create platform-specific optimization guides

---

## Conclusion

The DESKTOP_BUILD_FIXES.md document provides **good general guidance** but has gaps in:
1. **Execution completeness** - Many recommendations not yet implemented
2. **Platform-specific details** - Missing Linux desktop integration, signing details
3. **Distribution strategy** - No installer/distribution guidance
4. **Post-release operations** - No crash reporting, auto-update, telemetry discussion

**Current readiness for release**: **40% - CRITICAL issues must be fixed first**

The 6 critical file changes are straightforward and should be completed before any beta/release build. The remaining issues are important for a professional release but can be addressed in phases.

