import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FiloHeroLogo extends StatefulWidget {
  final double size;
  final Color? color;

  const FiloHeroLogo({
    super.key,
    this.size = 120,
    this.color,
  });

  @override
  State<FiloHeroLogo> createState() => _FiloHeroLogoState();
}

class _FiloHeroLogoState extends State<FiloHeroLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: SvgPicture.asset(
            'assets/filo_logo.svg',
            width: widget.size,
            height: widget.size,
            colorFilter: ColorFilter.mode(
              logoColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }
}
