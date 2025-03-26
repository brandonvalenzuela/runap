import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:runap/common/widgets/appbar/appbar.dart';
import 'package:runap/common/widgets/texts/sections_heading.dart';
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
    return ChangeNotifierProvider(
      create: (_) => TrainingViewModel(),
      child: Scaffold(
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
        body: Column(
          children: [
            /// HEADER - Sección Fija Superior con información del entrenamiento
            Consumer<TrainingViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.trainingData != null) {
                  final dashboard = viewModel.trainingData!.dashboard;

                  return Column(
                    children: [
                      // Tarjeta de información de entrenamiento
                      Padding(
                        padding: const EdgeInsets.all(TSizes.defaultSpace),
                        child: Container(
                          padding: const EdgeInsets.all(TSizes.md),
                          decoration: BoxDecoration(
                            color: TColors.primaryColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: TColors.primaryColor.withAlpha(76)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tipo de carrera y semanas restantes
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.directions_run,
                                          color: TColors.primaryColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        dashboard.raceType,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: TColors.primaryColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${dashboard.weeksToRace} semanas',
                                      style: TextStyle(
                                          color: TColors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: TSizes.sm),

                              // Ritmo objetivo y tiempo meta
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildInfoItem(context, 'Ritmo objetivo:',
                                      dashboard.targetPace),
                                  _buildInfoItem(context, 'Tiempo meta:',
                                      dashboard.goalTime),
                                ],
                              ),
                              const SizedBox(height: TSizes.sm),

                              // Barra de progreso
                              LinearProgressIndicator(
                                value: dashboard.completionRate / 100,
                                minHeight: 8,
                                backgroundColor: TColors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    TColors.primaryColor),
                              ),
                              const SizedBox(height: 4),

                              // Texto de progreso
                              Text(
                                '${dashboard.completedSessions} de ${dashboard.totalSessions} sesiones completadas (${dashboard.completionRate}%)',
                                style: TextStyle(
                                    fontSize: 12, color: TColors.darkGrey),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: TSizes.defaultSpace),
                        child: Divider(),
                      ),
                      // TSectionHeading fuera del área scrolleable
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: TSizes.defaultSpace),
                        child: TSectionHeading(
                          title: 'Entrenamientos de la semana',
                          onPressed: () => Get.to(() => MapScreen()),
                        ),
                      ),
                    ],
                  );
                } else if (viewModel.status == LoadingStatus.loading) {
                  // Mostrar un placeholder mientras carga
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(TSizes.defaultSpace),
                        child: Container(
                          padding: const EdgeInsets.all(TSizes.defaultSpace),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: TColors.darkGrey.withAlpha(76)),
                          ),
                          height: 120,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: TSizes.defaultSpace),
                        child: Divider(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: TSizes.defaultSpace),
                        child: TSectionHeading(
                          title: 'Entrenamientos de la semana',
                          onPressed: () => Get.to(() => MapScreen()),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mostrar un header predeterminado en caso de error o datos nulos
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(TSizes.defaultSpace),
                        child: Container(
                          padding: const EdgeInsets.all(TSizes.defaultSpace),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TColors.darkGrey),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_run,
                                  color: TColors.primaryColor),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sin datos de entrenamiento',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    'Inténtalo más tarde',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(Icons.refresh),
                                onPressed: () => viewModel.loadDashboardData(
                                    forceRefresh: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: TSizes.defaultSpace),
                        child: Divider(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: TSizes.defaultSpace),
                        child: TSectionHeading(
                          title: 'Entrenamientos de la semana',
                          onPressed: () => Get.to(() => MapScreen()),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),

            // Dentro del método build de tu Dashboard, actualiza esta parte:

// BODY - Sección Scrolleable con sesiones en orden cronológico
            Expanded(
              child: Consumer<TrainingViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.status == LoadingStatus.loading &&
                      viewModel.trainingData == null) {
                    return Center(child: CircularProgressIndicator());
                  } else if (viewModel.status == LoadingStatus.error) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error al cargar los datos de entrenamiento'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                viewModel.loadDashboardData(forceRefresh: true),
                            child: Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  } else if (viewModel.trainingData != null) {
                    final dashboard = viewModel.trainingData!.dashboard;

                    // Obtener sesiones para mostrar en la UI
                    final List<Session> sessions =
                        List.from(dashboard.nextWeekSessions);
                    final now = DateTime.now();

                    // Ordenar por fecha
                    sessions
                        .sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

                    return RefreshIndicator(
                      onRefresh: () =>
                          viewModel.loadDashboardData(forceRefresh: true),
                      child: sessions.isEmpty
                          ? Center(
                              child: Text(
                                  'No hay sesiones programadas para esta semana'))
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: TSizes.defaultSpace,
                                vertical: TSizes.spaceBtwItems,
                              ),
                              itemCount: sessions.length,
                              itemBuilder: (context, index) {
                                final session = sessions[index];
                                // Verificar si la sesión ya pasó
                                bool isPast = session.sessionDate.isBefore(now);

                                return TrainingCard(
                                  session: session,
                                  showBorder: true,
                                  isPast: isPast,
                                  // No más onToggleCompletion, toda la tarjeta es clickeable
                                );
                              },
                            ),
                    );
                  } else {
                    return Center(
                        child:
                            Text('No hay datos de entrenamiento disponibles'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
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
