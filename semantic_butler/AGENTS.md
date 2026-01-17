# Commands
- Server: `cd semantic_butler_server && dart run bin/main.dart --apply-migrations`
- Flutter: `cd semantic_butler_flutter && flutter run -d windows`
- Single test: `cd semantic_butler_server && dart test test/unit/auth_service_test.dart --name "test_name"`
- All tests: `cd semantic_butler_server && dart test`
- Analyze: `cd semantic_butler_server && dart analyze --fatal-infos`
- Format: `dart format --set-exit-if-changed .`

# Code Style
- Dart 3.8.0+, Flutter 3.32.0+
- Imports: `dart:` → `package:` → relative paths
- Use AppLogger (not print): `AppLogger.info/info/debug/error()` with optional `tag` param
- Error handling: Custom exceptions extending Exception with toString()
- State: flutter_riverpod for Flutter, Serverpod patterns for server
- Type annotations required on public APIs, inferred where obvious
- Trailing commas: preserve
- Linting: flutter_lints (Flutter), lints/recommended (server)
- Generated code excluded from analysis (lib/src/generated/**, lib/src/protocol/**)
- Test structure: group() → test() using package:test
- API calls via Serverpod Client with 120s timeout for AI operations
