#!/bin/bash

# Run all indexing logic tests with coverage

set -e

echo "=========================================="
echo "Running Indexing Logic Tests"
echo "=========================================="
echo ""

# Change to server directory
cd semantic_butler_server

# Install dependencies if needed
echo "Installing dependencies..."
dart pub get

# Generate mocks if needed
echo "Generating mocks..."
dart run build_runner build --delete-conflicting-outputs --build-filter=mockito

echo ""

# Run tests
echo "Running tests..."
echo ""

# Run all unit tests
dart test test/unit/file_watcher_service_test.dart -v
WATCHER_RESULT=$?

dart test test/unit/indexing_transaction_test.dart -v
TRANSACTION_RESULT=$?

dart test test/unit/file_extraction_service_test.dart -v
EXTRACTION_RESULT=$?

dart test test/unit/vector_search_test.dart -v
SEARCH_RESULT=$?

echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="

if [ $WATCHER_RESULT -eq 0 ]; then
  echo "✅ FileWatcherService tests: PASSED"
else
  echo "❌ FileWatcherService tests: FAILED"
fi

if [ $TRANSACTION_RESULT -eq 0 ]; then
  echo "✅ IndexingTransaction tests: PASSED"
else
  echo "❌ IndexingTransaction tests: FAILED"
fi

if [ $EXTRACTION_RESULT -eq 0 ]; then
  echo "✅ FileExtractionService tests: PASSED"
else
  echo "❌ FileExtractionService tests: PASSED"
fi

if [ $SEARCH_RESULT -eq 0 ]; then
  echo "✅ VectorSearch tests: PASSED"
else
  echo "❌ VectorSearch tests: FAILED"
fi

echo ""

# Check if all tests passed
if [ $WATCHER_RESULT -eq 0 ] && [ $TRANSACTION_RESULT -eq 0 ] && [ $EXTRACTION_RESULT -eq 0 ] && [ $SEARCH_RESULT -eq 0 ]; then
  echo "🎉 All tests PASSED!"
  exit 0
else
  echo "⚠️  Some tests FAILED"
  exit 1
fi
