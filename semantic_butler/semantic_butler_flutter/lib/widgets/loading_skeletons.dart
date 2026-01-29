import 'package:flutter/material.dart';

/// Shimmer effect for loading skeletons
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({
    super.key,
    required this.child,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerLow;
    final highlightColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                (_animation.value + 2) / 4,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

/// Skeleton placeholder widget
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Search result card skeleton
class SearchResultSkeleton extends StatelessWidget {
  const SearchResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  const SkeletonBox(width: 40, height: 40, borderRadius: 10),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          height: 16,
                        ),
                        const SizedBox(height: 6),
                        SkeletonBox(
                          width: MediaQuery.of(context).size.width * 0.3,
                          height: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Content preview
              const SkeletonBox(width: double.infinity, height: 12),
              const SizedBox(height: 6),
              const SkeletonBox(width: double.infinity, height: 12),
              const SizedBox(height: 6),
              SkeletonBox(
                width: MediaQuery.of(context).size.width * 0.7,
                height: 12,
              ),
              const SizedBox(height: 12),
              // Tags row
              Row(
                children: [
                  const SkeletonBox(width: 60, height: 24, borderRadius: 12),
                  const SizedBox(width: 8),
                  const SkeletonBox(width: 80, height: 24, borderRadius: 12),
                  const SizedBox(width: 8),
                  const SkeletonBox(width: 50, height: 24, borderRadius: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List of search result skeletons
class SearchResultsSkeletonList extends StatelessWidget {
  final int itemCount;

  const SearchResultsSkeletonList({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => SearchResultSkeleton(),
    );
  }
}

/// Stats card skeleton
class StatsCardSkeleton extends StatelessWidget {
  const StatsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SkeletonBox(width: 48, height: 48, borderRadius: 12),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 100, height: 14),
                    const SizedBox(height: 8),
                    const SkeletonBox(width: 60, height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recent searches skeleton
class RecentSearchesSkeleton extends StatelessWidget {
  final int itemCount;

  const RecentSearchesSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const SkeletonBox(
                width: 36,
                height: 36,
                borderRadius: 8,
              ),
              title: const SkeletonBox(width: 200, height: 14),
              subtitle: const SkeletonBox(width: 120, height: 12),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indexing progress skeleton
class IndexingProgressSkeleton extends StatelessWidget {
  const IndexingProgressSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SkeletonBox(width: 120, height: 16),
                  const SkeletonBox(width: 60, height: 16),
                ],
              ),
              const SizedBox(height: 12),
              const SkeletonBox(
                width: double.infinity,
                height: 8,
                borderRadius: 4,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SkeletonBox(width: 80, height: 12),
                  const SkeletonBox(width: 100, height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// File list skeleton
class FileListSkeleton extends StatelessWidget {
  final int itemCount;

  const FileListSkeleton({
    super.key,
    this.itemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => ListTile(
          leading: const SkeletonBox(width: 40, height: 40, borderRadius: 8),
          title: SkeletonBox(
            width: 100 + (index % 3) * 40.0,
            height: 14,
          ),
          subtitle: const SkeletonBox(width: 80, height: 12),
          trailing: const SkeletonBox(width: 24, height: 24, borderRadius: 4),
        ),
      ),
    );
  }
}
