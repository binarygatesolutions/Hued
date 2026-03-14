import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'approval_request_card.dart';

class DashboardHeaderShimmer extends StatelessWidget {
  const DashboardHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseShimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(height: 32, width: 200),
                  const SizedBox(height: 6),
                  _shimmerBox(height: 15, width: 250),
                ],
              ),
            ),
            const CircleAvatar(radius: 28, backgroundColor: Colors.white),
          ],
        ),
      ),
    );
  }
}

class DashboardStatsShimmer extends StatelessWidget {
  const DashboardStatsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseShimmer(
      child: Container(
        height: 170,
        margin: const EdgeInsets.only(bottom: 32),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: List.generate(3, (index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _shimmerBox(height: double.infinity, borderRadius: 32),
            ),
          )),
        ),
      ),
    );
  }
}

class DashboardApprovalsShimmer extends StatelessWidget {
  const DashboardApprovalsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _shimmerBox(height: 24, width: 150),
          ),
          const SizedBox(height: 17),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: List.generate(2, (index) => const ApprovalRequestCardShimmer(
                isCompact: false,
                width: 280,
              )),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class DashboardProjectGridShimmer extends StatelessWidget {
  const DashboardProjectGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            mainAxisExtent: 220,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => _shimmerBox(height: 220),
        ),
      ),
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

Widget _shimmerBox({
  required double height,
  double width = double.infinity,
  double borderRadius = 16,
}) {
  return Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );
}
