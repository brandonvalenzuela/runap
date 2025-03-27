import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:runap/common/widgets/custom_shapes/containers/ronuded_container.dart';
import 'package:runap/common/widgets/icons/t_circular_image.dart';
import 'package:runap/features/dashboard/viewmodels/training_view_model.dart';
import 'package:runap/features/map/models/workout_goal.dart';
import 'package:runap/features/map/screen/map.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/helpers/helper_functions.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';

class TrainingCard extends StatelessWidget {
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
  final void Function()? onTap; // Podemos mantener esto para casos especiales

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    // Obtener fecha actual una sola vez para consistencia
    final now = DateTime.now();

    // Verificar si es hoy (comparar año, mes y día)
    final isToday = now.year == session.sessionDate.year &&
        now.month == session.sessionDate.month &&
        now.day == session.sessionDate.day;

    // Imprimir para depuración
    print('Fecha actual: ${now.toString()}');
    print('Fecha sesión: ${session.sessionDate.toString()}');
    print('Es hoy: $isToday');
    print('Es después: ${session.sessionDate.isAfter(now)}');
    print(
        'Es descanso: ${session.workoutName.toLowerCase().contains('descanso')}');

    // Verificar si puede iniciarse (sólo hoy o futuro, y no es descanso)
    final canStartWorkout =
        isToday && !session.workoutName.toLowerCase().contains('descanso');

    print('Puede iniciar: $canStartWorkout');

    // Función personalizada para formatear fecha en español
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

    // Obtener la fecha formateada
    final formattedDate = formatearFecha(session.sessionDate);

    // Determinar si es el entrenamiento de hoy
    // final now = DateTime.now();
    // final isToday = now.year == session.sessionDate.year &&
    //     now.month == session.sessionDate.month &&
    //     now.day == session.sessionDate.day;

    // Comprobar si este entrenamiento puede ser iniciado
    // Solo los entrenamientos no completados del día actual o futuros pueden iniciarse
    // y solo si no es un entrenamiento de descanso
    // final canStartWorkout = (isToday || session.sessionDate.isAfter(now)) &&
    //     !session.workoutName.toLowerCase().contains('descanso');

    // Determinar el ícono según el tipo de entrenamiento
    String workoutIcon = _getWorkoutIcon(session.workoutName);

