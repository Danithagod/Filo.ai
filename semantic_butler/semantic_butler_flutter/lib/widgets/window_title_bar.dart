import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return WindowTitleBarBox(
      child: Row(
        children: [
          Expanded(
            child: MoveWindow(
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Image.asset(
                    'assets/filo_navbar.png',
                    width: 16,
                    height: 16,
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
      iconMouseOver: Theme.of(context).colorScheme.onSurface,
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
