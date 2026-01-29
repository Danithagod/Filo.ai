import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class OnboardingBackground extends StatefulWidget {
  final ValueNotifier<double> scrollPosition;
  final List<Color> pageColors;

  const OnboardingBackground({
    super.key,
    required this.scrollPosition,
    required this.pageColors,
  });

  @override
  State<OnboardingBackground> createState() => _OnboardingBackgroundState();
}

class _OnboardingBackgroundState extends State<OnboardingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _gridController;

  @override
  void initState() {
    super.initState();
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.scrollPosition,
      builder: (context, position, child) {
        final int index = position.floor();
        final double delta = position - index;

        Color color;
        if (index < widget.pageColors.length - 1) {
          color = Color.lerp(
            widget.pageColors[index],
            widget.pageColors[index + 1],
            delta,
          )!;
        } else {
          color = widget.pageColors.last;
        }

        return Stack(
          children: [
            Positioned.fill(
              child: Container(color: Theme.of(context).scaffoldBackgroundColor),
            ),
            // Animated Dotted Grid
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _gridController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _GridPainter(
                      progress: _gridController.value,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.03),
                    ),
                  );
                },
              ),
            ),
            // Animated Blob 1
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              top: -100 + (math.sin(position * math.pi) * 50),
              left: -100 - (position * 100),
              child: _Blob(color: color.withValues(alpha: 0.2), size: 400),
            ),
            // Animated Blob 2
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              bottom: -50 + (math.cos(position * math.pi) * 50),
              right: -100 + (position * 50),
              child: _Blob(
                color: widget.pageColors[position.round().clamp(
                  0,
                  widget.pageColors.length - 1,
                )].withValues(alpha: 0.15),
                size: 350,
              ),
            ),
            // Blur Effect
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final double progress;
  final Color color;

  _GridPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const double spacing = 40.0;
    final double offsetX = (progress * spacing);
    final double offsetY = (progress * spacing);

    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(
          Offset(x + (offsetX % spacing), y + (offsetY % spacing)),
          1.5,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;

  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
