import 'package:flutter/material.dart';
import 'package:runap/common/widgets/loaders/skeleton_loader.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:shimmer/shimmer.dart';

/// Header widget to display Date information for session groups
class DashboardDateHeader extends StatelessWidget {
  final String day;
  final String month;
  final String weekday;
  final String label; // e.g., "Hoy", "Mañana", or empty

  const DashboardDateHeader({
    super.key,
    required this.day,
    required this.month,
    required this.weekday,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final bool isToday = label == 'Hoy';
    final bool isTomorrow = label == 'Mañana';

    return Padding(
      padding: const EdgeInsets.only(top: TSizes.spaceBtwSections * 0.8, bottom: TSizes.spaceBtwItems),
      child: Row(
        children: [
          Container(
            width: 60, // Slightly smaller
            height: 60,
            decoration: BoxDecoration(
              color: isToday ? TColors.primaryColor.withAlpha(26) : TColors.white,//.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: isToday ? Border.all(color: TColors.primaryColor, width: 1.5) : null,
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withAlpha(13),
                   blurRadius: 5,
                   offset: const Offset(0, 2),
                 ),
               ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isToday ? TColors.primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                        height: 1.1
                      ),
                ),
                Text(
                  month.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isToday ? TColors.primaryColor.withAlpha(204) : Theme.of(context).textTheme.bodySmall?.color?.withAlpha(153),
                        height: 1.1
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.isNotEmpty ? label : weekday, // Show label if available, otherwise weekday
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isToday ? TColors.primaryColor : Theme.of(context).textTheme.titleMedium?.color,
                    ),
              ),
              // Show weekday as subtitle if label is shown
              if (label.isNotEmpty)
                Text(
                  weekday,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).textTheme.labelMedium?.color?.withAlpha(179),
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton Loader for the DashboardDateHeader
class SkeletonDashboardDateHeader extends StatelessWidget {
  const SkeletonDashboardDateHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.only(top: TSizes.spaceBtwSections * 0.8, bottom: TSizes.spaceBtwItems),
        child: Row(
          children: [
            const SkeletonWidget(height: 55, width: 55, borderRadius: 16),
            const SizedBox(width: TSizes.spaceBtwItems),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonWidget(height: 18, width: 100),
                SizedBox(height: TSizes.xs),
                SkeletonWidget(height: 14, width: 70),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 