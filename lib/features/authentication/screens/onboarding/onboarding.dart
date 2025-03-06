import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/features/authentication/controllers.onboarding/onboarding_controller.dart';
import 'package:runap/features/authentication/screens/onboarding/widgets/on_boarding_dot_navigation.dart';
import 'package:runap/features/authentication/screens/onboarding/widgets/on_boarding_next_button.dart';
import 'package:runap/features/authentication/screens/onboarding/widgets/onboarding_page.dart';
import 'package:runap/features/authentication/screens/onboarding/widgets/onboarding_skipt.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/text_strings.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    /// OnBoarding Controller to handle Logic
    final controller = Get.put(OnboardingController());

    return Scaffold(
        body: Stack(
      children: [
        /// Horizontal scrollable Pages
        PageView(
          controller: controller.pageController,
          onPageChanged: controller.updatePageIndicator,
          children: const [
            OnBoardingPage(
              image: TImages.onboarding1,
              title: TTexts.onBoardingTitle1,
              subtitle: TTexts.onBoardingSubtitle1,
            ),
            OnBoardingPage(
              image: TImages.onboarding2,
              title: TTexts.onBoardingTitle2,
              subtitle: TTexts.onBoardingSubtitle2,
            ),
            OnBoardingPage(
              image: TImages.onboarding3,
              title: TTexts.onBoardingTitle3,
              subtitle: TTexts.onBoardingSubtitle3,
            )
          ],
        ),

        /// Skip Button
        const OnBoardingSkip(),

        /// Dots Navigation SmoothPageIndicator
        const OnBoardingDotNavigation(),

        /// Circular button to go to the next page
        const OnBoardingNextButton(),
      ],
    ));
  }
}
