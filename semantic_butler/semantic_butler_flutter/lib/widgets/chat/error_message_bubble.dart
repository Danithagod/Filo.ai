import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/chat/chat_error.dart';
import '../../screens/settings_screen.dart';

/// Specialized bubble for displaying chat errors
class ErrorMessageBubble extends StatelessWidget {
  final ChatError error;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const ErrorMessageBubble({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Icon(
                error.icon,
                size: 18,
                color: colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Something went wrong',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Dismiss button
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDismiss,
                tooltip: 'Dismiss',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // User-friendly message
          Text(
            error.userMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),

          // Details (expandable)
          if (error.details != null) ...[
            const SizedBox(height: 8),
            _ErrorDetails(details: error.details!),
          ],

          const SizedBox(height: 12),

          // Action buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (error.isRetryable)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Try again'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              // Situational Quick Fixes
              if (error.type == ChatErrorType.network)
                TextButton.icon(
                  onPressed: () => _handleAction(context, 'Check connection'),
                  icon: const Icon(Icons.wifi_off_rounded, size: 16),
                  label: const Text('Connection fix'),
                ),
              if (error.type == ChatErrorType.apiAuth ||
                  error.type == ChatErrorType.apiServer)
                TextButton.icon(
                  onPressed: () => _handleAction(context, 'Settings'),
                  icon: const Icon(Icons.settings_rounded, size: 16),
                  label: const Text('Check Settings'),
                ),
              if (!error.isRetryable)
                TextButton.icon(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Clear error'),
                ),
              // Additional suggested actions
              ...error.suggestedActions
                  .where(
                    (action) =>
                        action != 'Retry' &&
                        action != 'Settings' &&
                        action != 'Check connection',
                  )
                  .map(
                    (action) => OutlinedButton(
                      onPressed: () => _handleAction(context, action),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(80, 32),
                      ),
                      child: Text(action),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'Check connection':
        onRetry();
        break;
      case 'Check API key':
      case 'Settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
      case 'Contact support':
        final Uri emailLaunchUri = Uri(
          scheme: 'mailto',
          path: 'support@desk-sense.com',
          query: _encodeQueryParameters({
            'subject': 'Support Request - Desk Sense',
            'body': 'Error details: ${error.details ?? 'No details provided'}',
          }),
        );
        launchUrl(emailLaunchUri);
        break;
      default:
        break;
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }
}

class _ErrorDetails extends StatefulWidget {
  final String details;

  const _ErrorDetails({required this.details});

  @override
  State<_ErrorDetails> createState() => _ErrorDetailsState();
}

class _ErrorDetailsState extends State<_ErrorDetails> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Details',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Text(
                      widget.details,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Global retry banner for connection issues
class RetryBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const RetryBanner({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MaterialBanner(
      content: Text(message),
      leading: Icon(Icons.warning_amber, color: colorScheme.error),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('Dismiss'),
        ),
        FilledButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
      backgroundColor: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
