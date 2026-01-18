import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../main.dart';
import '../../utils/app_logger.dart';

/// Dashboard for tracking AI API costs and budget
class AICostDashboard extends StatefulWidget {
  const AICostDashboard({super.key});

  @override
  State<AICostDashboard> createState() => _AICostDashboardState();
}

class _AICostDashboardState extends State<AICostDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _costSummary;
  Map<String, dynamic>? _budgetStatus;
  Map<String, dynamic>? _projection;
  List<Map<String, dynamic>> _dailyCosts = [];

  // Budget settings
  double _budgetLimit = 50.0;
  int _lookbackDays = 30;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: _lookbackDays));

      // Load cost summary
      final summary = await client.butler.getAICostSummary(
        startDate: startDate,
        endDate: now,
      );

      // Load budget status
      final budget = await client.butler.checkBudget(
        budgetLimit: _budgetLimit,
        periodStart: startDate,
        periodEnd: now,
      );

      // Load projection
      final projection = await client.butler.getProjectedCosts(
        lookbackDays: _lookbackDays,
        forecastDays: 30,
      );

      // Load daily costs for chart
      final dailyCosts = await client.butler.getDailyCosts(
        startDate: startDate,
        endDate: now,
      );

      setState(() {
        _costSummary = summary;
        _budgetStatus = budget;
        _projection = projection;
        _dailyCosts = dailyCosts;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load cost dashboard: $e', tag: 'CostDashboard');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showBudgetSettingsDialog() async {
    final budgetController = TextEditingController(text: _budgetLimit.toString());
    final daysController = TextEditingController(text: _lookbackDays.toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.settings),
        title: const Text('Budget Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Budget (\$)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tracking Period (days)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _budgetLimit = double.tryParse(budgetController.text) ?? _budgetLimit;
        _lookbackDays = int.tryParse(daysController.text) ?? _lookbackDays;
      });
      await _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      child: SizedBox(
        width: 900,
        height: 700,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.analytics_outlined, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'AI Cost Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _showBudgetSettingsDialog,
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Settings'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Budget alerts
                          if (_budgetStatus?['hasAlerts'] == true)
                            _buildBudgetAlerts(),

                          const SizedBox(height: 16),

                          // Summary cards
                          Row(
                            children: [
                              Expanded(child: _buildCostCard()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildBudgetCard()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildProjectionCard()),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Cost trend chart
                          Text(
                            'Cost Trend',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildCostChart(),

                          const SizedBox(height: 24),

                          // Feature breakdown
                          Text(
                            'Cost by Feature',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureBreakdown(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetAlerts() {
    final alerts = _budgetStatus?['alerts'] as List? ?? [];
    if (alerts.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: alerts.map<Widget>((alert) {
        final level = alert['level'] as String;
        final message = alert['message'] as String;

        Color backgroundColor;
        Color foregroundColor;
        IconData icon;

        switch (level) {
          case 'critical':
            backgroundColor = colorScheme.errorContainer;
            foregroundColor = colorScheme.onErrorContainer;
            icon = Icons.error_outline;
            break;
          case 'warning':
            backgroundColor = Colors.orange.shade100;
            foregroundColor = Colors.orange.shade900;
            icon = Icons.warning_amber_outlined;
            break;
          default:
            backgroundColor = colorScheme.primaryContainer;
            foregroundColor = colorScheme.onPrimaryContainer;
            icon = Icons.info_outline;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            color: backgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(icon, color: foregroundColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCostCard() {
    final totalCost = _costSummary?['totalCost'] as double? ?? 0.0;
    final callCount = _costSummary?['callCount'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Total Cost',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '\$${totalCost.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$callCount API calls',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard() {
    final remaining = _budgetStatus?['remaining'] as double? ?? 0.0;
    final percentUsed = _budgetStatus?['percentUsed'] as double? ?? 0.0;
    final colorScheme = Theme.of(context).colorScheme;

    Color progressColor;
    if (percentUsed >= 100) {
      progressColor = colorScheme.error;
    } else if (percentUsed >= 90) {
      progressColor = Colors.orange;
    } else if (percentUsed >= 80) {
      progressColor = Colors.yellow.shade700;
    } else {
      progressColor = colorScheme.primary;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: progressColor),
                const SizedBox(width: 8),
                const Text(
                  'Budget',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '\$${remaining.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (percentUsed / 100).clamp(0.0, 1.0),
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: progressColor,
            ),
            const SizedBox(height: 4),
            Text(
              '${percentUsed.toStringAsFixed(1)}% used',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionCard() {
    final projectedCost = _projection?['projectedCost'] as double? ?? 0.0;
    final dailyAverage = _projection?['dailyAverage'] as double? ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: 8),
                const Text(
                  'Projection',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '\$${projectedCost.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${dailyAverage.toStringAsFixed(2)}/day avg',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostChart() {
    if (_dailyCosts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: Text('No data available')),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < _dailyCosts.length; i++) {
      final cost = _dailyCosts[i]['cost'] as double? ?? 0.0;
      spots.add(FlSpot(i.toDouble(), cost));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${value.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= _dailyCosts.length) {
                        return const SizedBox.shrink();
                      }
                      final date = _dailyCosts[index]['date'] as String;
                      final parts = date.split('-');
                      if (parts.length >= 2) {
                        return Text(
                          '${parts[1]}/${parts[2]}',
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBreakdown() {
    final byFeature = _costSummary?['byFeature'] as Map<String, dynamic>? ?? {};

    if (byFeature.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: Text('No data available')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: byFeature.entries.map((entry) {
            final feature = entry.key;
            final cost = entry.value as double;
            final totalCost = _costSummary?['totalCost'] as double? ?? 1.0;
            final percentage = (cost / totalCost * 100);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        feature,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text('\$${cost.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
