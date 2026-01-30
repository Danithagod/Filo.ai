@echo off
REM ========================================
REM Semantic Butler Backend Package Builder
REM ========================================
REM
REM This script creates a distributable ZIP package
REM containing the backend server for hackathon demos.
REM
REM ========================================

setlocal enabledelayedexpansion

echo.
echo ========================================
echo   Semantic Butler Package Builder
echo ========================================
echo.

REM Configuration
set "SOURCE_DIR=%~dp0"
set "DIST_DIR=%SOURCE_DIR%dist"
set "PACKAGE_NAME=semantic-butler-backend"
set "VERSION=v1.0.0-stable"
set "OUTPUT_DIR=%SOURCE_DIR%..\build\%PACKAGE_NAME%-%VERSION%"

REM Create output directory
echo Creating package directory...
if exist "%OUTPUT_DIR%" rmdir /s /q "%OUTPUT_DIR%"
mkdir "%OUTPUT_DIR%"

REM Copy core server files
echo Copying server files...
xcopy "%SOURCE_DIR%bin" "%OUTPUT_DIR%\bin" /E /I /Y >nul 2>&1
xcopy "%SOURCE_DIR%lib" "%OUTPUT_DIR%\lib" /E /I /Y >nul 2>&1
xcopy "%SOURCE_DIR%config" "%OUTPUT_DIR%\config" /E /I /Y >nul 2>&1
xcopy "%SOURCE_DIR%migrations" "%OUTPUT_DIR%\migrations" /E /I /Y >nul 2>&1
xcopy "%SOURCE_DIR%web" "%OUTPUT_DIR%\web" /E /I /Y >nul 2>&1

REM Copy required files
copy "%SOURCE_DIR%pubspec.yaml" "%OUTPUT_DIR%\" >nul 2>&1
copy "%SOURCE_DIR%pubspec.lock" "%OUTPUT_DIR%\" >nul 2>&1
copy "%SOURCE_DIR%analysis_options.yaml" "%OUTPUT_DIR%\" >nul 2>&1

REM Copy dist files (run-server.bat, README.html, .env.example)
copy "%DIST_DIR%\run-server.bat" "%OUTPUT_DIR%\run-server.bat" >nul 2>&1
copy "%DIST_DIR%\README.html" "%OUTPUT_DIR%\" >nul 2>&1
copy "%DIST_DIR%\.env.example" "%OUTPUT_DIR%\" >nul 2>&1

REM Copy current .env if it exists (convenience for demo)
if exist "%SOURCE_DIR%.env" (
    echo Copying .env to package...
    copy "%SOURCE_DIR%.env" "%OUTPUT_DIR%\" >nul 2>&1
)

REM Run pub get to resolve dependencies and create .dart_tool
echo Resolving dependencies...
pushd "%OUTPUT_DIR%"
call dart pub get >nul 2>&1
popd

REM Create version info file
echo Semantic Butler Backend Server > "%OUTPUT_DIR%\VERSION.txt"
echo Version: %VERSION% >> "%OUTPUT_DIR%\VERSION.txt"
echo Build Date: %date% %time% >> "%OUTPUT_DIR%\VERSION.txt"

echo.
echo ========================================
echo   Package Created Successfully!
echo ========================================
echo.
echo Location: %OUTPUT_DIR%
echo.
echo Next steps:
echo   1. Copy the entire folder to a ZIP file
echo   2. Name it: %PACKAGE_NAME%-%VERSION%.zip
echo   3. Upload to website/downloads/
echo.
echo ========================================
echo.

pause
