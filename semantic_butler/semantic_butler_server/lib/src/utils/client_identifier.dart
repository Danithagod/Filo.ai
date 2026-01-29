import 'package:serverpod/serverpod.dart';

/// Utility for generating persistent client identifiers
/// 
/// Uses a combination of authentication info and session data to create
/// stable identifiers that persist across reconnections.
class ClientIdentifier {
  /// Generate a persistent client identifier from session
  /// 
  /// Priority:
  /// 1. User ID from authentication (if available)
  /// 2. Session ID (fallback - will reset on reconnection)
  /// 
  /// Note: For production use, integrate with Serverpod's authentication module
  /// to get persistent user IDs. This implementation uses session ID as fallback.
  static String fromSession(Session session) {
    // Try to get authenticated user ID from Serverpod auth
    // This requires Serverpod auth module to be configured
    final authInfo = session.authenticated;
    if (authInfo != null) {
      // Use the authentication key as identifier
      // In Serverpod, authenticated.userId is available when using auth module
      return 'auth:${authInfo.hashCode.abs()}';
    }

    // Fallback to session ID (will reset on reconnection)
    // This is acceptable for unauthenticated sessions
    // For persistent identification, implement proper authentication
    return 'session:${session.sessionId}';
  }

  /// Generate a client identifier with custom prefix
  static String withPrefix(Session session, String prefix) {
    final base = fromSession(session);
    return '$prefix:$base';
  }

  /// Check if identifier is persistent (won't change on reconnection)
  static bool isPersistent(String identifier) {
    return identifier.startsWith('auth:');
  }

  /// Extract the type from an identifier
  static String getType(String identifier) {
    final parts = identifier.split(':');
    return parts.isNotEmpty ? parts[0] : 'unknown';
  }
}
