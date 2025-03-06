import 'package:flutter/material.dart';

class ControlButtons extends StatelessWidget {
  final bool isWorkoutActive;
  final VoidCallback onStartWorkout;
  final VoidCallback onStopWorkout;

  const ControlButtons({
    Key? key,
    required this.isWorkoutActive,
    required this.onStartWorkout,
    required this.onStopWorkout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(
          onPressed: isWorkoutActive ? null : onStartWorkout,
          style: ElevatedButton.styleFrom(
            backgroundColor: isWorkoutActive ? Colors.grey : Colors.green,
          ),
          child: const Text('Iniciar', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: isWorkoutActive ? onStopWorkout : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isWorkoutActive ? Colors.red : Colors.grey,
          ),
          child: const Text('Detener', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
