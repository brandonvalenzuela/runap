import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:runap/features/survey/screens/survey_screen.dart';
import 'package:runap/features/survey/bindings/survey_binding.dart';

class OnboardingController extends GetxController {
  static OnboardingController get instance => Get.find();

  /// Variables
  final pageController = PageController();
  Rx<int> currentPageIndex = 0.obs;

  /// Update Current Index when Page Scroll
  void updatePageIndicator(index) => currentPageIndex.value = index;

  /// Jump to the specific dot selected page
  void dotNavigationClick(index) {
    currentPageIndex.value = index;
    pageController.jumpTo(index);
  }

  /// Update Current Index & jump to next page
  void nextPage() {
    if (currentPageIndex.value == 2) {
      final storage = GetStorage();

      if (kDebugMode) {
        print(
            '=========================== GET STORAGE Next Button (Onboarding Complete) ===========================');
        print('Setting IsFirstTime to false');
        print('Setting NeedsSurveyCompletion to true');
      }

      storage.write('IsFirstTime', false);
      storage.write('NeedsSurveyCompletion', true);

      Get.offAll(() => const SurveyScreen(), binding: SurveyBinding(), transition: Transition.upToDown);
    } else {
      int page = currentPageIndex.value + 1;
      pageController.jumpToPage(page);
    }
  }

  /// Update Current Index & junmp to the last page
  void skipPage() {
    if (currentPageIndex.value != 2) {
      currentPageIndex.value = 2;
      pageController.jumpToPage(2);

      final storage = GetStorage();
      if (kDebugMode) {
        print(
            '=========================== GET STORAGE Skip Button (Onboarding Skipped) ===========================');
        print('Setting IsFirstTime to false');
        print('Setting NeedsSurveyCompletion to true');
      }
      storage.write('IsFirstTime', false);
      storage.write('NeedsSurveyCompletion', true);
      Get.offAll(() => const SurveyScreen(), binding: SurveyBinding(), transition: Transition.upToDown);
    }
  }
}
