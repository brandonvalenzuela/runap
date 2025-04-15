import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart'; // Importar Iconsax
import '../controllers/survey_controller.dart';
import '../models/question_model.dart'; // Importar el modelo
import 'package:runap/utils/constants/sizes.dart'; // Asumiendo que tienes TSizes

class SurveyScreen extends GetView<SurveyController> {
  const SurveyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Quitar AppBar
      // appBar: AppBar(...),
      body: SafeArea( // Usar SafeArea para evitar solapamiento con notch/barra estado
        child: Padding(
          // Padding general para la pantalla
          padding: const EdgeInsets.only(
              top: kToolbarHeight, // Simular espacio de AppBar para progreso/atrás
              left: TSizes.defaultSpace,
              right: TSizes.defaultSpace,
              bottom: TSizes.defaultSpace), 
          child: Obx(() {
            // Indicador de carga
            if (controller.questions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            
            // Obtener pregunta actual
            final QuestionModel currentQuestion = controller.currentQuestion;
            final int currentIndex = controller.currentQuestionIndex.value;
            final int totalQuestions = controller.questions.length;

            // Usar Column para la estructura principal
            return Column(
              children: [
                // --- 1. Barra de Progreso Real ---
                _buildProgressBar(context, currentIndex, totalQuestions),
                const SizedBox(height: TSizes.spaceBtwSections),
                
                Expanded(
                  child: SingleChildScrollView( 
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center, // Centrar verticalmente
                        children: [
                          // --- Mostrar Imagen si existe --- 
                          _buildQuestionImage(currentQuestion),
                          
                          // Espacio solo si hubo imagen
                          if (currentQuestion.imagePath != null && currentQuestion.imagePath!.isNotEmpty) 
                             const SizedBox(height: TSizes.spaceBtwSections),
                          
                          // Widget Builder para añadir logs ANTES de construir el Text
                          Builder(
                            builder: (context) {
                              // --- Logs de depuración ---
                              print("📊 [SURVEY_DEBUG] Index: ${currentIndex}");
                              print("📊 [SURVEY_DEBUG] Total Preguntas: ${totalQuestions}");
                              print("📊 [SURVEY_DEBUG] ID Pregunta: ${currentQuestion.id}");
                              print("📊 [SURVEY_DEBUG] Texto Original: ${currentQuestion.text}");
                              final processedText = _getProcessedQuestionText(currentQuestion.text);
                              print("📊 [SURVEY_DEBUG] Texto Procesado: $processedText");
                              // --- Fin logs ---

                              // Devolver el widget Text real
                              return Text(
                                processedText,
                                style: Theme.of(context).textTheme.headlineSmall, 
                                textAlign: TextAlign.center,
                              );
                            }
                          ),
                          const SizedBox(height: TSizes.spaceBtwSections * 1.5),

                          // Widget de respuesta
                          _buildAnswerWidget(context, currentQuestion),
                        ],
                    ),
                  ), 
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                // --- 3. Botones de Navegación ---
                _buildNavigationButtons(context, currentIndex > 0, currentIndex < totalQuestions -1),
              ],
            );
          }),
        ),
      ),
      // Quitar BottomNavigationBar anterior
      // bottomNavigationBar: Padding(...),
    );
  }

  // --- Helper Widgets --- 

  // Barra de progreso con Título de Sección
  Widget _buildProgressBar(BuildContext context, int current, int total) {
    double progress = total > 0 ? (current + 1) / total : 0;
    final currentSectionTitle = controller.questions[current].sectionTitle;
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color lightBG = Theme.of(context).scaffoldBackgroundColor; // Asumiendo fondo claro
    final Color lightOrange = primaryColor.withOpacity(0.15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         // Título de sección (si existe)
         if (currentSectionTitle != null && currentSectionTitle.isNotEmpty)
           Padding(
             padding: const EdgeInsets.only(bottom: TSizes.sm, left: 6), // Ajustar padding
             child: Text(
                 currentSectionTitle,
                 style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: primaryColor), 
             ),
           ), 
          // Barra y Botón Atrás
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             crossAxisAlignment: CrossAxisAlignment.center,
             children: [
                 SizedBox(
                   width: 48,
                   child: current > 0
                     ? IconButton(icon: Icon(Icons.arrow_back_ios, size: 18, color: primaryColor), onPressed: controller.previousQuestion)
                     : null, 
                 ),
                 Expanded(
                   child: ClipRRect(
                      borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: lightBG, // Fondo claro
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                   ),
                 ),
                 const SizedBox(width: 48), 
             ],
          ),
      ],
    );
  }

  // Widget para mostrar imagen de la pregunta
  Widget _buildQuestionImage(QuestionModel question) {
    if (question.imagePath != null && question.imagePath!.isNotEmpty) {
      // Usar un tamaño razonable para la imagen
      return Image.asset(
        question.imagePath!,
        height: 120, // Ajusta esta altura según necesites
        errorBuilder: (context, error, stackTrace) {
          // Mostrar un icono o texto si la imagen no carga
          print("Error cargando imagen: ${question.imagePath} - $error");
          return const Icon(Icons.error_outline, color: Colors.red, size: 50);
        },
      );
    } else {
      // Si no hay imagen, no mostrar nada
      return const SizedBox.shrink(); 
    }
  }

  // Helper para procesar el texto de la pregunta (ej. reemplazar placeholders)
  String _getProcessedQuestionText(String text) {
      // Reemplazar {firstName} si existe la respuesta
      if (text.contains('{firstName}')) {
         final firstName = controller.userAnswers['firstName'] as String? ?? 'User';
         return text.replaceAll('{firstName}', firstName);
      }
      // Reemplazar {mainGoal} si existe la respuesta
       if (text.contains('{mainGoal}')) {
         final goal = controller.userAnswers['mainGoal'] as String? ?? 'your goal';
         return text.replaceAll('{mainGoal}', goal);
      }
      return text;
  }

  // Botones de navegación con estilo refinado
  Widget _buildNavigationButtons(BuildContext context, bool canGoBack, bool hasNext) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary; // Color del texto sobre el primario

    return Padding(
      // Añadir padding si es necesario para separarlo del borde inferior
      padding: const EdgeInsets.only(top: TSizes.spaceBtwSections), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón Atrás: Discreto, quizás solo icono
          SizedBox(
             width: 60, // Ancho fijo para alineación
             child: canGoBack 
                 ? IconButton(
                      icon: Icon(Iconsax.arrow_left_2, color: Colors.grey[600]), 
                      onPressed: controller.previousQuestion
                    )
                 : null, // No mostrar si no puede ir atrás
          ),

          // Botón Siguiente / Finalizar: Prominente
          Expanded(
            // Permitir que el botón se expanda si no hay botón Atrás?
            // O darle un ancho fijo/mínimo?
            // Por ahora, se expandirá si no hay botón Atrás.
            child: ElevatedButton(
              onPressed: controller.nextQuestion,
              style: ElevatedButton.styleFrom(
                 backgroundColor: primaryColor, 
                 foregroundColor: onPrimaryColor,
                 padding: const EdgeInsets.symmetric(vertical: TSizes.md), // Botón más alto
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusLg)), // Redondeado
                 textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: Text(hasNext ? 'Next' : 'Finish Survey'), // Texto más descriptivo al final
            ),
          ),

          // Placeholder derecho si hay botón Atrás, para centrar el botón Next
          if (canGoBack)
             const SizedBox(width: 60),
        ],
      ),
    );
  }

 // --- Widgets de Respuesta (Estilos Refinados) ---

 // Widget helper para construir la entrada de respuesta según el tipo
 Widget _buildAnswerWidget(BuildContext context, QuestionModel question) {
    // Valor actual guardado para esta pregunta
    final currentAnswer = controller.userAnswers[question.id];

    switch (question.type) {
      case 'text':
        return _buildTextWidget(context, question, currentAnswer as String? ?? '');
      case 'single_choice_button':
         return _buildSingleChoiceButtonWidget(context, question, currentAnswer as String?);
      case 'multiple_choice_checkbox':
         final selectedOptions = (currentAnswer is List)
            ? List<String>.from(currentAnswer)
            : <String>[];
         return _buildMultipleChoiceCheckboxWidget(context, question, selectedOptions);
      case 'info':
         return _buildInfoWidget(context, question);
      case 'text_with_unit':
         return _buildTextWithUnitWidget(context, question, currentAnswer as String? ?? '');
      case 'slider_choice':
        // Determinar valor inicial del slider (0, 1, 2)
        int sliderValue = 0;
        if (question.options != null && currentAnswer != null) {
           sliderValue = question.options!.indexOf(currentAnswer as String);
           if (sliderValue == -1) sliderValue = 0; // Default si no se encuentra
        }
         return _buildSliderChoiceWidget(context, question, sliderValue);
      // Mantener los casos antiguos si aún los necesitas o quieres reutilizar su lógica
      // case 'single_choice': ... 
      // case 'multiple_choice': ...
      default:
        return Text('Tipo de pregunta no soportado: ${question.type}');
    }
  }

  // Widget para Texto simple (Ajustes menores)
  Widget _buildTextWidget(BuildContext context, QuestionModel question, String currentAnswer) {
    if (controller.textInputController == null) {
       print("Error: textInputController es nulo en _buildTextWidget");
       return const Center(child: Text('Error al cargar campo de texto'));
    }
    // Determinar tipo de teclado
    TextInputType keyboardType = TextInputType.text;
    if (question.id == 'age') {
       keyboardType = TextInputType.number;
    }

    // --- Lógica de Hint Text Mejorada ---
    String hintTextValue = ''; // Hint vacío por defecto
    if (question.id == 'firstName') {
      hintTextValue = 'First Name';
    } else if (question.id == 'lastName') {
      hintTextValue = 'Last Name'; // <-- Hint específico para apellido
    } else if (question.id == 'age') {
      hintTextValue = '0'; // <-- Hint '0' solo para edad
    }
    // Puedes añadir más 'else if' para otros campos de texto si es necesario
    // --- Fin Lógica Hint Text ---

    return TextFormField(
      controller: controller.textInputController!,
      keyboardType: keyboardType,
      textAlign: TextAlign.center, 
      style: Theme.of(context).textTheme.headlineSmall, 
      decoration: InputDecoration(
        // Usar la variable hintTextValue
        hintText: hintTextValue, 
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg), 
            borderSide: BorderSide(color: Colors.grey.shade300)
        ),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
            borderSide: BorderSide(color: Colors.grey.shade300)
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
            borderSide: BorderSide(color: Theme.of(context).primaryColor)
        ),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor, 
      ),
    );
  }

  // Widget para botones de selección única (Refinado)
  Widget _buildSingleChoiceButtonWidget(BuildContext context, QuestionModel question, String? currentAnswer) {
     final Color primaryColor = Theme.of(context).primaryColor;
     final Color selectedTextColor = Theme.of(context).brightness == Brightness.light ? Colors.white : primaryColor; // Blanco en tema claro
     final Color unselectedTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
     final Color selectedBgColor = primaryColor;
     final Color unselectedBgColor = Theme.of(context).scaffoldBackgroundColor; // Fondo scaffold

     return Column(
       children: question.options!.map((option) {
          final isSelected = currentAnswer == option;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: TSizes.xs + 2),
            child: ElevatedButton( // Cambiado a ElevatedButton para fondo sólido
               onPressed: () => controller.saveAnswer(question.id, option),
               style: ElevatedButton.styleFrom(
                  elevation: isSelected ? 2 : 0, // Sombra suave si seleccionado
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusLg)), // Más redondeado
                  backgroundColor: isSelected ? selectedBgColor : unselectedBgColor,
                  // Añadir overlay color para feedback visual al presionar
                  foregroundColor: isSelected ? selectedTextColor : unselectedTextColor, 
                  side: !isSelected ? BorderSide(color: Colors.grey.shade300) : null, // Borde solo si no seleccionado
               ),
               child: Text(option, style: TextStyle(color: isSelected ? selectedTextColor : unselectedTextColor, fontWeight: FontWeight.w500)),
            ),
          );
       }).toList(),
    );
  }

  // Widget para checkboxes de selección múltiple (Refinado)
  Widget _buildMultipleChoiceCheckboxWidget(BuildContext context, QuestionModel question, List<String> selectedOptions) {
     final Color primaryColor = Theme.of(context).primaryColor;
     final Color selectedBgColor = primaryColor.withOpacity(0.1);
     final Color unselectedBgColor = Theme.of(context).scaffoldBackgroundColor;

     return Column(
      children: question.options!.map((option) {
         final isSelected = selectedOptions.contains(option);
         return Padding(
           padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
           child: Container( // Usar Container para controlar borde y fondo
              decoration: BoxDecoration(
                 color: isSelected ? selectedBgColor : unselectedBgColor,
                 borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                 border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300)
              ),
              child: CheckboxListTile(
                  title: Text(option, style: TextStyle(color: isSelected ? primaryColor : null)),
                  value: isSelected,
                  onChanged: (bool? isChecked) {
                    if (isChecked == null) return;
                    final currentSelection = List<String>.from(selectedOptions);
                    if (isChecked) {
                      if (!currentSelection.contains(option)) currentSelection.add(option);
                    } else {
                      currentSelection.remove(option);
                    }
                    controller.saveAnswer(question.id, currentSelection);
                  },
                  activeColor: primaryColor, // Color del check
                  checkColor: Colors.white, // Color de la palomita
                  controlAffinity: ListTileControlAffinity.trailing, // Checkbox a la derecha como en imagen 7
                  contentPadding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.xs),
                  // Quitar tileColor y shape de CheckboxListTile, se maneja en Container
              ),
           ),
         );
      }).toList(),
    );
  }

  // Widget para pantallas de información
  Widget _buildInfoWidget(BuildContext context, QuestionModel question) {
    // Simplemente muestra el texto, la navegación se hace con los botones inferiores
    // Podríamos añadir una imagen aquí si la incluimos en QuestionModel
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwSections * 2),
      child: Text(question.text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
    );
  }

  // Widget para texto con unidad (Ajustes menores)
  Widget _buildTextWithUnitWidget(BuildContext context, QuestionModel question, String currentAnswer) {
    if (controller.textInputController == null) {
       print("Error: textInputController es nulo en _buildTextWithUnitWidget");
       return const Center(child: Text('Error al cargar campo de texto'));
    }
    // Siempre numérico para estos campos
    TextInputType keyboardType = TextInputType.number;
    
    return TextFormField(
      controller: controller.textInputController!,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall,
      decoration: InputDecoration(
        hintText: '0',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusLg), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusLg), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusLg), borderSide: BorderSide(color: Theme.of(context).primaryColor)),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Chip(
              label: Text(question.unit ?? '', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)), 
              backgroundColor: Colors.grey.shade200,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Más padding
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusSm)), // Más redondeado
          ),
        ),
      ),
    );
  }

 // Widget para slider de selección (Refinado)
 Widget _buildSliderChoiceWidget(BuildContext context, QuestionModel question, int currentValueIndex) {
    final options = question.options ?? [];
    if (options.isEmpty) return const Text('Error: Faltan opciones para el slider');
    int validIndex = currentValueIndex.clamp(0, options.length - 1);
    final Color primaryColor = Theme.of(context).primaryColor;
    
    // Iconos para el slider (ejemplo) - Placeholder final
    List<IconData> sliderIcons = [Iconsax.speedometer, Iconsax.flash_1, Iconsax.airplane]; 

    return Column(
      children: [
         // Mostrar iconos encima del slider
         Padding(
           padding: const EdgeInsets.symmetric(horizontal: 16.0),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: List.generate(options.length, (index) => Icon(
                  sliderIcons.length > index ? sliderIcons[index] : Icons.circle, // Icono o placeholder
                  color: validIndex == index ? primaryColor : Colors.grey,
                  size: 30,
             )),
           ),
         ),
         const SizedBox(height: TSizes.xs),
          SliderTheme(
           data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryColor,
              inactiveTrackColor: Colors.grey[300],
              trackHeight: 6.0,
              thumbColor: primaryColor,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
              overlayColor: primaryColor.withOpacity(0.2),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 24.0),
              tickMarkShape: RoundSliderTickMarkShape(tickMarkRadius: 4),
              activeTickMarkColor: primaryColor.withOpacity(0.5),
              inactiveTickMarkColor: Colors.grey[500],
              valueIndicatorShape: PaddleSliderValueIndicatorShape(),
              valueIndicatorColor: primaryColor.withOpacity(0.8),
              valueIndicatorTextStyle: TextStyle(
                color: Colors.white,
              ),
           ),
           child: Slider(
              value: validIndex.toDouble(),
              min: 0,
              max: (options.length - 1).toDouble(),
              divisions: options.length - 1 > 0 ? options.length - 1 : 1, 
              label: options[validIndex], 
              onChanged: (double value) {
                controller.saveAnswer(question.id, options[value.toInt()]);
              },
            ),
         ),
        // const SizedBox(height: TSizes.sm),
        // Las etiquetas de texto ahora van con los iconos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: options.map((label) => Expanded(
                 child: Text(
                     label, 
                     style: Theme.of(context).textTheme.bodySmall,
                     textAlign: TextAlign.center,
                 ),
            )).toList(),
          ),
        ),
      ],
    );
  }
 
}
