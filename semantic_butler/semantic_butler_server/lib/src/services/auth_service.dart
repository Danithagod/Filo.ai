import 'package:serverpod/serverpod.dart';
import '../../server.dart' show getEnv;

/// Authentication service for API key validation
///
/// Provides API key-based authentication for protecting endpoints.
/// SECURITY: Always validates in production mode. Set API_KEY environment variable.
class AuthService {
  /// Header name for API key
  static const String apiKeyHeader = 'x-api-key';

  /// Environment variable name for the API key
  static const String apiKeyEnvVar = 'API_KEY';

  /// Environment variable to enable authentication in development
  static const String forceAuthEnvVar = 'FORCE_AUTH';

  /// Validate API key from session
  ///
  /// Returns true ONLY if:
  /// - No API_KEY is configured AND FORCE_AUTH is not set (development mode)
  /// - The provided API key in session headers matches the configured key
  ///
  /// For production, ALWAYS set API_KEY environment variable.
  static bool validateApiKey(Session session, {String? providedApiKey}) {
    final expectedKey = getEnv(apiKeyEnvVar, defaultValue: '');
    final forceAuth =
        getEnv(forceAuthEnvVar, defaultValue: '').toLowerCase() == 'true';

    // If no API key is configured and FORCE_AUTH is not set, allow (dev mode only)
    if (expectedKey.isEmpty && !forceAuth) {
      session.log(
        'API key not configured - running in development mode. Set API_KEY for production.',
        level: LogLevel.warning,
      );
      return true;
    }

    // If API key is configured, validation is required
    if (expectedKey.isEmpty && forceAuth) {
      session.log(
        'FORCE_AUTH is set but API_KEY is not configured!',
        level: LogLevel.error,
      );
      return false;
    }

    // Get API key from provided parameter or session
    final apiKey = providedApiKey ?? _getApiKeyFromSession(session);

    if (apiKey == null || apiKey.isEmpty) {
      session.log(
        'API key missing from request',
        level: LogLevel.warning,
      );
      return false;
    }

    // Constant-time comparison to prevent timing attacks
    if (!_constantTimeEquals(apiKey, expectedKey)) {
      session.log(
        'Invalid API key provided',
        level: LogLevel.warning,
      );
      return false;
    }

    return true;
  }

  /// Get API key from session headers (if available)
  static String? _getApiKeyFromSession(Session session) {
    // Serverpod doesn't expose HTTP headers directly on Session in endpoint methods
    // In production, use Serverpod's authentication module or pass API key as parameter
    // For now, return null - endpoints should pass API key explicitly
    return null;
  }

  /// Constant-time string comparison to prevent timing attacks
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Require valid API key or throw UnauthorizedException
  ///
  /// Call this at the start of protected endpoints.
  static void requireAuth(Session session, {String? apiKey}) {
    if (!validateApiKey(session, providedApiKey: apiKey)) {
      throw UnauthorizedException('Invalid or missing API key');
    }
  }

  /// Check if authentication is enabled (API_KEY is configured)
  static bool isAuthEnabled() {
    final expectedKey = getEnv(apiKeyEnvVar, defaultValue: '');
    final forceAuth =
        getEnv(forceAuthEnvVar, defaultValue: '').toLowerCase() == 'true';
    return expectedKey.isNotEmpty || forceAuth;
  }
}

/// Exception for unauthorized access
class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}
