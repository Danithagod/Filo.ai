import 'package:flutter/material.dart';

/// Material 3 styled settings screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
                subtitle: 'Connected to localhost:8080',
                trailing: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.storage_outlined,
                title: 'Database',
                subtitle: 'Neon PostgreSQL',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // AI Configuration section
          _SettingsSection(
            title: 'AI Configuration',
            children: [
              _SettingsTile(
                icon: Icons.psychology_outlined,
                title: 'AI Provider',
                subtitle: 'OpenRouter',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Configure OpenRouter API key'),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.memory_outlined,
                title: 'Embedding Model',
                subtitle: 'text-embedding-3-small',
              ),
              _SettingsTile(
                icon: Icons.smart_toy_outlined,
                title: 'Chat Model',
                subtitle: 'gemini-2.5-flash',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Appearance section
          _SettingsSection(
            title: 'Appearance',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Theme',
                subtitle: 'Dark',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Theme switching coming soon'),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About section
          _SettingsSection(
            title: 'About',
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: '1.0.0',
              ),
              _SettingsTile(
                icon: Icons.code_outlined,
                title: 'Source Code',
                subtitle: 'github.com/semantic-butler',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: children,
          ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(title, style: textTheme.bodyLarge),
      subtitle: Text(
        subtitle,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)
              : null),
      onTap: onTap,
    );
  }
}
