import 'package:flutter/material.dart'; // Importar flutter para TextEditingController
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // Importar GetStorage
import '../models/question_model.dart'; // Importar el modelo
import 'package:runap/features/authentication/screens/login/login.dart'; // Importar LoginScreen
import 'package:runap/features/authentication/screens/signup/signup_options_screen.dart'; 
import 'package:runap/features/authentication/screens/signup/signup.dart'; // Importar SignupScreen
import 'package:runap/features/authentication/bindings/signup_binding.dart'; // Importar el nuevo Binding

class SurveyController extends GetxController {
  static SurveyController get instance => Get.find();

  // Lista observable de preguntas
  final RxList<QuestionModel> questions = <QuestionModel>[].obs;
  // Índice de la pregunta actual
  final RxInt currentQuestionIndex = 0.obs;
  // Mapa para almacenar las respuestas del usuario (questionId -> answer)
  final RxMap<String, dynamic> userAnswers = <String, dynamic>{}.obs;
  // Instancia de GetStorage
  final storage = GetStorage();

  // Controlador para preguntas de tipo texto
  TextEditingController? textInputController;
  // Flag para evitar llamadas recursivas/excesivas al listener
  bool _isUpdatingFromListener = false;

  @override
  void onInit() {
    super.onInit();
    // Cargar respuestas pendientes si existen (útil si el usuario vuelve a la encuesta)
    final pendingAnswers = storage.read<Map<String, dynamic>>('pendingSurveyAnswers');
    if (pendingAnswers != null) {
      userAnswers.assignAll(pendingAnswers);
    }
    loadQuestions(); // Renombrado para claridad
    // Asegurarse de inicializar el controller si la primera pregunta es de texto
    _updateTextInputControllerIfNeeded(); 
  }

  @override
  void onClose() {
    // Liberar el controlador de texto al cerrar el SurveyController
    textInputController?.dispose();
    super.onClose();
  }

  // Método para cargar preguntas predeterminadas
  void loadQuestions() {
    // Nueva lista de preguntas basada en el flujo de Foodvisor
    final surveyFlowQuestions = [
       QuestionModel(
        id: 'firstName', 
        text: 'Let\'s start with the basics.\nWhat is your first name?', 
        type: 'text', 
        sectionTitle: 'Welcome', // Sección inicial
      ),
      QuestionModel(
        id: 'lastName', 
        text: 'Great, {firstName}! And your last name?',
        type: 'text',
        sectionTitle: 'Welcome', // Misma sección
        // Sin imagen para esta, o puedes añadir una diferente
      ),
      QuestionModel(
        id: 'mainGoal',
        text: 'Nice to meet you, {firstName}!\nSo, what brings you here?', // Texto ajustado
        type: 'single_choice_button', 
        options: [
          'Losing weight',
          'Gaining muscle and losing fat',
          'Gaining muscle, losing fat is secondary',
          'Eating healthier without losing weight'
        ],
        sectionTitle: 'Goal & Profile', // Empieza sección
      ),
       QuestionModel(
        id: 'howHeard',
        text: 'How did you hear about RunAP?', 
        type: 'single_choice_button', 
        options: [
          'Instagram / Facebook',
          'TikTok',
          'YouTube',
          'Play Store',
          'Friends / Family',
          'Influencer',
          'Online search (Google, etc.)',
          'Ad in another app',
          'Doctors / Health professionals',
          'Radio / Press' // Añadido de imagen 5
        ],
        sectionTitle: 'Goal & Profile', // Misma sección
      ),
      QuestionModel(
        id: 'loseWeightReasons',
        text: 'We all have different reasons to lose weight, what are yours?\n\nThis will help us keep you motivated towards your goal.', 
        type: 'multiple_choice_checkbox', 
        options: [
          'Feel better in my body',
          'Be healthier',
          'Get in shape',
          'Fit in my old clothes',
          'Be more energetic',
          'Move better or improve at a sport'
        ],
        sectionTitle: 'Goal & Profile',
        // Esta pregunta podría ser condicional basada en mainGoal == 'Losing weight'
        // Necesitaríamos lógica adicional para saltarla si no aplica.
      ),
       QuestionModel(
        id: 'infoScreen1',
        text: 'You are in the right place! Now let\'s get to know you.\n\nWe need some basic information to start customizing your plan.', 
        type: 'info', 
        imagePath: 'assets/images/survey/avocado_relax.png', // Placeholder
        sectionTitle: 'Goal & Profile',
      ),
      QuestionModel(
        id: 'gender', 
        text: 'What is your gender?', 
        type: 'single_choice_button',
        options: ['Male', 'Female', 'Non binary', 'Prefer not to say'], // Opciones de imagen 9
        sectionTitle: 'Goal & Profile',
      ),
      QuestionModel(
        id: 'age', 
        text: 'How old are you?', 
        type: 'text',
        sectionTitle: 'Goal & Profile',
        // keyboardType: number se manejará en UI
      ),
       QuestionModel(
        id: 'height', 
        text: 'What is your height?', 
        type: 'text_with_unit',
        unit: 'cm',
        sectionTitle: 'Goal & Profile',
        // keyboardType: number
      ),
      QuestionModel(
        id: 'currentWeight', 
        text: 'What is your current weight?', 
        type: 'text_with_unit',
        unit: 'kg',
        sectionTitle: 'Goal & Profile',
        // keyboardType: number
      ),
       QuestionModel(
        id: 'idealWeight', 
        text: 'So you are here to {mainGoal}!\nWhat would be your ideal weight?', // Usar objetivo 
        type: 'text_with_unit',
        unit: 'kg',
        sectionTitle: 'Goal & Profile',
        // keyboardType: number
        // Podría ser condicional también
      ),
      QuestionModel(
        id: 'pace', 
        text: 'What pace do you want to achieve your goal?', 
        type: 'slider_choice',
        options: ['Slowly but surely', 'In the middle', 'As fast as possible'],
        sectionTitle: 'Goal & Profile',
        // minValue: 0, maxValue: 2, divisions: 2 
      ),
      // --- Nuevas Preguntas --- 
       QuestionModel(
        id: 'activityLevel',
        text: 'In a typical day, are you mostly active or seated?',
        type: 'single_choice_button',
        options: ['Active', 'Seated'],
        sectionTitle: 'Your environment', 
      ),
      QuestionModel(
        id: 'infoScreen2',
        text: '''No worries. We have all been there!\n\nWe know that stopping snacking is easier said than done. But by identifying why you snack you already took the first step. Next time you're reaching for a snack, don\'t stop yourself, just take a moment to acknowledge why you're craving that snack.''',
        type: 'info',
        imagePath: 'assets/images/survey/avocado_snack.png', 
        sectionTitle: 'Your habits & behaviour', 
      ),
      // ... Añadir más si es necesario ...
    ];

    questions.assignAll(surveyFlowQuestions);

    // Lógica para ajustar índice si hay respuestas pendientes (simplificada)
    if (userAnswers.isNotEmpty && questions.isNotEmpty) {
      int lastAnsweredIndex = -1;
      for (int i = questions.length - 1; i >= 0; i--) {
        if (userAnswers.containsKey(questions[i].id)) {
          lastAnsweredIndex = i;
          break;
        }
      }
      if (lastAnsweredIndex != -1 && lastAnsweredIndex < questions.length - 1) {
        currentQuestionIndex.value = lastAnsweredIndex + 1;
      } else if (lastAnsweredIndex != -1) {
         currentQuestionIndex.value = lastAnsweredIndex; // Quédate en la última respondida si era la final
      }
    }
  }

