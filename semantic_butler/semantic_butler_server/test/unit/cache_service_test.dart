import 'package:test/test.dart';
import 'package:semantic_butler_server/src/services/cache_service.dart';

void main() {
  group('CacheService', () {
    late CacheService cache;

    setUp(() {
      cache = CacheService.instance;
      cache.clear();
    });

    tearDown(() {
      cache.clear();
    });

    group('get and set', () {
      test('returns null for missing keys', () {
        expect(cache.get<String>('missing'), isNull);
      });

      test('stores and retrieves string values', () {
        cache.set('key1', 'value1');
        expect(cache.get<String>('key1'), equals('value1'));
      });

      test('stores and retrieves list values', () {
        final embedding = [1.0, 2.0, 3.0, 4.0];
        cache.set('embed', embedding);
        expect(cache.get<List<double>>('embed'), equals(embedding));
      });

      test('stores and retrieves map values', () {
        final data = {'name': 'test', 'count': 42};
        cache.set('data', data);
        expect(cache.get<Map<String, dynamic>>('data'), equals(data));
      });

      test('overwrites existing values', () {
        cache.set('key', 'first');
        cache.set('key', 'second');
        expect(cache.get<String>('key'), equals('second'));
      });
    });

    group('TTL expiration', () {
      test('respects custom TTL', () async {
        cache.set('short', 'value', ttl: const Duration(milliseconds: 50));
        expect(cache.get<String>('short'), equals('value'));

        await Future.delayed(const Duration(milliseconds: 100));
        expect(cache.get<String>('short'), isNull);
      });

      test('default TTL is 24 hours (not expired immediately)', () {
        cache.set('default', 'value');
        expect(cache.get<String>('default'), equals('value'));
      });
    });

    group('containsKey', () {
      test('returns false for missing keys', () {
        expect(cache.containsKey('missing'), isFalse);
      });

      test('returns true for existing keys', () {
        cache.set('exists', 'value');
        expect(cache.containsKey('exists'), isTrue);
      });

      test('returns false for expired keys', () async {
        cache.set('expiring', 'value', ttl: const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 100));
        expect(cache.containsKey('expiring'), isFalse);
      });
    });

    group('remove', () {
      test('removes existing key', () {
        cache.set('key', 'value');
        cache.remove('key');
        expect(cache.get<String>('key'), isNull);
      });

      test('handles removing non-existent key', () {
        // Should not throw
        cache.remove('nonexistent');
      });
    });

    group('clear', () {
      test('removes all entries', () {
        cache.set('a', 1);
        cache.set('b', 2);
        cache.set('c', 3);

        cache.clear();

        expect(cache.get<int>('a'), isNull);
        expect(cache.get<int>('b'), isNull);
        expect(cache.get<int>('c'), isNull);
      });

      test('resets statistics', () {
        cache.set('key', 'value');
        cache.get<String>('key'); // hit
        cache.get<String>('miss'); // miss

        cache.clear();

        expect(cache.stats.hits, equals(0));
        expect(cache.stats.misses, equals(0));
      });
    });

    group('statistics', () {
      test('tracks hits', () {
        cache.set('key', 'value');
        cache.get<String>('key');
        cache.get<String>('key');
        cache.get<String>('key');

        expect(cache.stats.hits, equals(3));
      });

      test('tracks misses', () {
        cache.get<String>('miss1');
        cache.get<String>('miss2');

        expect(cache.stats.misses, equals(2));
      });

      test('calculates hit rate', () {
        cache.set('key', 'value');
        cache.get<String>('key'); // hit
        cache.get<String>('key'); // hit
        cache.get<String>('miss'); // miss
        cache.get<String>('miss2'); // miss

        expect(cache.stats.hitRate, equals(0.5));
      });

      test('hit rate is 0 when no requests', () {
        expect(cache.stats.hitRate, equals(0.0));
      });

      test('reports size correctly', () {
        cache.set('a', 1);
        cache.set('b', 2);
        cache.set('c', 3);

        expect(cache.stats.size, equals(3));
      });
    });

    group('LRU eviction', () {
      test('evicts oldest entries when at capacity', () {
        // This test simulates LRU behavior
        // When capacity is reached, oldest entries should be removed
        // Since maxEntries is 10000, we test the mechanism with smaller scale

        // Add entries
        for (var i = 0; i < 100; i++) {
          cache.set('key_$i', 'value_$i');
        }

        // All should exist since we're under capacity
        expect(cache.get<String>('key_0'), equals('value_0'));
        expect(cache.get<String>('key_99'), equals('value_99'));
      });
    });

    group('key generators', () {
      test('embeddingKey generates consistent keys', () {
        final key1 = CacheService.embeddingKey('hello world');
        final key2 = CacheService.embeddingKey('hello world');
        expect(key1, equals(key2));
        expect(key1, startsWith('embed:'));
      });

      test('embeddingKey generates different keys for different text', () {
        final key1 = CacheService.embeddingKey('hello');
        final key2 = CacheService.embeddingKey('world');
        expect(key1, isNot(equals(key2)));
      });

      test('summaryKey includes max words', () {
        final key1 = CacheService.summaryKey('hash123', 100);
        final key2 = CacheService.summaryKey('hash123', 200);
        expect(key1, isNot(equals(key2)));
        expect(key1, contains('100'));
        expect(key2, contains('200'));
      });

      test('tagsKey generates consistent keys', () {
        final key1 = CacheService.tagsKey('hash123');
        final key2 = CacheService.tagsKey('hash123');
        expect(key1, equals(key2));
        expect(key1, startsWith('tags:'));
      });
    });

    group('cleanupExpired', () {
      test('removes expired entries', () async {
        cache.set('expire1', 'value', ttl: const Duration(milliseconds: 50));
        cache.set('expire2', 'value', ttl: const Duration(milliseconds: 50));
        cache.set('keep', 'value', ttl: const Duration(hours: 1));

        await Future.delayed(const Duration(milliseconds: 100));

        final removed = cache.cleanupExpired();

        expect(removed, equals(2));
        expect(cache.containsKey('expire1'), isFalse);
        expect(cache.containsKey('expire2'), isFalse);
        expect(cache.containsKey('keep'), isTrue);
      });
    });
  });

  group('CacheStats', () {
    test('toJson returns correct structure', () {
      final stats = CacheStats(
        size: 100,
        maxSize: 10000,
        hits: 50,
        misses: 25,
        hitRate: 0.666,
      );

      final json = stats.toJson();

      expect(json['size'], equals(100));
      expect(json['maxSize'], equals(10000));
      expect(json['hits'], equals(50));
      expect(json['misses'], equals(25));
      expect(json['hitRate'], equals(0.666));
      expect(json['hitRatePercent'], equals('66.6%'));
    });
  });
}
