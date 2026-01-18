import 'package:serverpod/serverpod.dart';

/// Service for tracking AI API costs and managing budgets
///
/// Provides methods for:
/// - Recording costs per API call (embeddings, chat completions)
/// - Budget management with configurable limits
/// - Cost breakdown by feature (indexing, search, chat)
/// - Usage projections based on historical data
/// - Alert generation at threshold percentages
class AICostService {
  /// Record an AI API call cost
  static Future<void> recordCost(
    Session session, {
    required String feature,
    required String model,
    required int inputTokens,
    required int outputTokens,
    required double cost,
    Map<String, dynamic>? metadata,
  }) async {
    // final record = AICostRecord(
    //   feature: feature,
    //   model: model,
    //   inputTokens: inputTokens,
    //   outputTokens: outputTokens,
    //   totalTokens: inputTokens + outputTokens,
    //   cost: cost,
    //   metadataJson: metadata != null ? _encodeMetadata(metadata) : null,
    //   timestamp: DateTime.now(),
    // );

    // In production, this would insert into database
    // await AICostRecord.db.insertRow(session, record);
  }

  /// Get total costs within a date range
  static Future<CostSummary> getCostSummary(
    Session session, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    // In production, query from database
    // final records = await AICostRecord.db.find(
    //   session,
    //   where: (t) => t.timestamp >= start & t.timestamp <= end,
    // );

    // Mock data for now
    return CostSummary(
      totalCost: 0.0,
      totalTokens: 0,
      callCount: 0,
      startDate: start,
      endDate: end,
      byFeature: {},
      byModel: {},
    );
  }

  /// Get cost breakdown by feature
  static Future<Map<String, double>> getCostByFeature(
    Session session, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    // final end = endDate ?? DateTime.now();

    // In production, aggregate from database
    // final records = await AICostRecord.db.find(...);
    // return records.fold<Map<String, double>>({}, (map, record) {
    //   map[record.feature] = (map[record.feature] ?? 0.0) + record.cost;
    //   return map;
    // });

    return {};
  }

  /// Get cost breakdown by model
  static Future<Map<String, double>> getCostByModel(
    Session session, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    // final end = endDate ?? DateTime.now();

    // Similar aggregation logic for models
    return {};
  }

  /// Calculate projected costs based on historical usage
  static Future<CostProjection> getProjectedCosts(
    Session session, {
    int lookbackDays = 30,
    int forecastDays = 30,
  }) async {
    final start = DateTime.now().subtract(Duration(days: lookbackDays));
    final end = DateTime.now();

    // Get historical data
    final summary = await getCostSummary(
      session,
      startDate: start,
      endDate: end,
    );

    // Calculate daily average
    final dailyAverage = summary.totalCost / lookbackDays;

    // Project forward
    final projectedTotal = dailyAverage * forecastDays;

    return CostProjection(
      dailyAverage: dailyAverage,
      projectedCost: projectedTotal,
      forecastDays: forecastDays,
      basedOnDays: lookbackDays,
      timestamp: DateTime.now(),
    );
  }

  /// Check budget status and generate alerts
  static Future<BudgetStatus> checkBudget(
    Session session,
    double budgetLimit, {
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final summary = await getCostSummary(
      session,
      startDate: periodStart,
      endDate: periodEnd,
    );

    final percentUsed = (summary.totalCost / budgetLimit) * 100;
    final remaining = budgetLimit - summary.totalCost;

    // Generate alerts based on thresholds
    final alerts = <BudgetAlert>[];
    if (percentUsed >= 100) {
      alerts.add(
        BudgetAlert(
          level: AlertLevel.critical,
          message:
              'Budget exceeded by \$${(summary.totalCost - budgetLimit).toStringAsFixed(2)}',
          percentUsed: percentUsed,
          timestamp: DateTime.now(),
        ),
      );
    } else if (percentUsed >= 90) {
      alerts.add(
        BudgetAlert(
          level: AlertLevel.warning,
          message:
              'Budget 90% consumed (\$${remaining.toStringAsFixed(2)} remaining)',
          percentUsed: percentUsed,
          timestamp: DateTime.now(),
        ),
      );
    } else if (percentUsed >= 80) {
      alerts.add(
        BudgetAlert(
          level: AlertLevel.info,
          message:
              'Budget 80% consumed (\$${remaining.toStringAsFixed(2)} remaining)',
          percentUsed: percentUsed,
          timestamp: DateTime.now(),
        ),
      );
    }

    return BudgetStatus(
      budgetLimit: budgetLimit,
      currentSpend: summary.totalCost,
      remaining: remaining,
      percentUsed: percentUsed,
      alerts: alerts,
      periodStart: periodStart ?? summary.startDate,
      periodEnd: periodEnd ?? summary.endDate,
    );
  }

  /// Get cost trends over time (daily breakdown)
  static Future<List<DailyCost>> getDailyCosts(
    Session session, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // In production, aggregate costs by day
    // SELECT DATE(timestamp) as date, SUM(cost) as total_cost, SUM(total_tokens) as total_tokens
    // FROM ai_cost_record
    // WHERE timestamp BETWEEN startDate AND endDate
    // GROUP BY DATE(timestamp)
    // ORDER BY date ASC

    final dailyCosts = <DailyCost>[];
    final currentDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final finalDate = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(finalDate) ||
        currentDate.isAtSameMomentAs(finalDate)) {
      dailyCosts.add(
        DailyCost(
          date: DateTime(currentDate.year, currentDate.month, currentDate.day),
          cost: 0.0,
          tokens: 0,
          callCount: 0,
        ),
      );
      currentDate.add(const Duration(days: 1));
    }

    return dailyCosts;
  }

