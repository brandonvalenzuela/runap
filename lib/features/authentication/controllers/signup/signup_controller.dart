import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:runap/data/repositories/authentication/authentication_repository.dart';
import 'package:runap/data/repositories/user/user_repository.dart';
import 'package:runap/features/authentication/screens/signup/verify_email.dart';
import 'package:runap/features/personalization/models/user_model.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/helpers/network_manager.dart';
import 'package:runap/utils/popups/full_screen_loader.dart';
import 'package:runap/utils/popups/loaders.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  /// Variables
  final hidePassword = true.obs; // Observed variable for password visibility
  final privacyPolicy = true.obs; // Observed variable for privacy policy
  final email = TextEditingController(); // Controller for email input
  final lastName = TextEditingController(); // Controller for last name input
  final username = TextEditingController(); // Controller for username input
  final password = TextEditingController(); // Controller for password input
  final firstName = TextEditingController(); // Controller for first name input
  final phoneNumber =
      TextEditingController(); // Controller for phone number input
  GlobalKey<FormState> signupFormKey =
      GlobalKey<FormState>(); // Form key for form validation

  /// -- SIGNUP
  void signup() async {
    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog(
        'We are processing your information...',
        TImages.docerAnimation,
      );

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        // Remove Loader
        TFullScreenLoader.stopLoading();
        return;
      }

      // Form Validation
      if (!signupFormKey.currentState!.validate()) {
        // Remove Loader
        TFullScreenLoader.stopLoading();
        return;
      }

      // Privacy Policy Check
      if (!privacyPolicy.value) {
        TLoaders.warningSnackBar(
          title: 'Accept Privacy Policy',
          message:
              'In order to create account, you must have to read and accept the Privacy Policy & Terms of Use.',
        );
        return;
      }

      // Register user in the firebase Authentication & Save user data in the Firebase
      final userCredential = await AuthenticationRepository.instance
          .registerWithEmailAndPassword(
              email.text.trim(), password.text.trim());

      // Verify if user was created successfully
      if (userCredential.user == null) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: 'Oh Snap!',
          message: 'Account creation failed. Please try again.',
        );
        return;
      }

      // Save Authenticated user data in the Firebase Firestore
      final newUser = UserModel(
        id: userCredential.user!.uid,
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        username: username.text.trim(),
        email: email.text.trim(),
        phoneNumber: phoneNumber.text.trim(),
        porfilePicture: '',
      );

      final userRepository = Get.put(UserRepository());
      await userRepository.saveUserRecord(newUser);

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Show Success Message
      TLoaders.successSnackBar(
        title: 'Congratulations!',
        message:
            'Your account has been created successfully! Verify email to continue .',
      );

      // Move to Verify Email Screen
      Get.to(() => VerifyEmailScreen(email: email.text.trim()));
    } catch (e) {
      // Remove Loader
      TFullScreenLoader.stopLoading();
      // Show some Generic Error to the User
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }
}
