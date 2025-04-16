import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:runap/features/survey/screens/survey_screen.dart';
import 'package:runap/features/survey/bindings/survey_binding.dart';

class OnboardingController extends GetxController {
  static OnboardingController get instance => Get.find();

  /// Controlador de páginas para el onboarding
  final PageController pageController = PageController();
  final RxInt _currentPageIndex = 0.obs;

  int get currentPageIndex => _currentPageIndex.value;
  set currentPageIndex(int value) => _currentPageIndex.value = value;

  /// Actualiza el índice actual cuando se navega entre páginas
  void updatePageIndicator(int index) => currentPageIndex = index;

  /// Navega a la página seleccionada por el usuario
  void dotNavigationClick(int index) {
    currentPageIndex = index;
    pageController.jumpToPage(index);
  }

  /// Avanza a la siguiente página o finaliza el onboarding
  void nextPage() {
    if (currentPageIndex == 2) {
      final storage = GetStorage();

      if (kDebugMode) {
        print('=========================== GET STORAGE Next Button (Onboarding Complete) ===========================');
        print('Setting IsFirstTime to false');
        print('Setting NeedsSurveyCompletion to true');
      }

      storage.write('IsFirstTime', false);
      storage.write('NeedsSurveyCompletion', true);

      Get.offAll(() => const SurveyScreen(), binding: SurveyBinding(), transition: Transition.upToDown);
    } else {
      int page = currentPageIndex + 1;
      pageController.jumpToPage(page);
    }
  }

  /// Salta directamente a la última página y finaliza el onboarding
  void skipPage() {
    if (currentPageIndex != 2) {
      currentPageIndex = 2;
      pageController.jumpToPage(2);

      final storage = GetStorage();
      if (kDebugMode) {
        print('=========================== GET STORAGE Skip Button (Onboarding Skipped) ===========================');
        print('Setting IsFirstTime to false');
        print('Setting NeedsSurveyCompletion to true');
      }
      storage.write('IsFirstTime', false);
      storage.write('NeedsSurveyCompletion', true);
      Get.offAll(() => const SurveyScreen(), binding: SurveyBinding(), transition: Transition.upToDown);
    }
  }
}
