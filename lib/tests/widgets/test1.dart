import 'package:flutter/material.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:iconsax/iconsax.dart'; // Para iconos como calendar, chevron_right

class FullDiaryReplication extends StatelessWidget {
  const FullDiaryReplication({super.key});

  @override
  Widget build(BuildContext context) {
    // Colores aproximados de las imágenes
    const Color backgroundColor = Color(0xFFFEF3E0); // Fondo beige claro
    const Color primaryOrange = Color(0xFFF5A623); // Naranja principal (aprox)
    const Color cardBackgroundColor = Colors.white;
    const Color textColorDark = Color(0xFF4A4A4A); // Gris oscuro para texto
    const Color textColorLight = Color(0xFF9B9B9B); // Gris claro para texto
    const Color proteinColor = Color(0xFFE870A1); // Rosa para Proteína
    const Color fatColor = Color(0xFFF8E81C);     // Amarillo para Grasa
    const Color carbsColor = Color(0xFF50E3C2);    // Turquesa para Carbs
    const Color fiberColor = Color(0xFFBD10E0);    // Morado para Fibra
    const Color buttonBlue = Color(0xFF0A2A4D); // Azul oscuro para botón Add

    // Define text styles locally
    final TextStyle defaultTextStyle = DefaultTextStyle.of(context).style;
    final TextStyle headerStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(color: textColorDark, fontWeight: FontWeight.bold) ?? defaultTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold, color: textColorDark); // Fallback
    final TextStyle titleStyle = Theme.of(context).textTheme.titleMedium!.copyWith(color: textColorDark, fontWeight: FontWeight.w600);
    final TextStyle subtitleStyle = Theme.of(context).textTheme.bodySmall!.copyWith(color: textColorLight);
    final TextStyle itemTextStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(color: textColorDark);
    final TextStyle macroAmountStyle = Theme.of(context).textTheme.titleLarge!.copyWith(color: textColorDark, fontWeight: FontWeight.bold);
    final TextStyle macroGoalStyle = Theme.of(context).textTheme.labelSmall!.copyWith(color: textColorLight);
    final TextStyle macroLabelStyle = Theme.of(context).textTheme.bodySmall!.copyWith(color: textColorDark, fontWeight: FontWeight.w500);
    final TextStyle calorieValueStyle = Theme.of(context).textTheme.headlineMedium!.copyWith(color: textColorDark, fontWeight: FontWeight.bold);
    final TextStyle calorieLabelStyle = Theme.of(context).textTheme.bodySmall!.copyWith(color: textColorLight);
    final TextStyle calLeftValueStyle = Theme.of(context).textTheme.displaySmall!.copyWith(color: textColorDark, fontWeight: FontWeight.bold, height: 1.1);
    final TextStyle calLeftUnitStyle = Theme.of(context).textTheme.titleMedium!.copyWith(color: textColorDark, height: 1.1);
    final TextStyle calLeftLabelStyle = Theme.of(context).textTheme.bodySmall!.copyWith(color: textColorDark, height: 1.1);

