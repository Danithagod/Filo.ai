import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return WindowTitleBarBox(
      child: Row(
        children: [
          Expanded(
            child: MoveWindow(
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Image.asset(
                    'assets/app_icon.png', // Assuming we have one, or use Icon
                    width: 16,
                    height: 16,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.smart_toy,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Semantic Butler',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const WindowButtons(),
        ],
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final buttonColors = WindowButtonColors(
      iconNormal: colorScheme.onSurface,
      mouseOver: colorScheme.surfaceContainerHighest,
      mouseDown: colorScheme.primaryContainer,
      iconMouseOver: colorScheme.onSurface,
      iconMouseDown: colorScheme.primary,
    );

    final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: colorScheme.onSurface,
      iconMouseOver: Colors.white,
    );

    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
