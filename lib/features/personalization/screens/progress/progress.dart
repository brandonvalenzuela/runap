import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/common/widgets/icons/t_circular_image.dart';
import 'package:runap/features/personalization/controllers/user_controller.dart';
import 'package:runap/features/personalization/screens/settings/settings.dart'; // Para navegar a Settings
import 'package:runap/features/personalization/screens/profile/profile.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';
// Importar chart si se usa: import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Colores basados en la imagen (ajustar según tu tema)
    final headerBgColor = isDarkMode ? TColors.darkerGrey : const Color(0xFFE3F2F5); // Un azul claro/grisáceo
    final defaultBgColor = isDarkMode ? TColors.black : Colors.white;

    // Placeholders para los datos que no tenemos
    const userGoalText = 'Lose weight';
    const dailyCalories = '2055 Cal / d';
    const startWeight = '85.0 kg';
    const currentWeight = '85.0 kg';
    const goalWeight = '75.0 kg';

    // Datos placeholder para la lista de pesos guardados
    final List<Map<String, dynamic>> savedWeights = [
      {'weight': '85.0 kg', 'date': DateTime(2025, 4, 9)},
      // Añadir más entradas de ejemplo si es necesario
    ];

    // Datos placeholder para el gráfico (simplificado)
    // TODO: Reemplazar con datos reales y configuración de fl_chart
    // Comentado por ahora para evitar error de FlSpot
    // final List<FlSpot> chartSpots = [
    //    FlSpot(0, 85), // Representa 09/04 -> 85kg (simplificado)
    //    // FlSpot(1, 84), // Ejemplo
    //    // FlSpot(2, 83.5), // Ejemplo
    // ];

    return DefaultTabController(
      length: 2, // Dos pestañas: Weight, Nutrition
      child: Scaffold(
        backgroundColor: defaultBgColor,
        body: NestedScrollView( // Permite scroll con header/appbar que se colapsa/fija
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                automaticallyImplyLeading: false, // Sin botón de atrás por defecto
                pinned: true, // El TabBar se queda fijo
                floating: true, // El header aparece al hacer scroll hacia abajo
                expandedHeight: 230.0, // Altura expandida para el header completo
                backgroundColor: headerBgColor,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin, // Fija el TabBar abajo
                  background: _buildHeaderContent(context, userController, userGoalText, dailyCalories, headerBgColor),
                ),
                // El TabBar va en la parte inferior del AppBar colapsado/fijo
                bottom: TabBar(
                  indicatorColor: TColors.black, // Color del indicador
                  labelColor: TColors.black, // Color del texto seleccionado
                  unselectedLabelColor: Colors.grey, // Color del texto no seleccionado
                  tabs: const [
                    Tab(text: 'Weight'),
                    Tab(text: 'Nutrition'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // --- Contenido Pestaña WEIGHT ---
              _buildWeightTabContent(context, startWeight, currentWeight, goalWeight, /*chartSpots,*/ savedWeights), // chartSpots comentado
              
              // --- Contenido Pestaña NUTRITION (Placeholder) ---
              const Center(child: Text('Nutrition Tab Content (TODO)')),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Helper para el contenido del Header ---
  Widget _buildHeaderContent(BuildContext context, UserController userController, String goalText, String calories, Color bgColor) {
    // No envolver todo el Container con GestureDetector
    return Container(
      color: bgColor,
      padding: const EdgeInsets.only(
        left: TSizes.defaultSpace, 
        right: TSizes.defaultSpace, 
        top: kToolbarHeight, 
        bottom: kTextTabBarHeight
      ),
      child: Obx(() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Envolver Avatar con GestureDetector
          GestureDetector(
            onTap: () => Get.to(() => const ProfileScreen(), transition: Transition.rightToLeft),
            child: TCircularImage(
              image: userController.profilePicture.isNotEmpty
                ? userController.profilePicture
                : TImages.userIcon, 
              width: 60,
              height: 60,
              isNetworkImage: userController.profilePicture.isNotEmpty,
              backgroundColor: TColors.lightContainer,
            ),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          // Envolver Columna de texto con GestureDetector
          Expanded(
            child: GestureDetector(
              onTap: () => Get.to(() => const ProfileScreen(), transition: Transition.rightToLeft),
              // Añadir un color de fondo transparente para asegurar que el GestureDetector detecte el tap en toda la columna
              // Aunque generalmente no es necesario si los hijos ocupan el espacio.
              // color: Colors.transparent, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    userController.fullName, 
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    goalText, 
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: TSizes.xs),
                  // Contenedor de calorías puede quedar dentro, no necesita su propio GestureDetector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs / 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(TSizes.borderRadiusXl),
                    ),
                    child: Text(
                      calories,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Botón de Settings (ya es interactivo)
          IconButton(
            icon: const Icon(Iconsax.setting_2, color: Colors.black,weight: 200,),
            onPressed: () => Get.to(() => const SettingsScreen()),
          ),
        ],
      )),
    );
  }

  // --- Widget Helper para el contenido de la pestaña WEIGHT ---
  Widget _buildWeightTabContent(BuildContext context, String start, String current, String goal, /*List<FlSpot> spots,*/ List<Map<String, dynamic>> history) {
     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
     final buttonColor = isDarkMode ? TColors.light : TColors.dark; // Botón oscuro

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Métricas de Peso ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeightMetric(context, start, 'Start weight'),
              _buildWeightMetric(context, current, 'Current weight'),
              _buildWeightMetric(context, goal, 'Goal weight'),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwSections),

          // --- Botón Añadir Entrada ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { /* TODO: Implementar Add Weight Entry */ },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: isDarkMode ? TColors.dark : TColors.light,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusXl)),
                padding: const EdgeInsets.symmetric(vertical: TSizes.md),
              ),
              child: Text('Add a weight entry', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDarkMode ? TColors.dark : TColors.light, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwSections * 1.5),

          // --- Gráfico ---
          Text('Weight', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: TSizes.spaceBtwItems),
          Container(
            height: 200, // Altura fija para el gráfico
            width: double.infinity,
            decoration: BoxDecoration(
               color: isDarkMode ? TColors.darkerGrey : TColors.lightGrey.withOpacity(0.5),
               borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            // TODO: Implementar gráfico real con fl_chart
            child: Center(child: Text('Weight Chart Placeholder', style: Theme.of(context).textTheme.bodySmall)),
          ),
          const SizedBox(height: TSizes.spaceBtwSections * 1.5),

          // --- Historial ---
          Text('Weights saved', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: TSizes.spaceBtwItems),
          // TODO: Reemplazar con ListView.builder si la lista es larga
          Column(
             children: history.map((entry) => _buildWeightHistoryItem(context, entry['weight'], entry['date'])).toList(),
          ),
          const SizedBox(height: TSizes.spaceBtwSections),

        ],
      ),
    );
  }

  // Helper para una métrica de peso individual
  Widget _buildWeightMetric(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: TSizes.xs / 2),
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey)),
      ],
    );
  }

   // Helper para un item del historial de peso
  Widget _buildWeightHistoryItem(BuildContext context, String weight, DateTime date) {
    // Formatear fecha (p.ej., Apr 9, 2025)
    // final formattedDate = DateFormat('MMM d, yyyy').format(date); // Necesita import 'package:intl/intl.dart';
    final formattedDate = '${date.month}/${date.day}/${date.year}'; // Formato simple por ahora

    return InkWell(
      onTap: () { /* TODO: Implementar ver/editar entrada */ },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TSizes.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(weight, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
            Row(
              children: [
                Text(formattedDate, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                const SizedBox(width: TSizes.xs),
                const Icon(Iconsax.arrow_right_3, size: TSizes.iconSm, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

}


