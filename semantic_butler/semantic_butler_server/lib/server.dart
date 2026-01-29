import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:serverpod/serverpod.dart';

import 'src/endpoints/butler_endpoint.dart';
import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/web/routes/app_config_route.dart';
import 'src/web/routes/root.dart';
import 'src/services/indexing_service.dart';

/// Environment variables loaded from .env file
late DotEnv env;

/// Get environment variable (checks .env first, then system env)
String getEnv(String key, {String defaultValue = ''}) {
  return env.getOrElse(key, () => Platform.environment[key] ?? defaultValue);
}

/// The starting point of the Serverpod server.
Future<void> run(List<String> args) async {
  // Load environment variables from .env file
  env = DotEnv(includePlatformEnvironment: true)..load();

  // Log API key status (using stdout for startup messages)
  stdout.writeln(
    'Loaded environment: OPENROUTER_API_KEY is ${getEnv('OPENROUTER_API_KEY').isNotEmpty ? 'SET' : 'NOT SET'}',
  );

  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Note: Authentication removed for MVP. Add back when needed.
  // pod.initializeAuthServices(
  //   tokenManagerBuilders: [JwtConfigFromPasswords()],
  //   identityProviderBuilders: [EmailIdpConfigFromPasswords(...)],
  // );

  // Setup a default page at the web root.
  pod.webServer.addRoute(RootRoute(), '/');
  pod.webServer.addRoute(RootRoute(), '/index.html');

  // Serve all files in the web/static relative directory under /.
  final root = Directory(Uri(path: 'web/static').toFilePath());
  pod.webServer.addRoute(StaticRoute.directory(root));

  // Setup the app config route.
  pod.webServer.addRoute(
    AppConfigRoute(apiConfig: pod.config.apiServer),
    '/app/assets/config.json',
  );

  // Checks if the flutter web app has been built and serves it if it has.
  final appDir = Directory(Uri(path: 'web/app').toFilePath());
  if (appDir.existsSync()) {
    pod.webServer.addRoute(
      FlutterRoute(Directory(Uri(path: 'web/app').toFilePath())),
      '/app',
    );
  } else {
    pod.webServer.addRoute(
      StaticRoute.file(
        File(Uri(path: 'web/pages/build_flutter_app.html').toFilePath()),
      ),
      '/app/**',
    );
  }
  // Start the server.
  stdout.writeln('Starting Serverpod...');
  try {
    await pod.start();
    stdout.writeln('Serverpod started successfully.');

    // Issue #16: Register shutdown hook for graceful cleanup
    // Handle SIGINT (Ctrl+C) to dispose resources before exit
    ProcessSignal.sigint.watch().listen((_) async {
      stdout.writeln('Shutting down gracefully...');
      await ButlerEndpoint.disposeAll();
      stdout.writeln('Resources cleaned up. Exiting.');
      exit(0);
    });

    // Initialize periodic cleanup of idle file watchers
    // This prevents memory leaks from accumulated file watchers
    ButlerEndpoint.initializeWatcherCleanup();
    stdout.writeln('File watcher cleanup timer initialized.');

    // Startup recovery for indexing jobs
    final indexingService = IndexingService();
    await indexingService.recoverStuckJobs(pod);
    indexingService.initializeWatcherCallbacks(pod);
    stdout.writeln(
      'Background job recovery and watcher callbacks initialized.',
    );
  } catch (e, stack) {
    stdout.writeln('CRITICAL: pod.start() failed: $e\n$stack');
    rethrow;
  }
}
