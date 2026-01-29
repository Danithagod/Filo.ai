# Desktop Build Fixes & Implementation Guide

This document provides complete implementation guidance for all desktop platform issues that must be addressed before releasing the Semantic Butler (Filo) desktop application.

**Last Updated**: January 27, 2026  
**Status**: Critical issues identified and detailed  
**Priority**: MUST complete Phase 1 (Critical) before any release build

---

## Table of Contents

1. [Phase 1: Critical Issues (MUST FIX)](#phase-1-critical-issues-must-fix)
2. [Phase 2: High Priority Issues (Before Beta)](#phase-2-high-priority-issues-before-beta)
3. [Phase 3: Medium Priority Issues (Before Stable)](#phase-3-medium-priority-issues-before-stable)
4. [Platform-Specific Build Commands](#platform-specific-build-commands)
5. [Build Scripts](#build-scripts)
6. [Testing & Validation](#testing--validation)

---

## PHASE 1: Critical Issues (MUST FIX)

These issues prevent the app from functioning on each platform. **All must be completed before any release build.**

### 1.1 Fix macOS Release.entitlements (Network & File Access)

**Problem**: The macOS release build completely lacks network and file system entitlements, preventing API calls and file access.

**File**: `semantic_butler/semantic_butler_flutter/macos/Runner/Release.entitlements`

**Current Content** (BROKEN):
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

**Required Fix**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>

	<!-- REQUIRED: Allow outgoing network connections for API calls -->
	<key>com.apple.security.network.client</key>
	<true/>

	<!-- REQUIRED: Allow incoming connections (if running local server) -->
	<key>com.apple.security.network.server</key>
	<true/>

	<!-- REQUIRED: File system access for file manager app -->
	<!-- Access to files user explicitly selects via file picker -->
	<key>com.apple.security.files.user-selected.read-write</key>
	<true/>

	<!-- Access to downloads folder -->
	<key>com.apple.security.files.downloads.read-write</key>
	<true/>

	<!-- Access to documents folder -->
	<key>com.apple.security.files.documents.read-write</key>
	<true/>

	<!-- Optional: Uncomment for broader file system access -->
	<!-- User will be prompted for permission when needed -->
	<!--
	<key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
	<array>
		<string>/</string>
	</array>
	-->
</dict>
</plist>
```

**Impact if not fixed**:
- ❌ API calls will fail with network error
- ❌ File picker will not work
- ❌ App will not function

**Time to fix**: 5 minutes

---

### 1.2 Fix macOS DebugProfile.entitlements (Add network.client)

**File**: `semantic_butler/semantic_butler_flutter/macos/Runner/DebugProfile.entitlements`

**Current Content** (INCOMPLETE):
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

**Required Fix** (Add missing entitlement):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.cs.allow-jit</key>
	<true/>
	<!-- REQUIRED: Allow outgoing network connections for API calls -->
	<key>com.apple.security.network.client</key>
	<true/>
	<key>com.apple.security.network.server</key>
	<true/>
	<!-- File access for file picker -->
	<key>com.apple.security.files.user-selected.read-write</key>
	<true/>
	<key>com.apple.security.files.downloads.read-write</key>
	<true/>
	<key>com.apple.security.files.documents.read-write</key>
	<true/>
</dict>
</plist>
```

**Impact if not fixed**:
- ❌ Debug builds will fail when calling API
- ❌ Development workflow will be blocked

**Time to fix**: 2 minutes

---

### 1.3 Rename App to "Filo" on Windows

**Files to Update**:
1. `semantic_butler/semantic_butler_flutter/windows/runner/main.cpp`
2. `semantic_butler/semantic_butler_flutter/windows/runner/Runner.rc`

#### 1.3.1 Update main.cpp

**File**: `windows/runner/main.cpp`

**Current** (WRONG):
```cpp
int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // ...
  flutter::DartProject project(L"data");  // Line 23 - WRONG

  // ...
  if (!window.Create(L"semantic_butler_flutter", origin, size)) {  // Line 33 - WRONG
```

**Required Fix**:
```cpp
int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"Filo");  // FIXED

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Filo", origin, size)) {  // FIXED
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
```

**Changes**: 
- Line 23: `L"data"` → `L"Filo"`
- Line 33: `L"semantic_butler_flutter"` → `L"Filo"`

**Impact if not fixed**:
- ❌ Window title shows "semantic_butler_flutter"
- ❌ Unprofessional appearance

**Time to fix**: 2 minutes

---

#### 1.3.2 Update Runner.rc

**File**: `windows/runner/Runner.rc`

**Current** (WRONG):
```rc
BLOCK "StringFileInfo"
BEGIN
    BLOCK "040904e4"
    BEGIN
        VALUE "CompanyName", "com.example" "\0"
        VALUE "FileDescription", "semantic_butler_flutter" "\0"
        VALUE "FileVersion", VERSION_AS_STRING "\0"
        VALUE "InternalName", "semantic_butler_flutter" "\0"
        VALUE "LegalCopyright", "Copyright (C) 2025 com.example. All rights reserved." "\0"
        VALUE "OriginalFilename", "semantic_butler_flutter.exe" "\0"
        VALUE "ProductName", "semantic_butler_flutter" "\0"
        VALUE "ProductVersion", VERSION_AS_STRING "\0"
    END
END
```

**Required Fix**:
```rc
BLOCK "StringFileInfo"
BEGIN
    BLOCK "040904e4"
    BEGIN
        VALUE "CompanyName", "Filo Contributors" "\0"
        VALUE "FileDescription", "Filo - Semantic Desktop Butler" "\0"
        VALUE "FileVersion", VERSION_AS_STRING "\0"
        VALUE "InternalName", "filo" "\0"
        VALUE "LegalCopyright", "Copyright (C) 2025 Filo Contributors. All rights reserved." "\0"
        VALUE "OriginalFilename", "filo.exe" "\0"
        VALUE "ProductName", "Filo" "\0"
        VALUE "ProductVersion", VERSION_AS_STRING "\0"
    END
END
```

**Impact if not fixed**:
- ❌ File properties show "semantic_butler_flutter"
- ❌ Task manager shows wrong name
- ❌ Unprofessional appearance

**Time to fix**: 5 minutes

---

### 1.4 Rename App to "Filo" on Linux

**File**: `semantic_butler/semantic_butler_flutter/linux/runner/my_application.cc`

**Current** (WRONG):
```cc
// Line 48
gtk_header_bar_set_title(header_bar, "semantic_butler_flutter");

// Line 52
gtk_window_set_title(window, "semantic_butler_flutter");
```

**Required Fix**:
```cc
// Line 48
gtk_header_bar_set_title(header_bar, "Filo");

// Line 52
gtk_window_set_title(window, "Filo");
```

**Impact if not fixed**:
- ❌ Window title shows "semantic_butler_flutter"
- ❌ Application menu shows wrong name
- ❌ Poor user experience on Linux

**Time to fix**: 2 minutes

---

### 1.5 Update Flutter Window Title

**File**: `semantic_butler/semantic_butler_flutter/lib/main.dart`

**Current** (Line 118):
```dart
win.title = "Semantic Butler";
```

**Required Fix**:
```dart
win.title = "Filo";
```

**Impact if not fixed**:
- ⚠️ macOS window title will be inconsistent
- Cosmetic issue but important for branding

**Time to fix**: 1 minute

---

## PHASE 2: High Priority Issues (Before Beta)

These issues should be completed before releasing a beta version.

### 2.1 Create Linux Desktop Integration File

**Purpose**: Enables Filo to appear in application menus, be launched from desktop, and be associated with file types.

**File to create**: `semantic_butler/semantic_butler_flutter/linux/com.filo.app.desktop`

```ini
[Desktop Entry]
Type=Application
Name=Filo
Comment=Semantic Desktop Search and File Management
Exec=filo %u
Icon=com.filo.app
Categories=Utility;FileManager;
Keywords=search;files;documents;
StartupNotify=true
Terminal=false
MimeType=inode/directory;
```

**Installation Steps**:
```bash
# Install desktop file to standard location
cp linux/com.filo.app.desktop ~/.local/share/applications/
# Or for system-wide installation:
sudo cp linux/com.filo.app.desktop /usr/share/applications/
```

**Time to create**: 10 minutes

---

### 2.2 Create Build Automation Scripts

**Purpose**: Automate cross-platform builds with environment variable substitution.

#### 2.2.1 Unix/Linux/macOS Build Script

**File to create**: `scripts/build-desktop.sh`

```bash
#!/bin/bash

# Filo Desktop Build Script
# Usage: ./build-desktop.sh <macos|windows|linux> [staging|production]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FLUTTER_DIR="$PROJECT_ROOT/semantic_butler/semantic_butler_flutter"

PLATFORM="${1:-}"
ENVIRONMENT="${2:-development}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Validation
if [ -z "$PLATFORM" ]; then
    print_error "Platform not specified"
    echo "Usage: $0 <macos|windows|linux> [staging|production]"
    exit 1
fi

if [ ! -d "$FLUTTER_DIR" ]; then
    print_error "Flutter project directory not found: $FLUTTER_DIR"
    exit 1
fi

# Change to Flutter directory
cd "$FLUTTER_DIR"

print_info "Building Filo for $PLATFORM ($ENVIRONMENT environment)..."

# Get version from pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | head -1 | awk '{print $2}')
print_info "Version: $VERSION"

# Build based on platform
case "$PLATFORM" in
    macos)
        print_info "Building macOS release build..."
        flutter build macos --release --dart-define=ENVIRONMENT=$ENVIRONMENT
        BUILD_OUTPUT="build/macos/Build/Products/Release/Filo.app"
        if [ -d "$BUILD_OUTPUT" ]; then
            print_success "macOS build complete: $BUILD_OUTPUT"
        else
            print_error "macOS build failed - output not found"
            exit 1
        fi
        ;;
    windows)
        print_info "Building Windows release build..."
        flutter build windows --release --dart-define=ENVIRONMENT=$ENVIRONMENT
        BUILD_OUTPUT="build/windows/runner/Release"
        if [ -d "$BUILD_OUTPUT" ]; then
            print_success "Windows build complete: $BUILD_OUTPUT"
        else
            print_error "Windows build failed - output not found"
            exit 1
        fi
        ;;
    linux)
        print_info "Building Linux release build..."
        flutter build linux --release --dart-define=ENVIRONMENT=$ENVIRONMENT
        BUILD_OUTPUT="build/linux/x64/release/bundle"
        if [ -d "$BUILD_OUTPUT" ]; then
            print_success "Linux build complete: $BUILD_OUTPUT"
        else
            print_error "Linux build failed - output not found"
            exit 1
        fi
        ;;
    *)
        print_error "Unknown platform: $PLATFORM"
        echo "Supported platforms: macos, windows, linux"
        exit 1
        ;;
esac

print_success "Build completed successfully!"
```

**Make executable**:
```bash
chmod +x scripts/build-desktop.sh
```

**Usage**:
```bash
# Development build
./scripts/build-desktop.sh macos development
./scripts/build-desktop.sh windows development
./scripts/build-desktop.sh linux development

# Production build
./scripts/build-desktop.sh macos production
./scripts/build-desktop.sh windows production
./scripts/build-desktop.sh linux production
```

**Time to create**: 15 minutes

---

#### 2.2.2 Windows PowerShell Build Script

**File to create**: `scripts/build-desktop.ps1`

```powershell
# Filo Desktop Build Script (PowerShell)
# Usage: .\build-desktop.ps1 -Platform macos -Environment production

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("macos", "windows", "linux")]
    [string]$Platform,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment = "development"
)

# Error handling
$ErrorActionPreference = "Stop"

# Paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$FlutterDir = Join-Path $ProjectRoot "semantic_butler" "semantic_butler_flutter"

# Validate paths
if (-not (Test-Path $FlutterDir)) {
    Write-Error "Flutter project directory not found: $FlutterDir"
    exit 1
}

# Change to Flutter directory
Set-Location $FlutterDir

Write-Host "ℹ Building Filo for $Platform ($Environment environment)..." -ForegroundColor Yellow

# Build
switch ($Platform) {
    "windows" {
        Write-Host "ℹ Building Windows release build..." -ForegroundColor Yellow
        & flutter build windows --release --dart-define=ENVIRONMENT=$Environment
        $BuildOutput = "build\windows\runner\Release"
    }
    "macos" {
        Write-Host "ℹ Building macOS release build..." -ForegroundColor Yellow
        & flutter build macos --release --dart-define=ENVIRONMENT=$Environment
        $BuildOutput = "build/macos/Build/Products/Release/Filo.app"
    }
    "linux" {
        Write-Host "ℹ Building Linux release build..." -ForegroundColor Yellow
        & flutter build linux --release --dart-define=ENVIRONMENT=$Environment
        $BuildOutput = "build/linux/x64/release/bundle"
    }
}

# Verify output
if (Test-Path $BuildOutput) {
    Write-Host "✓ Build complete: $BuildOutput" -ForegroundColor Green
} else {
    Write-Error "Build failed - output not found: $BuildOutput"
    exit 1
}

Write-Host "✓ Build completed successfully!" -ForegroundColor Green
```

**Usage**:
```powershell
.\scripts\build-desktop.ps1 -Platform windows -Environment production
.\scripts\build-desktop.ps1 -Platform macos -Environment staging
```

**Time to create**: 10 minutes

---

### 2.3 API Configuration Verification

**Status**: ✅ Already implemented correctly

**File**: `semantic_butler/semantic_butler_flutter/lib/config/app_config.dart`

**Current Implementation** (GOOD):
```dart
class AppConfig {
  static String get apiBaseUrl {
    const env = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'development',
    );

    switch (env) {
      case 'production':
        return 'https://semantic-butler-api.serverpod.space/';
      case 'staging':
        return 'https://semantic-butler-staging-api.serverpod.space/';
      default:
        return 'http://127.0.0.1:8080/';
    }
  }

  static Future<AppConfig> loadConfig() async {
    return AppConfig();
  }

  final String apiUrl;

  AppConfig() : apiUrl = apiBaseUrl;
}
```

**No changes needed**. This correctly supports environment-based configuration.

---

### 2.4 Icon Configuration

**Status**: ⚠️ Needs verification

Create or verify icon files for each platform:

**macOS**:
- Location: `macos/Runner/Assets.xcassets/AppIcon.appiconset/`
- Format: `.icns`
- Size: 1024×1024 pixels

**Windows**:
- Location: `windows/runner/resources/app_icon.ico`
- Format: `.ico`
- Size: 256×256 pixels (minimum)

**Linux**:
- Location: `linux/assets/icon.png`
- Format: `.png`
- Size: 512×512 pixels

---

## PHASE 3: Medium Priority Issues (Before Stable Release)

These items should be completed before a stable release.

### 3.1 Code Signing Setup

**macOS Code Signing**:
```bash
# Verify code signing certificate
security find-identity -v -p codesigning

# Sign the built app
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (XXXXX)" \
  build/macos/Build/Products/Release/Filo.app

# Verify signature
codesign -v --deep build/macos/Build/Products/Release/Filo.app
spctl -a -v build/macos/Build/Products/Release/Filo.app
```

**Windows Code Signing**:
- Requires Authenticode certificate
- Use `signtool.exe` from Windows SDK:
```batch
signtool sign /f certificate.pfx /p password /t http://timestamp.server.com /fd SHA256 build\windows\runner\Release\filo.exe
```

---

### 3.2 Installer Package Creation

#### macOS Disk Image (.dmg)

```bash
# Install create-dmg
brew install create-dmg

# Create .dmg file
create-dmg \
  --volname "Filo" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --app-drop-link 450 185 \
  --background resources/dmg-background.png \
  "Filo-v1.0.0-macOS.dmg" \
  "build/macos/Build/Products/Release/Filo.app"
```

#### Windows Installer (.exe/.msi)

Option A: Using MSIX:
```bash
flutter pub add msix
flutter pub run msix:create
```

Option B: Using Inno Setup:
```bash
# Create filo-installer.iss (Inno Setup script)
# Then compile:
iscc filo-installer.iss
```

#### Linux AppImage

```bash
# Download linuxdeploy tools
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
wget https://github.com/linuxdeploy/linuxdeploy-plugin-flutter/releases/download/continuous/linuxdeploy-plugin-flutter-x86_64.AppImage

chmod +x linuxdeploy*.AppImage

# Create AppImage
./linuxdeploy-x86_64.AppImage \
  --plugin flutter \
  --executable build/linux/x64/release/bundle/filo \
  --output-dir appimage-output \
  --create-appimage

# Create .deb package
fpm -s dir -t deb -n filo -v 1.0.0 \
  -C build/linux/x64/release/bundle \
  --prefix /opt/filo \
  -a x86_64
```

---

### 3.3 Crash Reporting Integration

**Recommended**: Sentry or Firebase Crashlytics

**Sentry Setup** (Recommended for desktop):
```bash
flutter pub add sentry_flutter
```

**Configuration** (lib/main.dart):
```dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN';
      options.environment = Environment;
    },
    appRunner: () => runApp(const MyApp()),
  );
}
```

---

### 3.4 Create CHANGELOG.md

**File to create**: `CHANGELOG.md`

```markdown
# Changelog

All notable changes to Filo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2025-01-27

### Added
- Initial desktop application release
- Cross-platform support (macOS, Windows, Linux)
- Semantic file search with AI-powered indexing
- Real-time file system monitoring
- File tagging and organization
- Chat-based file operations
- Built-in file manager
- Settings and preferences

### Known Issues
- Linux Wayland support limited
- Some network proxy configurations may cause issues

## [Unreleased]

### Planned
- Web-based interface
- Mobile companion app
- Advanced filtering and saved searches
- Collaborative tagging
```

---

## Platform-Specific Build Commands

### macOS

**Development**:
```bash
cd semantic_butler/semantic_butler_flutter
flutter run -d macos
```

**Release Build**:
```bash
flutter build macos --release --dart-define=ENVIRONMENT=production
# Output: build/macos/Build/Products/Release/Filo.app
```

**With Build Script**:
```bash
./scripts/build-desktop.sh macos production
```

---

### Windows

**Development**:
```bash
cd semantic_butler/semantic_butler_flutter
flutter run -d windows
```

**Release Build**:
```bash
flutter build windows --release --dart-define=ENVIRONMENT=production
# Output: build/windows/runner/Release/filo.exe
```

**With Build Script**:
```bash
./scripts/build-desktop.sh windows production
# or
.\scripts\build-desktop.ps1 -Platform windows -Environment production
```

---

### Linux

**Development**:
```bash
cd semantic_butler/semantic_butler_flutter
flutter run -d linux
```

**Release Build**:
```bash
flutter build linux --release --dart-define=ENVIRONMENT=production
# Output: build/linux/x64/release/bundle/filo
```

**With Build Script**:
```bash
./scripts/build-desktop.sh linux production
```

---

## Build Scripts

### Using Bash/Shell (macOS/Linux)

```bash
# Make executable
chmod +x scripts/build-desktop.sh

# Build for production
./scripts/build-desktop.sh macos production
./scripts/build-desktop.sh linux production

# Build for staging (development testing)
./scripts/build-desktop.sh windows staging
```

### Using PowerShell (Windows)

```powershell
# Build for production
.\scripts\build-desktop.ps1 -Platform windows -Environment production

# Build for staging
.\scripts\build-desktop.ps1 -Platform macos -Environment staging
```

---

## Testing & Validation

### Pre-Release Checklist

#### macOS
- [ ] Build completes without errors: `flutter build macos --release`
- [ ] App launches from build directory
- [ ] Window title shows "Filo"
- [ ] API calls work with production URL
- [ ] File picker opens correctly
- [ ] File operations (read/write) work
- [ ] Code signature is valid: `codesign -v --deep build/macos/Build/Products/Release/Filo.app`
- [ ] Gatekeeper accepts app: `spctl -a -v build/macos/Build/Products/Release/Filo.app`
- [ ] App icon displays correctly

#### Windows
- [ ] Build completes without errors: `flutter build windows --release`
- [ ] Executable is named `filo.exe`
- [ ] App launches and shows "Filo" in window title
- [ ] API calls work with production URL
- [ ] File picker opens correctly
- [ ] File operations work
- [ ] Task Manager shows correct app name
- [ ] File properties show correct metadata
- [ ] No SmartScreen warnings (or properly signed)
- [ ] App icon displays correctly

#### Linux
- [ ] Build completes without errors: `flutter build linux --release`
- [ ] Executable is located at `build/linux/x64/release/bundle/filo`
- [ ] App launches from terminal
- [ ] Window title shows "Filo"
- [ ] Header bar shows "Filo" (if using header bar)
- [ ] API calls work with production URL
- [ ] File picker opens correctly
- [ ] File operations work
- [ ] Desktop file is properly installed
- [ ] App appears in application menu
- [ ] App icon displays correctly

#### All Platforms
- [ ] Production API URL is used (verify in logs)
- [ ] No development/hardcoded URLs visible
- [ ] App version number is correct
- [ ] No console output unless debug mode
- [ ] Error messages are user-friendly
- [ ] Network timeouts are handled gracefully

---

## Troubleshooting

### macOS Build Issues

**Entitlements Error**:
```
error: fatal error: provisioning profile does not include the aps-environment entitlement
```
**Solution**: Update entitlements files as shown in Phase 1.1 and 1.2

**"code has invalid signature"**:
```bash
# Verify
codesign -v --deep build/macos/Build/Products/Release/Filo.app

# Resign
codesign --deep --force --sign - build/macos/Build/Products/Release/Filo.app
```

---

### Windows Build Issues

**"DartProject" requires string**:
```
error: no matching constructor for initialization of 'flutter::DartProject'
```
**Solution**: Update `main.cpp` line 23 to use string, not `L"data"`

---

### Linux Build Issues

**GTK not found**:
```bash
sudo apt-get install libgtk-3-dev
```

**Missing plugins**:
```bash
flutter pub get
flutter pub run build_runner build
```

---

## Directory Structure After Changes

```
semantic_butler/
├── semantic_butler_server/
├── semantic_butler_client/
└── semantic_butler_flutter/
    ├── macos/
    │   ├── Runner/
    │   │   ├── Release.entitlements (UPDATED)
    │   │   ├── DebugProfile.entitlements (UPDATED)
    │   │   └── Info.plist
    ├── windows/
    │   ├── runner/
    │   │   ├── main.cpp (UPDATED)
    │   │   └── Runner.rc (UPDATED)
    ├── linux/
    │   ├── runner/
    │   │   └── my_application.cc (UPDATED)
    │   └── com.filo.app.desktop (NEW)
    ├── lib/
    │   ├── main.dart (UPDATED - line 118)
    │   └── config/
    │       └── app_config.dart (OK - no changes)
    ├── pubspec.yaml
    └── assets/
        └── config.json

scripts/
├── build-desktop.sh (NEW)
└── build-desktop.ps1 (NEW)

CHANGELOG.md (NEW)
```

---

## Build Timeline

**Phase 1 (Critical)**: 20 minutes
- macOS entitlements
- Windows app naming
- Linux app naming
- Window titles

**Phase 2 (Before Beta)**: 1-2 hours
- Build scripts
- Linux desktop integration
- Icon verification
- Basic testing

**Phase 3 (Before Stable)**: 4-8 hours
- Code signing setup
- Installer creation
- Crash reporting integration
- Comprehensive testing

**Total Effort**: 6-12 hours for complete release

---

## Additional Resources

- [Flutter Desktop Documentation](https://docs.flutter.dev/desktop)
- [macOS Entitlements Reference](https://developer.apple.com/documentation/bundleresources/entitlements)
- [Linux Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/)
- [Windows Resource Files](https://learn.microsoft.com/en-us/windows/win32/menurc/about-resource-files)
- [Code Signing and Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)

---

## Summary

**Status**: All critical issues identified and solutions provided.

**Next Steps**:
1. ✓ Apply Phase 1 changes (20 min) - **DO THIS FIRST**
2. ✓ Test builds on all platforms
3. ✓ Implement Phase 2 before beta (1-2 hours)
4. ✓ Complete Phase 3 before stable release (4-8 hours)

**Estimated Total**: 6-12 hours to production-ready state

---

Last updated: January 27, 2026
