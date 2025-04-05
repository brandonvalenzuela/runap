import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:runap/data/repositories/authentication/authentication_repository.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/helpers/network_manager.dart';
import 'package:runap/utils/popups/full_screen_loader.dart';
import 'package:runap/utils/popups/loaders.dart';

class LoginController extends GetxController {
  // Variables
  final localStorage = GetStorage();
  final email = TextEditingController();
  final password = TextEditingController();
  final hidePassword = true.obs;
  final rememberMe = false.obs;
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    // Recuperar el estado de rememberMe
    rememberMe.value = localStorage.read('REMEMBER_ME_STATUS') ?? false;
    
    // Solo cargar credenciales si rememberMe está activado
    if (rememberMe.value) {
      email.text = localStorage.read('REMEMBER_ME_EMAIL') ?? '';
      password.text = localStorage.read('REMEMBER_ME_PASSWORD') ?? '';
    }
  }

  /// -- Email and Password SignIn
  Future<void> emailAndPasswordSignIn() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog(
          'Loggin you in...', TImages.docerAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Form Validation
      if (loginFormKey.currentState == null ||
          !loginFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Please check your input and try again.',
        );
        return;
      }

      // Guardar el estado de Remember Me
      localStorage.write('REMEMBER_ME_STATUS', rememberMe.value);
      
      // Save Data if Remember Me is selected
      if (rememberMe.value) {
        localStorage.write('REMEMBER_ME_EMAIL', email.text.trim());
        localStorage.write('REMEMBER_ME_PASSWORD', password.text.trim());
      } else {
        // Eliminar datos guardados si Remember Me no está seleccionado
        localStorage.remove('REMEMBER_ME_EMAIL');
        localStorage.remove('REMEMBER_ME_PASSWORD');
      }

      // Login user using EMail & Password Authentication
      final userCredentials = await AuthenticationRepository.instance
          .loginWithEmailAndPassword(email.text.trim(), password.text.trim());

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Redirect
      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Oh Snap', message: e.toString());
    }
  }
}
