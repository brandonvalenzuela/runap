import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/features/dashboard/viewmodels/training_view_model.dart';
import 'package:runap/features/map/models/workout_goal.dart';
import 'package:runap/features/map/screen/map.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/helpers/helper_functions.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';

class TrainingCard extends StatefulWidget {
  const TrainingCard({
    super.key,
    required this.session,
    this.onTap,
    required this.showBorder,
    this.isPast = false,
  });

  final Session session;
  final bool showBorder;
  final bool isPast;
  final void Function()? onTap;

  @override
  State<TrainingCard> createState() => _TrainingCardState();
}

class _TrainingCardState extends State<TrainingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _blurAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _blurAnimation = Tween<double>(begin: 0.0, end: 5.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final now = DateTime.now();
    final isToday = now.year == widget.session.sessionDate.year &&
        now.month == widget.session.sessionDate.month &&
        now.day == widget.session.sessionDate.day;
    final canStartWorkout = isToday &&
        !widget.session.workoutName.toLowerCase().contains('descanso');

    String formatearFecha(DateTime fecha) {
      final List<String> diasSemana = [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo'
      ];
      final List<String> meses = [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre'
      ];

      int diaSemanaIndex = (fecha.weekday - 1) % 7;
      return '${diasSemana[diaSemanaIndex]}, ${fecha.day} ${meses[fecha.month - 1]}';
    }

    final formattedDate = formatearFecha(widget.session.sessionDate);
    String workoutIcon = _getWorkoutIcon(widget.session.workoutName);
    Color iconBackgroundColor = _getIconBackgroundColor(
        widget.session.workoutName,
        isToday,
        widget.session.completed,
        widget.isPast);
    Color iconColor = _getIconColor(widget.session.workoutName, isToday);

    void navigateToMap() {
      final now = DateTime.now();
      final isToday = now.year == widget.session.sessionDate.year &&
          now.month == widget.session.sessionDate.month &&
          now.day == widget.session.sessionDate.day;

      final shouldAllow = isToday &&
          !widget.session.workoutName.toLowerCase().contains('descanso');

      if (!shouldAllow) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Solo puedes iniciar entrenamientos programados para hoy'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      WorkoutGoal? workoutGoal = _createWorkoutGoalFromSession(widget.session);

      try {
        if (!Get.isRegistered<TrainingViewModel>()) {
          final viewModel = TrainingViewModel();
          Get.put(viewModel);
        }

        Get.to(() => MapScreen(
              initialWorkoutGoal: workoutGoal,
              sessionToUpdate: widget.session,
            ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar el entrenamiento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: canStartWorkout ? _handleTapDown : null,
          onTapUp: canStartWorkout ? _handleTapUp : null,
          onTapCancel: canStartWorkout ? _handleTapCancel : null,
          onTap: canStartWorkout
              ? () => navigateToMap()
              : (isToday &&
                      widget.session.workoutName
                          .toLowerCase()
                          .contains('descanso'))
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Hoy es tu día de descanso. ¡Aprovecha para recuperarte!'),
                          backgroundColor: Colors.blue,
                          action: SnackBarAction(
                            label: 'Entendido',
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                        ),
                      );
                    }
                  : null,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 700),
              opacity: 1.0,
              child: Container(
                padding: const EdgeInsets.all(TSizes.cardRadiusLg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.05 * _controller.value + 0.05),
                      blurRadius: 10 * _controller.value + 5,
                      offset: Offset(0, 3 * _controller.value + 2),
                      spreadRadius: 2 * _controller.value,
                    ),
                  ],
                  border: widget.showBorder
                      ? Border.all(
                          color: isToday
                              ? TColors.primaryColor.withAlpha(78)
                              : (widget.session.completed
                                  ? TColors.success.withAlpha(78)
                                  : (widget.isPast && !widget.session.completed
                                      ? Colors.grey
                                      : Colors.transparent)),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconBackgroundColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _getIconData(widget.session.workoutName),
                            color: iconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.session.workoutName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (widget.session.completed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: TColors.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Completado',
                              style: TextStyle(
                                fontSize: 10,
                                color: TColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: TColors.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Hoy',
                              style: TextStyle(
                                fontSize: 10,
                                color: TColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (widget.isPast && !widget.session.completed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Perdido',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.session.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.session.workoutName.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _buildTags(widget.session.description),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTags(String description) {
    List<Widget> tags = [];

    // Buscar patrones de tiempo (minutos)
    RegExp timeRegExp = RegExp(r'(\d+)\s*min');
    var timeMatch = timeRegExp.firstMatch(description);
    if (timeMatch != null) {
      tags.add(_buildTag('${timeMatch.group(1)} min'));
    }

    // Buscar patrones de distancia (km)
    RegExp distanceRegExp = RegExp(r'(\d+(?:\.\d+)?)\s*km');
    var distanceMatch = distanceRegExp.firstMatch(description);
    if (distanceMatch != null) {
      tags.add(_buildTag('${distanceMatch.group(1)} km'));
    }

    // Buscar patrones de ritmo (min/km)
    RegExp paceRegExp = RegExp(r'(\d+:\d+)\s*min/km');
    var paceMatch = paceRegExp.firstMatch(description);
    if (paceMatch != null) {
      tags.add(_buildTag(paceMatch.group(1)!));
    }

    return tags;
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
    );
  }

  IconData _getIconData(String workoutName) {
    workoutName = workoutName.toLowerCase();
    if (workoutName.contains('carrera') || workoutName.contains('correr'))
      return Icons.directions_run;
    if (workoutName.contains('descanso')) return Icons.hotel;
    if (workoutName.contains('fuerza')) return Icons.fitness_center;
    if (workoutName.contains('tempo') || workoutName.contains('velocidad'))
      return Icons.speed;
    return Icons.directions_run;
  }

  String _getWorkoutIcon(String workoutName) {
    workoutName = workoutName.toLowerCase();
    if (workoutName.contains('carrera')) return TImages.runningIcon;
    if (workoutName.contains('descanso')) return TImages.restIcon;
    if (workoutName.contains('fuerza')) return TImages.strengthIcon;
    return TImages.workoutIcon;
  }

  Color _getIconBackgroundColor(
      String workoutName, bool isToday, bool completed, bool isPast) {
    workoutName = workoutName.toLowerCase();
    if (completed) return TColors.success.withOpacity(0.2);
    if (isToday) return TColors.primaryColor.withOpacity(0.2);
    if (isPast && !completed) return Colors.grey.withOpacity(0.2);
    if (workoutName.contains('descanso')) return Colors.blue.withOpacity(0.2);
    return const Color(0xFFF2F3F7);
  }

  Color _getIconColor(String workoutName, bool isToday) {
    workoutName = workoutName.toLowerCase();
    if (isToday) return TColors.primaryColor;
    if (workoutName.contains('descanso')) return Colors.blue;
    return const Color(0xFF8E8E93);
  }

  WorkoutGoal? _createWorkoutGoalFromSession(Session session) {
    try {
      // Analizamos la descripción para determinar la distancia y el tiempo objetivo
      String description = session.description.toLowerCase();
      double targetDistanceKm = 5.0; // Valor predeterminado
      int targetTimeMinutes = 30; // Valor predeterminado

      // Extraer distancia (km)
      RegExp distanceRegExp = RegExp(r'(\d+(?:\.\d+)?)\s*km');
      var distanceMatch = distanceRegExp.firstMatch(description);
      if (distanceMatch != null) {
        targetDistanceKm =
            double.tryParse(distanceMatch.group(1) ?? '5.0') ?? 5.0;
      }

      // Extraer tiempo (minutos)
      RegExp timeRegExp = RegExp(r'(\d+)\s*min');
      var timeMatch = timeRegExp.firstMatch(description);
      if (timeMatch != null) {
        targetTimeMinutes = int.tryParse(timeMatch.group(1) ?? '30') ?? 30;
      }

      return WorkoutGoal(
        targetDistanceKm: targetDistanceKm,
        targetTimeMinutes: targetTimeMinutes,
        startTime: DateTime.now(),
      );
    } catch (e) {
      print('Error creating WorkoutGoal: $e');
      return null;
    }
  }
}
