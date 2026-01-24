import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import '../services/settings_service.dart';
import '../services/reset_service.dart';

/// Material 3 styled settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading settings: $error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(settingsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (settings) => _buildSettingsContent(
        context,
        ref,
        settings,
        colorScheme,
        textTheme,
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),

              // Connection section
              _SettingsSection(
                title: 'Connection',
                children: [
                  _SettingsTile(
                    icon: Icons.dns_outlined,
                    title: 'Server Status',
                    subtitle: 'Connected to ${settings.serverUrl}',
                    trailing: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onTap: () => _showServerUrlDialog(context, ref),
                  ),
                  const _SettingsTile(
                    icon: Icons.storage_outlined,
                    title: 'Database',
                    subtitle: 'Neon PostgreSQL (Auto-detected)',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // AI Configuration section
              _SettingsSection(
                title: 'AI Configuration',
                children: [
                  _SettingsTile(
                    icon: Icons.psychology_outlined,
                    title: 'AI Provider',
                    subtitle: settings.aiProvider,
                    onTap: () => _showAiProviderDialog(context, ref),
                  ),
                  _SettingsTile(
                    icon: Icons.key_outlined,
                    title: 'API Key',
                    subtitle: settings.openRouterKey != null
                        ? '••••••••••••••••'
                        : 'Not set',
                    onTap: () => _showApiKeyDialog(context, ref),
                  ),
                  const _SettingsTile(
                    icon: Icons.memory_outlined,
                    title: 'Embedding Model',
                    subtitle: 'text-embedding-3-small',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Appearance section
              _SettingsSection(
                title: 'Appearance',
                children: [
                  _SettingsTile(
                    icon: settings.themeMode == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : settings.themeMode == ThemeMode.light
                        ? Icons.light_mode_outlined
                        : Icons.brightness_auto_outlined,
                    title: 'Theme',
                    subtitle: _formatThemeMode(settings.themeMode),
                    onTap: () {
                      final nextMode = switch (settings.themeMode) {
                        ThemeMode.system => ThemeMode.light,
                        ThemeMode.light => ThemeMode.dark,
                        ThemeMode.dark => ThemeMode.system,
                      };
                      settingsNotifier.setThemeMode(nextMode);
                    },
                  ),
                ],
              ),

              // System & Maintenance section
              _SettingsSection(
                title: 'System & Maintenance',
                children: [
                  _SettingsTile(
                    icon: Icons.restart_alt_outlined,
                    title: 'Database Reset',
                    subtitle: 'Clean up all application data',
                    onTap: () => _showResetPreviewDialog(context, ref),
                  ),
                ],
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  String _formatThemeMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System Preference',
      ThemeMode.light => 'Light Mode',
      ThemeMode.dark => 'Dark Mode',
    };
  }

  void _showAiProviderDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select AI Provider'),
        children: ['OpenRouter', 'OpenAI', 'Anthropic', 'Local (Ollama)']
            .map(
              (p) => SimpleDialogOption(
                onPressed: () {
                  ref.read(settingsProvider.notifier).setAiProvider(p);
                  Navigator.pop(context);
                },
                child: Text(p),
              ),
            )
            .toList(),
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, WidgetRef ref) {
    final currentSettings = ref.read(settingsProvider).value;
    final controller = TextEditingController(
      text: currentSettings?.openRouterKey,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'sk-or-v1-...',
            helperText: 'Required for OpenRouter providers',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(settingsProvider.notifier)
                  .setOpenRouterKey(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showServerUrlDialog(BuildContext context, WidgetRef ref) {
    final currentSettings = ref.read(settingsProvider).value;
    final controller = TextEditingController(
      text: currentSettings?.serverUrl ?? 'http://127.0.0.1:8080/',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://localhost:8080/',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setServerUrl(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResetPreviewDialog(BuildContext context, WidgetRef ref) async {
    final resetService = ref.read(resetServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FutureBuilder<ResetPreview>(
        future: resetService.getPreview(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing database...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to load preview: ${snapshot.error}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          }

          final preview = snapshot.data!;
          return AlertDialog(
            title: const Text('Database Reset Preview'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The following records will be permanently deleted:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...preview.tables.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key),
                          Text(
                            e.value.toString(),
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Records:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        preview.totalRows.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estimated time: ${preview.estimatedTimeSeconds} seconds',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showResetConfirmationDialog(context, ref);
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Proceed to Reset'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context, WidgetRef ref) async {
    final resetService = ref.read(resetServiceProvider);
    final codeController = TextEditingController();
    String selectedScope = 'dataOnly';
    bool isResetting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Confirm Database Reset'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To prevent accidental data loss, a confirmation code is required.',
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: isResetting
                      ? null
                      : () async {
                          try {
                            final code = await resetService
                                .generateConfirmationCode();
                            // In a real app, this might be emailed, but here we'll show it or
                            // assume the user gets it from the logs/console for now as per "double check"
                            // Actually, let's just show it in a snackbar for convenience of the USER during testing.
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Confirmation code: $code'),
                                  duration: const Duration(seconds: 10),
                                  action: SnackBarAction(
                                    label: 'Copy',
                                    onPressed: () {
                                      // Copy to clipboard placeholder
                                    },
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to generate code: $e'),
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Request Reset Code'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmation Code',
                    hintText: 'RESET-DESK-SENSE-XXXXXX',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !isResetting,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Reset Scope:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedScope,
                  items: const [
                    DropdownMenuItem(
                      value: 'dataOnly',
                      child: Text('Data Only (Recommended)'),
                    ),
                    DropdownMenuItem(
                      value: 'soft',
                      child: Text('Soft Reset (Keep Config)'),
                    ),
                    DropdownMenuItem(
                      value: 'full',
                      child: Text('Full Reset (Truncate All)'),
                    ),
                  ],
                  onChanged: isResetting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => selectedScope = value);
                          }
                        },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                if (isResetting) ...[
                  const SizedBox(height: 24),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('Executing reset... Please wait.'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isResetting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isResetting
                    ? null
                    : () async {
                        if (!context.mounted) return;
                        if (codeController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter the confirmation code',
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() => isResetting = true);
                        try {
                          final result = await resetService.resetDatabase(
                            scope: selectedScope,
                            confirmationCode: codeController.text,
                          );

                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog
                            _showResetResultDialog(context, result);
                          }
                        } catch (e) {
                          setState(() => isResetting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Reset failed: $e')),
                            );
                          }
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Delete All Data'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetResultDialog(BuildContext context, ResetResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Text(result.success ? 'Reset Successful' : 'Reset Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.success)
              Text(
                'Successfully cleared ${result.scope} data in ${result.durationMs}ms.',
              )
            else
              Text('Error: ${result.errorMessage ?? "Unknown error"}'),
            const SizedBox(height: 16),
            const Text(
              'Affected Tables:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...result.affectedRows.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontSize: 12)),
                    Text(
                      '${e.value} deleted',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
