# Indexing Logic Tests

This directory contains comprehensive unit tests for the indexing logic improvements identified in `INDEXING_LOGIC_ANALYSIS.md`.

## Test Files

### 1. `file_watcher_service_test.dart`
Tests for the file watching service that monitors file system changes.

**Coverage:**
- Event debouncing (rapid file changes)
- File move detection (ADD after REMOVE)
- Ignore pattern matching (extensions, directories, filenames)
- Queue management (LRU eviction, size limits)
- File size filtering (50MB limit)
- Watcher health monitoring and auto-restart
- Timer cleanup on disposal

**Test Groups:**
- `Event Debouncing`: Tests that rapid changes are batched
- `File Move Detection`: Tests move detection logic
- `Ignore Patterns`: Tests glob pattern matching
- `Queue Management`: Tests LRU eviction and capacity limits
- `File Size Filtering`: Tests size limit enforcement
- `Watcher Health`: Tests health status and restart logic
- `Restore Watchers`: Tests database-backed watcher restoration
- `Timer Cleanup`: Tests proper cleanup of debounce timers

### 2. `indexing_transaction_test.dart`
Tests for transactional indexing to ensure atomicity and data consistency.

**Coverage:**
- Transaction atomicity (all-or-nothing semantics)
- Rollback on embedding failure
- Deduplication via content hash
- Duplicate path insert handling
- Chunked embeddings for long documents
- Error handling and failure recording
- Cache consistency (SHA-256 hashing)
- Batch processing performance

**Test Groups:**
- `Atomicity`: Tests transaction rollbacks and commits
- `Deduplication`: Tests content hash-based skipping
- `Chunked Embeddings`: Tests chunking logic for long documents
- `Error Handling`: Tests failure scenarios and error recording
- `Cache Consistency`: Tests SHA-256 hashing consistency
- `Performance`: Tests batch processing and parallel operations

### 3. `file_extraction_service_test.dart`
Tests for file extraction and document classification.

**Coverage:**
- Supported file format detection
- Document classification (code, document, config, data)
- MIME type detection
- Word counting
- Ignore pattern matching
- Content hashing (SHA-256)
- File size limits
- Error handling for missing files

**Test Groups:**
- `Supported Formats`: Tests file extension recognition
- `Document Classification`: Tests category assignment
- `MIME Type Detection`: Tests MIME type mapping
- `Word Counting`: Tests word count logic
- `Ignore Pattern Matching`: Tests glob pattern matching
- `Directory Scanning`: Tests recursive directory scanning
- `Content Hashing`: Tests hash consistency
- `File Size Limits`: Tests size limit enforcement
- `Error Handling`: Tests exception handling

### 4. `vector_search_test.dart`
Tests for vector similarity search and pgvector integration.

**Coverage:**
- Query embedding generation
- Similarity calculation (cosine similarity)
- pgvector query construction
- Fallback to Dart-based search
- Result ranking and filtering
- Performance (latency, efficiency)
- Error handling (malformed embeddings, no matches)
- Hybrid search (keyword + vector)

**Test Groups:**
- `Query Processing`: Tests query validation and embedding generation
- `Similarity Calculation`: Tests cosine similarity logic
- `pgvector Integration`: Tests pgvector query construction
- `Result Ranking`: Tests sorting and filtering
- `Performance`: Tests query latency and efficiency
- `Error Handling`: Tests error scenarios
- `Hybrid Search`: Tests combined vector and keyword search

## Running Tests

### Prerequisites

The tests require the following dependencies:

```yaml
dependencies:
  test: ^1.25.5
  mockito: ^5.4.0
  serverpod_test: 3.1.0
```

### Install Dependencies

```bash
cd semantic_butler_server
dart pub get
```

### Generate Mocks

If you see `@GenerateMocks` annotations, you need to generate mocks:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run All Tests

```bash
# Run all unit tests
dart test test/unit/

# Run with coverage
dart test test/unit/ --coverage

# Generate coverage report
dart pub global activate coverage
dart pub global run coverage:format_coverage --lcov --report-on=lib --packages=.packages --in=test/unit
```

### Run Specific Test Files

