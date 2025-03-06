import 'package:flutter/material.dart';
import '../../../../utils/constants/sizes.dart';
import '../../models/workout_data.dart';

class WorkoutMetricsPanel extends StatelessWidget {
  final WorkoutData workoutData;

  const WorkoutMetricsPanel({
    Key? key,
    required this.workoutData,
  }) : super(key: key);

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
