import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:runap/data/repositories/authentication/authentication_repository.dart';
import 'package:runap/navigation_menu.dart';
import 'package:runap/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:runap/utils/helpers/app_snackbar.dart';
import 'package:runap/utils/constants/text_strings.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  /// Envía el email de verificación y configura el temporizador para redirección automática.
  @override
  void onInit() {
    sendEmailVerification();
    setTimerForAutoRedirect();
    super.onInit();
  }

  /// Envía el enlace de verificación de email
  Future<void> sendEmailVerification({BuildContext? context}) async {
    try {
      await AuthenticationRepository.instance.sendEmailVerification();
      if (context != null) {
        AppSnackBar.show(
          context,
          message: TTexts.checkEmailToVerify,
          type: AppSnackBarType.success,
          title: TTexts.emailSent,
        );
      } else {
        TLoaders.successSnackBar(
          title: TTexts.emailSent,
          message: TTexts.checkEmailToVerify,
        );
      }
    } catch (e) {
      if (context != null) {
        AppSnackBar.show(
          context,
          message: e.toString(),
          type: AppSnackBarType.error,
          title: TTexts.ohSnap,
        );
      } else {
        TLoaders.errorSnackBar(title: TTexts.ohSnap, message: e.toString());
      }
    }
  }

  /// Temporizador para redirigir automáticamente tras la verificación
  void setTimerForAutoRedirect() {
    Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        final user = FirebaseAuth.instance.currentUser;
        await user?.reload();
        if (user?.emailVerified ?? false) {
          timer.cancel();
          Get.offAll(
            () => const NavigationMenu(),
            transition: Transition.upToDown,
          );
        }
      },
    );
  }

  /// Verifica manualmente si el email está verificado
  Future<void> checkEmailVerificationStatus({BuildContext? context}) async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.emailVerified) {
      Get.offAll(() => const NavigationMenu(), transition: Transition.upToDown);
    } else {
      if (context != null) {
        AppSnackBar.show(
          context,
          message: TTexts.emailNotVerified,
          type: AppSnackBarType.warning,
          title: TTexts.verificationPending,
        );
      } else {
        TLoaders.warningSnackBar(
          title: TTexts.verificationPending,
          message: TTexts.emailNotVerified,
        );
      }
    }
  }
}
