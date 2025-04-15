import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // Import GetStorage
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
  final phoneNumber = TextEditingController(); // Controller for phone number input (solo dígitos)
  String completePhoneNumber = ''; // Variable para almacenar el número completo con código de país
  GlobalKey<FormState> signupFormKey =
      GlobalKey<FormState>(); // Form key for form validation

  // Variable para guardar los datos de la encuesta
  Map<String, dynamic>? surveyData;
  final storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    // Leer datos de la encuesta al inicializar el controlador
    loadSurveyData();
  }

  void loadSurveyData() {
    surveyData = storage.read<Map<String, dynamic>>('pendingSurveyAnswers');
    print("Survey data loaded in SignUpController: $surveyData"); // Debug
    // No pre-rellenamos los controllers aquí, eso se manejará en la UI
  }

  // Helper para saber si un campo debe mostrarse en la UI
  bool shouldShowField(String fieldName) {
    // Muestra el campo si no hay datos de encuesta o si falta específicamente ese campo
    return surveyData == null || surveyData![fieldName] == null || surveyData![fieldName].toString().isEmpty;
  }


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
        TFullScreenLoader.stopLoading();
        return;
      }

      // Form Validation
      // Solo validamos si el formulario existe (puede que no si todos los campos vienen de la encuesta)
      if (signupFormKey.currentState != null && !signupFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Guardar el formulario para asegurar que onSaved sea llamado (si existe)
      signupFormKey.currentState?.save();

      // Privacy Policy Check
      if (!privacyPolicy.value) {
        TLoaders.warningSnackBar(
          title: 'Accept Privacy Policy',
          message:
              'In order to create account, you must have to read and accept the Privacy Policy & Terms of Use.',
        );
         TFullScreenLoader.stopLoading(); // Detener loader si falla la política
        return;
      }

      // --- Obtener datos --- 
      // Datos del formulario
      final emailFromForm = email.text.trim();
      final passwordFromForm = password.text.trim();
      final usernameFromForm = username.text.trim();
      final phoneFromForm = completePhoneNumber.isNotEmpty ? completePhoneNumber : phoneNumber.text.trim();
      
      // Datos de la encuesta (si existen)
      final firstNameFromSurvey = surveyData?['firstName'] as String? ?? '';
      final lastNameFromSurvey = surveyData?['lastName'] as String? ?? '';
      // Recuperar los nuevos datos de la encuesta
      final genderFromSurvey = surveyData?['gender'] as String?;
      final ageFromSurvey = surveyData?['age'] as String?;
      final heightFromSurvey = surveyData?['height'] as String?;
      final currentWeightFromSurvey = surveyData?['currentWeight'] as String?;
      final idealWeightFromSurvey = surveyData?['idealWeight'] as String?;
      final mainGoalFromSurvey = surveyData?['mainGoal'] as String?;
      final paceFromSurvey = surveyData?['pace'] as String?;
      // Recuperar otros si los añades al modelo (howHeard, loseWeightReasons, etc.)

      // --- Validar datos combinados --- 
      // Asegurarse de tener email y contraseña, ya sea del form o (hipotéticamente) de la encuesta
      if (emailFromForm.isEmpty) {
         TLoaders.errorSnackBar(title: 'Error', message: 'Email is required.');
         TFullScreenLoader.stopLoading();
         return;
      }
       if (passwordFromForm.isEmpty) {
         TLoaders.errorSnackBar(title: 'Error', message: 'Password is required.');
         TFullScreenLoader.stopLoading();
         return;
      }
       // Podrías añadir validación para firstName/lastName aquí si son obligatorios
       if (firstNameFromSurvey.isEmpty && shouldShowField('firstName')) {
         // Esto no debería pasar si la validación del form funciona, pero por si acaso
         TLoaders.errorSnackBar(title: 'Error', message: 'First Name is required.');
         TFullScreenLoader.stopLoading();
         return;
       }
        if (lastNameFromSurvey.isEmpty && shouldShowField('lastName')) {
         TLoaders.errorSnackBar(title: 'Error', message: 'Last Name is required.');
         TFullScreenLoader.stopLoading();
         return;
       }
       if (genderFromSurvey == null || genderFromSurvey.isEmpty) {
        // Considerar si el género es obligatorio
       }
       if (ageFromSurvey == null || ageFromSurvey.isEmpty) {
         TLoaders.errorSnackBar(title: 'Error', message: 'Age from survey is missing.');
         TFullScreenLoader.stopLoading();
         return;
       }
       // Añadir validaciones similares para height, currentWeight si son obligatorios

      // Register user in the firebase Authentication & Save user data in the Firebase
      final userCredential = await AuthenticationRepository.instance
          .registerWithEmailAndPassword(
              emailFromForm, passwordFromForm); // Usar datos del formulario para Auth

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
        // Datos de encuesta o formulario (para nombre/apellido, encuesta tiene prioridad)
        firstName: firstNameFromSurvey.isNotEmpty ? firstNameFromSurvey : firstName.text.trim(),
        lastName: lastNameFromSurvey.isNotEmpty ? lastNameFromSurvey : lastName.text.trim(),
        // Datos de formulario
        username: usernameFromForm,
        email: emailFromForm,
        phoneNumber: phoneFromForm,
        porfilePicture: '', // Dejar vacío inicialmente
        // Nuevos datos directamente de la encuesta
        gender: genderFromSurvey,
        age: ageFromSurvey,
        height: heightFromSurvey,
        currentWeight: currentWeightFromSurvey,
        idealWeight: idealWeightFromSurvey,
        mainGoal: mainGoalFromSurvey,
        pace: paceFromSurvey,
      );

      final userRepository = Get.put(UserRepository());
      await userRepository.saveUserRecord(newUser);

      // --- Limpieza --- 
      // Eliminar los datos de la encuesta de storage después de usarlos exitosamente
      storage.remove('pendingSurveyAnswers');
      print("Pending survey answers removed from storage."); // Debug

      // Remove Loader
      TFullScreenLoader.stopLoading();

      // Show Success Message
      TLoaders.successSnackBar(
        title: 'Congratulations!',
        message:
            'Your account has been created successfully! Verify email to continue .',
      );

      // Move to Verify Email Screen
      Get.to(() => VerifyEmailScreen(email: email.text.trim()), transition: Transition.upToDown);
    } catch (e) {
      // Remove Loader
      TFullScreenLoader.stopLoading();
      // Show some Generic Error to the User
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    }
  }
}
