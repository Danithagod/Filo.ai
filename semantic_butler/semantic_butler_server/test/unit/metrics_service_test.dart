import 'package:test/test.dart';
import 'package:semantic_butler_server/src/services/metrics_service.dart';

void main() {
  group('MetricsService', () {
    late MetricsService metrics;

    setUp(() {
      metrics = MetricsService.instance;
      metrics.reset();
    });

    tearDown(() {
      metrics.reset();
    });

    group('recordLatency', () {
      test('records latency values', () {
        metrics.recordLatency(
          'test_latency',
          const Duration(milliseconds: 100),
        );
        metrics.recordLatency(
          'test_latency',
          const Duration(milliseconds: 200),
        );
        metrics.recordLatency(
          'test_latency',
          const Duration(milliseconds: 300),
        );

        final summary = metrics.getMetric('test_latency');
        expect(summary, isNotNull);
        expect(summary!.sampleCount, equals(3));
        expect(summary.avg, equals(200.0));
      });

      test('calculates min and max', () {
        metrics.recordLatency('latency', const Duration(milliseconds: 50));
        metrics.recordLatency('latency', const Duration(milliseconds: 100));
        metrics.recordLatency('latency', const Duration(milliseconds: 150));

        final summary = metrics.getMetric('latency');
        expect(summary!.min, equals(50.0));
        expect(summary.max, equals(150.0));
      });

      test('calculates percentiles', () {
        // Add 100 values from 1-100
        for (var i = 1; i <= 100; i++) {
          metrics.recordLatency('perc', Duration(milliseconds: i));
        }

        final summary = metrics.getMetric('perc');
        expect(summary!.p50, closeTo(50.0, 1.0));
        expect(summary.p95, closeTo(95.0, 1.0));
        expect(summary.p99, closeTo(99.0, 1.0));
      });
    });

    group('incrementCounter', () {
      test('increments counter by 1', () {
        metrics.incrementCounter('requests');
        metrics.incrementCounter('requests');
        metrics.incrementCounter('requests');

        final summary = metrics.getMetric('requests');
        expect(summary!.count, equals(3));
      });

      test('increments by custom amount', () {
        metrics.incrementCounter('files', amount: 10);
        metrics.incrementCounter('files', amount: 5);

        final summary = metrics.getMetric('files');
        expect(summary!.count, equals(15));
      });
    });

    group('setGauge', () {
      test('sets gauge value', () {
        metrics.setGauge('active_connections', 42.0);

        final summary = metrics.getMetric('active_connections');
        expect(summary!.gauge, equals(42.0));
      });

      test('overwrites previous gauge value', () {
        metrics.setGauge('gauge', 10.0);
        metrics.setGauge('gauge', 20.0);

        final summary = metrics.getMetric('gauge');
        expect(summary!.gauge, equals(20.0));
      });
    });

    group('getMetric', () {
      test('returns null for unknown metric', () {
        expect(metrics.getMetric('unknown'), isNull);
      });

      test('returns summary for known metric', () {
        metrics.incrementCounter('known');
        expect(metrics.getMetric('known'), isNotNull);
      });
    });

    group('getAllMetrics', () {
      test('returns all metrics', () {
        metrics.incrementCounter('counter1');
        metrics.incrementCounter('counter2');
        metrics.setGauge('gauge1', 1.0);

        final all = metrics.getAllMetrics();
        expect(all.length, equals(3));
        expect(all.containsKey('counter1'), isTrue);
        expect(all.containsKey('counter2'), isTrue);
        expect(all.containsKey('gauge1'), isTrue);
      });

      test('returns empty map when no metrics', () {
        expect(metrics.getAllMetrics(), isEmpty);
      });
    });

    group('reset', () {
      test('clears all metrics', () {
        metrics.incrementCounter('counter');
        metrics.setGauge('gauge', 1.0);
        metrics.recordLatency('latency', const Duration(milliseconds: 100));

        metrics.reset();

        expect(metrics.getAllMetrics(), isEmpty);
      });
    });

    group('convenience methods', () {
      test('recordSearchLatency records correctly', () {
        metrics.recordSearchLatency(const Duration(milliseconds: 50));
        expect(metrics.getMetric('search_latency_ms'), isNotNull);
      });

      test('recordIndexingLatency records correctly', () {
        metrics.recordIndexingLatency(const Duration(milliseconds: 100));
        expect(metrics.getMetric('indexing_latency_ms'), isNotNull);
      });

      test('recordEmbeddingLatency records correctly', () {
        metrics.recordEmbeddingLatency(const Duration(milliseconds: 200));
        expect(metrics.getMetric('embedding_latency_ms'), isNotNull);
      });

      test('incrementSearchCount increments correctly', () {
        metrics.incrementSearchCount();
        metrics.incrementSearchCount();
        expect(metrics.getMetric('search_count')!.count, equals(2));
      });

      test('incrementIndexedFiles increments correctly', () {
        metrics.incrementIndexedFiles(count: 5);
        expect(metrics.getMetric('indexed_files')!.count, equals(5));
      });

      test('incrementFailedFiles increments correctly', () {
        metrics.incrementFailedFiles(count: 2);
        expect(metrics.getMetric('failed_files')!.count, equals(2));
      });

      test('incrementCacheHit increments correctly', () {
        metrics.incrementCacheHit();
        expect(metrics.getMetric('cache_hits')!.count, equals(1));
      });

      test('incrementCacheMiss increments correctly', () {
        metrics.incrementCacheMiss();
        expect(metrics.getMetric('cache_misses')!.count, equals(1));
      });

      test('setActiveJobs sets gauge correctly', () {
        metrics.setActiveJobs(3);
        expect(metrics.getMetric('active_indexing_jobs')!.gauge, equals(3.0));
      });

      test('setIndexedDocuments sets gauge correctly', () {
        metrics.setIndexedDocuments(1000);
        expect(metrics.getMetric('indexed_documents')!.gauge, equals(1000.0));
      });
    });
  });

  group('MetricSummary', () {
    test('toString for gauge', () {
      final summary = MetricSummary(
        name: 'test',
        count: 0,
        gauge: 42.0,
        sampleCount: 0,
        lastUpdate: DateTime.now(),
      );

      expect(summary.toString(), contains('gauge=42.0'));
    });

    test('toString for latency with samples', () {
      final summary = MetricSummary(
        name: 'test',
        count: 10,
        avg: 100.5,
        p50: 95.0,
        p95: 150.0,
        sampleCount: 10,
        lastUpdate: DateTime.now(),
      );

      expect(summary.toString(), contains('count=10'));
      expect(summary.toString(), contains('avg=100.5ms'));
      expect(summary.toString(), contains('p50=95.0ms'));
      expect(summary.toString(), contains('p95=150.0ms'));
    });

    test('toString for counter only', () {
      final summary = MetricSummary(
        name: 'test',
        count: 5,
        sampleCount: 0,
        lastUpdate: DateTime.now(),
      );

      expect(summary.toString(), equals('count=5'));
    });

    test('toJson includes all fields', () {
      final now = DateTime.now();
      final summary = MetricSummary(
        name: 'test_metric',
        count: 10,
        gauge: 5.0,
        avg: 100.0,
        min: 50.0,
        max: 150.0,
        p50: 100.0,
        p95: 140.0,
        p99: 148.0,
        sampleCount: 10,
        lastUpdate: now,
      );

      final json = summary.toJson();

      expect(json['name'], equals('test_metric'));
      expect(json['count'], equals(10));
      expect(json['gauge'], equals(5.0));
      expect(json['avg_ms'], equals(100.0));
      expect(json['min_ms'], equals(50.0));
      expect(json['max_ms'], equals(150.0));
      expect(json['p50_ms'], equals(100.0));
      expect(json['p95_ms'], equals(140.0));
      expect(json['p99_ms'], equals(148.0));
      expect(json['sample_count'], equals(10));
      expect(json['last_update'], equals(now.toIso8601String()));
    });

    test('toJson omits null fields', () {
      final summary = MetricSummary(
        name: 'test',
        count: 1,
        sampleCount: 0,
        lastUpdate: DateTime.now(),
      );

      final json = summary.toJson();

      expect(json.containsKey('gauge'), isFalse);
      expect(json.containsKey('avg_ms'), isFalse);
      expect(json.containsKey('min_ms'), isFalse);
    });
  });
}
