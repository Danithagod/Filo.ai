import 'package:semantic_butler_client/semantic_butler_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

/// Global Serverpod client
late final Client client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load configuration
  const serverUrlFromEnv = String.fromEnvironment('SERVER_URL');
  final config = await AppConfig.loadConfig();
  final serverUrl = serverUrlFromEnv.isEmpty
      ? config.apiUrl ?? 'http://$localhost:8080/'
      : serverUrlFromEnv;

  // Initialize Serverpod client
  client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor();

  runApp(
    const ProviderScope(
      child: SemanticButlerApp(),
    ),
  );
}

class SemanticButlerApp extends StatelessWidget {
  const SemanticButlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Semantic Butler',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
