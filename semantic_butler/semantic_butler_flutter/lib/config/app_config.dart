import 'dart:convert';
import 'package:flutter/services.dart';

class AppConfig {
  final String apiUrl;

  AppConfig._({required this.apiUrl});

  /// Load configuration from assets/config.json
  /// Falls back to environment-based defaults if config.json cannot be read
  static Future<AppConfig> loadConfig() async {
    try {
      final jsonString = await rootBundle.loadString('assets/config.json');
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      final apiUrl = jsonMap['apiUrl'] as String? ?? _getFallbackUrl();
      return AppConfig._(apiUrl: apiUrl);
    } catch (e) {
      // Fallback to environment-based URL if config.json fails
      return AppConfig._(apiUrl: _getFallbackUrl());
    }
  }

  /// Fallback URL based on compile-time environment
  static String _getFallbackUrl() {
    const env = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'development',
    );

    switch (env) {
      case 'production':
        return 'http://localhost:8080/';
      case 'staging':
        return 'https://semantic-butler-staging-api.serverpod.space/';
      default:
        return 'http://127.0.0.1:8080/';
    }
  }

  /// Deprecated: Use loadConfig() instead
  @Deprecated('Use loadConfig() for async configuration loading')
  static String get apiBaseUrl => _getFallbackUrl();
}
