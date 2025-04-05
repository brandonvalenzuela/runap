import 'package:flutter/material.dart';
import 'package:runap/common/widgets/loaders/skeleton_loader.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonEntryCardWidget extends StatelessWidget {
  const SkeletonEntryCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonCircle(radius: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonWidget(height: 16, width: 150),
                    const SizedBox(height: 4),
                    const SkeletonWidget(height: 12, width: 80),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonWidget(height: 16, width: double.infinity),
            const SizedBox(height: 4),
            const SkeletonWidget(height: 16, width: 200),
            const SizedBox(height: 12),
            Row(
              children: [
                const SkeletonWidget(height: 24, width: 60, borderRadius: 16),
                const SizedBox(width: 8),
                const SkeletonWidget(height: 24, width: 60, borderRadius: 16),
              ],
            )
          ],
        ),
      ),
    );
  }
} 