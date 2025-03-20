import 'package:flutter/material.dart';
import 'package:runap/features/map/models/workout_data.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'workout_metrics_panel.dart';
import 'workout_goal_panel.dart';
import 'control_buttons.dart';

class DraggableInfoSheet extends StatelessWidget {
  final WorkoutData workoutData;
  final VoidCallback onStartWorkout;
  final VoidCallback onStopWorkout;
  final String elapsedTime;
  final Function() onSelectGoal;

  const DraggableInfoSheet({
    super.key,
    required this.workoutData,
    required this.onStartWorkout,
    required this.onStopWorkout,
    required this.elapsedTime,
    required this.onSelectGoal,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize:
          0.31, // Incrementado para acomodar el panel de objetivos
      minChildSize: 0.31,
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
                  padding: const EdgeInsets.all(TSizes.spaceBtwItems),
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Panel de objetivos
                        if (workoutData.goal != null)
                          WorkoutGoalPanel(
                            workoutData: workoutData,
                            elapsedTime: elapsedTime,
                          ),

                        if (workoutData.goal == null &&
                            !workoutData.isWorkoutActive)
                          ElevatedButton(
                            onPressed: onSelectGoal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    TSizes.borderRadiusSm),
                              ),
                            ),
                            child: const Text(
                              'Seleccionar objetivo',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),

                        const SizedBox(height: TSizes.spaceBtwItems),

                        // Métricas
                        WorkoutMetricsPanel(workoutData: workoutData),

                        const SizedBox(height: TSizes.spaceBtwItems),

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
