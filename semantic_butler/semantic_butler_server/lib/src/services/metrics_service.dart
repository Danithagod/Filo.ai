import 'package:serverpod/serverpod.dart';

/// Metrics service for performance monitoring
///
/// Records custom metrics for search latency, indexing speed,
/// cache performance, and error rates.
class MetricsService {
  /// Singleton instance
  static final MetricsService instance = MetricsService._();

  MetricsService._();

  /// Metric storage
  final Map<String, _MetricData> _metrics = {};

  /// Record a latency measurement
  void recordLatency(String name, Duration duration) {
    final data = _metrics.putIfAbsent(name, () => _MetricData());
    data.addValue(duration.inMilliseconds.toDouble());
  }

  /// Record a counter increment
  void incrementCounter(String name, {int amount = 1}) {
    final data = _metrics.putIfAbsent(name, () => _MetricData());
    data.incrementCount(amount);
  }

  /// Record a gauge value (current state)
  void setGauge(String name, double value) {
    final data = _metrics.putIfAbsent(name, () => _MetricData());
    data.setGauge(value);
  }

  /// Get metric summary for a specific metric
  MetricSummary? getMetric(String name) {
    final data = _metrics[name];
    if (data == null) return null;
    return data.getSummary(name);
  }

  /// Get all metric summaries
  Map<String, MetricSummary> getAllMetrics() {
    return _metrics.map((key, value) => MapEntry(key, value.getSummary(key)));
  }

  /// Log metrics to session (for debugging)
  void logMetrics(Session session, {LogLevel level = LogLevel.info}) {
    final all = getAllMetrics();
    for (final entry in all.entries) {
      session.log(
        'Metric [${entry.key}]: ${entry.value}',
        level: level,
      );
    }
  }

  /// Reset all metrics
  void reset() {
    _metrics.clear();
  }

  // ============================================================
  // Convenience methods for common metrics
  // ============================================================

  /// Record search latency
  void recordSearchLatency(Duration duration) {
    recordLatency('search_latency_ms', duration);
  }

  /// Record indexing latency per file
  void recordIndexingLatency(Duration duration) {
    recordLatency('indexing_latency_ms', duration);
  }

  /// Record embedding generation time
  void recordEmbeddingLatency(Duration duration) {
    recordLatency('embedding_latency_ms', duration);
  }

  /// Increment search count
  void incrementSearchCount() {
    incrementCounter('search_count');
  }

  /// Increment indexed file count
  void incrementIndexedFiles({int count = 1}) {
    incrementCounter('indexed_files', amount: count);
  }

  /// Increment failed file count
  void incrementFailedFiles({int count = 1}) {
    incrementCounter('failed_files', amount: count);
  }

  /// Increment cache hit count
  void incrementCacheHit() {
    incrementCounter('cache_hits');
  }

  /// Increment cache miss count
  void incrementCacheMiss() {
    incrementCounter('cache_misses');
  }

  /// Set active indexing jobs gauge
  void setActiveJobs(int count) {
    setGauge('active_indexing_jobs', count.toDouble());
  }

  /// Set indexed documents gauge
  void setIndexedDocuments(int count) {
    setGauge('indexed_documents', count.toDouble());
  }
}

class _MetricData {
  final List<double> _values = [];
  int _count = 0;
  double? _gauge;
  DateTime _lastUpdate = DateTime.now();

  void addValue(double value) {
    _values.add(value);
    // Keep only last 1000 values for percentile calculations
    if (_values.length > 1000) {
      _values.removeAt(0);
    }
    _lastUpdate = DateTime.now();
  }

  void incrementCount(int amount) {
    _count += amount;
    _lastUpdate = DateTime.now();
  }

  void setGauge(double value) {
    _gauge = value;
    _lastUpdate = DateTime.now();
  }

  MetricSummary getSummary(String name) {
    double? avg;
    double? p50;
    double? p95;
    double? p99;
    double? min;
    double? max;

    if (_values.isNotEmpty) {
      final sorted = List<double>.from(_values)..sort();
      avg = sorted.reduce((a, b) => a + b) / sorted.length;
      min = sorted.first;
      max = sorted.last;
      p50 = _percentile(sorted, 0.50);
      p95 = _percentile(sorted, 0.95);
      p99 = _percentile(sorted, 0.99);
    }

    return MetricSummary(
      name: name,
      count: _count,
      gauge: _gauge,
      avg: avg,
      min: min,
      max: max,
      p50: p50,
      p95: p95,
      p99: p99,
      sampleCount: _values.length,
      lastUpdate: _lastUpdate,
    );
  }

  double _percentile(List<double> sorted, double p) {
    final index = (p * (sorted.length - 1)).round();
    return sorted[index];
  }
}

/// Summary of a metric
class MetricSummary {
  final String name;
  final int count;
  final double? gauge;
  final double? avg;
  final double? min;
  final double? max;
  final double? p50;
  final double? p95;
  final double? p99;
  final int sampleCount;
  final DateTime lastUpdate;

  MetricSummary({
    required this.name,
    required this.count,
    this.gauge,
    this.avg,
    this.min,
    this.max,
    this.p50,
    this.p95,
    this.p99,
    required this.sampleCount,
    required this.lastUpdate,
  });

  @override
  String toString() {
    if (gauge != null) {
      return 'gauge=$gauge';
    }
    if (sampleCount > 0) {
      return 'count=$count, avg=${avg?.toStringAsFixed(1)}ms, '
          'p50=${p50?.toStringAsFixed(1)}ms, p95=${p95?.toStringAsFixed(1)}ms';
    }
    return 'count=$count';
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'count': count,
    if (gauge != null) 'gauge': gauge,
    if (avg != null) 'avg_ms': avg,
    if (min != null) 'min_ms': min,
    if (max != null) 'max_ms': max,
    if (p50 != null) 'p50_ms': p50,
    if (p95 != null) 'p95_ms': p95,
    if (p99 != null) 'p99_ms': p99,
    'sample_count': sampleCount,
    'last_update': lastUpdate.toIso8601String(),
  };
}
