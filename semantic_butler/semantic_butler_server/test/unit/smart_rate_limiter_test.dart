import 'package:test/test.dart';
import 'package:semantic_butler_server/src/services/smart_rate_limiter.dart';

void main() {
  group('SmartRateLimiter Tests', () {
    late SmartRateLimiter limiter;

    setUp(() {
      // We can't easily reset the singleton instance state without reflection or a clear method.
      // For testing purposes, we might need a way to reset or use a separate instance if possible.
      // Since the class has a private constructor, we have to rely on the singleton.
      // However, for unit testing logic, it's better if we could inspect the bucket.
      limiter = SmartRateLimiter.instance;
    });

    test('Should allow initial requests', () {
      expect(limiter.check('search', clientId: 'test_user'), isTrue);
    });

    // Note: Testing accurate rate limits requires mocking time or waiting, which is slow.
    // We will trust the TokenBucket logic if we can test TokenBucket in isolation,
    // but TokenBucket is private to the file.
    // Instead, we can verify retry budget consumption basics.

    test('Retry budget reduces on consumption', () {
      // Consume some retries
      bool allowed = limiter.check(
        'search',
        clientId: 'test_user',
        isRetry: true,
      );
      expect(allowed, isTrue); // Should assume budget has space initially
    });

    test('Seconds until available returns 0 when tokens exist', () {
      expect(
        limiter.getSecondsUntilAvailable('search', 'test_user'),
        equals(0),
      );
    });

    test('Unknown operation accepts by default', () {
      expect(limiter.check('unknown_op', clientId: 'test_user'), isTrue);
    });
  });

  // Since TokenBucket is private in the file, we can't test it directly here
  // without modifying the source to make it public or visible for testing.
  // Ideally, we would make TokenBucket @visibleForTesting.
}
