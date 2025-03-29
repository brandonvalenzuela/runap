import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:runap/features/map/controller/map_controller.dart';
import 'package:runap/features/map/models/workout_goal.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';

class MapScreen extends StatelessWidget {
  final WorkoutGoal? initialWorkoutGoal;
  final Session? sessionToUpdate;

  const MapScreen({
    super.key,
    this.initialWorkoutGoal,
    this.sessionToUpdate,
  });

  @override
  Widget build(BuildContext context) {
    // Inyectar el controlador
    final controller = Get.put(MapController(
      initialSession: sessionToUpdate,
      initialWorkoutGoal: initialWorkoutGoal,
    ));

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          if (controller.sessionToUpdate.value != null) {
            return Text(controller.sessionToUpdate.value!.workoutName);
          }
          return Text('Entrenamiento');
        }),
        actions: [
          Obx(() {
            return IconButton(
              icon: Icon(Icons.flag),
              onPressed: controller.workoutData.value.isWorkoutActive
                  ? null
                  : controller.toggleGoalSelector,
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          Obx(() => _buildMap(controller)),

          // Panel de información inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Obx(() => _buildInfoPanel(controller)),
          ),

          // Selector de objetivos (condicional)
          Obx(() {
            if (controller.showGoalSelector.value) {
              return _buildGoalSelector(controller);
            }
            return SizedBox.shrink();
          }),

          // Indicador de carga
          Obx(() {
            if (controller.isLoading.value) {
              return Container(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return SizedBox.shrink();
          }),

          // Indicador de guardado
          Obx(() {
            if (controller.isSaving.value) {
              return Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Guardando entrenamiento...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildMap(MapController controller) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: controller.workoutData.value.currentPosition ??
            LatLng(20.651464, -103.392958),
        zoom: 17.0,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      polylines: controller.workoutData.value.polylines,
      onMapCreated: (GoogleMapController mapController) {
        controller.setMapControllerInstance(mapController);
      },
    );
  }

  Widget _buildInfoPanel(MapController controller) {
    return Container(
      padding: EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Información del objetivo (si hay uno establecido)
          if (controller.workoutData.value.goal != null) ...[
            Text(
              'Objetivo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricTile(
                  icon: Icons.straighten,
                  value:
                      '${controller.workoutData.value.goal!.targetDistanceKm} km',
                  label: 'Distancia',
                ),
                _buildMetricTile(
                  icon: Icons.timer,
                  value:
                      '${controller.workoutData.value.goal!.targetTimeMinutes} min',
                  label: 'Tiempo',
                ),
                _buildProgressTile(controller),
              ],
            ),
            SizedBox(height: 16),
          ],

          // Métricas actuales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricTile(
                icon: Icons.straighten,
                value:
                    '${(controller.workoutData.value.distanceMeters / 1000).toStringAsFixed(2)} km',
                label: 'Distancia',
              ),
              _buildMetricTile(
                icon: Icons.timer,
                value: controller.getFormattedElapsedTime(),
                label: 'Tiempo',
              ),
              _buildMetricTile(
                icon: Icons.speed,
                value: controller.workoutData.value.isWorkoutActive
                    ? controller.workoutData.value
                        .getPaceFormatted() // Usar el nuevo método
                    : "--:--",
                label: 'Ritmo (min/km)', // Cambiar la etiqueta para claridad
              ),
            ],
          ),
          SizedBox(height: 16),

          // Botón de inicio/parada
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.workoutData.value.isWorkoutActive
                  ? controller.stopWorkout
                  : controller.startWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.workoutData.value.isWorkoutActive
                    ? Colors.red
                    : TColors.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                controller.workoutData.value.isWorkoutActive
                    ? 'DETENER'
                    : 'INICIAR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: TColors.primaryColor),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTile(MapController controller) {
    // Calcular el progreso
    final elapsedSeconds = controller.getElapsedTimeSeconds();
    final targetSeconds =
        controller.workoutData.value.goal!.targetTimeMinutes * 60;
    final progress = targetSeconds > 0 ? elapsedSeconds / targetSeconds : 0.0;

    return Column(
      children: [
        Icon(Icons.check_circle, color: TColors.primaryColor),
        SizedBox(height: 4),
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 5,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(TColors.primaryColor),
          ),
        ),
        Text(
          'Progreso',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSelector(MapController controller) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.all(TSizes.defaultSpace),
          padding: EdgeInsets.all(TSizes.defaultSpace),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona un objetivo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ...controller.availableGoals
                  .map((goal) => _buildGoalOption(controller, goal)),
              SizedBox(height: 16),
              TextButton(
                onPressed: controller.toggleGoalSelector,
                child: Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalOption(MapController controller, WorkoutGoal goal) {
    final isSelected = controller.workoutData.value.goal?.targetDistanceKm ==
            goal.targetDistanceKm &&
        controller.workoutData.value.goal?.targetTimeMinutes ==
            goal.targetTimeMinutes;

    return GestureDetector(
      onTap: () => controller.setWorkoutGoal(goal),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? TColors.primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? TColors.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? TColors.primaryColor : Colors.grey,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${goal.targetDistanceKm} km en ${goal.targetTimeMinutes} min',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Ritmo: ${(goal.targetDistanceKm / (goal.targetTimeMinutes / 60)).toStringAsFixed(2)} km/h',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
