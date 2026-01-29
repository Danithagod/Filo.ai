import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Provider for the SettingsService using AsyncNotifier
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Model for application settings
class AppSettings {
  final ThemeMode themeMode;
  final String aiProvider;
  final String? openRouterKey;
  final String serverUrl;
  final bool hasSeenOnboarding;
  final String? userName;

  const AppSettings({
    required this.themeMode,
    required this.aiProvider,
    this.openRouterKey,
    required this.serverUrl,
    required this.hasSeenOnboarding,
    this.userName,
  });

  /// Default settings used during loading (serverUrl will be overridden by config)
  static const defaultSettings = AppSettings(
    themeMode: ThemeMode.dark,
    aiProvider: 'OpenRouter',
    serverUrl:
        'http://127.0.0.1:8080/', // Fallback only, config.json takes precedence
    hasSeenOnboarding: false,
    userName: null,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? aiProvider,
    String? openRouterKey,
    bool clearOpenRouterKey = false,
    String? serverUrl,
    bool? hasSeenOnboarding,
    String? userName,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      aiProvider: aiProvider ?? this.aiProvider,
      openRouterKey:
          clearOpenRouterKey ? null : (openRouterKey ?? this.openRouterKey),
      serverUrl: serverUrl ?? this.serverUrl,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      userName: userName ?? this.userName,
    );
  }
}

/// Async Notifier for persistent settings
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  late SharedPreferences _prefs;

  static const _keyThemeMode = 'settings_theme_mode';
  static const _keyAiProvider = 'settings_ai_provider';
  static const _keyOpenRouterKey = 'settings_openrouter_key';
  static const _keyServerUrl = 'settings_server_url';
  static const _keyHasSeenOnboarding = 'settings_has_seen_onboarding';
  static const _keyUserName = 'settings_user_name';

  @override
  Future<AppSettings> build() async {
    _prefs = await SharedPreferences.getInstance();

    int themeIndex = _prefs.getInt(_keyThemeMode) ?? ThemeMode.dark.index;

    // Migrate ThemeMode.system (0) to ThemeMode.dark (2)
    if (themeIndex == ThemeMode.system.index) {
      themeIndex = ThemeMode.dark.index;
      await _prefs.setInt(_keyThemeMode, themeIndex);
    }

    final aiProvider = _prefs.getString(_keyAiProvider) ?? 'OpenRouter';
    final openRouterKey = _prefs.getString(_keyOpenRouterKey);

    // Load default serverUrl from config.json if not already stored in preferences
    // Also migrate from localhost to production URL for existing users
    String serverUrl;
    final storedServerUrl = _prefs.getString(_keyServerUrl);

    // Load config.json to get the bundled production URL
    String configUrl;
    try {
      final config = await AppConfig.loadConfig();
      configUrl = config.apiUrl;
    } catch (e) {
      configUrl = 'http://127.0.0.1:8080/';
    }

    if (storedServerUrl == null) {
      // First run: use URL from config.json
      serverUrl = configUrl;
      await _prefs.setString(_keyServerUrl, serverUrl);
    } else if (storedServerUrl.contains('127.0.0.1') ||
        storedServerUrl.contains('localhost')) {
      // Migration: existing users with localhost should switch to production URL
      // Only migrate if config.json has a non-localhost URL
      if (!configUrl.contains('127.0.0.1') &&
          !configUrl.contains('localhost')) {
        serverUrl = configUrl;
        await _prefs.setString(_keyServerUrl, serverUrl);
      } else {
        serverUrl = storedServerUrl;
      }
    } else {
      serverUrl = storedServerUrl;
    }

    final hasSeenOnboarding = _prefs.getBool(_keyHasSeenOnboarding) ?? false;
    final userName = _prefs.getString(_keyUserName);

    return AppSettings(
      themeMode: ThemeMode.values[themeIndex],
      aiProvider: aiProvider,
      openRouterKey: openRouterKey,
      serverUrl: serverUrl,
      hasSeenOnboarding: hasSeenOnboarding,
      userName: userName,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final currentSettings = state.value ?? AppSettings.defaultSettings;
    state = AsyncData(currentSettings.copyWith(themeMode: mode));
    await _prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<void> setAiProvider(String provider) async {
    final currentSettings = state.value ?? AppSettings.defaultSettings;
    state = AsyncData(currentSettings.copyWith(aiProvider: provider));
    await _prefs.setString(_keyAiProvider, provider);
  }

  Future<void> setOpenRouterKey(String? key) async {
    final currentSettings = state.value ?? AppSettings.defaultSettings;
    if (key == null) {
      state = AsyncData(currentSettings.copyWith(clearOpenRouterKey: true));
      await _prefs.remove(_keyOpenRouterKey);
    } else {
      state = AsyncData(currentSettings.copyWith(openRouterKey: key));
      await _prefs.setString(_keyOpenRouterKey, key);
    }
  }

  Future<void> setServerUrl(String url) async {
    final currentSettings = state.value ?? AppSettings.defaultSettings;
    state = AsyncData(currentSettings.copyWith(serverUrl: url));
    await _prefs.setString(_keyServerUrl, url);
  }

  Future<void> setOnboardingSeen(bool seen) async {
    final currentSettings = state.value ?? AppSettings.defaultSettings;
    state = AsyncData(currentSettings.copyWith(hasSeenOnboarding: seen));
    await _prefs.setBool(_keyHasSeenOnboarding, seen);
  }

  Future<void> setUserName(String name) async {
    final currentSettings = state.value ?? AppSettings.defaultSettings;
    state = AsyncData(currentSettings.copyWith(userName: name));
    await _prefs.setString(_keyUserName, name);
  }
}
