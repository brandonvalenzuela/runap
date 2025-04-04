import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:runap/common/widgets/success_screen/success_screen.dart';
import 'package:runap/data/repositories/authentication/authentication_repository.dart';
import 'package:runap/features/authentication/screens/login/login.dart';
import 'package:runap/navigation_menu.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/text_strings.dart';
import 'package:runap/utils/popups/loaders.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  /// Send Email Whenever Verify Screen appears & Set Timer for auto redirect.
  @override
  void onInit() {
    sendEmailVerification();
    setTimerForAutoRedirect();
    super.onInit();
  }

  /// Send Email Verification Link
  sendEmailVerification() async {
    try {
      await AuthenticationRepository.instance.sendEmailVerification();
      TLoaders.successSnackBar(
          title: 'Email Sent',
          message: 'Please check your email and verify your email address');
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }

  /// Timer to automatically redirect on Email Verification
  setTimerForAutoRedirect() {
    Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        final user = FirebaseAuth.instance.currentUser;
        // Refresh user
        await user?.reload();
        if (user?.emailVerified ?? false) {
          timer.cancel();
          Get.off(() => const NavigationMenu(), transition: Transition.upToDown);
        }
      },
    );
  }

  /// Manually Check if Email is verified
  checkEmailVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    // Refresh user
    await user?.reload();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.emailVerified) {
      Get.off(() => const LoginScreen(), transition: Transition.upToDown);
    }
  }
}
