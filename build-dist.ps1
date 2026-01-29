# Filo Windows Distribution Build Script
# This script automates the process of building the Flutter app and creating the MSIX installer.

$ErrorActionPreference = "Stop"

$rootPath = Get-Location
$flutterPath = Join-Path $rootPath "semantic_butler\semantic_butler_flutter"
$websitePath = Join-Path $rootPath "website"

Write-Host "🚀 Starting Filo Windows Distribution Build..." -ForegroundColor Cyan

# 1. Prerequisite Checks
Write-Host "`n🔍 Checking prerequisites..." -ForegroundColor Yellow

if (!(Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter SDK not found in PATH. Please install Flutter and try again."
}

# 2. Prepare Flutter Application
Write-Host "`n📦 Preparing Flutter application..." -ForegroundColor Yellow
Set-Location $flutterPath
Write-Host "Running flutter pub get..."
flutter pub get

# 3. Build Windows Release
Write-Host "`n🏗️ Building Windows release..." -ForegroundColor Yellow
flutter build windows --release

# 4. Create MSIX Installer
Write-Host "`n🎁 Creating MSIX installer..." -ForegroundColor Yellow
# Run msix:create using dart run
dart run msix:create

$msixPath = Join-Path $flutterPath "build\windows\x64\runner\Release\semantic_butler_flutter.msix"

if (Test-Path $msixPath) {
    Write-Host "`n✅ MSIX Installer created successfully at: $msixPath" -ForegroundColor Green
    
    # 5. Distribute to Website (Optional)
    $destPath = Join-Path $websitePath "public\downloads\filo-windows.msix"
    $destDir = [System.IO.Path]::GetDirectoryName($destPath)
    
    if (!(Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    
    Write-Host "`n🚚 Copying installer to website downloads..." -ForegroundColor Yellow
    Copy-Item -Path $msixPath -Destination $destPath -Force
    Write-Host "✅ Installer copied to: $destPath" -ForegroundColor Green
} else {
    Write-Error "Failed to locate generated MSIX installer."
}

Set-Location $rootPath
Write-Host "`n🎉 Build and Distribution process complete!" -ForegroundColor Cyan
Write-Host "You can now commit the changes and the updated installer to the repository." -ForegroundColor Gray
