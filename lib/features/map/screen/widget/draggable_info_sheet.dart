import 'package:flutter/material.dart';
import '../../models/workout_data.dart';
import 'workout_metrics_panel.dart';
import 'control_buttons.dart';

class DraggableInfoSheet extends StatelessWidget {
  final WorkoutData workoutData;
  final VoidCallback onStartWorkout;
  final VoidCallback onStopWorkout;

  const DraggableInfoSheet({
    Key? key,
    required this.workoutData,
    required this.onStartWorkout,
    required this.onStopWorkout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.30,
      minChildSize: 0.30,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Indicador de arrastre
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Métricas
                        WorkoutMetricsPanel(workoutData: workoutData),
                        const SizedBox(height: 20),
                        // Botones de control
                        ControlButtons(
                          isWorkoutActive: workoutData.isWorkoutActive,
                          onStartWorkout: onStartWorkout,
                          onStopWorkout: onStopWorkout,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
