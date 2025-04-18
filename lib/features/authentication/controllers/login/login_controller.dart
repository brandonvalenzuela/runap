import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:runap/data/repositories/authentication/authentication_repository.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/helpers/network_manager.dart';
import 'package:runap/utils/popups/full_screen_loader.dart';
import 'package:runap/utils/popups/loaders.dart';
import 'package:runap/utils/helpers/app_snackbar.dart';
import 'package:runap/utils/constants/text_strings.dart';

class LoginController extends GetxController {
  final GetStorage _localStorage = GetStorage();
  final email = TextEditingController();
  final password = TextEditingController();
  final RxBool _hidePassword = true.obs;
  final RxBool _rememberMe = false.obs;
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  // Getters y setters controlados
  bool get hidePassword => _hidePassword.value;
  set hidePassword(bool value) => _hidePassword.value = value;
  bool get rememberMe => _rememberMe.value;
  set rememberMe(bool value) => _rememberMe.value = value;

  @override
  void onInit() {
    super.onInit();
    // Recuperar el estado de rememberMe
    rememberMe = _localStorage.read('REMEMBER_ME_STATUS') ?? false;
    // Solo cargar credenciales si rememberMe está activado
    if (rememberMe) {
      email.text = _localStorage.read('REMEMBER_ME_EMAIL') ?? '';
      password.text = _localStorage.read('REMEMBER_ME_PASSWORD') ?? '';
    }
  }

  /// -- Email and Password SignIn
  Future<void> emailAndPasswordSignIn({BuildContext? context}) async {
    try {
      TFullScreenLoader.openLoadingDialog(
        'Loggin you in...',
        TImages.docerAnimation,
      );

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        if (context != null) {
          AppSnackBar.show(
            context,
            message: TTexts.noInternet,
            type: AppSnackBarType.error,
            title: TTexts.networkError,
          );
        } else {
          TLoaders.errorSnackBar(
            title: TTexts.networkError,
            message: TTexts.noInternet,
          );
        }
        return;
      }

      if (loginFormKey.currentState == null ||
          !loginFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        if (context != null) {
          AppSnackBar.show(
            context,
            message: TTexts.checkInput,
            type: AppSnackBarType.error,
            title: TTexts.error,
          );
        } else {
          TLoaders.errorSnackBar(
            title: TTexts.error,
            message: TTexts.checkInput,
          );
        }
        return;
      }

      _localStorage.write('REMEMBER_ME_STATUS', rememberMe);
      if (rememberMe) {
        _localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
        _localStorage.write('REMEMBER_ME_PASSWORD', password.text.trim());
      } else {
        _localStorage.remove('REMEMBER_ME_EMAIL');
        _localStorage.remove('REMEMBER_ME_PASSWORD');
      }

      await AuthenticationRepository.instance.loginWithEmailAndPassword(
        email.text.trim(),
        password.text.trim(),
      );
      // La navegación se maneja en AuthenticationRepository
    } catch (e) {
      TFullScreenLoader.stopLoading();
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
}
