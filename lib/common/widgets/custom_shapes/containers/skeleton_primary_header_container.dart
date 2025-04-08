import 'package:flutter/material.dart';
import 'package:runap/common/widgets/custom_shapes/containers/circular_container.dart';
import 'package:runap/common/widgets/loaders/skeleton_loader.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonPrimaryHeader extends StatelessWidget {
  const SkeletonPrimaryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
       baseColor: TColors.primaryColor.withAlpha(128),
       highlightColor: TColors.primaryColor.withAlpha(204),
      child: Container(
        color: TColors.primaryColor, // Fondo base
        padding: const EdgeInsets.all(0),
        child: SizedBox(
          height: 250, // Altura similar al original
          child: Stack(
            children: [
              Positioned(
                  top: -150,
                  right: -250,
                  child: TCircleContainer(backgroundColor: TColors.textWhite.withAlpha(26))),
              Positioned(
                  top: 100,
                  right: -300,
                  child: TCircleContainer(backgroundColor: TColors.textWhite.withAlpha(26))),
              // Contenido del esqueleto
              Column(
                children: [
                  // AppBar Skeleton
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: const SkeletonWidget(height: 24, width: 150),
                  ),
                  // User Profile Tile Skeleton (ya se maneja internamente, pero podemos poner un placeholder)
                  const ListTile(
                     leading: SkeletonCircle(radius: 25),
                     title: SkeletonWidget(height: 16, width: 150),
                     subtitle: SkeletonWidget(height: 12, width: 200),
                     trailing: SkeletonWidget(height: 24, width: 24),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
} 