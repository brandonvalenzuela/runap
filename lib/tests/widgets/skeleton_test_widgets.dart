import 'package:flutter/material.dart';
import 'package:runap/common/widgets/loaders/skeleton_loader.dart';
import 'package:shimmer/shimmer.dart';

// Esqueleto para HeaderWidget
class SkeletonHeaderWidget extends StatelessWidget {
  const SkeletonHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SkeletonWidget(height: 36, width: 200, borderRadius: 4),
          const SkeletonCircle(radius: 24),
        ],
      ),
    );
  }
}

// Esqueleto para StatsCardWidget
class SkeletonStatsCardWidget extends StatelessWidget {
  const SkeletonStatsCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(3, (_) => Column(
            children: const [
              SkeletonWidget(height: 28, width: 40, borderRadius: 4),
              SizedBox(height: 8),
              SkeletonWidget(height: 15, width: 80, borderRadius: 4),
            ],
          )),
        ),
      ),
    );
  }
}

// Esqueleto para PromoCardWidget
class SkeletonPromoCardWidget extends StatelessWidget {
  const SkeletonPromoCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const SkeletonCircle(radius: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonWidget(height: 18, width: 120),
                    SizedBox(height: 4),
                    SkeletonWidget(height: 12, width: 150),
                  ],
                ),
              ],
            ),
            const SkeletonWidget(height: 24, width: 24, borderRadius: 4), // Placeholder for chevron
          ],
        ),
      ),
    );
  }
}

// Esqueleto para DateHeaderWidget
class SkeletonDateHeaderWidget extends StatelessWidget {
  const SkeletonDateHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        children: [
          const SkeletonWidget(height: 60, width: 60, borderRadius: 16),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonWidget(height: 22, width: 80),
              SizedBox(height: 4),
              SkeletonWidget(height: 14, width: 100),
            ],
          ),
        ],
      ),
    );
  }
} 