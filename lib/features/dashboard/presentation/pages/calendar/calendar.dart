import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:runap/navigation_menu.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:iconsax/iconsax.dart'; // Para iconos como calendar, chevron_right
import 'dart:math' as math;

// --- Imports para TrainingCard --- 
import 'package:runap/features/dashboard/presentation/manager/training_view_model.dart';
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';
import 'package:runap/common/widgets/training/training_card.dart';
import 'package:runap/utils/device/device_utility.dart';


class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Estado para rastrear el progreso del scroll entre initial y first snap
  double _scrollProgress = 0.0; // Reemplaza _isSnapped
  DateTime _selectedDate = DateTime.now();

  // --- ESTADO PARA DATOS DEPENDIENTES DE LA FECHA ---
  int _eatenCaloriesForSelectedDate = 223; // Valor inicial de ejemplo
  int _burnedCaloriesForSelectedDate = 0;
  final double _goalCalories = 2055; // Asumiendo meta fija por ahora
  final Map<String, Map<String, double>> _macroData = {
    'protein': {'eaten': 32, 'goal': 128},
    'fat': {'eaten': 4, 'goal': 103},
    'carbs': {'eaten': 9, 'goal': 144},
    'fiber': {'eaten': 0, 'goal': 21},
  };
  final Map<String, List<String>> _mealItems = {
    'Breakfast': ['Teriyaki chicken (224 Cal)'],
    'Lunch': [],
    'Dinner': [],
    'Snacks': [],
  };
  final Map<String, int> _mealCaloriesEaten = {
    'Breakfast': 224, 'Lunch': 0, 'Dinner': 0, 'Snacks': 0,
  };
  final Map<String, int> _mealCaloriesGoal = { // Ejemplo de metas por comida
    'Breakfast': 617, 'Lunch': 617, 'Dinner': 617, 'Snacks': 206,
  };
  int _streakCount = 1; // Ejemplo racha

  // Constantes (movidas aquí o dejadas en build si no dependen del estado/context)
  static const Color backgroundColor = TColors.secondaryColor;
  static const Color primaryOrange = TColors.primaryColor; 
  static const Color cardBackgroundColor = TColors.white;
  static const Color textColorDark = TColors.colorBlack;
  static const Color textColorLight = Color(0xFF9B9B9B);
  static const Color proteinColor = Color(0xFFE870A1);
  static const Color fatColor = Color(0xFFF8E81C);
  static const Color carbsColor = Color(0xFF50E3C2);
  static const Color fiberColor = Color(0xFFBD10E0);
  static const Color buttonBlue = TColors.colorBlack;

  // Snap sizes (necesarios para la lógica de notificación)
  static const double initialSheetSize = 0.565; 
  static const double minSheetSize = 0.565;   
  static const double maxChildSize = 1.0;   
  static const double firstSnapSize = 0.76; 

  // Acceder al ViewModel existente
  final TrainingViewModel _viewModel = Get.find<TrainingViewModel>();

  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales para la fecha actual
    _loadDataForDate(_selectedDate);
  }

  // --- FUNCIÓN PARA CARGAR/SIMULAR DATOS PARA UNA FECHA ---
  void _loadDataForDate(DateTime date) {
    // Simulación de carga de datos basada en la fecha
    // En una aplicación real, aquí harías una llamada a tu backend/base de datos
    print('Loading data for: ${DateFormat('yyyy-MM-dd').format(date)}');
    setState(() {
      // Cambiar valores de ejemplo para simular datos diferentes
      // Usar hashCode para generar valores pseudoaleatorios basados en la fecha
      final dateHash = date.hashCode;
      _eatenCaloriesForSelectedDate = (dateHash % 500) + 100; // Ejemplo: Calorías comidas entre 100 y 600
      _burnedCaloriesForSelectedDate = (dateHash % 100); // Ejemplo: Calorías quemadas entre 0 y 100
      _streakCount = (dateHash % 5) + 1; // Racha aleatoria entre 1 y 5

      // Simular macros (ejemplo simple)
      _macroData['protein']?['eaten'] = (dateHash % 50).toDouble();
      _macroData['fat']?['eaten'] = (dateHash % 30).toDouble();
      _macroData['carbs']?['eaten'] = (dateHash % 80).toDouble();
      _macroData['fiber']?['eaten'] = (dateHash % 10).toDouble();

      // Simular ítems y calorías de comidas (ejemplo muy básico)
      int breakfastCals = (_eatenCaloriesForSelectedDate * 0.4).toInt();
      int lunchCals = (_eatenCaloriesForSelectedDate * 0.35).toInt();
      int dinnerCals = (_eatenCaloriesForSelectedDate * 0.25).toInt();

      _mealCaloriesEaten['Breakfast'] = breakfastCals;
      _mealCaloriesEaten['Lunch'] = lunchCals;
      _mealCaloriesEaten['Dinner'] = dinnerCals;
      _mealCaloriesEaten['Snacks'] = _eatenCaloriesForSelectedDate - breakfastCals - lunchCals - dinnerCals; // Resto para snacks

      if (date.day % 2 == 0) {
        _mealItems['Breakfast'] = ['Scrambled Eggs ($breakfastCals Cal)'];
        _mealItems['Lunch'] = ['Chicken Salad ($lunchCals Cal)'];
        _mealItems['Dinner'] = []; // Sin cena en días pares
      } else {
        _mealItems['Breakfast'] = ['Oatmeal ($breakfastCals Cal)'];
        _mealItems['Lunch'] = []; // Sin almuerzo en días impares
        _mealItems['Dinner'] = ['Salmon ($dinnerCals Cal)'];
      }
       _mealItems['Snacks'] = (_mealCaloriesEaten['Snacks'] ?? 0) > 0 ? ['Apple (${_mealCaloriesEaten['Snacks']} Cal)'] : [];

      // Recalcular total comido (debería coincidir con _eatenCaloriesForSelectedDate si la simulación es correcta)
      _eatenCaloriesForSelectedDate = _mealCaloriesEaten.values.fold(0, (sum, cals) => sum + cals);

    });
  }

  @override
  Widget build(BuildContext context) {
    // Define text styles locally (pueden seguir aquí ya que dependen del context)
    final TextStyle defaultTextStyle = DefaultTextStyle.of(context).style;
    final TextStyle headerStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(color: textColorDark, fontWeight: FontWeight.bold, fontSize: TSizes.fontSizeLg ) ?? defaultTextStyle.copyWith(fontSize: TSizes.fontSizeXl, fontWeight: FontWeight.bold, color: textColorDark); // Fallback
    final TextStyle titleStyle = Theme.of(context).textTheme.titleMedium!.copyWith(color: textColorDark, fontWeight: FontWeight.w600);
    final TextStyle subtitleStyle = Theme.of(context).textTheme.bodySmall!.copyWith(color: textColorLight);
    final TextStyle itemTextStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(color: textColorDark);
    final TextStyle macroAmountStyle = Theme.of(context).textTheme.titleLarge!.copyWith(color: textColorDark, fontWeight: FontWeight.bold);
    final TextStyle macroGoalStyle = Theme.of(context).textTheme.labelSmall!.copyWith(color: textColorLight);
    final TextStyle macroLabelStyle = Theme.of(context).textTheme.bodySmall!.copyWith(color: textColorDark, fontWeight: FontWeight.w500);
    final TextStyle calorieValueStyle = Theme.of(context).textTheme.headlineMedium!.copyWith(color: textColorDark, fontWeight: FontWeight.bold);
    final TextStyle calorieLabelStyle = Theme.of(context).textTheme.bodySmall!.copyWith(color: textColorLight);
    final TextStyle calLeftValueStyle = Theme.of(context).textTheme.displaySmall!.copyWith(color: textColorDark, fontWeight: FontWeight.bold, fontSize: TSizes.fontSizeLx + 5);
    final TextStyle calLeftUnitStyle = Theme.of(context).textTheme.titleMedium!.copyWith(color: textColorDark, height: 1.1);
    final TextStyle calLeftLabelStyle = Theme.of(context).textTheme.bodySmall!.copyWith(color: textColorDark, height: 1.1);


    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // --- Contenido Fijo (detrás de la hoja) ---
            Column(
              children: [
                // Envolver Padding con Stack
                Stack(
                  children: [
                     // 1. Padding con la Row SOLO para _buildCaloriesSummary
                     Padding(
                       padding: const EdgeInsets.only(top: TSizes.sm, bottom: TSizes.sm), 
                       child: Row(
                         children: [
                           // Restaurar Expanded y quitar Center
                           Expanded(
                             child: _buildCaloriesSummary(
                               context,
                               primaryOrange,
                               textColorDark,
                               textColorLight,
                               calorieValueStyle,
                               calorieLabelStyle,
                               calLeftValueStyle,
                               calLeftUnitStyle,
                               calLeftLabelStyle,
                             ),
                           ),
                           // Quitar el streakIcon Container de aquí
                         ],
                       ),
                     ),
                     // 2. Align para posicionar el streakIcon
                     Align(
                       alignment: Alignment.topRight,
                       child: Padding(
                         padding: const EdgeInsets.only(top: TSizes.sm, right: TSizes.md), // Padding para el icono
                         child: Container( 
                           padding: const EdgeInsets.symmetric(horizontal: TSizes.smx, vertical: TSizes.xs),
                           decoration: BoxDecoration(
                             border: Border.all(color: primaryOrange),
                             color: cardBackgroundColor,
                             borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                           ),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(Iconsax.flash_11, color: primaryOrange, size: 16),
                               const SizedBox(width: TSizes.xs),
                               Text(
                                 '$_streakCount',
                                 style: Theme.of(context).textTheme.labelLarge?.copyWith(color: primaryOrange, fontWeight: FontWeight.bold)
                               ),
                             ],
                           ),
                         ),
                       ),
                     ),
                  ]
                ),
                 const SizedBox(height: TSizes.defaultSpace),
                // --- Contenedor para la transición entre Macros Circulares y Barras --- // PASO 3
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.smx),
                  // Usar Stack con Opacity y Transform.translate
                  child: Stack(
        children: [
                      // Sección Circular (cayendo hacia atrás y desvaneciéndose)
                      Transform(
                        // Usar Matrix4 para rotación 3D + traslación (SIN PERSPECTIVA)
                        transform: Matrix4.identity()
                          ..rotateX(-math.pi / 2 * _scrollProgress) // Rota hacia atrás
                          ..translate(0.0, _scrollProgress * 30, 0.0), // Traslación vertical
                        alignment: FractionalOffset.center,
                        child: Opacity(
                          opacity: (1.0 - _scrollProgress).clamp(0.0, 1.0),
                          child: _buildMacronutrientsSection(
                            context, cardBackgroundColor, textColorDark, textColorLight,
                            proteinColor, fatColor, carbsColor, fiberColor,
                            headerStyle, macroAmountStyle, macroGoalStyle, macroLabelStyle
                          ),
                        ),
                      ),
                      // Sección Barras Horizontales (levantándose y apareciendo)
                      Transform(
                        // Usar Matrix4 solo para rotación 3D (SIN PERSPECTIVA NI TRASLACIÓN)
                        transform: Matrix4.identity()
                          ..rotateX(-math.pi / 2 * (1.0 - _scrollProgress)), // Solo rotación
                        alignment: FractionalOffset.center,
                        child: Opacity(
                          opacity: _scrollProgress.clamp(0.0, 1.0),
                          child: _buildMinimalHorizontalBars(
                            context, proteinColor, fatColor, carbsColor, fiberColor,
                            // Datos desde el estado (ya se pasan desde el build)
                            _macroData['protein']!,
                            _macroData['fat']!,
                            _macroData['carbs']!,
                            _macroData['fiber']!,
                          ),
                        ),
                      ),
                      // --- Flecha hacia abajo (Aparece con las barras) ---
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          // Añadir padding SUPERIOR para separarlo de las barras
                          padding: EdgeInsets.only(top: TSizes.lg * _scrollProgress), // Padding above, scales with scroll
                          child: Opacity(
                            opacity: _scrollProgress.clamp(0.0, 1.0), // Misma opacidad que las barras
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: textColorLight, // Usar un color sutil
                              size: 24.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                 const SizedBox(height: TSizes.xl + TSizes.sm), 
              ],
            ),

            // --- Hoja Deslizable (encima del contenido fijo) ---
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                // Calcular el progreso entre initial y first snap
                final currentExtent = notification.extent;
                double progress = 0.0;
                if (firstSnapSize > initialSheetSize) { // Evitar división por cero
                  progress = (currentExtent - initialSheetSize) / (firstSnapSize - initialSheetSize);
                }
                // Asegurarse de que el progreso esté entre 0.0 y 1.0
                final clampedProgress = progress.clamp(0.0, 1.0);

                // Actualizar estado solo si el progreso cambió significativamente
                // (Evita reconstrucciones innecesarias)
                if ((clampedProgress - _scrollProgress).abs() > 0.01) { 
                  setState(() {
                    _scrollProgress = clampedProgress;
                  });
                }
                return true; // Indicar que hemos manejado la notificación
              },
              child: Positioned.fill( 
                child: DraggableScrollableSheet(
                  initialChildSize: initialSheetSize,
                  minChildSize: minSheetSize,
                  maxChildSize: maxChildSize,
                  snap: true,
                  snapSizes: const [initialSheetSize, firstSnapSize],
                  builder: (BuildContext context, ScrollController scrollController) {
                    // --- Obtener sesiones para la fecha seleccionada --- 
                    final sessionsForSelectedDay = _getSessionsForDay(_selectedDate);
                    final today = DateTime.now();
                    final isPastDay = _selectedDate.isBefore(DateTime(today.year, today.month, today.day));

                    return Container(
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(TSizes.cardRadiusXxlg),
                          topRight: Radius.circular(TSizes.cardRadiusXxlg),
                        ),
                        boxShadow: [ 
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 6.0,
                            spreadRadius: 1.0,
                            offset: const Offset(0, -2),
                          )
                        ]
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(TSizes.cardRadiusLg),
                          topRight: Radius.circular(TSizes.cardRadiusLg),
                        ),
                        child: ListView(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: TSizes.sm, left: TSizes.smx, right: TSizes.smx, bottom: TSizes.defaultSpace), // Añadir padding inferior
                          children: [
                            _buildDateNavigation(context, textColorDark),
                            const SizedBox(height: TSizes.spaceBtwItems),

                            // --- Sección Training Cards --- 
                            if (sessionsForSelectedDay.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: TSizes.lg),
                                child: Center(
                                  child: Text(
                                    'No hay entrenamientos programados.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.darkGrey),
                                  ),
                                ),
                              )
                            else
                              ...sessionsForSelectedDay.map((session) => Padding(
                                padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
                                child: TrainingCard(
                                  session: session,
                                  showBorder: true,
                                  isPast: isPastDay, // Usar el flag calculado
                                ),
                              )).toList(), 
                              
                            const SizedBox(height: TSizes.spaceBtwSections), // Espacio antes de las comidas

                            // --- Secciones de Comida --- 
                            _buildMealSection(
                              context, icon: Iconsax.sun_1, iconColor: Colors.orangeAccent, title: 'Breakfast',
                              eatenCal: _mealCaloriesEaten['Breakfast'] ?? 0, // Usar estado
                              goalCal: _mealCaloriesGoal['Breakfast'] ?? 0,   // Usar estado
                              items: _mealItems['Breakfast'],                 // Usar estado
                              buttonColor: buttonBlue,
                              cardBackgroundColor: cardBackgroundColor, titleStyle: titleStyle, subtitleStyle: subtitleStyle, itemTextStyle: itemTextStyle
                            ),
                            _buildMealSection(
                              context, icon: Iconsax.candle_2, iconColor: Colors.redAccent, title: 'Lunch',
                              eatenCal: _mealCaloriesEaten['Lunch'] ?? 0,   // Usar estado
                              goalCal: _mealCaloriesGoal['Lunch'] ?? 0,     // Usar estado
                              items: _mealItems['Lunch'],                   // Usar estado
                              buttonColor: buttonBlue,
                              cardBackgroundColor: cardBackgroundColor, titleStyle: titleStyle, subtitleStyle: subtitleStyle, itemTextStyle: itemTextStyle
                            ),
                            _buildMealSection(
                              context, icon: Iconsax.coffee, iconColor: Colors.blueAccent, title: 'Dinner',
                              eatenCal: _mealCaloriesEaten['Dinner'] ?? 0,  // Usar estado
                              goalCal: _mealCaloriesGoal['Dinner'] ?? 0,    // Usar estado
                              items: _mealItems['Dinner'],                  // Usar estado
                              buttonColor: buttonBlue,
                              cardBackgroundColor: cardBackgroundColor, titleStyle: titleStyle, subtitleStyle: subtitleStyle, itemTextStyle: itemTextStyle
                            ),
                            _buildMealSection(
                              context, icon: Iconsax.cake, iconColor: Colors.lightGreen, title: 'Snacks',
                              eatenCal: _mealCaloriesEaten['Snacks'] ?? 0,  // Usar estado
                              goalCal: _mealCaloriesGoal['Snacks'] ?? 0,    // Usar estado
                              items: _mealItems['Snacks'],                  // Usar estado
                              buttonColor: buttonBlue,
                              cardBackgroundColor: cardBackgroundColor, titleStyle: titleStyle, subtitleStyle: subtitleStyle, itemTextStyle: itemTextStyle
          ),
          const SizedBox(height: TSizes.spaceBtwSections),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ... (Mantener _buildCaloriesSummary, _buildCalorieItem, _buildCircularGoal, _buildMacronutrientsSection, _buildMacroItem, _buildDateNavigation, _buildNavButton, _buildMealSection como métodos de la clase _FullDiaryReplicationState)

  // --- Widgets Constructores (movidos a ser métodos de la clase State) --- //

  Widget _buildCaloriesSummary(
    BuildContext context, 
    Color primaryOrange, 
    Color textColorDark, 
    Color textColorLight, 
    TextStyle valueStyle, 
    TextStyle labelStyle, 
    TextStyle leftValStyle, 
    TextStyle leftUnitStyle, 
    TextStyle leftLabelStyle,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 70.0,
          child: _buildCalorieItem('Eaten', _eatenCaloriesForSelectedDate.toString(), valueStyle, labelStyle)
        ),
        _buildCircularGoal(
            primaryOrange,
            textColorDark,
            leftValStyle,
            leftUnitStyle,
            leftLabelStyle,
            _eatenCaloriesForSelectedDate, 
            _goalCalories                 
        ),
        SizedBox(
          width: 70.0,
          child: _buildCalorieItem('Burned', _burnedCaloriesForSelectedDate.toString(), valueStyle, labelStyle)
        ),
      ],
    );
  }

  Widget _buildCalorieItem(String label, String value, TextStyle valueStyle, TextStyle labelStyle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: valueStyle, textAlign: TextAlign.center),
        Text(label, style: labelStyle, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildCircularGoal(Color primaryOrange, Color textColorDark, TextStyle valueStyle, TextStyle unitStyle, TextStyle labelStyle, int eaten, double goal) {
   // (Código existente de _buildCircularGoal)
    final double left = (goal - eaten).clamp(0.0, goal); // Asegurar que no sea negativo
    final double progress = goal == 0 ? 0 : (eaten / goal).clamp(0.0, 1.0); // Usar parámetros

    return SizedBox(
      width: 90, 
      height: 90,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 5, 
            backgroundColor: primaryOrange.withAlpha(52),
            valueColor: AlwaysStoppedAnimation<Color>(primaryOrange.withAlpha(52)),
            strokeCap: StrokeCap.round,
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(left.toStringAsFixed(0), style: valueStyle),
                Text('Cal', style: unitStyle),
                Text('left', style: labelStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacronutrientsSection(BuildContext context, Color cardBackgroundColor, Color textColorDark, Color textColorLight, Color proteinColor, Color fatColor, Color carbsColor, Color fiberColor, TextStyle headerStyle, TextStyle amountStyle, TextStyle goalStyle, TextStyle labelStyle) {
    // (Código existente de _buildMacronutrientsSection)
    return Card(
      elevation: 1.5,
      shadowColor: TColors.colorBlack.withAlpha(20),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusXxlg)),
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.only(top: TSizes.md, bottom: TSizes.xl, left: TSizes.sm, right: TSizes.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             Padding(
               padding: const EdgeInsets.only(left: TSizes.sm, bottom: TSizes.sm),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.center,
                 children: [
                   Text('Macronutrients', style: headerStyle),
                    Container( 
                       margin: const EdgeInsets.only(top: TSizes.smx),
                       height: 2, width: 50, 
                       decoration: BoxDecoration(
                         color: textColorDark.withAlpha(70),
                         borderRadius: BorderRadius.circular(5)
                       ),
                     ),
                 ],
               ),
             ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceAround,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 _buildMacroItem('Protein', 32, 128, proteinColor, amountStyle, goalStyle, labelStyle),
                 _buildMacroItem('Fat', 4, 103, fatColor, amountStyle, goalStyle, labelStyle),
                 _buildMacroItem('Carbs', 9, 144, carbsColor, amountStyle, goalStyle, labelStyle),
                 _buildMacroItem('Fiber', 0, 21, fiberColor, amountStyle, goalStyle, labelStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String name, double eaten, double goal, Color color, TextStyle amountStyle, TextStyle goalStyle, TextStyle labelStyle) {
   // (Código existente de _buildMacroItem)
    double progress = goal == 0 ? 0 : (eaten / goal).clamp(0.0, 1.0);
    String eatenStr = eaten.toStringAsFixed(0);
    String goalStr = goal.toStringAsFixed(0);

    return Column(
      children: [
        SizedBox(
          width: 55,
          height: 55,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 4,
                backgroundColor: color.withAlpha(38),
                valueColor: AlwaysStoppedAnimation<Color>(color.withAlpha(38)),
                 strokeCap: StrokeCap.round,
              ),
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                 strokeCap: StrokeCap.round,
              ),
              Center(
                 child: Column( 
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Text(eatenStr, style: amountStyle.copyWith(fontSize: TSizes.fontSizeMd)), 
                     Text('/${goalStr}g', style: goalStyle.copyWith(fontSize: TSizes.fontSizeXs)) 
                   ],
                 )
              ),
            ],
          ),
        ),
        const SizedBox(height: TSizes.xs),
        Text(name, style: labelStyle, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildDateNavigation(BuildContext context, Color textColorDark) {
    // Obtener fecha actual y ayer (sin hora) para comparación
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    // No necesitamos selectedDateWithoutTime si comparamos componentes
    // final selectedDateWithoutTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    // Determinar el texto a mostrar comparando componentes
    String labelText;
    if (_selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day) {
      labelText = 'Today';
    } else if (_selectedDate.year == yesterday.year &&
               _selectedDate.month == yesterday.month &&
               _selectedDate.day == yesterday.day) {
      labelText = 'Yesterday';
    } else if (_selectedDate.year == tomorrow.year &&
               _selectedDate.month == tomorrow.month &&
               _selectedDate.day == tomorrow.day) {
      labelText = 'Tomorrow';
    } else {
      // Formato para otras fechas (ej: Apr 9, 2025)
      labelText = DateFormat.yMMMd().format(_selectedDate);
    }

    // Usar Row para la estructura de 3 partes
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Asegurar alineación vertical central
           children: [
        // Botón Izquierdo
        _buildNavButton(context, Icons.chevron_left, () {
          setState(() {
            _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            _loadDataForDate(_selectedDate);
          });
          TDiviceUtility.vibrateMedium();;
        }),
        const SizedBox(width: TSizes.sm), // Espacio entre botón y centro

        // Contenedor Central Expandido
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: TSizes.xs, vertical: TSizes.sm / 1.5), // Restaurar padding vertical
            decoration: BoxDecoration(
              color: Colors.grey.shade100, // Fondo gris claro para el centro
              borderRadius: BorderRadius.circular(TSizes.borderRadiusLg * 2), // Muy redondeado
              // Quitar sombra de aquí si la tuviera
            ),
            child: TextButton.icon(
              icon: Icon(Iconsax.calendar_1, size: 20, color: textColorDark),
                label: Text(
                labelText,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: textColorDark, fontWeight: FontWeight.bold)
                ),
              onPressed: () {
                 _showCalendarPicker(context);
                 TDiviceUtility.vibrateMedium();
              },
              // Asegurarse de que el estilo del botón no interfiera con el contenedor
                 style: TextButton.styleFrom(
                foregroundColor: textColorDark,
                backgroundColor: Colors.transparent, 
                elevation: 0, 
                     padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap, 
                minimumSize: Size.zero, // Añadir para evitar tamaño mínimo
              ),
            ),
          ),
        ),
        const SizedBox(width: TSizes.sm), // Espacio entre centro y botón

        // Botón Derecho
        _buildNavButton(context, Icons.chevron_right, () {
           setState(() {
             _selectedDate = _selectedDate.add(const Duration(days: 1));
             _loadDataForDate(_selectedDate);
           });
           TDiviceUtility.vibrateMedium();
        }),
      ],
    );
  }

  // Botones laterales como cuadrados redondeados
  Widget _buildNavButton(BuildContext context, IconData icon, VoidCallback onPressed) {
    return GestureDetector( 
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(TSizes.sm), 
        decoration: BoxDecoration(
          color: Colors.grey.shade100, 
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd + 5), // Aumentar redondez de esquinas
        ),
        child: Icon(
          icon, 
          color: TColors.darkerGrey, 
          size: 22 
        ),
      ),
    );
  }

  Widget _buildMealSection(
    BuildContext context,
    { required IconData icon,
      required Color iconColor,
      required String title,
      required int eatenCal,
      required int goalCal,
      List<String>? items,
      required Color buttonColor,
      required Color cardBackgroundColor,
      required TextStyle titleStyle,
      required TextStyle subtitleStyle,
      required TextStyle itemTextStyle,
    }) {
    // (Código existente de _buildMealSection)
    return Card(
        elevation: 0.0,
        margin: const EdgeInsets.only(bottom: TSizes.sm),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusMd)),
        color: cardBackgroundColor,
        child: Padding(
        padding: EdgeInsets.symmetric(horizontal: TSizes.xs, vertical: TSizes.sm + 4), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                 Container(
                   width: 40, height: 40,
                   decoration: BoxDecoration(
                     color: iconColor.withAlpha(38),
                     shape: BoxShape.circle,
                   ),
                   child: Icon(icon, color: iconColor, size: 20),
                 ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle),
                      Text('$eatenCal / $goalCal Cal', style: subtitleStyle),
                    ],
                  ),
                ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    style: IconButton.styleFrom(
                       backgroundColor: buttonColor,
                       shape: const CircleBorder(),
                       padding: const EdgeInsets.all(TSizes.xs),
                       minimumSize: const Size(36, 36) 
                    ),
                    onPressed: () { /* Add item */ },
                    tooltip: 'Add $title',
                 ),
              ],
            ),
            if (items != null && items.isNotEmpty) ...[
                const SizedBox(height: TSizes.sm),
                Padding(
                  padding: const EdgeInsets.only(left: 40.0 + TSizes.spaceBtwItems, right: TSizes.md), 
                  child: const Divider(height: 1, thickness: 0.5), 
                ),
                const SizedBox(height: TSizes.xs),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(left: 40.0 + TSizes.spaceBtwItems, top: TSizes.xs, bottom: TSizes.xs, right: TSizes.md),
                      child: Text(item, style: itemTextStyle.copyWith(fontSize: 13)), 
                    )),
            ]
          ],
        ),
      ),
    );
  }

  // --- PASO 4: Crear widget para barras horizontales SIMPLIFICADAS ---
  Widget _buildMinimalHorizontalBars(
    BuildContext context,
    Color proteinColor, Color fatColor, Color carbsColor, Color fiberColor,
    Map<String, double> proteinData, Map<String, double> fatData, Map<String, double> carbsData, Map<String, double> fiberData,
  ) {
    // Contenedor opcional para dar un fondo o padding si es necesario
    // return Container(
    //   padding: const EdgeInsets.symmetric(vertical: TSizes.sm), 
    //   child: Column(...)
    // );
    return Row(
          children: [
        Expanded(child: _buildMinimalHorizontalMacroItem(proteinData['eaten']!, proteinData['goal']!, proteinColor)),
        const SizedBox(width: TSizes.md), // Aumentar espacio entre barras
        Expanded(child: _buildMinimalHorizontalMacroItem(fatData['eaten']!, fatData['goal']!, fatColor)),
        const SizedBox(width: TSizes.md), // Aumentar espacio entre barras
        Expanded(child: _buildMinimalHorizontalMacroItem(carbsData['eaten']!, carbsData['goal']!, carbsColor)),
        const SizedBox(width: TSizes.md), // Aumentar espacio entre barras
        Expanded(child: _buildMinimalHorizontalMacroItem(fiberData['eaten']!, fiberData['goal']!, fiberColor)),
      ],
    );
  }

  // Helper para construir cada barra horizontal SIMPLIFICADA
  Widget _buildMinimalHorizontalMacroItem(double eaten, double goal, Color color) {
     double progress = goal == 0 ? 0 : (eaten / goal).clamp(0.0, 1.0);

     return ClipRRect( // Para bordes redondeados
       borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
       child: LinearProgressIndicator(
         value: progress,
         minHeight: 8, // Altura de la barra
         backgroundColor: color.withAlpha(100), // Aumentar opacidad del fondo de la barra
         valueColor: AlwaysStoppedAnimation<Color>(color), // Color de progreso
       ),
     );
  }

  // --- Añadir función para mostrar el calendario como Dialog --- // MODIFICADO
  void _showCalendarPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent, // Hacer transparente para que el Container controle el fondo
        elevation: 0, // Quitar sombra del Dialog base
        insetPadding: const EdgeInsets.symmetric(horizontal: TSizes.smx, vertical: TSizes.sm), // Márgenes del dialog
        child: ClipRRect( // Aplicar bordes redondeados al contenido
          borderRadius: BorderRadius.circular(TSizes.cardRadiusXxlg),
          child: Container(
            color: Theme.of(context).cardColor, // Usar color de tarjeta del tema
            child: ConstrainedBox( // Limitar altura máxima del dialog
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5, // 60% de la altura pantalla max
              ),
              child: _CalendarView( // Usar el widget del calendario
                initialDate: _selectedDate,
                onDateSelected: (newDate) {
                  Navigator.pop(context); // Cerrar el dialog PRIMERO
                  setState(() { // Luego actualizar estado y cargar datos
                    _selectedDate = newDate;
                    _loadDataForDate(_selectedDate); // <-- LLAMAR AQUI
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- FUNCIÓN PARA OBTENER SESIONES DEL DÍA --- 
  List<Session> _getSessionsForDay(DateTime day) {
    if (_viewModel.trainingData == null) {
      return []; // No hay datos cargados
    }
    // Usar la misma lógica de agrupación/filtrado que calendar.dart si es necesario
    // Por ahora, filtraremos directamente la lista `nextWeekSessions`
    final dateUtc = DateTime.utc(day.year, day.month, day.day);
    return _viewModel.trainingData!.dashboard.nextWeekSessions
        .where((session) {
          final sessionDateUtc = DateTime.utc(
              session.sessionDate.year, session.sessionDate.month, session.sessionDate.day);
          return sessionDateUtc == dateUtc; 
        })
        .toList();
  }

} // Fin de _FullDiaryReplicationState


// --- PASO 5: Crear el Widget _CalendarView (Estructura básica) ---
class _CalendarView extends StatefulWidget {
  // final ScrollController scrollController; // ELIMINADO
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarView({
    super.key,
    // required this.scrollController, // ELIMINADO
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  // Colores y estilos específicos del calendario
  final Color _selectedDayColor = Colors.grey.shade300;
  final Color _todayIndicatorColor = Colors.orange;
  final Color _buttonColor = TColors.colorBlack; // Definir color del botón aquí
  final TextStyle _dayHeaderStyle = const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600);
  final TextStyle _dayNumberStyle = const TextStyle(fontWeight: FontWeight.w500);
  final TextStyle _disabledDayNumberStyle = TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500);
  final TextStyle _selectedDayNumberStyle = const TextStyle(color: Colors.white, fontWeight: FontWeight.bold);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    // Asegurarse de que _currentMonth solo tenga año y mes
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: TSizes.md,
        left: TSizes.defaultSpace,
        right: TSizes.defaultSpace,
        // Quitar padding inferior del sistema ya que no es bottom sheet
        bottom: TSizes.md,
      ),
      child: Column(
        children: [
          // --- Fila superior: Flechas, Mes/Año ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
               IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                     setState(() {
                       _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                     });
                     TDiviceUtility.vibrateMedium();
                  },
                  tooltip: 'Previous Month',
               ),
               Text(
                 DateFormat('MMMM yyyy').format(_currentMonth),
                 style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
               ),
               IconButton(
                 icon: const Icon(Icons.chevron_right),
                 onPressed: () {
                     setState(() {
                       _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                     });
                     TDiviceUtility.vibrateMedium();
                 },
                 tooltip: 'Next Month',
                       ),
                    ],
                 ),
          const SizedBox(height: TSizes.spaceBtwItems),

          // --- Cabecera de Días (Sun, Mon...) ---
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
             children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                 .map((day) => Text(day, style: _dayHeaderStyle))
                 .toList(),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          // --- Grid del Calendario --- // MODIFICADO: Re-añadir Expanded
          Expanded( // <-- Re-añadido Expanded
            child: _buildCalendarGrid(context),
          ),
          const SizedBox(height: TSizes.spaceBtwSections), // <-- Espacio después del Expanded

          // --- Botón Inferior --- // (Sin cambios)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Cambiar a la pantalla de Progress usando el NavigationController
                Get.find<NavigationController>().selectedIndex.value = 2;
                TDiviceUtility.vibrateMedium();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonColor,
                padding: const EdgeInsets.symmetric(vertical: TSizes.smx),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusXxlg)),
                side: BorderSide.none,
              ),
              child: const Text('See my progress', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Método para construir el Grid del Calendario --- // MODIFICADO: Quitar shrinkWrap y NeverScrollable
  Widget _buildCalendarGrid(BuildContext context) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // DateTime.weekday devuelve 1 para Lunes, 7 para Domingo. Ajustamos para que Domingo sea 0.
    final startWeekday = (firstDayOfMonth.weekday % 7);

    // Calcular el número total de celdas necesarias (incluyendo días mes anterior/siguiente)
    // Empezamos desde el primer día del mes y contamos hacia atrás según el día de la semana
    // Luego añadimos los días del mes y rellenamos hasta completar 6 semanas si es necesario
    // Por simplicidad aquí, usaremos un tamaño fijo de 42 celdas (6 semanas)
    const totalCells = 42;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day); // Para comparar solo fechas

    return GridView.builder(
      shrinkWrap: true, // RE-AÑADIDO
      physics: const NeverScrollableScrollPhysics(), // RE-AÑADIDO
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0, // Ajustar para que quepan mejor con margen reducido
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        // Calcular la fecha para esta celda
        final dayOffset = index - startWeekday;
        final date = firstDayOfMonth.add(Duration(days: dayOffset));

        // Determinar si es un día del mes actual
        final isCurrentMonth = date.year == _currentMonth.year && date.month == _currentMonth.month;
        final isSelected = isCurrentMonth && date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
        final isToday = date.year == todayDate.year && date.month == todayDate.month && date.day == todayDate.day;

        // Estilo base
        TextStyle textStyle = isCurrentMonth ? _dayNumberStyle : _disabledDayNumberStyle;
        BoxDecoration decoration = const BoxDecoration();
        Widget? bottomIndicator;

        // Aplicar estilos condicionales
        if (isSelected) {
          textStyle = _selectedDayNumberStyle;
          decoration = BoxDecoration(color: _selectedDayColor, shape: BoxShape.circle);
        } else if (isToday && isCurrentMonth) {
          // Indicador para "hoy" (si no está seleccionado)
          bottomIndicator = Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 5, height: 5,
              margin: const EdgeInsets.only(bottom: 4), // Ajustar posición
              decoration: BoxDecoration(color: _todayIndicatorColor, shape: BoxShape.circle),
       ),
     );
  }

        // Si no es del mes actual, devolver celda vacía
        if (!isCurrentMonth) {
          return Container();
        }

        // Si es del mes actual, construir la celda normal
        return GestureDetector(
          onTap: () {
            widget.onDateSelected(date);
            TDiviceUtility.vibrateMedium();
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.all(2), // Reducir margen para que quepa mejor
            decoration: decoration,
            alignment: Alignment.center,
            child: Stack( // Usar Stack para superponer el indicador de "hoy"
              alignment: Alignment.center,
              children: [
                // Dibujar indicador de HOY encima si está SELECCIONADO
                if (isSelected && isToday) Align(
                  alignment: Alignment.bottomCenter, // Posicionar arriba
                  child: Container(
                    width: 7, height: 7,
                    margin: const EdgeInsets.only(top: 4), // Ajustar posición vertical
                    decoration: BoxDecoration(color: _todayIndicatorColor, shape: BoxShape.circle),
                  ),
                ),
                // Indicador de HOY abajo si NO está seleccionado
                if (bottomIndicator != null && !isSelected) bottomIndicator,
                Text(
                  '${date.day}',
                  style: textStyle,
                ),
              ],
            )
          ),
        );
       },
     );
   }

}