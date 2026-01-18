import 'dart:async';
import 'dart:io' show Platform;
import 'package:semantic_butler_client/semantic_butler_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/window_title_bar.dart';
import 'utils/app_logger.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

/// Global Serverpod client (kept for backward compatibility)
/// Prefer using clientProvider for new code
late final Client client;

/// Riverpod provider for Serverpod client
/// Use this for proper dependency injection and testability
final clientProvider = Provider<Client>((ref) {
  // Return the initialized client
  // This provider should only be accessed after client is initialized
  return client;
});

/// Provider for server URL configuration
final serverUrlProvider = StateProvider<String>((ref) {
  return 'http://127.0.0.1:8080/';
});

void main() async {
  // Catch all Flutter errors
  FlutterError.onError = (details) {
    AppLogger.error(
      'Flutter Error: ${details.exceptionAsString()}',
      tag: 'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Catch async errors
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AppLogger.lifecycle('App starting...');

      // Load configuration
      const serverUrlFromEnv = String.fromEnvironment('SERVER_URL');
      AppLogger.info('Loading configuration...', tag: 'Init');
      String serverUrl;
      try {
        final config = await AppConfig.loadConfig();
        serverUrl = serverUrlFromEnv.isEmpty
            ? config.apiUrl ?? 'http://127.0.0.1:8080/'
            : serverUrlFromEnv;
      } catch (e) {
        AppLogger.warning(
          'Failed to load config, using default URL: $e',
          tag: 'Init',
        );
        serverUrl = 'http://127.0.0.1:8080/';
      }

      // Ensure trailing slash and correct format
      if (!serverUrl.endsWith('/')) serverUrl += '/';
      if (!serverUrl.startsWith('http')) serverUrl = 'http://$serverUrl';

      AppLogger.info('Connecting to server: $serverUrl', tag: 'Init');

      // Initialize Serverpod client with longer timeout for AI API calls
      client = Client(
        serverUrl,
        connectionTimeout: const Duration(
          seconds: 120,
        ), // AI calls can take 30-60s
        onFailedCall: (context, error, stackTrace) {
          AppLogger.error(
            'API call failed: ${context.methodName} on $serverUrl',
            tag: 'API',
            error: error,
            stackTrace: stackTrace,
          );
        },
        onSucceededCall: (context) {
          AppLogger.debug(
            'API call succeeded: ${context.methodName}',
            tag: 'API',
          );
        },
      )..connectivityMonitor = FlutterConnectivityMonitor();

      AppLogger.lifecycle('Client initialized. Starting UI...');

      runApp(
        const ProviderScope(
          child: SemanticButlerApp(),
        ),
      );

      AppLogger.lifecycle('runApp called, waiting for window ready...');

      // Only run desktop-specific window configuration on desktop platforms
      // bitsdojo_window only works on Windows, macOS, and Linux
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        doWhenWindowReady(() {
          AppLogger.lifecycle('Window ready, configuring appearance...');
          final win = appWindow;
          const initialSize = Size(1280, 720);
          win.minSize = const Size(800, 600);
          win.size = initialSize;
          win.alignment = Alignment.center;
          win.title = "Semantic Butler";
          AppLogger.lifecycle('Showing window...');
          win.show();
        });
      } else {
        AppLogger.lifecycle(
          'Skipping desktop window configuration (non-desktop platform)',
        );
      }
    },
    (error, stackTrace) {
      AppLogger.error(
        'Uncaught error',
        tag: 'Zone',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

class SemanticButlerApp extends StatelessWidget {
  const SemanticButlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.lifecycle('Building SemanticButlerApp');
    return MaterialApp(
      title: 'Semantic Butler',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
      navigatorObservers: [_LoggingNavigatorObserver()],
      builder: (context, child) {
        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              const WindowTitleBar(),
              Expanded(child: child ?? const SizedBox()),
            ],
          ),
        );
      },
    );
  }
}

/// Navigator observer for logging route changes
class _LoggingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.debug(
      'Navigate to: ${route.settings.name ?? route.runtimeType}',
      tag: 'Navigation',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.debug(
      'Pop: ${route.settings.name ?? route.runtimeType}',
      tag: 'Navigation',
    );
  }
}
