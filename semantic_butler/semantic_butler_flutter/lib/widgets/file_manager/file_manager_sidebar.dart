import 'package:flutter/material.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';

/// Sidebar widget displaying available drives for file navigation
/// with error handling and retry functionality
class FileManagerSidebar extends StatelessWidget {
  final List<DriveInfo> drives;
  final String currentPath;
  final bool isLoading;
  final String? errorMessage;
  final void Function(String) onDriveSelected;
  final VoidCallback? onRetry;

  const FileManagerSidebar({
    super.key,
    required this.drives,
    required this.currentPath,
    this.isLoading = false,
    this.errorMessage,
    required this.onDriveSelected,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page Title
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File Manager',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Browse and manage your files',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Drives Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Row(
            children: [
              Icon(Icons.storage, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Drives',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (onRetry != null && !isLoading)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: onRetry,
                  tooltip: 'Refresh drives',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
        Expanded(
          child: _buildDrivesList(context, colorScheme, textTheme),
        ),
      ],
    );
  }

  Widget _buildDrivesList(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Show loading state
    if (isLoading && drives.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error state with retry button
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 32,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load drives',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getFriendlyErrorMessage(errorMessage!),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: onRetry,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 18),
                      SizedBox(width: 8),
                      Text('Retry'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Show empty state
    if (drives.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storage_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No drives found',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Show drives list with accessibility labels
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: drives.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final drive = drives[index];
        // Windows path comparison should be case-insensitive
        final isSelected = currentPath.toLowerCase().startsWith(
          drive.path.toLowerCase(),
        );

        return Semantics(
          label: 'Drive ${drive.name}, ${isSelected ? 'selected' : 'not selected'}',
          button: true,
          selected: isSelected,
          onTapHint: 'Navigate to ${drive.name}',
          child: Material(
            color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onDriveSelected(drive.path),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.dns,
                      size: 20,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      semanticLabel: null, // Exclude from semantics
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        drive.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colorScheme.onPrimaryContainer,
                        semanticLabel: null, // Exclude from semantics
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Convert technical error messages to user-friendly text
  String _getFriendlyErrorMessage(String error) {
    final lowerError = error.toLowerCase();

    if (lowerError.contains('permission') || lowerError.contains('access denied')) {
      return 'Permission denied. Check file access permissions.';
    }
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'Network error. Check your connection.';
    }
    if (lowerError.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (lowerError.contains('not found') || lowerError.contains('404')) {
      return 'Resource not found.';
    }

    // Truncate long error messages
    if (error.length > 100) {
      return '${error.substring(0, 100)}...';
    }

    return error;
  }
}