  /// Get most expensive operations
  static Future<List<AICostRecord>> getTopCostlyOperations(
    Session session, {
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // In production, query top N by cost
    // await AICostRecord.db.find(
    //   session,
    //   where: startDate != null && endDate != null
    //       ? (t) => t.timestamp >= startDate & t.timestamp <= endDate
    //       : null,
    //   orderBy: (t) => t.cost,
    //   orderDescending: true,
    //   limit: limit,
    // );

    return [];
  }

  /// Reset budget alerts (mark as acknowledged)
  static Future<void> acknowledgeAlerts(
    Session session, {
    DateTime? before,
  }) async {
    // Mark budget alerts as acknowledged in database
    // This prevents showing the same alert repeatedly
  }

  /// Helper to encode metadata as JSON string
  // static String _encodeMetadata(Map<String, dynamic> metadata) {
  //   // Use a simple JSON encoding
  //   return metadata.entries.map((e) => '"${e.key}":"${e.value}"').join(',');
  // }

  /// Calculate cost for a specific model and token count
  static double calculateCost({
    required String model,
    required int inputTokens,
    required int outputTokens,
  }) {
    // Pricing per 1M tokens (as of 2024)
    const pricing = {
      'text-embedding-3-small': {'input': 0.02, 'output': 0.0},
      'text-embedding-3-large': {'input': 0.13, 'output': 0.0},
      'gpt-4-turbo': {'input': 10.0, 'output': 30.0},
      'gpt-4': {'input': 30.0, 'output': 60.0},
      'gpt-3.5-turbo': {'input': 0.5, 'output': 1.5},
      'claude-3-opus': {'input': 15.0, 'output': 75.0},
      'claude-3-sonnet': {'input': 3.0, 'output': 15.0},
      'claude-3-haiku': {'input': 0.25, 'output': 1.25},
    };

    final modelPricing = pricing[model] ?? {'input': 1.0, 'output': 1.0};
    final inputCost = (inputTokens / 1000000) * (modelPricing['input'] ?? 0);
    final outputCost = (outputTokens / 1000000) * (modelPricing['output'] ?? 0);

    return inputCost + outputCost;
  }
}

/// AI cost record model (in-memory until database model is created)
class AICostRecord {
  final int? id;
  final String feature;
  final String model;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final double cost;
  final String? metadataJson;
  final DateTime timestamp;

  AICostRecord({
    this.id,
    required this.feature,
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.cost,
    this.metadataJson,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'feature': feature,
    'model': model,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'totalTokens': totalTokens,
    'cost': cost,
    'metadata': metadataJson,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Cost summary for a time period
class CostSummary {
  final double totalCost;
  final int totalTokens;
  final int callCount;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, double> byFeature;
  final Map<String, double> byModel;

  CostSummary({
    required this.totalCost,
    required this.totalTokens,
    required this.callCount,
    required this.startDate,
    required this.endDate,
    required this.byFeature,
    required this.byModel,
  });

  Map<String, dynamic> toJson() => {
    'totalCost': totalCost,
    'totalTokens': totalTokens,
    'callCount': callCount,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'byFeature': byFeature,
    'byModel': byModel,
  };
}

/// Cost projection based on historical usage
class CostProjection {
  final double dailyAverage;
  final double projectedCost;
  final int forecastDays;
  final int basedOnDays;
  final DateTime timestamp;

  CostProjection({
    required this.dailyAverage,
    required this.projectedCost,
    required this.forecastDays,
    required this.basedOnDays,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'dailyAverage': dailyAverage,
    'projectedCost': projectedCost,
    'forecastDays': forecastDays,
    'basedOnDays': basedOnDays,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Budget status with alerts
class BudgetStatus {
  final double budgetLimit;
  final double currentSpend;
  final double remaining;
  final double percentUsed;
  final List<BudgetAlert> alerts;
  final DateTime periodStart;
  final DateTime periodEnd;

  BudgetStatus({
    required this.budgetLimit,
    required this.currentSpend,
    required this.remaining,
    required this.percentUsed,
    required this.alerts,
    required this.periodStart,
    required this.periodEnd,
  });

  bool get hasAlerts => alerts.isNotEmpty;
  bool get isCritical => alerts.any((a) => a.level == AlertLevel.critical);

  Map<String, dynamic> toJson() => {
    'budgetLimit': budgetLimit,
    'currentSpend': currentSpend,
    'remaining': remaining,
    'percentUsed': percentUsed,
    'alerts': alerts.map((a) => a.toJson()).toList(),
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
  };
}

/// Budget alert with severity level
class BudgetAlert {
  final AlertLevel level;
  final String message;
  final double percentUsed;
  final DateTime timestamp;

  BudgetAlert({
    required this.level,
    required this.message,
    required this.percentUsed,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'level': level.toString().split('.').last,
    'message': message,
    'percentUsed': percentUsed,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Alert severity levels
enum AlertLevel {
  info,
  warning,
  critical,
}

/// Daily cost breakdown
class DailyCost {
  final DateTime date;
  final double cost;
  final int tokens;
  final int callCount;

  DailyCost({
    required this.date,
    required this.cost,
    required this.tokens,
    required this.callCount,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String().split('T').first,
    'cost': cost,
    'tokens': tokens,
    'callCount': callCount,
  };
}
