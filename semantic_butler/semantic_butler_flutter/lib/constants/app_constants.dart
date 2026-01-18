/// App-wide constants to eliminate magic numbers
///
/// Centralizes configuration values that were previously scattered throughout
/// the codebase as undocumented magic numbers.
class AppConstants {
  AppConstants._(); // Prevent instantiation

  // Window dimensions
  static const double minWindowWidth = 800;
  static const double minWindowHeight = 600;
  static const double defaultWindowWidth = 1280;
  static const double defaultWindowHeight = 720;

  // API configuration
  static const Duration connectionTimeout = Duration(seconds: 120);
  static const Duration pollingInterval = Duration(seconds: 2);

  // Chat limits
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxContentLength = 10000;
  static const int maxMessages = 100;

  // Layout
  static const double sidebarWidth = 280;
  static const double defaultPadding = 24;
  static const double cardRadius = 12;
}
