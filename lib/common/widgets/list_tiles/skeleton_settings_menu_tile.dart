import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/common/widgets/loaders/skeleton_loader.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonSettingsMenuTile extends StatelessWidget {
  const SkeletonSettingsMenuTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListTile(
        leading: const SkeletonCircle(radius: 16),
        title: const SkeletonWidget(height: 16, width: 150),
        subtitle: const SkeletonWidget(height: 12, width: 200),
        trailing: const SkeletonWidget(height: 24, width: 40), // Placeholder for Switch or Icon
      ),
    );
  }
} 