  // Helper para inicializar/actualizar/limpiar el text controller
  void _updateTextInputControllerIfNeeded() {
    if (questions.isEmpty) return; 
    final currentQ = currentQuestion;
    if (currentQ.type == 'text' || currentQ.type == 'text_with_unit') {
      final currentText = userAnswers[currentQ.id] as String? ?? '';
      // Si no existe, crear y añadir listener
      if (textInputController == null) {
        textInputController = TextEditingController(text: currentText);
        textInputController?.addListener(_saveTextControllerValue);
      } else {
        // Si existe, actualizar texto SOLO si es diferente
        if (textInputController!.text != currentText) {
           // Usar flag para indicar que estamos actualizando programáticamente
           _isUpdatingFromListener = true;
           textInputController!.text = currentText;
           textInputController!.selection = TextSelection.fromPosition(
              TextPosition(offset: textInputController!.text.length),
           );
           // Esperar un frame antes de quitar el flag (más seguro)
           WidgetsBinding.instance.addPostFrameCallback((_) {
              _isUpdatingFromListener = false;
           });
        }
        // Asegurar que el listener esté añadido (podría haberse quitado)
        // textInputController?.removeListener(_saveTextControllerValue); // Quitar primero por si acaso
        // textInputController?.addListener(_saveTextControllerValue);
         // -> En realidad, si el controlador persiste, el listener también.
         //    No debería ser necesario re-añadirlo aquí.
      }
    } else {
       // Si la pregunta NO es de texto, ya no necesitamos el listener activo
       // (aunque mantener el controlador puede ser útil si hay varias preguntas de texto)
       // textInputController?.removeListener(_saveTextControllerValue); // No quitar aún
    }
  }

  void _saveTextControllerValue() {
     // Si la actualización viene de _updateTextInputControllerIfNeeded, ignorar
     if (_isUpdatingFromListener) return;

     if (textInputController != null && questions.isNotEmpty) {
        final currentQId = currentQuestion.id;
         if (currentQuestion.type == 'text' || currentQuestion.type == 'text_with_unit'){
             final currentText = textInputController!.text;
             if (userAnswers[currentQId] != currentText) {
                 // Llamar a saveAnswer en lugar de modificar userAnswers directamente
                 saveAnswer(currentQId, currentText); 
                 // print('Saved from listener: $currentQId -> $currentText');
             }
         }
     }
  }

