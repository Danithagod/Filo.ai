import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';

enum SearchPhaseStatus {
  pending,
  inProgress,
  completed,
  notNeeded,
  error,
}

class SearchPhase {
  final String title;
  final String description;
  final SearchPhaseStatus status;
  final IconData icon;

  SearchPhase({
    required this.title,
    required this.description,
    required this.status,
    required this.icon,
    this.assetIcon,
  });

  final String? assetIcon;
}

class AISearchProgressView extends StatelessWidget {
  final List<AISearchProgress> history;
  final bool isComplete;
  final String? error;

  const AISearchProgressView({
    super.key,
    required this.history,
    this.isComplete = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final phases = _calculatePhases();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                isComplete ? 'Search Complete' : 'AI Search in progress...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!isComplete && error == null)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ...phases.map((phase) => _buildPhaseItem(context, phase)),
        ],
      ),
    );
  }

  Widget _buildPhaseItem(BuildContext context, SearchPhase phase) {
    final Color color;

    switch (phase.status) {
      case SearchPhaseStatus.pending:
        color = Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
        break;
      case SearchPhaseStatus.inProgress:
      case SearchPhaseStatus.completed:
        color = Theme.of(context).colorScheme.primary;
        break;
      case SearchPhaseStatus.notNeeded:
        color = Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3);
        break;
      case SearchPhaseStatus.error:
        color = Theme.of(context).colorScheme.error;
        break;
    }

    Widget iconWidget;
    if (phase.status == SearchPhaseStatus.inProgress) {
      iconWidget = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    } else if (phase.status == SearchPhaseStatus.completed) {
      iconWidget = Icon(Icons.check_circle_outline, size: 18, color: color);
    } else if (phase.status == SearchPhaseStatus.error) {
      iconWidget = Icon(Icons.error_outline, size: 18, color: color);
    } else if (phase.assetIcon != null) {
      iconWidget = SvgPicture.asset(
        phase.assetIcon!,
        width: 18,
        height: 18,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    } else {
      iconWidget = Icon(phase.icon, size: 18, color: color);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: iconWidget,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: phase.status == SearchPhaseStatus.inProgress
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: phase.status == SearchPhaseStatus.notNeeded
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                        : null,
                  ),
                ),
                if (phase.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      phase.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<SearchPhase> _calculatePhases() {
    // 1. Analysis
    var analysisStatus = SearchPhaseStatus.pending;
    var analysisDesc = 'Understanding your search intent...';

    // 2. Index Search
    var indexStatus = SearchPhaseStatus.pending;
    var indexDesc = 'Searching for files in the semantic index...';

    // 3. Deep Search
    var deepStatus = SearchPhaseStatus.pending;
    var deepDesc = 'Exploring filesystem for matching patterns...';

    // 4. Agent Search
    var agentStatus = SearchPhaseStatus.pending;
    var agentDesc = 'AI agent refining search results...';

    // 5. Finalizing
    var finalizingStatus = SearchPhaseStatus.pending;
    var finalizingDesc = 'Ranking and sorting found files...';

    for (final progress in history) {
      final msg = progress.message ?? '';
      final type = progress.type;
      final source = progress.source;

      if (msg.contains('Analyzing')) {
        analysisStatus = SearchPhaseStatus.inProgress;
      }

      if (source == 'semantic') {
        analysisStatus = SearchPhaseStatus.completed;
        indexStatus = SearchPhaseStatus.inProgress;
        if (type == 'found') {
          indexDesc = msg;
        }
      }

      if (source == 'terminal') {
        deepStatus = SearchPhaseStatus.inProgress;
        indexStatus = indexStatus == SearchPhaseStatus.inProgress
            ? SearchPhaseStatus.completed
            : indexStatus;
        if (type == 'found') {
          deepDesc = msg;
        }
      }

      if (msg.contains('agentic search')) {
        deepStatus = deepStatus == SearchPhaseStatus.inProgress
            ? SearchPhaseStatus.completed
            : deepStatus;
        agentStatus = SearchPhaseStatus.inProgress;
      }

      if (msg.contains('Ranking')) {
        agentStatus = agentStatus == SearchPhaseStatus.inProgress
            ? SearchPhaseStatus.completed
            : agentStatus;
        indexStatus = indexStatus == SearchPhaseStatus.inProgress
            ? SearchPhaseStatus.completed
            : indexStatus;
        deepStatus = deepStatus == SearchPhaseStatus.inProgress
            ? SearchPhaseStatus.completed
            : deepStatus;
        finalizingStatus = SearchPhaseStatus.inProgress;
      }
    }

    if (isComplete) {
      analysisStatus = analysisStatus == SearchPhaseStatus.error
          ? SearchPhaseStatus.error
          : SearchPhaseStatus.completed;
      indexStatus = indexStatus == SearchPhaseStatus.error
          ? SearchPhaseStatus.error
          : (indexStatus == SearchPhaseStatus.pending
                ? SearchPhaseStatus.notNeeded
                : SearchPhaseStatus.completed);
      deepStatus = deepStatus == SearchPhaseStatus.error
          ? SearchPhaseStatus.error
          : (deepStatus == SearchPhaseStatus.pending
                ? SearchPhaseStatus.notNeeded
                : SearchPhaseStatus.completed);
      agentStatus = agentStatus == SearchPhaseStatus.error
          ? SearchPhaseStatus.error
          : (agentStatus == SearchPhaseStatus.pending
                ? SearchPhaseStatus.notNeeded
                : SearchPhaseStatus.completed);
      finalizingStatus = finalizingStatus == SearchPhaseStatus.error
          ? SearchPhaseStatus.error
          : SearchPhaseStatus.completed;
    }

    if (error != null) {
      if (finalizingStatus == SearchPhaseStatus.inProgress) {
        finalizingStatus = SearchPhaseStatus.error;
      } else if (agentStatus == SearchPhaseStatus.inProgress) {
        agentStatus = SearchPhaseStatus.error;
      } else if (deepStatus == SearchPhaseStatus.inProgress) {
        deepStatus = SearchPhaseStatus.error;
      } else if (indexStatus == SearchPhaseStatus.inProgress) {
        indexStatus = SearchPhaseStatus.error;
      } else {
        analysisStatus = SearchPhaseStatus.error;
      }
    }

    return [
      SearchPhase(
        title: 'Query Analysis',
        description: analysisDesc,
        status: analysisStatus,
        icon: Icons.psychology_outlined,
      ),
      SearchPhase(
        title: 'Smart Index Search',
        description: indexDesc,
        status: indexStatus,
        icon: Icons.search_rounded,
      ),
      SearchPhase(
        title: 'Deep Filesystem Search',
        description: deepDesc,
        status: deepStatus,
        icon: Icons.folder_copy_outlined,
      ),
      SearchPhase(
        title: 'Agentic Discovery',
        description: agentDesc,
        status: agentStatus,
        icon: Icons.smart_toy_outlined,
        assetIcon: 'assets/filo_logo.svg',
      ),
      SearchPhase(
        title: 'Ranking & Optimization',
        description: finalizingDesc,
        status: finalizingStatus,
        icon: Icons.sort_rounded,
      ),
    ];
  }
}
