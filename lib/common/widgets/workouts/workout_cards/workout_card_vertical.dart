import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/common/styles/shadows.dart';
import 'package:runap/common/widgets/custom_shapes/containers/ronuded_container.dart';
import 'package:runap/common/widgets/icons/t_circular_icon.dart';
import 'package:runap/common/widgets/images/t_rounded_image.dart';
import 'package:runap/common/widgets/texts/t_brand_title_text_with_verified_icon.dart';
import 'package:runap/common/widgets/texts/workout_subtitle_text.dart';
import 'package:runap/common/widgets/texts/workout_title_text.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/helpers/helper_functions.dart';

class TWorkoutCardVertical extends StatelessWidget {
  const TWorkoutCardVertical({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    /// Container with side padding, color, edges, radius and shadow.
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          boxShadow: [TShadowStyle.verticalProductShadow],
          borderRadius: BorderRadius.circular(TSizes.workoutImageRadius),
          color: THelperFunctions.isDarkMode(context)
              ? TColors.darkerGrey
              : TColors.white,
        ),
        child: Column(
          children: [
            /// THUMBNAIL, WISHLIST BUTTON, DISCOUNT TAG
            TRonudedContainer(
              height: 100, // 180 tutorial
              padding: const EdgeInsets.all(TSizes.xs),
              backgroundColor: dark ? TColors.dark : TColors.light,
              child: Stack(
                children: [
                  /// THUMBNAIL IMAGE
                  const TRoundedImage(
                    imageUrl: TImages.runningWorkout1,
                    applyImageRadius: true,
                  ),

                  /// -- SALE TAG
                  Positioned(
                    top: 12,
                    child: TRonudedContainer(
                      radius: TSizes.md,
                      backgroundColor: TColors.secondaryColor.withAlpha(204),
                      padding: const EdgeInsets.symmetric(
                          horizontal: TSizes.sm, vertical: TSizes.xs),
                      child: Text(
                        '25%',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge!
                            .apply(color: TColors.black),
                      ),
                    ),
                  ),

                  /// FAV ICON BUTTON
                  Positioned(
                    top: 0,
                    right: 0,
                    child: const TCircularIcon(
                      icon: Iconsax.heart5,
                      color: Colors.red,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),

            /// -- DETAILS
            Padding(
              padding: const EdgeInsets.only(left: TSizes.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TWorckoutTitleText(
                    title: 'Green Nike Air Shoes',
                    smallSize: true,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems / 2),
                  TBrandTitleWithVerifiedICon(title: 'Nike'),
                ],
              ),
            ),

            /// SPACER
            const Spacer(),

            /// PRICE ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// PRICE
                Padding(
                  padding: const EdgeInsets.only(left: TSizes.md),
                  child: const TWorkoutSubtitleText(price: '35.0'),
                ),

                /// ADD CAR
                Container(
                  decoration: const BoxDecoration(
                    color: TColors.dark,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(TSizes.cardRadiusMd),
                      bottomRight: Radius.circular(TSizes.workoutImageRadius),
                    ),
                  ),
                  child: const SizedBox(
                    width: TSizes.iconLg * 1.2,
                    height: TSizes.iconLg * 1.2,
                    child:
                        Center(child: Icon(Iconsax.add, color: TColors.white)),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