```bash
# Run file watcher tests
dart test test/unit/file_watcher_service_test.dart

# Run indexing transaction tests
dart test test/unit/indexing_transaction_test.dart

# Run file extraction tests
dart test test/unit/file_extraction_service_test.dart

# Run vector search tests
dart test test/unit/vector_search_test.dart
```

### Run Specific Test Groups

```bash
# Run only debouncing tests
dart test test/unit/file_watcher_service_test.dart --name "Event Debouncing"

# Run only transaction atomicity tests
dart test test/unit/indexing_transaction_test.dart --name "Atomicity"

# Run only similarity calculation tests
dart test test/unit/vector_search_test.dart --name "Similarity Calculation"
```

### Run with Verbose Output

```bash
# Show detailed test output
dart test test/unit/ -v

# Show test names and descriptions
dart test test/unit/ --reporter expanded
```

## Test Coverage

Currently, the project has tests for:
- ✅ CacheService (242 lines, comprehensive)
- ✅ RateLimitService (178 lines, comprehensive)
- ✅ AuthService (unit tests exist)
- ✅ MetricsService (unit tests exist)
- ✅ Validation (unit tests exist)

New tests added:
- ✅ FileWatcherService (comprehensive, new)
- ✅ IndexingTransaction (comprehensive, new)
- ✅ FileExtractionService (comprehensive, new)
- ✅ VectorSearch (comprehensive, new)

**Target Coverage:** 80%+ for core indexing logic

## Test Design Principles

1. **Isolation**: Each test is independent and can run in any order
2. **Clarity**: Test names describe what is being tested
3. **Simplicity**: Tests focus on one aspect at a time
4. **Speed**: Tests run quickly (no unnecessary delays)
5. **Maintainability**: Tests use helper functions for common operations
6. **Realism**: Tests simulate real-world scenarios

## Known Limitations

1. **Mock Dependencies**: These tests use mocks for dependencies (Session, FileExtractionService, etc.). Integration tests with real database would be more comprehensive.

2. **File System**: File system operations are simulated. Real file system tests would require setup/teardown of test files.

3. **Network**: AI API calls are mocked. Tests don't validate actual API behavior.

4. **Concurrency**: Some concurrent scenarios are tested, but true concurrency testing would require isolate pools or multiple processes.

## Integration Tests

For end-to-end testing, see:

- `test/integration/greeting_endpoint_test.dart` (example integration test)
- Run integration tests with: `dart test test/integration/`

## Continuous Integration

These tests are designed to run in CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run tests
  run: |
    cd semantic_butler_server
    dart pub get
    dart run build_runner build --delete-conflicting-outputs
    dart test test/unit/ --coverage

- name: Upload coverage
  run: |
    dart pub global activate coverage
    dart pub global run coverage:format_coverage --lcov --report-on=lib --packages=.packages --in=test/unit
```

## Debugging Failed Tests

If tests fail:

1. **Run with verbose output:**
   ```bash
   dart test test/unit/file_watcher_service_test.dart -v
   ```

2. **Run specific test:**
   ```bash
   dart test test/unit/file_watcher_service_test.dart --name "debounces rapid file changes"
   ```

3. **Check mock expectations:**
   - Verify mock interactions are correct
   - Check that all expected calls were made
   - Verify no unexpected calls were made

4. **Add debug prints:**
   ```dart
   test('example', () {
     print('Debug: Starting test');
     // ... test logic
     print('Debug: Test completed');
   });
   ```

## Future Enhancements

1. **Integration Tests**: Add end-to-end tests with real database
2. **Load Tests**: Add performance tests under high load
3. **Property-Based Tests**: Use dart_test_check for property testing
4. **Fuzz Testing**: Add fuzz testing for input validation
5. **Golden Tests**: Add golden file tests for output validation

## Contributing

When adding new tests:

1. Follow the existing test structure
2. Use descriptive test names (what, expected, scenario)
3. Test both success and failure cases
4. Keep tests isolated and independent
5. Add comments for complex test logic
6. Update this README with new test coverage

## References

- [Dart Test Documentation](https://dart.dev/guides/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [INDEXING_LOGIC_ANALYSIS.md](../../INDEXING_LOGIC_ANALYSIS.md) - Comprehensive analysis
- [AUTO_INDEXING_ANALYSIS.md](../../AUTO_INDEXING_ANALYSIS.md) - Known issues
