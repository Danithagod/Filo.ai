@echo off
REM Run all indexing logic tests with coverage

echo ==========================================
echo Running Indexing Logic Tests
echo ==========================================
echo.

REM Change to server directory
cd semantic_butler_server

REM Install dependencies if needed
echo Installing dependencies...
call dart pub get

REM Generate mocks if needed
echo Generating mocks...
call dart run build_runner build --delete-conflicting-outputs --build-filter=mockito

echo.

REM Run tests
echo Running tests...
echo.

REM Run all unit tests
call dart test test/unit/file_watcher_service_test.dart -v
set WATCHER_RESULT=%ERRORLEVEL%

call dart test test/unit/indexing_transaction_test.dart -v
set TRANSACTION_RESULT=%ERRORLEVEL%

call dart test test/unit/file_extraction_service_test.dart -v
set EXTRACTION_RESULT=%ERRORLEVEL%

call dart test/unit/vector_search_test.dart -v
set SEARCH_RESULT=%ERRORLEVEL%

echo.
echo ==========================================
echo Test Results
echo ==========================================

if %WATCHER_RESULT% EQU 0 (
  echo ✅ FileWatcherService tests: PASSED
) else (
  echo ❌ FileWatcherService tests: FAILED
)

if %TRANSACTION_RESULT% EQU 0 (
  echo ✅ IndexingTransaction tests: PASSED
) else (
  echo ❌ IndexingTransaction tests: FAILED
)

if %EXTRACTION_RESULT% EQU 0 (
  echo ✅ FileExtractionService tests: PASSED
) else (
  echo ❌ FileExtractionService tests: FAILED
)

if %SEARCH_RESULT% EQU 0 (
  echo ✅ VectorSearch tests: PASSED
) else (
  echo ❌ VectorSearch tests: FAILED
)

echo.

REM Check if all tests passed
if %WATCHER_RESULT% EQU 0 if %TRANSACTION_RESULT% EQU 0 if %EXTRACTION_RESULT% EQU 0 if %SEARCH_RESULT% EQU 0 (
  echo 🎉 All tests PASSED!
  exit /b 0
) else (
  echo ⚠️  Some tests FAILED
  exit /b 1
)
