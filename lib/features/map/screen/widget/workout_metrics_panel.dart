import 'package:flutter/material.dart';
import 'package:runap/features/map/models/workout_data.dart';
import 'package:runap/utils/constants/sizes.dart';

class WorkoutMetricsPanel extends StatelessWidget {
  final WorkoutData workoutData;

  const WorkoutMetricsPanel({
    super.key,
    required this.workoutData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('Velocidad: ${workoutData.getSpeedFormatted()} km/h',
              style: const TextStyle(fontSize: 16)),
          Text('Distancia: ${workoutData.getDistanceFormatted()} km',
              style: const TextStyle(fontSize: 16)),
          Text('Cadencia: ${workoutData.cadenceStepsPerMinute} pasos/min',
              style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
