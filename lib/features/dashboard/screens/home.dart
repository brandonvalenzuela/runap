import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/common/widgets/appbar/appbar.dart';
import 'package:runap/common/widgets/training/training_card.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:runap/features/dashboard/viewmodels/training_view_model.dart';
import 'package:runap/features/map/screen/map.dart';
import 'package:runap/features/personalization/screens/profile/profile.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Asegurar que el ViewModel esté disponible antes de usarlo
    // Usamos lazyPut porque podría estar registrado con anterioridad
    if (!Get.isRegistered<TrainingViewModel>()) {
      print("📱 HomeScreen - Registrando TrainingViewModel");
      Get.put(TrainingViewModel(), permanent: true);
    } else {
      print("📱 HomeScreen - TrainingViewModel ya registrado");
    }

    // Ahora usamos el ViewModel después de asegurarnos que está registrado
    final today = DateTime.now();
    print(
        "🗓️ Buscando sesiones para: ${today.year}-${today.month}-${today.day}");

    return Scaffold(
      appBar: TAppBar(
        title: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: TSizes.spaceBtwItems),
              child: CircleAvatar(
                backgroundImage: AssetImage(TImages.userIcon),
                radius: 25,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Brandon Valenzuela',
                  style: TextStyle(color: Colors.black),
                ),
                Text(
                  'brandonvalenzuela@gmail.com',
                  style: TextStyle(color: TColors.darkGrey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () => Get.to(() => const ProfileScreen()),
          ),
        ],
      ),
      body: GetBuilder<TrainingViewModel>(
        builder: (viewModel) {
          print("🔍 HomeScreen - Construyendo pantalla completa");

          // Verificar sesiones de hoy después de que ya tenemos datos
          final todaySessions = viewModel
                  .trainingData?.dashboard.nextWeekSessions
                  .where((session) =>
                      session.sessionDate.year == today.year &&
                      session.sessionDate.month == today.month &&
                      session.sessionDate.day == today.day)
                  .toList() ??
              [];
          print("🗓️ Sesiones encontradas para hoy: ${todaySessions.length}");

          // Si quieres resaltar las sesiones de hoy, puedes hacer algo como:
          if (todaySessions.isNotEmpty) {
            print(
                "🎯 Primer entrenamiento de hoy: ${todaySessions.first.workoutName}");
          }

          // Verificar estado de carga
          if (viewModel.status == LoadingStatus.loading &&
              viewModel.trainingData == null) {
            return Center(child: CircularProgressIndicator());
          } else if (viewModel.status == LoadingStatus.error) {
            return _buildErrorView(context, viewModel);
          } else if (viewModel.trainingData != null) {
            return _buildHomeContent(context, viewModel);
          } else {
            return Center(
                child: Text('No hay datos de entrenamiento disponibles'));
          }
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, TrainingViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error al cargar los datos de entrenamiento'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => viewModel.loadDashboardData(forceRefresh: true),
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, TrainingViewModel viewModel) {
    final dashboard = viewModel.trainingData!.dashboard;

    // Obtener sesiones para mostrar en la UI
    List<Session> sessions = List.from(dashboard.nextWeekSessions);
    if (sessions.isEmpty) {
      print("⚠️ HomeScreen - Lista de sesiones vacía");
    } else {
      print("📋 HomeScreen - Sesiones disponibles: ${sessions.length}");
      print("📋 Primera sesión: ${sessions[0].workoutName}");
    }

    // Ordenar por fecha
    sessions.sort((a, b) => a.sessionDate.compareTo(b.sessionDate));
    final now = DateTime.now();

    // Verificar si hay sesiones para hoy
    final todaySessions = sessions
        .where((session) =>
            session.sessionDate.year == now.year &&
            session.sessionDate.month == now.month &&
            session.sessionDate.day == now.day)
        .toList();

    // Encontrar la próxima sesión
    final nextSession = sessions.firstWhere(
      (session) =>
          session.sessionDate.isAfter(now) ||
          (session.sessionDate.year == now.year &&
              session.sessionDate.month == now.month &&
              session.sessionDate.day == now.day),
      orElse: () => sessions.isNotEmpty
          ? sessions.first
          : Session(
              sessionDate: DateTime.now().add(Duration(days: 1)),
              workoutName: "No disponible",
              description: "",
            ),
    );

    return Column(
      children: [
        // Header con información de entrenamiento
        Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Container(
            padding: const EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              color: TColors.primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo de carrera y semanas restantes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_run,
                            color: TColors.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          dashboard.raceType,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: TColors.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${dashboard.weeksToRace} semanas',
                        style: TextStyle(color: TColors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.sm),

                // Ritmo objetivo y tiempo meta
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                        context, 'Ritmo objetivo:', dashboard.targetPace),
                    _buildInfoItem(context, 'Tiempo meta:', dashboard.goalTime),
                  ],
                ),
                const SizedBox(height: TSizes.sm),

                // Barra de progreso
                LinearProgressIndicator(
                  value: dashboard.completionRate / 100,
                  minHeight: 8,
                  backgroundColor: TColors.grey,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(TColors.primaryColor),
                ),
                const SizedBox(height: 4),

                // Texto de progreso
                Text(
                  '${dashboard.completedSessions} de ${dashboard.totalSessions} sesiones completadas (${dashboard.completionRate}%)',
                  style: TextStyle(fontSize: 12, color: TColors.darkGrey),
                ),
              ],
            ),
          ),
        ),

        // Mensaje para el día sin entrenamiento (si aplica)
        if (todaySessions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(
              bottom: TSizes.defaultSpace,
              left: TSizes.defaultSpace,
              right: TSizes.defaultSpace,
            ),
            child: Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        "Hoy - ${now.day}/${now.month}/${now.year}",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Día de recuperación activa",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Aprovecha este día para descansar y prepararte para tu próxima sesión de entrenamiento.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.arrow_forward,
                          color: TColors.primaryColor, size: 16),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Próximo entrenamiento: ${_formatDate(nextSession.sessionDate)} - ${nextSession.workoutName}",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: TColors.primaryColor,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
          child: Divider(),
        ),

        // Título de sección
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
          child: Row(
            children: [
              Text(
                "Próximos entrenamientos",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Iconsax.map_1, size: 20),
                onPressed: () => Get.to(() => const MapScreen()),
              ),
            ],
          ),
        ),

        // Lista de sesiones
        Expanded(
          child: sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No hay sesiones programadas para esta semana'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            viewModel.loadDashboardData(forceRefresh: true),
                        child: Text('Actualizar datos'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      viewModel.loadDashboardData(forceRefresh: true),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: TSizes.defaultSpace,
                      vertical: TSizes.spaceBtwItems,
                    ),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];

                      // Verificar si la sesión ya pasó
                      bool isPast = session.sessionDate.isBefore(now);

                      print(
                          "🏋️ Renderizando sesión $index: ${session.workoutName}");

                      return TrainingCard(
                        key: ValueKey(
                            'session-${session.workoutName}-${session.sessionDate}'),
                        session: session,
                        showBorder: false,
                        isPast: isPast,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // Función auxiliar para formatear fechas
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // Widget para mostrar elementos de información
  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: TColors.darkGrey,
          ),
        ),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
