import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Intent to focus the search bar
class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

/// Intent to navigate to a specific tab by index
class NavigateTabIntent extends Intent {
  final int index;
  const NavigateTabIntent(this.index);
}

/// Manager for application-wide keyboard shortcuts
class ShortcutManager {
  /// Map of logical keys to intents
  static Map<ShortcutActivator, Intent> get shortcuts {
    return {
      // Search: Ctrl/Cmd + K
      const SingleActivator(LogicalKeyboardKey.keyK, control: true):
          const FocusSearchIntent(),
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
          const FocusSearchIntent(),

      // Tab Navigation: Ctrl/Cmd + 1-5
      const SingleActivator(LogicalKeyboardKey.digit1, control: true):
          const NavigateTabIntent(0),
      const SingleActivator(LogicalKeyboardKey.digit1, meta: true):
          const NavigateTabIntent(0),

      const SingleActivator(LogicalKeyboardKey.digit2, control: true):
          const NavigateTabIntent(1),
      const SingleActivator(LogicalKeyboardKey.digit2, meta: true):
          const NavigateTabIntent(1),

      const SingleActivator(LogicalKeyboardKey.digit3, control: true):
          const NavigateTabIntent(2),
      const SingleActivator(LogicalKeyboardKey.digit3, meta: true):
          const NavigateTabIntent(2),

      const SingleActivator(LogicalKeyboardKey.digit4, control: true):
          const NavigateTabIntent(3),
      const SingleActivator(LogicalKeyboardKey.digit4, meta: true):
          const NavigateTabIntent(3),

      const SingleActivator(LogicalKeyboardKey.digit5, control: true):
          const NavigateTabIntent(4),
      const SingleActivator(LogicalKeyboardKey.digit5, meta: true):
          const NavigateTabIntent(4),

      const SingleActivator(LogicalKeyboardKey.digit6, control: true):
          const NavigateTabIntent(5),
      const SingleActivator(LogicalKeyboardKey.digit6, meta: true):
          const NavigateTabIntent(5),
    };
  }
}
