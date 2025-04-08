import 'package:flutter/material.dart';
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';

class StatsCard extends StatelessWidget {
  final Dashboard dashboard;

  const StatsCard({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan de ${dashboard.raceType}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  context,
                  'Ritmo objetivo',
                  dashboard.targetPace,
                  Icons.speed,
                ),
                _buildStatItem(
                  context,
                  'Tiempo meta',
                  dashboard.goalTime,
                  Icons.timer,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  context,
                  'Semanas para la carrera',
                  '${dashboard.weeksToRace}',
                  Icons.calendar_today,
                ),
                _buildStatItem(
                  context,
                  'Progreso',
                  '${dashboard.completionRate}%',
                  Icons.trending_up,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 