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
import 'package:runap/features/authentication/services/survey_service.dart';
import 'package:runap/features/authentication/services/error_handler_service.dart';
import 'package:runap/utils/constants/text_strings.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  /// Variables
  final RxBool _hidePassword = true.obs;
  final RxBool _privacyPolicy = true.obs;
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final firstName = TextEditingController();
  final phoneNumber = TextEditingController();
  String completePhoneNumber = '';
  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();
  
  bool _firstNamePreFilled = false;

  Map<String, dynamic>? surveyData;
  final SurveyService _surveyService = SurveyService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  // Getters para exponer solo lectura
  bool get hidePassword => _hidePassword.value;
  bool get privacyPolicy => _privacyPolicy.value;
  set hidePassword(bool value) => _hidePassword.value = value;
  set privacyPolicy(bool value) => _privacyPolicy.value = value;

  @override
  void onInit() {
    super.onInit();
    // Leer datos de la encuesta al inicializar
    loadSurveyData();
    // Ya no intentamos obtener nombre/apellido de los argumentos aquí
  }

  void loadSurveyData() {
    surveyData = _surveyService.readPendingSurvey();
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
      if (!privacyPolicy) {
        TLoaders.warningSnackBar(
          title: TTexts.error,
          message: TTexts.iAgreeTo + ' ' + TTexts.privacyPolicy + ' & ' + TTexts.termsOfUse,
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
        TLoaders.errorSnackBar(title: TTexts.error, message: TTexts.firstName + ' ' + TTexts.checkInput);
        TFullScreenLoader.stopLoading(); 
        return; 
      }
      if (lastNameFromSurvey.isEmpty) { 
        TLoaders.errorSnackBar(title: TTexts.error, message: TTexts.lastName + ' ' + TTexts.checkInput);
        TFullScreenLoader.stopLoading(); 
        return; 
      }
      if (ageFromSurvey == null || ageFromSurvey.isEmpty) { 
         TLoaders.errorSnackBar(title: TTexts.error, message: 'Edad ' + TTexts.checkInput);
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
      await _surveyService.setSurveyCompleted(true);
      print("SurveyCompleted flag set to true in storage."); // Debug

      // --- Limpieza --- 
      // Eliminar los datos de la encuesta de storage después de usarlos exitosamente
      await _surveyService.removePendingSurvey();
      print("Pending survey answers removed from storage."); // Debug
      
      TFullScreenLoader.stopLoading();

      TLoaders.successSnackBar(
          title: TTexts.yourAccountCreatedTitle,
          message: TTexts.yourAccountCreatedSubTitle);

      // Navegar a VerifyEmailScreen
      Get.to(() => VerifyEmailScreen(email: emailFromForm));
    } catch (e, stackTrace) { 
      TFullScreenLoader.stopLoading();
      _errorHandler.logError(e, stackTrace);
      String errorMessage = _errorHandler.getFriendlyMessage(e);
      _errorHandler.showError(title: TTexts.ohSnap, message: errorMessage);
    }
  }
}