    // Configurar los parámetros del entrenamiento para el mapa
    void navigateToMap() {
      print('Intentando navegar al mapa. canStartWorkout = $canStartWorkout');

      // Verificación doble para mayor seguridad
      final now = DateTime.now();
      final isToday = now.year == session.sessionDate.year &&
          now.month == session.sessionDate.month &&
          now.day == session.sessionDate.day;

      // SOLO permitir entrenamientos de HOY (no futuros)
      final shouldAllow =
          isToday && !session.workoutName.toLowerCase().contains('descanso');

      if (!shouldAllow) {
        print('No se puede iniciar este entrenamiento: ${session.sessionDate}');

        // Mensaje claro para el usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Solo puedes iniciar entrenamientos programados para hoy'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Crear un WorkoutGoal basado en la descripción
      WorkoutGoal? workoutGoal = _createWorkoutGoalFromSession(session);

      try {
        // Verificar si el Provider está disponible
        final viewModel =
            Provider.of<TrainingViewModel>(context, listen: false);

        // Navegar con el Provider
        Get.to(() => ChangeNotifierProvider.value(
              value: viewModel,
              child: MapScreen(
                initialWorkoutGoal: workoutGoal,
                sessionToUpdate: session,
              ),
            ));
      } catch (e) {
        print('Error al obtener TrainingViewModel: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar el entrenamiento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return InkWell(
      onTap: canStartWorkout ? () => navigateToMap() : null,
      child: Opacity(
        opacity: canStartWorkout
            ? 1.0
            : 0.5, // Reducir opacidad para entrenamientos que no se pueden iniciar
        child: Container(
          margin: const EdgeInsets.only(bottom: TSizes.sm),
          child: TRonudedContainer(
            showBorder: showBorder,
            backgroundColor: isToday
                ? TColors.primaryColor.withOpacity(0.1)
                : (session.completed
                    ? TColors.success.withOpacity(0.1)
                    : (isPast && !session.completed
                        ? Colors.grey.withOpacity(0.1)
                        : Colors.transparent)),
            borderColor: isToday
                ? TColors.primaryColor.withOpacity(0.3)
                : (session.completed
                    ? TColors.success.withOpacity(0.3)
                    : (isPast && !session.completed
                        ? Colors.grey
                        : Colors.transparent)),
            padding: const EdgeInsets.all(TSizes.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ícono del tipo de entrenamiento
                Flexible(
                  flex: 1,
                  child: TCircularImage(
                    isNetworkImage: false,
                    image: workoutIcon,
                    backgroundColor: Colors.transparent,
                    overLayColor: isPast && !session.completed
                        ? Colors.grey
                        : (isDark ? TColors.white : TColors.black),
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems / 2),

                // Información del entrenamiento
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Nombre del entrenamiento
                          Expanded(
                            child: Text(
                              session.workoutName,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isPast && !session.completed
                                        ? Colors.grey
                                        : null,
                                  ),
                            ),
                          ),

                          // Fecha del entrenamiento
                          Text(
                            formattedDate,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: isPast && !session.completed
                                      ? Colors.grey
                                      : TColors.accent,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TSizes.xs),

                      // Descripción del entrenamiento
                      Text(
                        session.description,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isPast && !session.completed
                                  ? Colors.grey
                                  : null,
                            ),
                      ),

                      // Chip de estado (sin el botón de iniciar)
                      Padding(
                        padding: const EdgeInsets.only(top: TSizes.xs),
                        child: Chip(
                          backgroundColor: _getStatusChipColor(
                              isPast, session.completed, isToday),
                          label: Text(
                            _getStatusText(isPast, session.completed, isToday),
                            style: TextStyle(
                              color: _getStatusTextColor(
                                  isPast, session.completed, isToday),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Crear un WorkoutGoal basado en la descripción del entrenamiento
  WorkoutGoal? _createWorkoutGoalFromSession(Session session) {
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
  }

  // Método para determinar el ícono según el tipo de entrenamiento
  String _getWorkoutIcon(String workoutName) {
    workoutName = workoutName.toLowerCase();

    if (workoutName.contains('tirada') || workoutName.contains('rodaje')) {
      return TImages.runningIcon;
    } else if (workoutName.contains('fuerza')) {
      return TImages.strengthIcon;
    } else if (workoutName.contains('tempo')) {
      return TImages.speedIcon;
    } else if (workoutName.contains('descanso')) {
      return TImages.restIcon;
    } else {
      return TImages.workoutIcon;
    }
  }

  // Método para obtener el color de fondo del chip de estado
  Color _getStatusChipColor(bool isPast, bool completed, bool isToday) {
    if (completed) {
      return TColors.success.withOpacity(0.2);
    } else if (isPast) {
      return Colors.red.withOpacity(0.2);
    } else if (isToday) {
      return TColors.secondaryColor.withOpacity(0.2);
    } else {
      return TColors.primaryColor.withOpacity(0.2);
    }
  }

  // Método para obtener el color del texto del chip de estado
  Color _getStatusTextColor(bool isPast, bool completed, bool isToday) {
    if (completed) {
      return TColors.success;
    } else if (isPast) {
      return Colors.red;
    } else if (isToday) {
      return TColors.secondaryColor;
    } else {
      return TColors.primaryColor;
    }
  }

  // Método para obtener el texto del chip de estado
  String _getStatusText(bool isPast, bool completed, bool isToday) {
    if (completed) {
      return 'Completado';
    } else if (isPast) {
      return 'Perdido';
    } else if (isToday) {
      return 'Hoy';
    } else {
      return 'Pendiente';
    }
  }
}
