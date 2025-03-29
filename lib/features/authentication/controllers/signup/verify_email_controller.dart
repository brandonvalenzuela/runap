import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:runap/common/widgets/success_screen/success_screen.dart';
import 'package:runap/data/repositories/authentication/authentication_repository.dart';
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

  /// Send Email Verification Link.
  sendEmailVerification() async {
    try {
      await AuthenticationRepository.instace.sendEmailVerification();
      TLoaders.successSnackBar(
          title: 'Email send',
          message: 'Please check your email to verify your account.');
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh snap!', message: e.toString());
    }
  }

  /// Timer to Automatically redirect on Email Verification.
  setTimerForAutoRedirect() async {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      await FirebaseAuth.instance.currentUser!.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user?.emailVerified ?? false) {
        timer.cancel();
        Get.off(
          () => SuccessScreen(
            image: TImages.verifyIllustration,
            title: TTexts.yourAccountCreatedTitle,
            subtitle: TTexts.yourAccountCreatedSubTitle,
            onPressed: () => AuthenticationRepository.instace.screenRedirect(),
          ),
        );
      }
    });
  }

  /// Manually Check if Email Verified.
  checkEmailVerificationState() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.emailVerified) {
      Get.off(
        () => SuccessScreen(
          image: TImages.staticSuccessIllustration,
          title: TTexts.yourAccountCreatedTitle,
          subtitle: TTexts.yourAccountCreatedSubTitle,
          onPressed: () => AuthenticationRepository.instace.screenRedirect(),
        ),
      );
    }
  }
}
