---
description: Run tests with code coverage for the semantic butler server
---

# Run Tests with Code Coverage

This workflow explains how to run tests with code coverage reporting.

## Prerequisites

Activate the coverage package globally:
```bash
dart pub global activate coverage
```

## Steps

// turbo-all

1. Navigate to the server directory:
```bash
cd semantic_butler/semantic_butler_server
```

2. Get dependencies:
```bash
dart pub get
```

3. Run tests:
```bash
dart test test/unit/
```

4. Run tests with coverage collection:
```bash
dart test --coverage=coverage test/unit/
```

5. Format coverage to LCOV:
```bash
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

6. Generate HTML report (requires genhtml from lcov):
```bash
genhtml coverage/lcov.info -o coverage/html
```

## Quick Test Command

Run all unit tests with verbose output:
```bash
dart test test/unit/ --reporter=expanded
```

## Test Statistics

Current test count: 88 tests across 5 test files:
- validation_test.dart (22 tests)
- rate_limit_test.dart (9 tests)
- cache_service_test.dart (37 tests)
- metrics_service_test.dart (33 tests)
- auth_service_test.dart (4 tests)
