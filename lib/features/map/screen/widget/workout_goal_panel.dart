import 'package:flutter/material.dart';
import 'package:runap/features/map/models/workout_data.dart';
import 'package:runap/utils/constants/colors.dart';

class WorkoutGoalPanel extends StatelessWidget {
  final WorkoutData workoutData;
  final String elapsedTime;

  const WorkoutGoalPanel({
    super.key,
    required this.workoutData,
    required this.elapsedTime,
  });

  @override
  Widget build(BuildContext context) {
    if (workoutData.goal == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Objetivo: ${workoutData.goal!.formattedTargetDistance} km',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Tiempo objetivo: ${workoutData.goal!.targetTimeMinutes} min',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barra de progreso de distancia
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso: ${workoutData.getDistanceFormatted()} km',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${workoutData.getGoalDistanceCompletionPercentage().toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: workoutData.getGoalDistanceCompletionPercentage() / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  workoutData.getGoalDistanceCompletionPercentage() >= 100
                      ? Colors.green
                      : Colors.blue,
                ),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Información de tiempo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tiempo transcurrido:',
                      style: TextStyle(fontSize: 14)),
                  Text(
                    elapsedTime,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Tiempo estimado:',
                      style: TextStyle(fontSize: 14)),
                  Text(
                    workoutData.getEstimatedCompletionTime(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: workoutData.isWorkoutActive
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (workoutData.goal!.isCompleted)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 4),
                  Text(
                    '¡Objetivo completado!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