  void saveAnswer(String questionId, dynamic answer) {
    // Solo actualizar si el valor es realmente diferente
    if (userAnswers[questionId] != answer) {
        userAnswers[questionId] = answer;
        print('Respuesta guardada: $questionId -> $answer');
    }
  }

  // --- Lógica de Navegación con Condiciones ---

  // Verifica si la pregunta actual debe saltarse
  bool _shouldSkipQuestion(int index) {
    if (index < 0 || index >= questions.length) return false; // Índice inválido

    final questionId = questions[index].id;
    
    // Condición para 'loseWeightReasons'
    if (questionId == 'loseWeightReasons') {
      final mainGoalAnswer = userAnswers['mainGoal'] as String?;
      // Saltar si el objetivo principal NO es perder peso
      // Ajusta las strings exactas según tus opciones en 'mainGoal'
      return !(mainGoalAnswer == 'Losing weight' || mainGoalAnswer == 'Gaining muscle and losing fat');
    }
    
    // Condición para 'idealWeight' (si la haces condicional)
    if (questionId == 'idealWeight') {
       final mainGoalAnswer = userAnswers['mainGoal'] as String?;
       // Saltar si el objetivo principal NO es perder peso ni ganar músculo perdiendo grasa
       return !(mainGoalAnswer == 'Losing weight' || mainGoalAnswer == 'Gaining muscle and losing fat');
    }

    // Añadir más condiciones aquí para otras preguntas si es necesario

    return false; // Por defecto, no saltar
  }

  // Encuentra el índice de la SIGUIENTE pregunta válida (saltando condicionales)
  int _findNextValidQuestionIndex(int currentIndex) {
    int nextIndex = currentIndex + 1;
    while (nextIndex < questions.length && _shouldSkipQuestion(nextIndex)) {
      nextIndex++;
    }
    return nextIndex;
  }

  // Encuentra el índice de la ANTERIOR pregunta válida (saltando condicionales)
  int _findPreviousValidQuestionIndex(int currentIndex) {
     int prevIndex = currentIndex - 1;
    while (prevIndex >= 0 && _shouldSkipQuestion(prevIndex)) {
      prevIndex--;
    }
    return prevIndex; 
  }

  // Método para ir a la siguiente pregunta
  void nextQuestion() {
    // TODO: Añadir validaciones específicas para los nuevos tipos si es necesario
    // Ej: Validar que campos numéricos (edad, peso, altura) sean números válidos.
    final currentQ = currentQuestion;
    final currentAnswer = userAnswers[currentQ.id];
    bool requiredFieldMissing = false;

    // Validaciones generales (pueden necesitar ajuste por tipo)
    if (currentQ.type != 'info') { // Las pantallas de info no requieren respuesta
        if (currentAnswer == null) {
             requiredFieldMissing = true;
        } else if (currentAnswer is String && currentAnswer.isEmpty) {
             requiredFieldMissing = true;
        } else if (currentAnswer is List && currentAnswer.isEmpty) {
             requiredFieldMissing = true;
        }
    }

    if (requiredFieldMissing) {
       Get.snackbar('Respuesta requerida', 'Por favor, completa la información para continuar.', snackPosition: SnackPosition.BOTTOM);
       return;
    }
    
    // Encontrar el índice de la próxima pregunta válida
    int nextValidIndex = _findNextValidQuestionIndex(currentQuestionIndex.value);

    // Lógica de navegación
    if (nextValidIndex < questions.length) {
      currentQuestionIndex.value = nextValidIndex;
      _updateTextInputControllerIfNeeded();
    } else {
      // Si no hay más preguntas válidas, finalizar
      submitSurvey();
    }
  }

  // Método para ir a la pregunta anterior (opcional)
  void previousQuestion() {
    // Encontrar el índice de la pregunta válida anterior
    int prevValidIndex = _findPreviousValidQuestionIndex(currentQuestionIndex.value);
    
    if (prevValidIndex >= 0) {
       currentQuestionIndex.value = prevValidIndex;
       _updateTextInputControllerIfNeeded(); 
    }
    // Si prevValidIndex es -1, no hacer nada (ya está en la primera)
  }

  // Método para enviar la encuesta
  void submitSurvey() {
    print('Enviando encuesta con respuestas: $userAnswers');
    
    try {
      // Guardar respuestas finales para que Signup las lea
      storage.write('pendingSurveyAnswers', userAnswers.value); 
      print('Respuestas de encuesta guardadas temporalmente.');
      
      // LIMPIAR el índice de progreso, ya no es necesario
      storage.remove('nextSurveyQuestionIndex');
      print("Índice de progreso de encuesta eliminado.");
      
      // Navegar a la pantalla de signup principal USANDO EL BINDING
      Get.offAll(() => const SignupScreen(), 
                 binding: SignupBinding(),
                 transition: Transition.upToDown); 
    } catch (e) {
      print("Error al finalizar encuesta y navegar a Signup: $e");
      Get.snackbar("Error", "No se pudo procesar la encuesta. Inténtalo de nuevo.", snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Helper para obtener la pregunta actual
  QuestionModel get currentQuestion => questions[currentQuestionIndex.value];
}
