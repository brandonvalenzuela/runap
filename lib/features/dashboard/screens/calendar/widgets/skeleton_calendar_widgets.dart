import 'package:flutter/material.dart';
import 'package:runap/common/widgets/loaders/skeleton_loader.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:shimmer/shimmer.dart';

// Esqueleto para DateHeader
class SkeletonDateHeader extends StatelessWidget {
  const SkeletonDateHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
       baseColor: Colors.white.withAlpha(100), // Adaptado al fondo gradiente
       highlightColor: Colors.white.withAlpha(150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: TSizes.spaceBtwItems),
          SkeletonWidget(height: 28, width: 120, borderRadius: 4),
          SizedBox(height: 4),
          SkeletonWidget(height: 14, width: 180, borderRadius: 4),
        ],
      ),
    );
  }
}

// Esqueleto para WeekdayTracker
class SkeletonWeekdayTracker extends StatelessWidget {
  const SkeletonWeekdayTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
       baseColor: Colors.white.withAlpha(100),
       highlightColor: Colors.white.withAlpha(150),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (_) => const SkeletonWidget(height: 44, width: 44, borderRadius: 12)),
        ),
      ),
    );
  }
}

// Esqueleto para FavoritesCard
class SkeletonFavoritesCard extends StatelessWidget {
  const SkeletonFavoritesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const SkeletonWidget(height: 20, width: 100),
                const SizedBox(height: 8),
                const SkeletonWidget(height: 14, width: 250),
                const SizedBox(height: 24),
                const SkeletonWidget(height: 54, width: double.infinity, borderRadius: 12),
              ],
            ),
          ),
          const Positioned(
            top: -30,
            child: SkeletonCircle(radius: 24),
          ),
        ],
      ),
    );
  }
}

// Esqueleto para ChallengeCard
class SkeletonChallengeCard extends StatelessWidget {
  const SkeletonChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white, // Usar blanco base para shimmer
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SkeletonWidget(height: 16, width: 150),
                const SkeletonWidget(height: 32, width: 32, borderRadius: 8),
              ],
            ),
            const SizedBox(height: 24),
            const SkeletonWidget(height: 18, width: 80),
            const SizedBox(height: 4),
            const SkeletonWidget(height: 24, width: 150),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: const SkeletonWidget(height: 80, width: 100, borderRadius: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// Esqueleto para QuoteCard
class SkeletonQuoteCard extends StatelessWidget {
  const SkeletonQuoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
       baseColor: Colors.grey[300]!,
       highlightColor: Colors.grey[100]!,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
         child: Stack(
          children: [
             Center(
                child: const SkeletonWidget(height: 40, width: 280, borderRadius: 20),
             ),
              Positioned(
                bottom: 10,
                right: 10,
                child: const SkeletonWidget(height: 32, width: 32, borderRadius: 8),
             ),
          ],
         )
      ),
    );
  }
} 