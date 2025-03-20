import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:runap/common/styles/spacing_styles.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/constants/text_strings.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen(
      {super.key,
      required this.image,
      required this.title,
      required this.subtitle,
      required this.onPressed});

  final String image, title, subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: TSpacingStyle.paddingWithAppBarHeight * 2,
        child: Column(
          children: [
            /// Image
            Lottie.asset(
              image,
              width: MediaQuery.of(context).size.width * 0.6,
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            /// Title & SubTitle
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            /// BUTTONS
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: onPressed, child: const Text(TTexts.tContinue)),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
          ],
        ),
      ),
    );
  }
}
