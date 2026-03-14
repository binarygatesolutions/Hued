import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/glass_container.dart';

class ProjectDetailShimmer extends StatelessWidget {
  const ProjectDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ProjectHeroShimmer(),
          SizedBox(height: 24),
          ProjectStatsShimmer(),
          SizedBox(height: 32),
          ProjectStakeholderShimmer(),
          SizedBox(height: 32),
          ProjectHeaderShimmer(),
          SizedBox(height: 24),
          ProjectTaskItemShimmer(),
          SizedBox(height: 16),
          ProjectTaskItemShimmer(),
          SizedBox(height: 16),
          ProjectTaskItemShimmer(),
        ],
      ),
    );
  }
}

class ProjectHeroShimmer extends StatelessWidget {
  const ProjectHeroShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseShimmer(
      child: GlassContainer(
        height: 220,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _shimmerBox(height: 32, width: 150),
                _shimmerBox(height: 32, width: 80),
              ],
            ),
            const SizedBox(height: 24),
            _shimmerBox(height: 16, width: double.infinity),
            const SizedBox(height: 12),
            _shimmerBox(height: 16, width: 250),
            const Spacer(),
            Row(
              children: [
                const CircleAvatar(radius: 20, backgroundColor: Colors.white),
                const SizedBox(width: 12),
                _shimmerBox(height: 14, width: 100),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectStatsShimmer extends StatelessWidget {
  const ProjectStatsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseShimmer(
      child: Row(
        children: [
          Expanded(child: _shimmerBox(height: 100)),
          const SizedBox(width: 16),
          Expanded(child: _shimmerBox(height: 100)),
          const SizedBox(width: 16),
          Expanded(child: _shimmerBox(height: 100)),
        ],
      ),
    );
  }
}

class ProjectStakeholderShimmer extends StatelessWidget {
  const ProjectStakeholderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseShimmer(
      child: _shimmerBox(height: 120, width: double.infinity),
    );
  }
}

class ProjectHeaderShimmer extends StatelessWidget {
  const ProjectHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseShimmer(
      child: _shimmerBox(height: 24, width: 120),
    );
  }
}

class ProjectTaskItemShimmer extends StatelessWidget {
  const ProjectTaskItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseShimmer(
      child: _shimmerBox(height: 90, width: double.infinity),
    );
  }
}

class _BaseShimmer extends StatelessWidget {
  final Widget child;
  const _BaseShimmer({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor.withOpacity(0.3),
      highlightColor: highlightColor.withOpacity(0.3),
      child: child,
    );
  }
}

Widget _shimmerBox({required double height, double width = double.infinity}) {
  return Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
  );
}
