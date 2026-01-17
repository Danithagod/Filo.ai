import 'package:test/test.dart';
import 'package:semantic_butler_server/src/services/rate_limit_service.dart';

void main() {
  group('RateLimitService', () {
    late RateLimitService service;

    setUp(() {
      // Use a fresh instance for each test
      service = RateLimitService.instance;
      service.clearAll();
    });

    tearDown(() {
      service.clearAll();
    });

    group('checkAndConsume', () {
      test('allows requests within limit', () {
        const clientId = 'test-client';
        const endpoint = 'test-endpoint';
        const limit = 5;

        // All 5 requests should be allowed
        for (var i = 0; i < limit; i++) {
          expect(
            service.checkAndConsume(clientId, endpoint, limit: limit),
            isTrue,
            reason: 'Request $i should be allowed',
          );
        }
      });

      test('blocks requests exceeding limit', () {
        const clientId = 'test-client';
        const endpoint = 'test-endpoint';
        const limit = 3;

        // Consume all tokens
        for (var i = 0; i < limit; i++) {
          service.checkAndConsume(clientId, endpoint, limit: limit);
        }

        // Next request should be blocked
        expect(
          service.checkAndConsume(clientId, endpoint, limit: limit),
          isFalse,
        );
      });

      test('isolates different clients', () {
        const endpoint = 'test-endpoint';
        const limit = 2;

        // Client A uses all tokens
        service.checkAndConsume('client-a', endpoint, limit: limit);
        service.checkAndConsume('client-a', endpoint, limit: limit);

        // Client B should still have tokens
        expect(
          service.checkAndConsume('client-b', endpoint, limit: limit),
          isTrue,
        );

        // Client A should be blocked
        expect(
          service.checkAndConsume('client-a', endpoint, limit: limit),
          isFalse,
        );
      });

      test('isolates different endpoints', () {
        const clientId = 'test-client';
        const limit = 2;

        // Use all tokens on endpoint A
        service.checkAndConsume(clientId, 'endpoint-a', limit: limit);
        service.checkAndConsume(clientId, 'endpoint-a', limit: limit);

        // Endpoint B should still have tokens
        expect(
          service.checkAndConsume(clientId, 'endpoint-b', limit: limit),
          isTrue,
        );

        // Endpoint A should be blocked
        expect(
          service.checkAndConsume(clientId, 'endpoint-a', limit: limit),
          isFalse,
        );
      });
    });

    group('getRemainingTokens', () {
      test('returns default for unknown client', () {
        expect(
          service.getRemainingTokens('unknown', 'endpoint'),
          equals(RateLimitService.defaultTokensPerMinute),
        );
      });

      test('decrements with consumption', () {
        const clientId = 'test-client';
        const endpoint = 'test-endpoint';
        const limit = 10;

        service.checkAndConsume(clientId, endpoint, limit: limit);
        service.checkAndConsume(clientId, endpoint, limit: limit);
        service.checkAndConsume(clientId, endpoint, limit: limit);

        expect(
          service.getRemainingTokens(clientId, endpoint),
          equals(7),
        );
      });
    });

    group('requireRateLimit', () {
      test('does not throw when within limit', () {
        const clientId = 'test-client';
        const endpoint = 'test-endpoint';

        // Should not throw
        service.requireRateLimit(clientId, endpoint);
      });

      test('throws RateLimitException when exceeded', () {
        const clientId = 'test-client';
        const endpoint = 'test-endpoint';
        const limit = 1;

        // Use the only token
        service.checkAndConsume(clientId, endpoint, limit: limit);

        // Should throw
        expect(
          () => service.requireRateLimit(clientId, endpoint, limit: limit),
          throwsA(isA<RateLimitException>()),
        );
      });
    });

    group('clearClient', () {
      test('clears only specified client', () {
        const endpoint = 'test-endpoint';
        const limit = 2;

        // Both clients use tokens
        service.checkAndConsume('client-a', endpoint, limit: limit);
        service.checkAndConsume('client-b', endpoint, limit: limit);

        // Clear client A
        service.clearClient('client-a');

        // Client A should have full tokens again
        expect(
          service.getRemainingTokens('client-a', endpoint),
          equals(RateLimitService.defaultTokensPerMinute),
        );

        // Client B should still have reduced tokens
        expect(
          service.getRemainingTokens('client-b', endpoint),
          equals(1),
        );
      });
    });
  });

  group('RateLimitException', () {
    test('toString includes message', () {
      final exception = RateLimitException('Test error');
      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('RateLimitException'));
    });
  });
}
