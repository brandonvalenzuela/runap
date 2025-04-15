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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Importar para PlatformException
import 'package:runap/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:runap/utils/exceptions/firebase_exceptions.dart';
import 'package:runap/utils/exceptions/format_exceptions.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  /// Variables
  final hidePassword = true.obs; // Observed variable for password visibility
  final privacyPolicy = true.obs; // Observed variable for privacy policy
  final email = TextEditingController(); // Controller for email input
  final username = TextEditingController(); // Controller for username input
  final password = TextEditingController(); // Controller for password input
  final firstName = TextEditingController(); // Controller for first name input
  final phoneNumber = TextEditingController(); // Controller for phone number input (solo dígitos)
  String completePhoneNumber = ''; // Variable para almacenar el número completo con código de país
  GlobalKey<FormState> signupFormKey =
      GlobalKey<FormState>(); // Form key for form validation
  
  bool _firstNamePreFilled = false;

  // Variable para guardar los datos de la encuesta leídos de storage
  Map<String, dynamic>? surveyData;
  final storage = GetStorage(); // Instancia de GetStorage

  @override
  void onInit() {
    super.onInit();
    // Leer datos de la encuesta al inicializar
    loadSurveyData();
    // Ya no intentamos obtener nombre/apellido de los argumentos aquí
  }

  void loadSurveyData() {
    surveyData = storage.read<Map<String, dynamic>>('pendingSurveyAnswers');
    print("Datos encuesta leídos en SignUpController: $surveyData"); // Debug
    // Pre-rellenar controllers SI hay datos de encuesta
    if (surveyData != null) {
      if (surveyData!.containsKey('firstName') && surveyData!['firstName'] != null) {
        firstName.text = surveyData!['firstName'];
        _firstNamePreFilled = true;
      }
    }
  }

  // Método para determinar si mostrar el campo (usado en el UI)
  bool shouldShowField(String fieldName) {
    // Mostrar el campo si NO fue pre-rellenado desde la encuesta
    switch (fieldName) {
      case 'firstName':
        return !_firstNamePreFilled;
      default:
        return true; // Mostrar otros campos por defecto
    }
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

      // Form Validation (Solo si hay campos visibles que validar)
      if (signupFormKey.currentState != null && !signupFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Guardar formulario (si existe)
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

      // --- Recolectar datos --- 
      // Datos del formulario visible
      final emailFromForm = email.text.trim();
      final passwordFromForm = password.text.trim();
      final usernameFromForm = username.text.trim();
      final phoneFromForm = completePhoneNumber.isNotEmpty ? completePhoneNumber : phoneNumber.text.trim();
      
      // Datos de la encuesta (obligatorios ahora)
      final firstNameFromSurvey = surveyData?['firstName'] as String? ?? '';
      final lastNameFromSurvey = surveyData?['lastName'] as String? ?? '';
      final genderFromSurvey = surveyData?['gender'] as String?;
      final ageFromSurvey = surveyData?['age'] as String?;
      final heightFromSurvey = surveyData?['height'] as String?;
      final currentWeightFromSurvey = surveyData?['currentWeight'] as String?;
      final idealWeightFromSurvey = surveyData?['idealWeight'] as String?;
      final mainGoalFromSurvey = surveyData?['mainGoal'] as String?;
      final paceFromSurvey = surveyData?['pace'] as String?;

      // --- Validaciones Adicionales --- 
      final finalFirstName = firstNameFromSurvey.isNotEmpty ? firstNameFromSurvey : firstName.text.trim();
      
      if (finalFirstName.isEmpty) { 
        TLoaders.errorSnackBar(title: 'Validation Error', message: 'First Name is required.');
        TFullScreenLoader.stopLoading(); 
        return; 
      }
      if (lastNameFromSurvey.isEmpty) { 
        TLoaders.errorSnackBar(title: 'Data Error', message: 'Last Name information from survey is missing. Please complete the survey again.');
        TFullScreenLoader.stopLoading(); 
        return; 
      }
      if (ageFromSurvey == null || ageFromSurvey.isEmpty) { 
         TLoaders.errorSnackBar(title: 'Validation Error', message: 'Age information from survey is missing.');
        TFullScreenLoader.stopLoading(); return; 
      }

      // --- Registro y Guardado --- 
      final userCredential = await AuthenticationRepository.instance
          .registerWithEmailAndPassword(emailFromForm, passwordFromForm);

      if (userCredential.user == null) { /* Error */ TFullScreenLoader.stopLoading(); return; }

      final newUser = UserModel(
        id: userCredential.user!.uid,
        firstName: finalFirstName,
        lastName: lastNameFromSurvey,
        username: usernameFromForm,
        email: emailFromForm,
        phoneNumber: phoneFromForm,
        porfilePicture: '',
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

      // --- Marcar Encuesta como Completada --- 
      // Guardamos esto después de que el usuario se haya guardado correctamente.
      storage.write('SurveyCompleted', true);
      print("SurveyCompleted flag set to true in storage."); // Debug

      // --- Limpieza --- 
      // Eliminar los datos de la encuesta de storage después de usarlos exitosamente
      storage.remove('pendingSurveyAnswers');
      print("Pending survey answers removed from storage."); // Debug
      
      TFullScreenLoader.stopLoading();

      TLoaders.successSnackBar(
          title: 'Congratulations!',
          message: 'Your account has been created! Verify email to continue.');

      // Navegar a VerifyEmailScreen
      Get.to(() => VerifyEmailScreen(email: emailFromForm));
    } catch (e, stackTrace) { 
      TFullScreenLoader.stopLoading();
      
      // --- Log detallado del error ---
      print("‼️----- SIGNUP ERROR CAUGHT -----‼️");
      print("Error Type: ${e.runtimeType}");
      print("Error Message: ${e.toString()}");
      String errorMessage = 'An unexpected error occurred during signup. Please try again.';
      
      if (e is FirebaseAuthException) {
        print("Firebase Auth Code: ${e.code}");
        // Usar el mensaje de nuestra clase TFirebaseAuthException
        errorMessage = TFirebaseAuthException(e.code).message;
      } else if (e is FirebaseException) {
        print("Firebase Code: ${e.code}");
        // Usar el mensaje de nuestra clase TFirebaseException
        errorMessage = TFirebaseException(e.code).message;
         if (e.code == 'permission-denied') {
           errorMessage = 'Database permission denied. Check Firestore rules.';
         }
      } else if (e is FormatException) {
        // Usar el mensaje de nuestra clase TFormatException
        errorMessage = TFormatException().message; // Asumiendo constructor por defecto
      } else if (e is PlatformException) {
        print("Platform Exception Code: ${e.code}");
        // Mostrar mensaje genérico o e.message si prefieres
        errorMessage = 'An error occurred with a platform service: ${e.message ?? e.code}'; 
      } else {
        errorMessage = e.toString(); 
      }
      
      print("Stack Trace:\n$stackTrace");
      print("‼️-------------------------------‼️");
      
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: errorMessage);
    }
  }
}
