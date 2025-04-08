import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onToggleCompletion;

  const SessionCard({
    Key? key,
    required this.session,
    required this.onToggleCompletion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d MMM', 'es');
    final formattedDate = dateFormat.format(session.sessionDate);

    return Card(
      child: InkWell(
        onTap: onToggleCompletion,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Checkbox(
                value: session.completed,
                onChanged: (_) => onToggleCompletion(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.workoutName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: session.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    if (session.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        session.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              decoration: session.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 