import 'package:flutter/material.dart';
import 'package:runap/common/widgets/brands/brand_show_case.dart';
import 'package:runap/common/widgets/layouts/grid_layout.dart';
import 'package:runap/common/widgets/texts/sections_heading.dart';
import 'package:runap/common/widgets/workouts/workout_cards/workout_card_vertical.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';

class TCategoryTab extends StatelessWidget {
  const TCategoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              /// -- BRANDS
              TBrandShowcase(images: [
                TImages.jacketIcon,
                TImages.shirtIcon,
                TImages.tshirtIcon
              ]),
              TBrandShowcase(images: [
                TImages.jacketIcon,
                TImages.shirtIcon,
                TImages.tshirtIcon
              ]),

              const SizedBox(height: TSizes.spaceBtwItems),

              /// -- PRODUCTS
              TSectionHeading(title: 'You may also like', onPressed: () {}),
              const SizedBox(height: TSizes.spaceBtwItems),

              TGridLayout(
                  itemCount: 4,
                  itemBuilder: (_, index) => const TWorkoutCardVertical()),

              const SizedBox(height: TSizes.spaceBtwSections),
            ],
          ),
        )
      ],
    );
  }
}
