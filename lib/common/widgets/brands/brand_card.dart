import 'package:flutter/material.dart';
import 'package:runap/common/widgets/custom_shapes/containers/ronuded_container.dart';
import 'package:runap/common/widgets/icons/t_circular_image.dart';
import 'package:runap/common/widgets/texts/t_brand_title_text_with_verified_icon.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/enums.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/helpers/helper_functions.dart';

class TBrandCard extends StatelessWidget {
  const TBrandCard({
    super.key,
    this.onTap,
    required this.showBorder,
  });

  final bool showBorder;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return GestureDetector(
      onTap: onTap,

      /// CONTAINER DESIGN
      child: TRonudedContainer(
        showBorder: showBorder,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.all(TSizes.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// -- ICON
            Flexible(
              child: TCircularImage(
                isNetworkImage: false,
                image: TImages.clothIcon,
                backgroundColor: Colors.transparent,
                overLayColor: isDark ? TColors.white : TColors.black,
              ),
            ),
            const SizedBox(width: TSizes.spaceBtwItems / 2),

            /// -- TEXT
            /// [Expanded] & COLUMN [MainAxisSize.min] IS IMPORTANT TO KEEP THE ELEMENTS IS  THE VERTICAL CENTER AND ALSO
            /// TO KEEP TEXT INSIDE THE BOUNDARIES
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TBrandTitleWithVerifiedICon(
                      title: 'Nike', brandTextSize: TextSizes.large),
                  Text(
                    '256 products with asdjkgahsd as',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
