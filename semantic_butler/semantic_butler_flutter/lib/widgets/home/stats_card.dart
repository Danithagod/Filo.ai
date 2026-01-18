import 'package:flutter/material.dart';

/// Modern statistics card widget with animations
class StatsCard extends StatefulWidget {
  final String title;
  final double numericValue;
  final String suffix;
  final IconData icon;
  final Color color;
  final bool isPulse;
  final double? progress;

  const StatsCard({
    super.key,
    required this.title,
    required this.numericValue,
    this.suffix = '',
    required this.icon,
    required this.color,
    this.isPulse = false,
    this.progress,
  });

  // Keep old constructor for compatibility if needed, but better to update calls
  factory StatsCard.static({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    // Try to parse double from value string for backward compatibility
    double numericValue = 0;
    String suffix = '';
    final cleanedValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
    numericValue = double.tryParse(cleanedValue) ?? 0;
    if (value.contains('%')) suffix = '%';

    return StatsCard(
      title: title,
      numericValue: numericValue,
      suffix: suffix,
      icon: icon,
      color: color,
    );
  }

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulse != oldWidget.isPulse) {
      if (widget.isPulse) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ScaleTransition(
                scale: widget.isPulse
                    ? _pulseAnimation
                    : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 24),
                ),
              ),
              if (widget.progress != null)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: widget.progress,
                    strokeWidth: 3,
                    backgroundColor: widget.color.withValues(alpha: 0.1),
                    color: widget.color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: widget.numericValue),
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                '${value.toInt()}${widget.suffix}',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            widget.title,
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          if (widget.progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: widget.progress,
                minHeight: 4,
                backgroundColor: widget.color.withValues(alpha: 0.1),
                color: widget.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
