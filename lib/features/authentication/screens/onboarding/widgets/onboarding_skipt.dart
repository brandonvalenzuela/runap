import 'package:flutter/material.dart';
import 'package:runap/features/authentication/controllers/onboarding/onboarding_controller.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/device/device_utility.dart';

class OnBoardingSkip extends StatelessWidget {
  const OnBoardingSkip({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: TDiviceUtility.getAppBarHeight(),
        right: TSizes.defaultSpace,
        child: TextButton(
          onPressed: () => OnboardingController.instance.skipPage(),
          child: const Text('Skip'),
        ));
  }
}
