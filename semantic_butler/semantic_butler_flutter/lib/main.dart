import 'dart:async';
import 'dart:io' show Platform;
import 'package:semantic_butler_client/semantic_butler_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import 'config/app_config.dart';
import 'theme/app_theme.dart';
import 'widgets/window_title_bar.dart';
import 'services/settings_service.dart';
import 'utils/app_logger.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'services/shortcut_manager.dart' as sm;
import 'services/shortcut_manager.dart'
    show FocusSearchIntent, NavigateTabIntent;
import 'providers/navigation_provider.dart';
import 'providers/search_controller.dart' as sc;
import 'screens/search_results_screen.dart';
import 'screens/splash_landing_screen.dart';

/// Internal Serverpod client instance
/// Set during app initialization and accessed via clientProvider
Client? _clientInstance;

/// Riverpod provider for Serverpod client
/// Use this for proper dependency injection and testability
final clientProvider = Provider<Client>((ref) {
  if (_clientInstance == null) {
    throw StateError(
      'Client not initialized. Ensure app startup completes before accessing clientProvider.',
    );
  }
  return _clientInstance!;
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
        serverUrl = serverUrlFromEnv.isEmpty ? config.apiUrl : serverUrlFromEnv;
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
      _clientInstance = Client(
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
          win.title = "Filo";
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

class SemanticButlerApp extends ConsumerWidget {
  const SemanticButlerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.lifecycle('Building SemanticButlerApp');
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => MaterialApp(
        title: 'Filo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => MaterialApp(
        title: 'Filo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: Text('Error loading settings: $error'),
          ),
        ),
      ),
      data: (settings) => Shortcuts(
        shortcuts: sm.ShortcutManager.shortcuts,
        child: Actions(
          actions: <Type, Action<Intent>>{
            FocusSearchIntent: CallbackAction<FocusSearchIntent>(
              onInvoke: (_) => _handleGlobalSearch(context, ref),
            ),
            NavigateTabIntent: CallbackAction<NavigateTabIntent>(
              onInvoke: (intent) {
                FocusManager.instance.primaryFocus?.unfocus();
                ref.read(navigationProvider.notifier).navigateTo(intent.index);
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: false, // Don't steal focus from initial screen
            child: MaterialApp(
              title: 'Filo',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: settings.themeMode,
              themeAnimationDuration: const Duration(milliseconds: 500),
              themeAnimationCurve: Curves.easeInOut,
              home: const SplashLandingScreen(),
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
            ),
          ),
        ),
      ),
    );
  }

  void _handleGlobalSearch(BuildContext context, WidgetRef ref) {
    final navState = ref.read(navigationProvider);
    // If not on home screen, navigate to home first to provide context
    if (navState.selectedIndex != 0) {
      ref.read(navigationProvider.notifier).navigateTo(0);
      // Wait for navigation to complete before showing search
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showSearch(
          context: context,
          delegate: _GlobalSearchDelegate(ref),
        );
      });
    } else {
      showSearch(
        context: context,
        delegate: _GlobalSearchDelegate(ref),
      );
    }
  }
}

/// A global search delegate that provides a quick search UI from anywhere in the app
class _GlobalSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  _GlobalSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) return const SizedBox();

    // Navigate to SearchResultsScreen when user submits search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(
            query: query,
            initialMode: sc.SearchMode.hybrid,
          ),
        ),
      );
    });

    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // This could show recent searches or suggestions
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text('Enter keywords to search your files'),
        ],
      ),
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
