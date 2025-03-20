import 'package:flutter/material.dart';
import 'package:runap/features/map/models/workout_goal.dart';
import 'package:runap/utils/constants/sizes.dart';

class WorkoutGoalSelectionDialog extends StatelessWidget {
  final List<WorkoutGoal> availableGoals;
  final Function(WorkoutGoal) onGoalSelected;

  const WorkoutGoalSelectionDialog({
    super.key,
    required this.availableGoals,
    required this.onGoalSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(TSizes.spaceBtwItems),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecciona un objetivo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            ...availableGoals.map((goal) => _buildGoalItem(context, goal)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(BuildContext context, WorkoutGoal goal) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          onGoalSelected(goal);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(TSizes.spaceBtwItems),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${goal.formattedTargetDistance} km',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Objetivo: ${goal.targetTimeMinutes} minutos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
