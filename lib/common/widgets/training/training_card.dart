// Actualización del widget TrainingCard
import 'package:flutter/material.dart';
import 'package:runap/common/widgets/custom_shapes/containers/ronuded_container.dart';
import 'package:runap/common/widgets/icons/t_circular_image.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/helpers/helper_functions.dart';

class TrainingCard extends StatelessWidget {
  const TrainingCard({
    super.key,
    required this.session,
    this.onTap,
    this.onToggleCompletion,
    required this.showBorder,
    this.isPast = false,
  });

  final Session session;
  final bool showBorder;
  final bool isPast;
  final void Function()? onTap;
  final void Function(bool)? onToggleCompletion;

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

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

      // Ajusta el índice (DateTime usa 0=domingo, nosotros 0=lunes)
      int diaSemanaIndex = (fecha.weekday - 1) % 7;

      return '${diasSemana[diaSemanaIndex]}, ${fecha.day} ${meses[fecha.month - 1]}';
    }

    // Obtener la fecha formateada
    final formattedDate = formatearFecha(session.sessionDate);

    // Determinar el ícono según el tipo de entrenamiento
    String workoutIcon = _getWorkoutIcon(session.workoutName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: TSizes.sm),
        child: TRonudedContainer(
          showBorder: showBorder,
          backgroundColor: isPast && !session.completed
              ? Colors.grey.withOpacity(
                  0.1) // Fondo gris para sesiones pasadas no completadas
              : Colors.transparent,
          borderColor: isPast && !session.completed
              ? Colors.grey // Borde gris para sesiones pasadas no completadas
              : Colors.transparent,
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
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
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

                    // Fila con estado y checkbox
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Estado de completado o pasado
                        Chip(
                          backgroundColor:
                              _getStatusChipColor(isPast, session.completed),
                          label: Text(
                            _getStatusText(isPast, session.completed),
                            style: TextStyle(
                              color: _getStatusTextColor(
                                  isPast, session.completed),
                              fontSize: 12,
                            ),
                          ),
                        ),

                        // Checkbox para marcar como completado/no completado
                        Checkbox(
                          value: session.completed,
                          onChanged: onToggleCompletion != null
                              ? (value) => onToggleCompletion!(value ?? false)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
  Color _getStatusChipColor(bool isPast, bool completed) {
    if (completed) {
      return TColors.success.withOpacity(0.2);
    } else if (isPast) {
      return Colors.red.withOpacity(0.2);
    } else {
      return TColors.primaryColor.withOpacity(0.2);
    }
  }

  // Método para obtener el color del texto del chip de estado
  Color _getStatusTextColor(bool isPast, bool completed) {
    if (completed) {
      return TColors.success;
    } else if (isPast) {
      return Colors.red;
    } else {
      return TColors.primaryColor;
    }
  }

  // Método para obtener el texto del chip de estado
  String _getStatusText(bool isPast, bool completed) {
    if (completed) {
      return 'Completado';
    } else if (isPast) {
      return 'Perdido';
    } else {
      return 'Pendiente';
    }
  }
}
