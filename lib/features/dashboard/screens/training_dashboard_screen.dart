// training_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/common/widgets/training/training_info_card.dart';
import 'package:runap/common/widgets/training/training_show_case.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:runap/utils/constants/sizes.dart';
import '../viewmodels/training_view_model.dart';

class TrainingDashboardScreen extends StatelessWidget {
  const TrainingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Asegurar que el ViewModel esté disponible
    // Puedes hacerlo en bindings si prefieres
    final TrainingViewModel viewModel = Get.put(TrainingViewModel());

    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Entrenamiento'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => viewModel.loadDashboardData(forceRefresh: true),
          ),
        ],
      ),
      body: Obx(() {
        // Verificamos el estado de carga
        if (viewModel.status == LoadingStatus.loading &&
            viewModel.trainingData == null) {
          return Center(child: CircularProgressIndicator());
        } else if (viewModel.status == LoadingStatus.error) {
          return _buildErrorView(context, viewModel);
        } else if (viewModel.trainingData != null) {
          return _buildDashboardContent(context, viewModel);
        } else {
          return Center(child: Text('No hay datos disponibles'));
        }
      }),
    );
  }

  Widget _buildErrorView(BuildContext context, TrainingViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error al cargar los datos'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => viewModel.loadDashboardData(forceRefresh: true),
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(
      BuildContext context, TrainingViewModel viewModel) {
    final dashboard = viewModel.trainingData!.dashboard;

    // Dividir las sesiones en grupos según su tipo
    final Map<String, List<Session>> sessionsByType = {};

    // Agrupar las sesiones por tipo
    for (var session in dashboard.nextWeekSessions) {
      String type = _getSessionType(session.workoutName);
      if (!sessionsByType.containsKey(type)) {
        sessionsByType[type] = [];
      }
      sessionsByType[type]!.add(session);
    }

    return Column(
      children: [
        // Sección superior - Información general
        Padding(
          padding: EdgeInsets.all(TSizes.defaultSpace),
          child: TrainingInfoCard(dashboard: dashboard),
        ),

        // Sección Scrolleable con las sesiones agrupadas
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => viewModel.loadDashboardData(forceRefresh: true),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
                vertical: TSizes.spaceBtwItems,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mapear las categorías de sesiones
                  ...sessionsByType.entries.map(
                    (entry) {
                      return TrainingShowcase(
                        title: _getCategoryTitle(entry.key),
                        sessions: entry.value,
                      );
                    },
                  ),

                  // Espacio adicional al final para evitar que el FAB tape contenido
                  SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Categoriza el tipo de sesión según su nombre
  String _getSessionType(String workoutName) {
    workoutName = workoutName.toLowerCase();

    if (workoutName.contains('tirada') || workoutName.contains('rodaje')) {
      return 'running';
    } else if (workoutName.contains('fuerza')) {
      return 'strength';
    } else if (workoutName.contains('tempo')) {
      return 'speed';
    } else if (workoutName.contains('descanso')) {
      return 'rest';
    } else {
      return 'other';
    }
  }

  // Obtiene un título amigable para cada categoría
  String _getCategoryTitle(String type) {
    switch (type) {
      case 'running':
        return 'Sesiones de Carrera';
      case 'strength':
        return 'Entrenamiento de Fuerza';
      case 'speed':
        return 'Entrenamiento de Velocidad';
      case 'rest':
        return 'Días de Descanso';
      default:
        return 'Otras Sesiones';
    }
  }
}
