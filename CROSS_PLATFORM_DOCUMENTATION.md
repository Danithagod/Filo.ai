# Cross-Platform Documentation

This document provides comprehensive information for building, testing, and deploying the Semantic Butler application across Windows, macOS, and Linux platforms.

## Table of Contents

1. [Cross-Platform Compatibility](#cross-platform-compatibility)
2. [Platform Build Guide](#platform-build-guide)
3. [Platform Testing Checklist](#platform-testing-checklist)

---

## Cross-Platform Compatibility

### Overview

Semantic Butler is a **Flutter desktop application** with a Serverpod backend. The application is designed primarily for desktop platforms (Windows, macOS, Linux) and includes platform-specific optimizations.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Desktop App                      │
│  (semantic_butler_flutter)                                   │
│  - Windows: CMake build system                               │
│  - macOS: Xcode project files                                │
│  - Linux: GTK/CMake build system                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Serverpod Backend                          │
│  (semantic_butler_server)                                    │
│  - Docker deployment (PostgreSQL + Redis)                    │
│  - Cross-platform Dart server                                │
└─────────────────────────────────────────────────────────────┘
```

### Platform Behaviors and Limitations

#### Windows

**Status:** Fully Supported

**Capabilities:**
- Custom window controls via `bitsdojo_window`
- Direct file system access
- Native file dialogs via `file_picker`
- Native path handling (backslash separators)
- Registry access for settings (APPDATA environment variable)

**Known Limitations:**
- `bitsdojo_window` package is Windows-focused
- Path separators require special handling (`\` vs `/`)
- File permissions model differs from Unix-like systems

**Platform-Specific Code Locations:**
- [main.dart:112-129](semantic_butler/semantic_butler_flutter/lib/main.dart#L112-L129) - Window initialization
- [file_manager_screen.dart:854-864](semantic_butler/semantic_butler_flutter/lib/screens/file_manager_screen.dart#L854-L864) - Windows APPDATA path handling
- [breadcrumb_navigation.dart:226](semantic_butler/semantic_butler_flutter/lib/widgets/file_manager/breadcrumb_navigation.dart#L226) - Windows path handling
- [windows/runner/CMakeLists.txt](semantic_butler/semantic_butler_flutter/windows/runner/CMakeLists.txt) - Native build configuration

#### macOS

**Status:** Fully Supported (with entitlements)

**Capabilities:**
- Custom window controls via `bitsdojo_window`
- Direct file system access
- Native file dialogs via `file_picker`
- Unix-style path handling
- Sandbox entitlements for security

**Known Limitations:**
- App sandbox restrictions (see entitlements files)
- Code signing required for distribution
- Notarization required for macOS 10.15+
- File system access limited outside home directory in sandbox

**Platform-Specific Code Locations:**
- [main.dart:112-129](semantic_butler/semantic_butler_flutter/lib/main.dart#L112-L129) - Window initialization
- [file_manager_screen.dart:858-863](semantic_butler/semantic_butler_flutter/lib/screens/file_manager_screen.dart#L858-L863) - macOS HOME path handling
- [macos/Runner/Info.plist](semantic_butler/semantic_butler_flutter/macos/Runner/Info.plist) - App configuration
- [macos/Runner/DebugProfile.entitlements](semantic_butler/semantic_butler_flutter/macos/Runner/DebugProfile.entitlements) - Debug entitlements
- [macos/Runner/Release.entitlements](semantic_butler/semantic_butler_flutter/macos/Runner/Release.entitlements) - Release entitlements

**Entitlements Required:**
- `com.apple.security.app-sandbox` - App sandboxing
- `com.apple.security.cs.allow-jit` - JIT compilation (debug)
- `com.apple.security.network.server` - Network server access (debug)

**Additional Entitlements for Production:**
```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

#### Linux

**Status:** Fully Supported

**Capabilities:**
- Custom window controls via `bitsdojo_window`
- Direct file system access
- Native file dialogs via `file_picker`
- Unix-style path handling
- GTK integration for native look and feel

**Known Limitations:**
- GTK 3+ development libraries required
- Distribution-specific packaging (AppImage, deb, rpm)
- Desktop entry files required for proper integration
- No centralized app store (varies by distribution)

**Platform-Specific Code Locations:**
- [main.dart:112-129](semantic_butler/semantic_butler_flutter/lib/main.dart#L112-L129) - Window initialization
- [file_manager_screen.dart:863](semantic_butler/semantic_butler_flutter/lib/screens/file_manager_screen.dart#L863) - Linux HOME path handling
- [linux/runner/CMakeLists.txt](semantic_butler/semantic_butler_flutter/linux/runner/CMakeLists.txt) - GTK/CMake build configuration

#### Web (Future)

**Status:** Partially Supported (backend only)

**Capabilities:**
- Serverpod backend supports web deployment
- Flutter web build available in server pubspec

**Known Limitations:**
- `bitsdojo_window` not supported (desktop-only)
- File system access restricted (browser sandbox)
- No direct file system access
- Custom window title bar not applicable

#### Mobile (Future)

**Status:** Not Currently Supported

**Limitations:**
- UI not optimized for mobile screens
- Custom window controls not applicable
- Different file access patterns required
- Backend server would need remote deployment

### Dependency Platform Matrix

| Dependency | Windows | macOS | Linux | Web | Notes |
|------------|---------|-------|-------|-----|-------|
| `bitsdojo_window` | ✅ | ✅ | ✅ | ❌ | Desktop-only window controls |
| `file_picker` | ✅ | ✅ | ✅ | ⚠️ | Limited on web |
| `url_launcher` | ✅ | ✅ | ✅ | ✅ | Full cross-platform |
| `path_provider` | ✅ | ✅ | ✅ | ⚠️ | Limited on web |
| `flutter_riverpod` | ✅ | ✅ | ✅ | ✅ | Full cross-platform |
| `fl_chart` | ✅ | ✅ | ✅ | ✅ | Full cross-platform |
| `serverpod_flutter` | ✅ | ✅ | ✅ | ✅ | Full cross-platform |

### Key Platform Differences

#### Path Separators

| Platform | Separator | Constant |
|----------|-----------|----------|
| Windows | `\` | `Platform.pathSeparator` |
| macOS/Linux | `/` | `Platform.pathSeparator` |

**Implementation:** Code uses `Platform.pathSeparator` for cross-platform compatibility.

#### Environment Variables

| Setting | Windows | macOS/Linux |
|---------|---------|-------------|
| App Data | `%APPDATA%` | `$HOME/.config` |
| Home | `%USERPROFILE%` | `$HOME` |
| Temp | `%TEMP%` | `/tmp` |

**Implementation:** See [file_manager_screen.dart:854-863](semantic_butler/semantic_butler_flutter/lib/screens/file_manager_screen.dart#L854-L863)

#### Root/Drive Access

| Platform | Root Display | Icon |
|----------|--------------|------|
| Windows | "This PC" | `Icons.computer` |
| macOS/Linux | "Root" | `Icons.home_outlined` |

**Implementation:** See [breadcrumb_navigation.dart:70-81](semantic_butler/semantic_butler_flutter/lib/widgets/file_manager/breadcrumb_navigation.dart#L70-L81)

### File System Permissions

#### macOS Sandbox

The macOS app runs in a sandbox with the following restrictions:
- Can only access user-selected files explicitly
- Cannot access arbitrary paths without user permission
- Network access must be explicitly declared

**Required entitlements for full functionality:**
```xml
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

#### Windows

- Full file system access (no sandbox)
- May require administrator privileges for system folders
- User Account Control (UAC) may prompt for elevated access

#### Linux

- Full file system access (no sandbox)
- Respects Unix file permissions
- May need appropriate user/group permissions

---

## Platform Build Guide

### Prerequisites

#### Common Requirements

```bash
# Flutter SDK (3.24.0+)
# Dart SDK (3.8.0+)
# Git
```

Verify installation:
```bash
flutter --version
dart --version
```

### Windows Build Guide

#### Development Environment Setup

1. **Install Visual Studio 2022** (Community or higher)
   - Select "Desktop development with C++" workload
   - Include Windows 10/11 SDK

2. **Install Flutter SDK**
   ```powershell
   # Download from https://docs.flutter.dev/get-started/install/windows
   # Add to PATH
   flutter doctor
   ```

3. **Verify Dependencies**
   ```powershell
   flutter doctor -v
   ```

#### Debug Build

```powershell
cd semantic_butler/semantic_butler_flutter

# Get dependencies
flutter pub get

# Run in debug mode
flutter run -d windows

# Run with specific configuration
flutter run -d windows --profile
```

#### Release Build

```powershell
# Build release executable
flutter build windows --release

# Output location: build/windows/runner/Release/
# Main executable: build/windows/runner/Release/semantic_butler_flutter.exe
```

#### Installer Creation

**Using WiX Toolset:**

```powershell
# Install WiX Toolset
# Download from https://wixtoolset.org/releases/

# Create installer (manual process with WiX)
# Or use electron-builder-like alternatives for Flutter
```

**Alternative: MSIX Packaging**

```powershell
# Install Windows SDK
# Use MakeAppx.exe and SignTool.exe

flutter build windows --release

# Create MSIX package manually or via Windows Application Packaging Project
```

#### Code Signing (Optional)

```powershell
# Sign the executable
signtool sign /f certificate.pfx /p password /t http://timestamp.digicert.com build/windows/runner/Release/semantic_butler_flutter.exe
```

### macOS Build Guide

#### Development Environment Setup

1. **Install Xcode** (from Mac App Store)
   ```bash
   xcode-select --install
   ```

2. **Install Flutter SDK**
   ```bash
   # Download from https://docs.flutter.dev/get-started/install/macos
   # Add to PATH
   flutter doctor
   ```

3. **Install CocoaPods**
   ```bash
   sudo gem install cocoapods
   ```

#### Debug Build

```bash
cd semantic_butler/semantic_butler_flutter

# Get dependencies
flutter pub get

# Install CocoaPods dependencies
cd macos
pod install
cd ..

# Run in debug mode
flutter run -d macos

# Run with specific configuration
flutter run -d macos --profile
```

#### Release Build

```bash
# Build release app
flutter build macos --release

# Output location: build/macos/Build/Products/Release/
# App bundle: build/macos/Build/Products/Release/semantic_butler_flutter.app
```

#### Code Signing

**Development Signing:**

```bash
# Automatic with debug builds
flutter build macos
```

**Release Signing:**

1. **Create Developer ID Certificate**
   - Go to Apple Developer Portal
   - Create "Developer ID Application" certificate
   - Download and install in Keychain

2. **Update Entitlements**

Edit [macos/Runner/Release.entitlements](semantic_butler/semantic_butler_flutter/macos/Runner/Release.entitlements):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

3. **Sign and Build**

```bash
# Update the bundle identifier if needed
# Edit macos/Runner/Info.plist

# Build with signing
flutter build macos --release

# Verify signature
codesign -dv --verbose=4 build/macos/Build/Products/Release/semantic_butler_flutter.app
```

#### Notarization (Required for macOS 10.15+)

```bash
# After code signing, submit for notarization
xcrun notarytool submit build/macos/Build/Products/Release/semantic_butler_flutter.app \
    --apple-id "your@email.com" \
    --password "app-specific-password" \
    --team-id "TEAM_ID" \
    --wait

# Staple the notary ticket
xcrun stapler staple build/macos/Build/Products/Release/semantic_butler_flutter.app
```

#### DMG Creation

```bash
# Create DMG
hdiutil create -volname "Semantic Butler" \
    -srcfolder build/macos/Build/Products/Release/semantic_butler_flutter.app \
    -ov -format UDZO build/SemanticButler.dmg
```

**Alternative:** Use [dmgbuild](https://github.com/al45tair/dmgbuild) for styled DMGs:
```bash
pip install dmgbuild
dmgbuild -s "path/to/settings.py" "Semantic Butler" build/SemanticButler.dmg
```

### Linux Build Guide

#### Development Environment Setup

1. **Install Flutter Dependencies**

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev \
    curl \
    git
```

**Fedora:**
```bash
sudo dnf install \
    clang \
    cmake \
    ninja-build \
    gtk3-devel \
    lzma-devel \
    gcc-c++ \
    curl \
    git
```

**Arch Linux:**
```bash
sudo pacman -S \
    clang \
    cmake \
    ninja \
    gtk3 \
    xz \
    gcc \
    curl \
    git
```

2. **Install Flutter SDK**
   ```bash
   # Download from https://docs.flutter.dev/get-started/install/linux
   # Add to PATH
   export PATH="$PATH:$HOME/flutter/bin"
   flutter doctor
   ```

#### Debug Build

```bash
cd semantic_butler/semantic_butler_flutter

# Get dependencies
flutter pub get

# Run in debug mode
flutter run -d linux

# Run with specific configuration
flutter run -d linux --profile
```

#### Release Build

```bash
# Build release executable
flutter build linux --release

# Output location: build/linux/*/release/bundle/
```

#### Packaging

**AppImage (Universal Linux Package):**

1. Install appimage-builder:
   ```bash
   # Download from https://appimage-builder.readthedocs.io
   wget https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.0.0/appimage-builder-1.0.0-x86_64.AppImage
   chmod +x appimage-builder-1.0.0-x86_64.AppImage
   ```

2. Create AppImage recipe (`AppImageBuilder.yml`):
   ```yaml
   version: 1.0.0
   app:
     id: com.semanticbutler.app
     name: Semantic Butler
     icon: assets/app_icon.png
     exec: usr/bin/semantic_butler_flutter
     paths:
       - build/linux/*/release/bundle

   linux:
   - category: Utility
   - description: Semantic Desktop Butler with AI-powered file search
   - executables:
       - name: semantic_butler_flutter
         path: usr/bin/semantic_butler_flutter

   runtime:
     env:
       APPIMAGE_EXTRACT_AND_RUN: 1
   ```

3. Build AppImage:
   ```bash
   ./appimage-builder-1.0.0-x86_64.AppImage
   ```

**Debian Package (.deb):**

```bash
# Install dpkg-deb and dependencies
sudo apt install dpkg-deb

# Create package structure
mkdir -p semantic-butler_$VERSION/opt/semantic-butler
mkdir -p semantic-butler_$VERSION/usr/share/applications
mkdir -p semantic-butler_$VERSION/usr/share/pixmaps

# Copy files
cp -r build/linux/*/release/bundle/* semantic-butler_$VERSION/opt/semantic-butler/

# Create desktop entry
cat > semantic-butler_$VERSION/usr/share/applications/semantic-butler.desktop << EOF
[Desktop Entry]
Name=Semantic Butler
Comment=AI-powered file search for your desktop
Exec=/opt/semantic-butler/semantic_butler_flutter
Icon=semantic-butler
Type=Application
Categories=Utility;FileManager;
EOF

# Create DEB package
dpkg-deb --build semantic-butler_$VERSION
```

**RPM Package (.rpm):**

```bash
# Install rpmbuild
sudo dnf install rpm-build

# Create spec file and build
rpmbuild -bb semantic-butler.spec
```

#### Flatpak (Alternative Distribution)

```bash
# Install flatpak and flatpak-builder
sudo flatpak install flathub org.freedesktop.Platform//22.08
sudo flatpak install flathub org.freedesktop.Sdk//22.08

# Create flatpak manifest (com.semanticbutler.app.json)
# Then build:
flatpak-builder build-dir com.semanticbutler.app.json
```

---

## Platform Testing Checklist

### Pre-Testing Setup

#### Test Environment Preparation

```bash
# 1. Clean build for each platform
flutter clean
flutter pub get

# 2. Run analyzer
flutter analyze

# 3. Run tests (if available)
flutter test
```

#### Test Data

Prepare a standardized test folder structure:
```
test_folder/
├── documents/
│   ├── test.txt
│   ├── report.pdf
│   └── notes.md
├── images/
│   ├── photo.jpg
│   └── diagram.png
├── code/
│   ├── script.py
│   └── app.js
└── empty_folder/
```

### Windows Testing Checklist

#### Installation Tests

- [ ] Application installs without errors
- [ ] Desktop shortcut created correctly
- [ ] Start menu entry present
- [ ] Uninstaller removes all files
- [ ] Uninstaller removes registry entries
- [ ] Re-installation works correctly

#### Launch Tests

- [ ] Application launches from desktop shortcut
- [ ] Application launches from Start menu
- [ ] Application launches from executable directly
- [ ] Launch time under 3 seconds on modern hardware
- [ ] Multiple instances handled correctly

#### UI/UX Tests

- [ ] Window title bar displays correctly with custom controls
- [ ] Minimize/Maximize/Close buttons work
- [ ] Window resizing works smoothly
- [ ] Window minimum size (800x600) enforced
- [ ] Dark/light theme toggle works
- [ ] All text renders correctly
- [ ] No layout issues on different DPI settings (100%, 125%, 150%, 200%)
- [ ] Touch gestures work on touch-enabled devices

#### File System Tests

- [ ] "This PC" root navigation works
- [ ] Drive letters display correctly
- [ ] Can navigate to C:\
- [ ] Can navigate to other drives (D:, E:, etc.)
- [ ] Path handling with backslashes works
- [ ] UNC paths (\\server\share) work if supported
- [ ] File picker opens correctly
- [ ] Can select files from file picker
- [ ] Can select folders from folder picker
- [ ] File operations work (copy, move, delete)
- [ ] Special folders (Documents, Desktop, Downloads) accessible

#### Network Tests

- [ ] Connects to local server (http://127.0.0.1:8080/)
- [ ] Handles server connection failure gracefully
- [ ] Reconnects when server becomes available
- [ ] API calls complete without timeout errors
- [ ] Search functionality works

#### Permissions Tests

- [ ] Works with standard user account
- [ ] No admin privileges required for basic operations
- [ ] UAC prompts only when necessary
- [ ] File operations respect Windows permissions

#### Performance Tests

- [ ] Memory usage under 500MB at idle
- [ ] CPU usage under 5% at idle
- [ ] Search results return in reasonable time
- [ ] No memory leaks after extended use
- [ ] No UI freeze during long operations

#### Error Handling Tests

- [ ] Graceful handling of missing config file
- [ ] Graceful handling of invalid server URL
- [ ] Graceful handling of network errors
- [ ] Graceful handling of file access denied errors
- [ ] Error messages are user-friendly

### macOS Testing Checklist

#### Installation Tests

- [ ] Application installs by dragging to Applications
- [ ] Application launches from Applications folder
- [ ] Dock icon appears correctly
- [ ] Spotlight finds the application
- [ ] Uninstalling removes all files
- [ ] Application bundle structure is correct

#### Code Signing Tests

- [ ] Debug build runs without code signing issues
- [ ] Release build is properly signed
- [ ] No untrusted developer warnings
- [ ] Signature verification passes: `codesign -dv`
- [ ] Notarization successful (for release builds)
- [ ] No quarantine attribute on launch

#### Launch Tests

- [ ] Application launches from Applications folder
- [ ] Application launches from Dock
- [ ] Application launches from Spotlight
- [ ] Launch time under 3 seconds on modern hardware
- [ ] Resume state works after closing

#### UI/UX Tests

- [ ] Window title bar displays correctly with custom controls
- [ ] Traffic light buttons (close, minimize, maximize) work
- [ ] Window snapping works (optional)
- [ ] Full-screen mode works
- [ ] Dark/light theme toggle works
- [ ] All text renders correctly
- [ ] Native macOS look and feel maintained
- [ ] Trackpad gestures work (scroll, swipe)

#### File System Tests

- [ ] "Root" navigation works
- [ ] Home folder (~) accessible
- [ ] Desktop folder accessible
- [ ] Documents folder accessible
- [ ] Downloads folder accessible
- [ ] Path handling with forward slashes works
- [ ] File picker opens correctly
- [ ] Sandbox file access works correctly
- [ ] Can select files from file picker
- [ ] Can select folders from folder picker
- [ ] File operations work (copy, move, delete)

#### Sandbox Tests

- [ ] App runs within sandbox without errors
- [ ] User-selected files are accessible
- [ ] Entitlements are properly configured
- [ ] No unauthorized file access attempts
- [ ] Network access works as configured

#### Network Tests

- [ ] Connects to local server (http://127.0.0.1:8080/)
- [ ] Handles server connection failure gracefully
- [ ] Reconnects when server becomes available
- [ ] API calls complete without timeout errors
- [ ] Search functionality works

#### Performance Tests

- [ ] Memory usage under 500MB at idle
- [ ] CPU usage under 5% at idle
- [ ] Search results return in reasonable time
- [ ] No memory leaks after extended use
- [ ] No UI freeze during long operations

#### macOS-Specific Tests

- [ ] Follows macOS human interface guidelines
- [ ] Proper menu bar extras (if any)
- [ ] Proper keyboard shortcuts (Cmd+Q, Cmd+W, etc.)
- [ ] Native font rendering looks good
- [ ] Retina display support works

### Linux Testing Checklist

#### Installation Tests

- [ ] AppImage runs without installation
- [ ] AppImage launches correctly
- [ ] DEB package installs correctly (Ubuntu/Debian)
- [ ] RPM package installs correctly (Fedora/RHEL)
- [ ] Desktop entry created correctly
- [ ] Application appears in application menu
- [ ] Icon displays correctly
- [ ] Uninstallation removes all files

#### Launch Tests

- [ ] Application launches from desktop entry
- [ ] Application launches from terminal
- [ ] Application launches from AppImage
- [ ] Launch time under 3 seconds on modern hardware
- [ ] No console errors on launch

#### UI/UX Tests

- [ ] Window title bar displays correctly with custom controls
- [ ] Window controls (minimize, maximize, close) work
- [ ] Window resizing works smoothly
- [ ] Window minimum size (800x600) enforced
- [ ] Dark/light theme toggle works
- [ ] GTK theme integration works
- [ ] All text renders correctly
- [ ] No layout issues on different screen scales
- [ ] Compositor effects work if available

#### File System Tests

- [ ] "Root" navigation works
- [ ] Home folder (~) accessible
- [ ] Desktop folder accessible
- [ ] Documents folder accessible
- [ ] Downloads folder accessible
- [ ] Other mount points accessible
- [ ] Path handling with forward slashes works
- [ ] File picker opens correctly
- [ ] Can select files from file picker
- [ ] Can select folders from folder picker
- [ ] File operations work (copy, move, delete)
- [ ] Symlinks handled correctly
- [ ] Hidden files displayed correctly

#### Network Tests

- [ ] Connects to local server (http://127.0.0.1:8080/)
- [ ] Handles server connection failure gracefully
- [ ] Reconnects when server becomes available
- [ ] API calls complete without timeout errors
- [ ] Search functionality works

#### Performance Tests

- [ ] Memory usage under 500MB at idle
- [ ] CPU usage under 5% at idle
- [ ] Search results return in reasonable time
- [ ] No memory leaks after extended use
- [ ] No UI freeze during long operations

#### Distribution-Specific Tests

**Ubuntu/Debian:**
- [ ] Works on Ubuntu 22.04 LTS
- [ ] Works on Ubuntu 24.04 LTS
- [ ] Works on Debian 12
- [ ] DEB package dependencies correct

**Fedora:**
- [ ] Works on Fedora 39
- [ ] Works on Fedora 40
- [ ] RPM package dependencies correct

**Arch Linux:**
- [ ] Works on Arch rolling release
- [ ] AUR package (if available) works

#### Linux-Specific Tests

- [ ] Follows freedesktop.org standards
- [ ] XDG directories respected
- [ ] Keyboard shortcuts follow Linux conventions
- [ ] Font rendering looks good (fontconfig)
- [ ] Works with Wayland (if supported by Flutter)
- [ ] Works with X11

### Cross-Platform Testing

#### Feature Parity Tests

Verify these features work identically across all platforms:

- [ ] Search functionality
- [ ] File indexing
- [ ] Tag management
- [ ] File preview
- [ ] Settings persistence
- [ ] Theme switching
- [ ] Keyboard shortcuts
- [ ] Error messages

#### Configuration Tests

- [ ] Server URL configuration works
- [ ] Settings persist across restarts
- [ ] Configuration file format is compatible
- [ ] Default settings are appropriate

#### Accessibility Tests

- [ ] Screen reader compatibility (Windows: Narrator, macOS: VoiceOver, Linux: Orca)
- [ ] Keyboard navigation works
- [ ] High contrast mode support
- [ ] Font scaling works

### Automated Testing

#### Unit Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

#### Integration Tests

```bash
# Run integration tests
flutter test integration_test/
```

#### Platform-Specific Tests

```bash
# Windows tests
flutter test -d windows

# macOS tests
flutter test -d macos

# Linux tests
flutter test -d linux
```

### Continuous Integration

#### GitHub Actions Workflows

The project includes CI workflows:

- **[tests.yml](semantic_butler/.github/workflows/tests.yml)** - Runs server tests on Ubuntu
- **[analyze.yml](semantic_butler/.github/workflows/analyze.yml)** - Code analysis
- **[format.yml](semantic_butler/.github/workflows/format.yml)** - Code formatting checks

#### Recommended Platform-Specific CI

**Windows (GitHub Actions):**
```yaml
jobs:
  test-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter test -d windows
```

**macOS (GitHub Actions):**
```yaml
jobs:
  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter test -d macos
```

**Linux (GitHub Actions):**
```yaml
jobs:
  test-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter test -d linux
```

### Release Checklist

Before releasing to any platform:

- [ ] All tests pass on target platform
- [ ] Code coverage above threshold (if defined)
- [ ] No critical bugs outstanding
- [ ] Documentation updated
- [ ] Release notes prepared
- [ ] Version number updated in pubspec.yaml
- [ ] Build artifacts created and tested
- [ ] Code signing completed (Windows, macOS)
- [ ] Notarization completed (macOS)
- [ ] Package tested on clean system
- [ ] Installation/uninstallation verified
- [ ] Performance benchmarks met

---

## Platform-Specific Resources

### Windows
- [Flutter Windows Desktop](https://docs.flutter.dev/platform-integration/windows)
- [Windows Developer Documentation](https://developer.microsoft.com/windows)

### macOS
- [Flutter macOS Desktop](https://docs.flutter.dev/platform-integration/macos)
- [Apple Developer Documentation](https://developer.apple.com/documentation)
- [macOS Code Signing](https://developer.apple.com/support/code-signing/)
- [Notarization for macOS](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

### Linux
- [Flutter Linux Desktop](https://docs.flutter.dev/platform-integration/linux)
- [Freedesktop.org Standards](https://standards.freedesktop.org/)
- [AppImage Documentation](https://docs.appimage.org/)
- [Flatpak Documentation](https://docs.flatpak.org/)

---

## Troubleshooting

### Common Issues

#### Build Failures

**Flutter Doctor Issues:**
```bash
flutter doctor -v
# Follow recommendations for missing dependencies
```

**CMake Errors (Windows/Linux):**
```bash
# Verify CMake is installed and in PATH
cmake --version
```

**Xcode Errors (macOS):**
```bash
# Accept Xcode license
sudo xcodebuild -license
# Install command line tools
xcode-select --install
```

#### Runtime Issues

**bitsdojo_window Not Working:**
- Ensure package is in pubspec.yaml
- Run `flutter pub get`
- Verify platform is Windows, macOS, or Linux (not web)

**File Access Denied (macOS):**
- Check entitlements file
- Ensure sandbox permissions are adequate
- Consider disabling sandbox for development

**Server Connection Issues:**
- Verify server is running: `dart bin/main.dart` in server directory
- Check firewall settings
- Verify server URL in config

#### Performance Issues

**Slow Launch:**
- Profile the app: `flutter run --profile`
- Check for blocking operations in main()
- Verify database connection is efficient

**High Memory Usage:**
- Run Flutter DevTools memory profiler
- Check for memory leaks in long-running operations
- Verify proper disposal of resources

---

## Contributing

When adding new features, ensure:

1. Platform-specific code is properly guarded
2. All platforms are tested
3. Documentation is updated
4. Platform limitations are noted

### Platform Detection Pattern

```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void platformSpecificOperation() {
  if (kIsWeb) {
    // Web-specific code
  } else if (Platform.isWindows) {
    // Windows-specific code
  } else if (Platform.isMacOS) {
    // macOS-specific code
  } else if (Platform.isLinux) {
    // Linux-specific code
  } else {
    // Default or unsupported
  }
}
```

---

## Appendix

### File Structure Reference

```
semantic_butler/
├── semantic_butler_flutter/          # Flutter desktop app
│   ├── lib/
│   │   ├── main.dart                 # Platform detection & window setup
│   │   ├── screens/                  # UI screens
│   │   └── widgets/                  # Reusable widgets
│   ├── windows/                      # Windows platform files
│   │   └── runner/CMakeLists.txt     # Windows build config
│   ├── macos/                        # macOS platform files
│   │   └── Runner/
│   │       ├── Info.plist            # App configuration
│   │       ├── DebugProfile.entitlements
│   │       └── Release.entitlements
│   └── linux/                        # Linux platform files
│       └── runner/CMakeLists.txt     # Linux build config
├── semantic_butler_server/           # Serverpod backend
│   ├── bin/main.dart                 # Server entry point
│   ├── docker-compose.yaml           # Docker deployment
│   └── pubspec.yaml                  # Server dependencies
└── semantic_butler_client/           # Generated client
    └── lib/src/protocol/             # Protocol definitions
```

### Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | TBD | Initial release with Windows, macOS, Linux support |
