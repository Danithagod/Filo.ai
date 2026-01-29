class AppConfig {
  static String get apiBaseUrl {
    const env = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'development',
    );

    switch (env) {
      case 'production':
        return 'https://semantic-butler-api.serverpod.space/';
      case 'staging':
        return 'https://semantic-butler-staging-api.serverpod.space/';
      default:
        return 'http://127.0.0.1:8080/';
    }
  }

  // Backward compatibility wrapper
  static Future<AppConfig> loadConfig() async {
    return AppConfig();
  }

  final String apiUrl;

  AppConfig() : apiUrl = apiBaseUrl;
}
