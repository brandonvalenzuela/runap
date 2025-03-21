// Widget para mostrar información general del entrenamiento
import 'package:flutter/material.dart';
import 'package:runap/common/widgets/custom_shapes/containers/ronuded_container.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';

class TrainingInfoCard extends StatelessWidget {
  const TrainingInfoCard({
    super.key,
    required this.dashboard,
  });

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return TRonudedContainer(
      showBorder: true,
      borderColor: Colors.transparent,
      backgroundColor: TColors.primaryColor.withOpacity(0.1),
      padding: const EdgeInsets.all(TSizes.md),
      margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo de carrera y semanas restantes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dashboard.raceType,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: TSizes.sm, vertical: TSizes.xs),
                decoration: BoxDecoration(
                  color: TColors.primaryColor,
                  borderRadius: BorderRadius.circular(TSizes.sm),
                ),
                child: Text(
                  '${dashboard.weeksToRace} semanas',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: TColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          // Ritmo objetivo y tiempo meta
          _buildInfoRow(context, 'Ritmo objetivo:', dashboard.targetPace),
          _buildInfoRow(context, 'Tiempo meta:', dashboard.goalTime),
          const SizedBox(height: TSizes.spaceBtwItems),

          // Barra de progreso
          LinearProgressIndicator(
            value: dashboard.completionRate / 100,
            minHeight: 8,
            backgroundColor: TColors.grey,
            valueColor: AlwaysStoppedAnimation<Color>(TColors.success),
          ),
          const SizedBox(height: TSizes.xs),

          // Texto de progreso
          Text(
            '${dashboard.completedSessions} de ${dashboard.totalSessions} sesiones completadas (${dashboard.completionRate}%)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TColors.darkGrey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.xs),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: TSizes.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
