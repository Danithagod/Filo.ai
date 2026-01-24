import 'package:flutter/material.dart';

/// A reusable background widget featuring a dense dot pattern and a subtle
/// vertical linear gradient from bottom to top.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // 1. Background Pattern
        const Positioned.fill(child: _BackgroundPattern()),

        // 2. Subtle Vertical Gradient (Bottom to Top)
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.05),
                  colorScheme.primary.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.4],
              ),
            ),
          ),
        ),

        // 3. Content
        child,
      ],
    );
  }
}

class _BackgroundPattern extends StatelessWidget {
  const _BackgroundPattern();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _PatternPainter(
        color: colorScheme.onSurface.withValues(alpha: 0.03),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;
  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const spacing = 15.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