    // Estimación de tamaños para DraggableScrollableSheet en Stack
    // TODO: Ajustar estos valores basados en pruebas y altura real de los widgets
    const double initialSheetSize = 0.5; // AJUSTADO: Para empezar bajo el contenido fijo en Stack (estimado)
    const double minSheetSize = 0.5;   // MANTENIDO: Altura mínima para cubrir macros (aprox)
    const double maxChildSize = 1.0;   // MANTENIDO: Permitir que cubra toda la altura hasta la AppBar
    const double firstSnapSize = 0.77;   // MANTENIDO: Permitir que cubra toda la altura hasta la AppBar

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // --- Contenido Fijo (detrás de la hoja) ---
            Column(
              children: [
                // --- Contador de Racha (movido desde AppBar) ---
                Padding(
                  padding: const EdgeInsets.only(top: TSizes.lg, right: TSizes.md, left: TSizes.md),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs / 2),
                      decoration: BoxDecoration(
                        color: primaryOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.flash_1, color: primaryOrange, size: 16),
                          const SizedBox(width: TSizes.xs),
                          Text('1', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: primaryOrange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                // --- Resumen de Calorías ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
                  child: _buildCaloriesSummary(context, primaryOrange, textColorDark, textColorLight, calorieValueStyle, calorieLabelStyle, calLeftValueStyle, calLeftUnitStyle, calLeftLabelStyle),
                ),
                const SizedBox(height: TSizes.sm),
                // --- Macronutrientes ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
                  child: _buildMacronutrientsSection(
                    context, cardBackgroundColor, textColorDark, textColorLight,
                    proteinColor, fatColor, carbsColor, fiberColor,
                    headerStyle, macroAmountStyle, macroGoalStyle, macroLabelStyle
                  ),
                ),
                const SizedBox(height: TSizes.lg),
              ],
            ),

            // --- Hoja Deslizable (encima del contenido fijo) ---
            Positioned.fill( // Mantenido para asegurar que llene el Stack
              child: DraggableScrollableSheet(
                initialChildSize: initialSheetSize,
                minChildSize: minSheetSize,
                maxChildSize: maxChildSize,
                snap: true,
                snapSizes: const [initialSheetSize, firstSnapSize],
                builder: (BuildContext context, ScrollController scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: cardBackgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(TSizes.cardRadiusLg),
                        topRight: Radius.circular(TSizes.cardRadiusLg),
                      ),
                      boxShadow: [ // Sombra sutil para dar efecto de elevación
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10.0,
                          spreadRadius: 1.0,
                          offset: Offset(0, -2),
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
                        padding: const EdgeInsets.only(top: TSizes.md, left: TSizes.md, right: TSizes.md),
                        children: [
                          _buildDateNavigation(context, textColorDark),
                          const SizedBox(height: TSizes.spaceBtwItems),
                          _buildMealSection(
                            context, icon: Iconsax.sun_1, iconColor: Colors.orangeAccent, title: 'Breakfast',
                            eatenCal: 224, goalCal: 617, items: ['Teriyaki chicken (224 Cal)'], buttonColor: buttonBlue,
                            cardBackgroundColor: cardBackgroundColor, titleStyle: titleStyle, subtitleStyle: subtitleStyle, itemTextStyle: itemTextStyle
                          ),
                          _buildMealSection(
                            context, icon: Iconsax.candle_2, iconColor: Colors.redAccent, title: 'Lunch',
                            eatenCal: 0, goalCal: 617, buttonColor: buttonBlue,
                            cardBackgroundColor: cardBackgroundColor, titleStyle: titleStyle, subtitleStyle: subtitleStyle, itemTextStyle: itemTextStyle
                          ),
                          _buildMealSection(
                            context, icon: Iconsax.coffee, iconColor: Colors.blueAccent, title: 'Dinner',
                            eatenCal: 0, goalCal: 617, buttonColor: buttonBlue,
                            cardBackgroundColor: cardBackgroundColor, titleStyle: titleStyle, subtitleStyle: subtitleStyle, itemTextStyle: itemTextStyle
                          ),
                          _buildMealSection(
                            context, icon: Iconsax.cake, iconColor: Colors.lightGreen, title: 'Snacks',
                            eatenCal: 0, goalCal: 206, buttonColor: buttonBlue,
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
          ],
        ),
      ),
    );
  }

  // --- Widgets Constructores --- //

  Widget _buildCaloriesSummary(BuildContext context, Color primaryOrange, Color textColorDark, Color textColorLight, TextStyle valueStyle, TextStyle labelStyle, TextStyle leftValStyle, TextStyle leftUnitStyle, TextStyle leftLabelStyle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCalorieItem('Eaten', '223', valueStyle, labelStyle),
        _buildCircularGoal(primaryOrange, textColorDark, leftValStyle, leftUnitStyle, leftLabelStyle),
        _buildCalorieItem('Burned', '0', valueStyle, labelStyle),
      ],
    );
  }

  Widget _buildCalorieItem(String label, String value, TextStyle valueStyle, TextStyle labelStyle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: valueStyle),
        Text(label, style: labelStyle),
      ],
    );
  }

  Widget _buildCircularGoal(Color primaryOrange, Color textColorDark, TextStyle valueStyle, TextStyle unitStyle, TextStyle labelStyle) {
    const double goal = 2055; // Estimado
    const double left = 1832;
    const double eaten = goal - left;
    final double progress = (eaten / goal).clamp(0.0, 1.0);

    return SizedBox(
      width: 120, // Ligeramente más grande
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 10, // Más grueso
            backgroundColor: primaryOrange.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(primaryOrange.withOpacity(0.2)),
            strokeCap: StrokeCap.round,
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 10,
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
    return Card(
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.08),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusLg)),
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TSizes.lg, horizontal: TSizes.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding(
               padding: const EdgeInsets.only(left: TSizes.sm, bottom: TSizes.sm),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('Macronutrients', style: headerStyle),
                    Container( // Línea corta debajo del título
                       margin: const EdgeInsets.only(top: TSizes.xs / 2),
                       height: 3, width: 30, 
                       decoration: BoxDecoration(
                         color: textColorDark.withOpacity(0.5),
                         borderRadius: BorderRadius.circular(2)
                       ),
                     ),
                 ],
               ),
             ),
            const SizedBox(height: TSizes.spaceBtwItems),
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
    double progress = goal == 0 ? 0 : (eaten / goal).clamp(0.0, 1.0);
    String eatenStr = eaten.toStringAsFixed(0);
    String goalStr = goal.toStringAsFixed(0);

    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 6,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.15)),
                 strokeCap: StrokeCap.round,
              ),
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                 strokeCap: StrokeCap.round,
              ),
              Center(
                 child: Text(eatenStr, style: amountStyle.copyWith(fontSize: 18)) // Ajustar tamaño
              ),
            ],
          ),
        ),
        const SizedBox(height: TSizes.xs),
         Text('/${goalStr}g', style: goalStyle),
        const SizedBox(height: TSizes.sm),
        Text(name, style: labelStyle, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildDateNavigation(BuildContext context, Color textColorDark) {
     return Card(
      elevation: 1.0,
      shadowColor: Colors.black.withOpacity(0.08),
      margin: EdgeInsets.zero,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius * 1.5)), // Más redondeado
       color: Colors.white,
       child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
         child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             _buildNavButton(context, Iconsax.arrow_left_2, () {}), // Usar Iconsax
             TextButton.icon(
                icon: Icon(Iconsax.calendar_1, size: 20, color: textColorDark), // Usar Iconsax
                label: Text('Today', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: textColorDark, fontWeight: FontWeight.bold)),
                onPressed: () { /* show calendar */ },
                style: TextButton.styleFrom(foregroundColor: textColorDark),
              ),
             _buildNavButton(context, Iconsax.arrow_right_3, () {}), // Usar Iconsax
           ],
         ),
       ),
     );
  }

  // Helper para botones de navegación izquierda/derecha
  Widget _buildNavButton(BuildContext context, IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(TSizes.buttonRadius),
      child: Padding(
        padding: const EdgeInsets.all(TSizes.sm), // Área de toque
        child: Icon(icon, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7), size: 20),
      ),
    );
  }

  // Helper específico para las tarjetas de comida
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
    return Card(
       elevation: 0.0,
       margin: const EdgeInsets.only(bottom: TSizes.sm),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusMd)),
       color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(TSizes.md, TSizes.sm + 4, TSizes.sm, TSizes.sm + 4), // Ajustar padding
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                 Container(
                   width: 40, height: 40,
                   decoration: BoxDecoration(
                     color: iconColor.withOpacity(0.15),
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
                 // Botón de añadir
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    style: IconButton.styleFrom(
                       backgroundColor: buttonColor,
                       shape: const CircleBorder(),
                       padding: const EdgeInsets.all(TSizes.xs),
                       minimumSize: const Size(36, 36) // Tamaño fijo botón
                    ),
                    onPressed: () { /* Add item */ },
                    tooltip: 'Add $title',
                 ),
              ],
            ),
            if (items != null && items.isNotEmpty) ...[
                const SizedBox(height: TSizes.sm),
                Padding(
                  padding: const EdgeInsets.only(left: 40.0 + TSizes.spaceBtwItems, right: TSizes.md), // Alineación con texto
                  child: const Divider(height: 1, thickness: 0.5), 
                ),
                const SizedBox(height: TSizes.xs),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(left: 40.0 + TSizes.spaceBtwItems, top: TSizes.xs, bottom: TSizes.xs, right: TSizes.md),
                      child: Text(item, style: itemTextStyle.copyWith(fontSize: 13)), // Ajustar tamaño
                    )).toList(),
            ]
          ],
        ),
      ),
    );
  }

}