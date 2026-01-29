import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_indexing_service.dart';
import '../services/settings_service.dart';
import '../main.dart'; // Usually where client or clientProvider is defined. Or we use the global client.

// Assuming global 'client' variable exists in main.dart or exported similarly as per other providers.
// If Riverpod refactor was done, we might have a clientProvider.
// Checking existing providers: 'chat_history_provider.dart' might show usage.

/// Provider for LocalIndexingService
final localIndexingServiceProvider = Provider<LocalIndexingService>((ref) {
  final settings = ref.watch(settingsProvider).value;
  final apiKey = settings?.openRouterKey ?? '';

  // Create service with current settings
  // Note: If API Key changes, this provider rebuilds and creates a new service instance.
  return LocalIndexingService(
    client: ref.watch(clientProvider),
    openRouterApiKey: apiKey,
  );
});
