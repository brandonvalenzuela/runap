import 'package:flutter/material.dart';
// Asegúrate de que estas rutas sean correctas para tu proyecto
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';

class FullDiaryReplication extends StatelessWidget {
  const FullDiaryReplication({super.key});

  @override
  Widget build(BuildContext context) {
    // Colores aproximados de las imágenes
    const Color backgroundColor = Color(0xFFfef3e0); // Fondo beige claro
    const Color primaryOrange = Color(0xFFf5a623); // Naranja principal
    const Color cardBackgroundColor = Colors.white;
    const Color textColorDark = Color(0xFF4a4a4a); // Gris oscuro para texto
    const Color textColorLight = Color(0xFF9b9b9b); // Gris claro para texto
    const Color proteinColor = Color(0xFFe870a1);
    const Color fatColor = Color(0xFFf8e81c);
    const Color carbsColor = Color(0xFF50e3c2);
    const Color fiberColor = Color(0xFFb480eb); // Ajustado para mejor visibilidad que bd10e0

    // Define text styles locally if Theme.of(context) might cause issues in static context
    final TextStyle titleMediumBoldDark = TextStyle(color: textColorDark, fontWeight: FontWeight.bold, fontSize: 16); // Approx titleMedium
    final TextStyle bodySmallLight = TextStyle(color: textColorLight, fontSize: 12); // Approx bodySmall
    final TextStyle bodySmallDark = TextStyle(color: textColorDark, fontSize: 13);


    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: textColorDark),
          onPressed: () {
            // Acción de cerrar (no funcional en estático)
          },
        ),
        actions: [
          // Icono de "streak"
          Padding(
            padding: const EdgeInsets.only(right: TSizes.sm),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                   Icon(Icons.local_fire_department_rounded, color: primaryOrange.withOpacity(0.5), size: 30),
                   const Text('1', style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView( // Usamos ListView para permitir el scroll
        padding: const EdgeInsets.all(TSizes.md),
        children: [
          // --- Sección Resumen Superior (Calorías) ---
          _buildCaloriesSummary(primaryOrange, textColorDark, textColorLight),
          const SizedBox(height: TSizes.spaceBtwSections),

          // --- Sección Macronutrientes ---
          _buildMacronutrientsSection(
            context, // Necesario para Theme
            titleMediumBoldDark, // Pass styles
            cardBackgroundColor,
            textColorDark,
            textColorLight,
            proteinColor,
            fatColor,
            carbsColor,
            fiberColor,
          ),
          const SizedBox(height: TSizes.spaceBtwSections),

          // --- Navegación de Fecha ---
          _buildDateNavigation(textColorDark),
          const SizedBox(height: TSizes.spaceBtwItems), // Menos espacio antes de la lista

          // --- Lista Principal (Comidas, Actividades, etc.) ---
           _buildMainList(
              context,
              titleMediumBoldDark, // Pass styles
              bodySmallLight,
              bodySmallDark,
              cardBackgroundColor,
              textColorDark,
              textColorLight
            ),

          // --- Podrías añadir aquí las otras secciones como Water Challenge si es necesario ---
          const SizedBox(height: TSizes.spaceBtwSections),

        ],
      ),
       // --- Bottom Navigation Bar (Estático) ---
       bottomNavigationBar: _buildBottomNavigationBar(primaryOrange, textColorLight),
    );
  }

  // --- Widgets Constructores para cada Sección ---

  Widget _buildCaloriesSummary(Color primaryOrange, Color textColorDark, Color textColorLight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCalorieItem('Eaten', '223', '', textColorDark, textColorLight),
        _buildCircularGoal(primaryOrange, textColorDark),
        _buildCalorieItem('Burned', '0', '', textColorDark, textColorLight),
      ],
    );
  }

  Widget _buildCalorieItem(String label, String value, String unit, Color textColorDark, Color textColorLight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColorDark)),
        Text(label, style: TextStyle(fontSize: 12, color: textColorLight)),
        if (unit.isNotEmpty) Text(unit, style: TextStyle(fontSize: 12, color: textColorLight)),
      ],
    );
  }

  Widget _buildCircularGoal(Color primaryOrange, Color textColorDark) {
    // Simulación del indicador circular
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Círculo de fondo
          CircularProgressIndicator(
            value: 1.0, // Círculo completo
            strokeWidth: 8,
            backgroundColor: primaryOrange.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(primaryOrange.withOpacity(0.2)),
            strokeCap: StrokeCap.round, // Bordes redondeados
          ),
          // Progreso (simulado)
          CircularProgressIndicator(
            value: (2055 - 1832) / 2055, // Simula 1832 cal left de un total (ej: 2055)
            strokeWidth: 8,
            valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
             strokeCap: StrokeCap.round, // Bordes redondeados
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('1832', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColorDark, height: 1.1)),
                const Text('Cal', style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.1)),
                const Text('left', style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacronutrientsSection(BuildContext context, TextStyle titleStyle, Color cardBackgroundColor, Color textColorDark, Color textColorLight, Color proteinColor, Color fatColor, Color carbsColor, Color fiberColor) {
    return Card(
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: EdgeInsets.zero, // Sin margen exterior
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusLg)),
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TSizes.md, horizontal: TSizes.sm), // Ajustar padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding(
               padding: const EdgeInsets.only(left: TSizes.sm), // Padding solo para el título
               child: Text('Macronutrients', style: titleStyle),
             ),
            const SizedBox(height: TSizes.spaceBtwItems),
            // Vista de los macros
             _buildMacroRow([
               _buildMacroItem('Protein', 32, 128, proteinColor, textColorDark, textColorLight),
               _buildMacroItem('Fat', 4, 103, fatColor, textColorDark, textColorLight),
               _buildMacroItem('Carbs', 9, 144, carbsColor, textColorDark, textColorLight),
               _buildMacroItem('Fiber', 0, 21, fiberColor, textColorDark, textColorLight),
            ]),
          ],
        ),
      ),
    );
  }

   Widget _buildMacroRow(List<Widget> items) {
     // Usa Wrap si no caben en una fila en pantallas pequeñas, o Row si siempre caben
     return Row(
       mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribuir items
       crossAxisAlignment: CrossAxisAlignment.start,
       children: items, // No usar Expanded aquí, controlar tamaño en _buildMacroItem
     );
   }

  Widget _buildMacroItem(String name, double eaten, double goal, Color color, Color textColorDark, Color textColorLight) {
    double progress = goal == 0 ? 0 : (eaten / goal).clamp(0.0, 1.0);
    String eatenStr = eaten.toStringAsFixed(0); // Sin decimales
    String goalStr = goal.toStringAsFixed(0);

    return Column(
      children: [
        // Indicador circular pequeño
        SizedBox(
          width: 55, // Ligeramente más grande
          height: 55,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 5,
                backgroundColor: color.withOpacity(0.15), // Más suave
                valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.15)),
                 strokeCap: StrokeCap.round,
              ),
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                 strokeCap: StrokeCap.round,
              ),
              Center(
                 child: Text(
                    eatenStr,
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColorDark, fontSize: 13), // Un poco más grande
                 )
              ),
            ],
          ),
        ),
        const SizedBox(height: TSizes.xs / 2), // Menos espacio
         Text(
             '/${goalStr}g',
             style: TextStyle(fontSize: 11, color: textColorLight) // Un poco más grande
         ),
        const SizedBox(height: TSizes.sm),
        Text(
            name,
            style: TextStyle(fontSize: 13, color: textColorDark, fontWeight: FontWeight.w500), // Un poco más grande
            textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDateNavigation(Color textColorDark) {
     return Card(
      elevation: 1.0,
      shadowColor: Colors.black.withOpacity(0.08),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius)),
      color: Colors.white, // Fondo blanco para esta barra
       child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: TSizes.xs, vertical: TSizes.xs / 2),
         child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             IconButton(
               icon: Icon(Icons.chevron_left, color: textColorDark),
               onPressed: () {}, // No funcional
               tooltip: 'Previous Day',
                splashRadius: 20,
             ),
             // Botón central como TextButton para el popup
             TextButton.icon(
                icon: Icon(Icons.calendar_today_outlined, size: 16, color: textColorDark),
                label: Text(
                  'Today', // Podría ser dinámico si hubiera lógica
                  style: TextStyle(color: textColorDark, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  // Aquí se podría llamar a _showCalendarPopup(context) si se implementa
                },
                 style: TextButton.styleFrom(
                     foregroundColor: textColorDark, // Color de texto y icono
                     padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
                     tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Menor área de tap
                  ),
              ),

             IconButton(
               icon: Icon(Icons.chevron_right, color: textColorDark),
               onPressed: () {}, // No funcional
               tooltip: 'Next Day',
               splashRadius: 20,
             ),
           ],
         ),
       ),
     );
  }

  Widget _buildMainList(BuildContext context, TextStyle titleStyle, TextStyle subtitleStyle, TextStyle itemTextStyle, Color cardBackgroundColor, Color textColorDark, Color textColorLight) {
    // Lista estática de elementos como en las imágenes
    return Column(
      children: [
        _buildListItem(
            context: context,
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            itemTextStyle: itemTextStyle,
            icon: Icons.wb_sunny, // Icono aproximado
            iconColor: Colors.orangeAccent,
            title: 'Breakfast',
            subtitle: '224 / 617 Cal', // Datos de ejemplo
            trailing: const Icon(Icons.add_circle, color: TColors.primaryColor), // Icono +
            items: ['Teriyaki chicken (224 Cal)'], // Ejemplo de item añadido
            cardBackgroundColor: cardBackgroundColor,
            textColorDark: textColorDark,
            textColorLight: textColorLight),
        _buildListItem(
            context: context,
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            itemTextStyle: itemTextStyle,
            icon: Icons.restaurant, // Icono aproximado
            iconColor: Colors.redAccent,
            title: 'Lunch',
            subtitle: '0 / 617 Cal',
             trailing: const Icon(Icons.add_circle, color: TColors.primaryColor),
            cardBackgroundColor: cardBackgroundColor,
            textColorDark: textColorDark,
            textColorLight: textColorLight),
        _buildListItem(
            context: context,
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            itemTextStyle: itemTextStyle,
            icon: Icons.local_dining, // Icono aproximado
            iconColor: Colors.blueAccent,
            title: 'Dinner',
            subtitle: '0 / 617 Cal',
             trailing: const Icon(Icons.add_circle, color: TColors.primaryColor),
            cardBackgroundColor: cardBackgroundColor,
            textColorDark: textColorDark,
            textColorLight: textColorLight),
         _buildListItem(
            context: context,
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            itemTextStyle: itemTextStyle,
            icon: Icons.apple, // Icono aproximado
            iconColor: Colors.lightGreen, // Ajustado
            title: 'Snacks',
            subtitle: '0 / 206 Cal',
             trailing: const Icon(Icons.add_circle, color: TColors.primaryColor),
            cardBackgroundColor: cardBackgroundColor,
            textColorDark: textColorDark,
            textColorLight: textColorLight),
          _buildActivityItem( // Widget específico para Activities
            context: context,
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            cardBackgroundColor: cardBackgroundColor,
            textColorDark: textColorDark,
            textColorLight: textColorLight
            ),
         // Añade aquí _buildListItem para Water Challenge si es necesario
         _buildListItem(
             context: context,
             titleStyle: titleStyle,
             subtitleStyle: subtitleStyle,
             itemTextStyle: itemTextStyle,
             icon: Icons.water_drop, // Icono aproximado
             iconColor: Colors.lightBlueAccent,
             title: 'Water Challenge',
             subtitle: 'Water',
             trailing: const Icon(Icons.more_horiz, color: Colors.grey), // Icono ...
             cardBackgroundColor: cardBackgroundColor,
             textColorDark: textColorDark,
             textColorLight: textColorLight,
             items: ['0.00 L'], // Ejemplo de contenido de agua
          ),
      ],
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required TextStyle titleStyle,
    required TextStyle subtitleStyle,
    required TextStyle itemTextStyle,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    List<String>? items,
    required Widget trailing,
    required Color cardBackgroundColor,
    required Color textColorDark,
    required Color textColorLight,
  }) {
    return Card(
       elevation: 0.0, // Sin elevación para integrarse más
       margin: const EdgeInsets.only(bottom: TSizes.sm), // Menos margen
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusMd)),
       color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TSizes.sm, horizontal: TSizes.md), // Padding ajustado
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                 // Icono circular
                 Container(
                   width: 36, height: 36, // Tamaño fijo
                   padding: const EdgeInsets.all(TSizes.xs), // Padding interno
                   decoration: BoxDecoration(
                     color: iconColor.withOpacity(0.15),
                     shape: BoxShape.circle,
                   ),
                   child: Icon(icon, color: iconColor, size: 18), // Icono más pequeño
                 ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle),
                      Text(subtitle, style: subtitleStyle),
                    ],
                  ),
                ),
                 // Botón de añadir/trailing
                 InkWell(
                    onTap: () {}, // No funcional
                    child: Padding(
                      padding: const EdgeInsets.all(TSizes.xs), // Padding para el área de tap
                      child: trailing,
                    ),
                    borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                    splashColor: TColors.primaryColor.withOpacity(0.1),
                 ),
              ],
            ),
             // Mostrar items si existen (ej: comida añadida)
            if (items != null && items.isNotEmpty) ...[
                const SizedBox(height: TSizes.sm),
                const Divider(height: 1, thickness: 0.5, indent: 48, endIndent: 16), // Divider alineado
                const SizedBox(height: TSizes.xs),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(left: 48 + TSizes.sm, top: TSizes.xs, bottom: TSizes.xs, right: 16), // Alineado aprox
                      child: Text(item, style: itemTextStyle),
                    )).toList(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
     required BuildContext context,
     required TextStyle titleStyle,
     required TextStyle subtitleStyle,
     required Color cardBackgroundColor,
     required Color textColorDark,
     required Color textColorLight,
  }) {
     // Similar a _buildListItem pero con contenido específico para Actividades
     return Card(
       elevation: 0.0,
       margin: const EdgeInsets.only(bottom: TSizes.sm),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusMd)),
       color: cardBackgroundColor,
        child: Padding(
        padding: const EdgeInsets.fromLTRB(TSizes.md, TSizes.md, TSizes.md, TSizes.lg), // Más padding abajo
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
              children: [
                 Container(
                    width: 36, height: 36,
                   padding: const EdgeInsets.all(TSizes.xs),
                   decoration: BoxDecoration(
                     color: Colors.amber.withOpacity(0.15), // Color ajustado
                     shape: BoxShape.circle,
                   ),
                   child: const Icon(Icons.emoji_events, color: Colors.amber, size: 18), // Icono de trofeo
                 ),
                 const SizedBox(width: TSizes.spaceBtwItems),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('Activities', style: titleStyle),
                       Text('0 Cal Burned', style: subtitleStyle), // Ejemplo
                     ],
                   ),
                 ),
                 // No hay botón de añadir aquí directamente
               ],
             ),
              const SizedBox(height: TSizes.md),
              Padding(
                padding: const EdgeInsets.only(left: 48 + TSizes.sm, right: 16), // Alineado
                child: Text(
                   'Automatically track your activities by connecting to your health apps',
                   style: subtitleStyle.copyWith(fontSize: 13), // Ligeramente más grande
                ),
              ),
              const SizedBox(height: TSizes.lg),
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
                 child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribuir botones
                    children: [
                       OutlinedButton(
                         onPressed: () {},
                         style: OutlinedButton.styleFrom(
                           side: const BorderSide(color: TColors.primaryColor),
                           foregroundColor: TColors.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: TSizes.lg * 1.5, vertical: TSizes.sm), // Más padding
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius)),
                         ),
                         child: const Text('Connect'),
                       ),
                       // const SizedBox(width: TSizes.spaceBtwItems), // Quitado para usar spaceEvenly
                       ElevatedButton(
                         onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColors.darkGrey, // Color más oscuro como en la imagen
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: TSizes.lg* 1.5, vertical: TSizes.sm),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius)),
                          ),
                         child: const Text('Add an activity'),
                       ),
                    ],
                 ),
               )
          ],
         ),
       ),
     );
  }

  // --- Bottom Navigation Bar Estático ---
   Widget _buildBottomNavigationBar(Color textColorDark, Color textColorLight) {
     return BottomNavigationBar(
       currentIndex: 1, // Índice estático (Journal seleccionado)
       type: BottomNavigationBarType.fixed, // Para mostrar labels siempre
       backgroundColor: Colors.white,
       selectedItemColor: textColorDark, // Seleccionado es oscuro en la imagen
       unselectedItemColor: textColorLight, // No seleccionado gris claro
       showUnselectedLabels: true, // Mostrar siempre labels
       selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
       unselectedLabelStyle: const TextStyle(fontSize: 10),
       items: const [
         BottomNavigationBarItem(
           icon: Icon(Icons.shield_outlined), // Icono Coach (aproximado)
           label: 'Coach',
         ),
         BottomNavigationBarItem(
           icon: Icon(Icons.article_outlined), // Icono Journal
           label: 'Journal',
         ),
         BottomNavigationBarItem(
           icon: Icon(Icons.person_outline), // Icono Profile
           label: 'Profile',
         ),
       ],
       onTap: (index) {
         // No funcional en estático
       },
     );
   }
}