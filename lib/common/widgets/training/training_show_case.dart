import 'package:flutter/material.dart';
import 'package:runap/common/widgets/custom_shapes/containers/ronuded_container.dart';
import 'package:runap/common/widgets/training/training_card.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';

class TrainingShowcase extends StatelessWidget {
  const TrainingShowcase({
    super.key,
    required this.sessions,
    this.title = 'Próximas sesiones',
  });

  final List<Session> sessions;
  final String title;

  @override
  Widget build(BuildContext context) {
    return TRonudedContainer(
      showBorder: true,
      borderColor: Colors.transparent,
      backgroundColor: TColors.grey,
      padding: const EdgeInsets.all(TSizes.md),
      margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Padding(
            padding: const EdgeInsets.only(bottom: TSizes.sm),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Lista de sesiones de entrenamiento
          ...sessions
              .map((session) => TrainingCard(
                    session: session,
                    showBorder: false,
                  ))
              .toList(),
        ],
      ),
    );
  }
}
