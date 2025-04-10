import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';
import 'package:runap/features/dashboard/presentation/manager/training_view_model.dart';
import 'package:runap/features/map/models/workout_data.dart';
import 'package:runap/features/map/models/workout_goal.dart';
import 'package:runap/features/map/services/location_service.dart';
import 'package:runap/features/map/services/map_workout_data_provider.dart';
import 'location_permission_controller.dart';
import 'package:flutter/foundation.dart';

class WorkoutController extends GetxController {
  final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  // Estado Observable
  final Rx<WorkoutData> workoutData = WorkoutData().obs;
  final RxBool isSaving = false.obs;
  final Rxn<DateTime> workoutStartTime = Rxn<DateTime>();
  final Rxn<Session> sessionToUpdate = Rxn<Session>();

  // Dependencias (inyectadas a través de Get.find)
  late final LocationService _locationService;
  final LocationPermissionController _permissionController = Get.find<LocationPermissionController>();
  final WorkoutDatabaseService _databaseService = WorkoutDatabaseService(); // Podría inyectarse si es necesario
  final TrainingViewModel _trainingViewModel = Get.find<TrainingViewModel>(); // Para actualizar sesión

  // Variables de control internas
  int _stabilizationCount = 0;
  LatLng? _lastStablePosition;
  Timer? _goalCheckTimer;

  // Flag de depuración (podría venir de configuración)
  final bool _isDebugMode = false;

  WorkoutController();

  // Nuevo método para inicializar con datos opcionales
  void initializeWithSession(Session? initialSession) {
      logger.d("(WorkoutCtrl) Intentando inicializar con sesión: ${initialSession?.workoutName}");
      if (initialSession != null) {
          sessionToUpdate.value = initialSession;
          final goal = _createWorkoutGoalFromSession(initialSession);
          if (goal != null) {
             workoutData.update((val) {
               val?.setGoal(goal);
               logger.d("(WorkoutCtrl) Objetivo establecido/actualizado desde la sesión inicial.");
             });
          }
           _checkSessionAccess(); // Verificar acceso ahora que tenemos la sesión
          logger.i("(WorkoutCtrl) Inicializado/Actualizado con éxito con la sesión: ${initialSession.workoutName}");
      } else {
           logger.d("(WorkoutCtrl) Inicializando sin sesión específica (o null pasada).");
      }
  }

  @override
  void onInit() {
    super.onInit();
    _locationService = LocationService(
      onLocationUpdate: handleLocationUpdate,
      onMetricsUpdate: handleMetricsUpdate,
    );
    logger.i("WorkoutController inicializado.");

    // Verificar acceso a la sesión inicial si existe
    _checkSessionAccess();
  }

  void _checkSessionAccess() {
    if (sessionToUpdate.value != null) {
      final now = DateTime.now();
      final sessionDate = sessionToUpdate.value!.sessionDate;
      final isToday = now.year == sessionDate.year &&
                      now.month == sessionDate.month &&
                      now.day == sessionDate.day;

      final isRestDay = sessionToUpdate.value!.workoutName.toLowerCase().contains('descanso');

      if (!isToday || isRestDay) {
        logger.w("Acceso denegado a la sesión: No es hoy o es día de descanso.");
        // Opcional: mostrar mensaje y volver atrás si se entra directamente a esta lógica
        // Get.snackbar('Acceso denegado', ...);
        // Get.back();
      }
    }
  }

  // --- Manejo de Ubicación y Métricas --- 

  void handleLocationUpdate(LatLng position) {
    logger.d("📍 (WorkoutCtrl) Nueva posición recibida: $position");

    workoutData.update((val) {
      val?.currentPosition = position;

      if (val?.isWorkoutActive == true) {
        // Estabilización de ruta al inicio
        if (_stabilizationCount < 3) {
          _stabilizationCount++;
          if (_lastStablePosition != null) {
            double distance = Geolocator.distanceBetween(
                _lastStablePosition!.latitude,
                _lastStablePosition!.longitude,
                position.latitude,
                position.longitude);
            if (distance > 50) {
              _stabilizationCount = 0;
              logger.d("⚠️ (WorkoutCtrl) Saltó GPS detectado (${distance.toStringAsFixed(1)}m), esperando estabilización");
              return;
            }
          }
          _lastStablePosition = position;
          if (_stabilizationCount < 3) {
            logger.d("🔍 (WorkoutCtrl) Estabilizando GPS: $_stabilizationCount/3");
            return;
          } else {
            logger.d("✅ (WorkoutCtrl) GPS estabilizado, iniciando trazado de ruta");
          }
        }

        // Añadir punto a la ruta
        val?.polylineCoordinates.add(position);
        val?.updatePolyline(); // Llama al método dentro de WorkoutData para actualizar el Set<Polyline>
        logger.d("✅ (WorkoutCtrl) Polilínea actualizada - ${val?.polylineCoordinates.length} puntos");
      }
    });
  }

  void handleMetricsUpdate(Position position) {
    // Ejecutar en microtask para no bloquear
    Future.microtask(() {
      _locationService.updateMetrics(workoutData.value, position);

      if (workoutData.value.isWorkoutActive && workoutData.value.goal != null) {
        workoutData.value.checkGoalCompletion();
      }
      workoutData.refresh(); // Notificar a la UI que los datos de métricas cambiaron
    });
  }

  // --- Control del Entrenamiento --- 

  Future<void> startWorkout() async {
    // 1. Verificar Permisos
    if (_permissionController.permissionStatus.value != LocationPermissionStatus.granted) {
      logger.w("(WorkoutCtrl) Permiso no concedido. No se puede iniciar.");
      _permissionController.showPermissionDialogIfNeeded();
      return;
    }

    // 2. Verificar acceso a la sesión (si aplica)
     if (sessionToUpdate.value != null) {
      final now = DateTime.now();
      final sessionDate = sessionToUpdate.value!.sessionDate;
      final isToday = now.year == sessionDate.year &&
                      now.month == sessionDate.month &&
                      now.day == sessionDate.day;
       final isRestDay = sessionToUpdate.value!.workoutName.toLowerCase().contains('descanso');

      if (!isToday || isRestDay) {
        logger.w("(WorkoutCtrl) Intento de iniciar sesión no válida.");
         Get.snackbar(
          'Acceso denegado',
          'Solo puedes iniciar entrenamientos programados para hoy que no sean de descanso.',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }
    }

    // 3. Inicialización y estabilización
    _stabilizationCount = 0;
    _lastStablePosition = null;
    // Considerar mostrar un loader aquí si la estabilización toma tiempo

    // 4. Obtener posición inicial estable
    try {
       logger.d("🔄 (WorkoutCtrl) Estabilizando ubicación GPS...");
       // Dar tiempo al GPS
       await Future.delayed(const Duration(seconds: 2));
       final initialPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 5),
          )
       );

       if (initialPosition.accuracy <= 20) {
          _lastStablePosition = LatLng(initialPosition.latitude, initialPosition.longitude);
          workoutData.update((val) { val?.currentPosition = _lastStablePosition; });
          logger.d("✅ (WorkoutCtrl) Ubicación inicial estable: ${initialPosition.accuracy}m");
       } else {
         logger.w("⚠️ (WorkoutCtrl) Precisión inicial insuficiente: ${initialPosition.accuracy}m");
         // Intentar obtener posición actual como fallback si no hay estable
         if (workoutData.value.currentPosition == null) {
            workoutData.update((val) { val?.currentPosition = LatLng(initialPosition.latitude, initialPosition.longitude); });
         }
       }
    } catch (e) {
       logger.w("⚠️ (WorkoutCtrl) Error al obtener ubicación estable: $e");
        // Intentar obtener cualquier posición como fallback
        if (workoutData.value.currentPosition == null) {
            try {
                Position position = await Geolocator.getCurrentPosition(
                    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5))
                );
                 workoutData.update((val) { val?.currentPosition = LatLng(position.latitude, position.longitude); });
                 logger.d("✅ (WorkoutCtrl) Posición inicial (fallback) obtenida.");
            } catch (e2) {
                logger.e("❌ (WorkoutCtrl) Fallo total al obtener posición inicial: $e2");
                 // Usar posición por defecto si estamos en debug/emulador
                if (kDebugMode) {
                  workoutData.update((val) { val?.currentPosition = const LatLng(20.651464, -103.392958); });
                  logger.d("🔮 (WorkoutCtrl) Usando posición por defecto para el emulador");
                } else {
                   Get.snackbar('GPS no disponible', 'No se pudo obtener la ubicación inicial.');
                   return; // No podemos iniciar sin posición inicial
                }
            }
        }
    }

    // 5. Resetear datos y marcar como activo
    workoutData.update((val) {
      val?.reset();
      val?.isWorkoutActive = true;
      val?.previousTime = DateTime.now(); // Inicializar tiempo previo
      // Re-aplicar el objetivo si existe, actualizando su startTime
      if (val?.goal != null) {
          val?.setGoal(WorkoutGoal(
              targetDistanceKm: val.goal!.targetDistanceKm,
              targetTimeMinutes: val.goal!.targetTimeMinutes,
              startTime: DateTime.now(), // Actualizar tiempo de inicio del objetivo
          ));
      }
      // Añadir punto inicial si es estable
      if (_lastStablePosition != null) {
          // Verificar cercanía con la posición actual por si acaso
          double distanceBetween = workoutData.value.currentPosition != null ? Geolocator.distanceBetween(
            _lastStablePosition!.latitude, _lastStablePosition!.longitude,
            workoutData.value.currentPosition!.latitude, workoutData.value.currentPosition!.longitude
          ) : 0;
          if (distanceBetween < 30) {
              val?.polylineCoordinates.add(_lastStablePosition!); // Añadir punto estable
              logger.d("✅ (WorkoutCtrl) Punto inicial añadido a la ruta");
              val?.updatePolyline();
          }
      }
    });

    workoutStartTime.value = DateTime.now();
    workoutData.refresh(); // Asegurar que la UI refleje el inicio

    // 6. Iniciar servicios y timers
    logger.d("▶️ (WorkoutCtrl) Iniciando entrenamiento...");
    logWorkoutStatus(detailed: true);
    _locationService.startLocationUpdates();
    _startGoalCheckTimer();
  }

  void _startGoalCheckTimer() {
    _goalCheckTimer?.cancel();
    _goalCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!workoutData.value.isWorkoutActive) {
        timer.cancel();
        return;
      }
      // Refrescar datos para la UI (tiempo transcurrido, etc.)
      workoutData.refresh();
    });
  }

  Future<void> stopWorkout() async {
    if (!workoutData.value.isWorkoutActive) return;

    isSaving.value = true;
    logger.d("⏹️ (WorkoutCtrl) Deteniendo entrenamiento...");

    workoutData.update((val) {
      val?.isWorkoutActive = false;
    });

    _locationService.stopLocationUpdates();
    _goalCheckTimer?.cancel();

    // Guardar datos
    await _saveWorkoutData();

    // Actualizar sesión en el dashboard si aplica
    await _updateDashboardSession();

    isSaving.value = false;
    logger.d("✅ (WorkoutCtrl) Entrenamiento detenido y guardado.");

    // Mostrar diálogo de completado
    await _showCompletionDialog();

    // Opcional: Resetear estado después de guardar y mostrar diálogo
    // workoutData.update((val) { val?.reset(); });
    // workoutStartTime.value = null;
  }

  Future<void> _saveWorkoutData() async {
      if (workoutStartTime.value == null) return;

      final durationSeconds = DateTime.now().difference(workoutStartTime.value!).inSeconds;
      final distanceKm = workoutData.value.distanceMeters / 1000;
      final goalCompleted = workoutData.value.goal?.isCompleted ?? false;

      try {
          await _databaseService.saveWorkoutResult(distanceKm, durationSeconds, goalCompleted);
          logger.d("💾 Resultado guardado: ${distanceKm.toStringAsFixed(2)}km en $durationSeconds seg. Meta: $goalCompleted");
          if (workoutData.value.polylineCoordinates.length > 5) {
              await _databaseService.saveWorkoutRoute(workoutData.value.polylineCoordinates);
              logger.d("💾 Ruta guardada con ${workoutData.value.polylineCoordinates.length} puntos.");
          }
      } catch (e) {
          logger.e("❌ Error al guardar datos del entrenamiento: $e");
          Get.snackbar("Error", "No se pudo guardar el entrenamiento: $e");
      }
  }

  Future<void> _updateDashboardSession() async {
     if (sessionToUpdate.value != null) {
      try {
        logger.d("🔄 Actualizando sesión en TrainingViewModel...");
        // Usamos el TrainingViewModel que debería estar disponible globalmente (lazy loaded)
        await _trainingViewModel.toggleSessionCompletion(sessionToUpdate.value!);
        logger.d("✅ Sesión actualizada en TrainingViewModel.");
      } catch (e) {
         logger.e("❌ Error al actualizar sesión en TrainingViewModel: $e");
         Get.snackbar('Error', 'Error al actualizar el estado en el dashboard: $e');
      }
    }
  }

  Future<void> _showCompletionDialog() async {
    return Get.dialog(
      AlertDialog(
        title: const Text('¡Entrenamiento completado!'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Has finalizado tu entrenamiento.'),
              SizedBox(height: 8),
              Text(
                'Distancia: ${(workoutData.value.distanceMeters / 1000).toStringAsFixed(2)} km',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Tiempo: ${getFormattedElapsedTime()}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                 'Ritmo Prom.: ${workoutData.value.getAveragePaceFormatted()} min/km',
                 style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Aceptar'),
            onPressed: () {
              Get.back(); // Cerrar diálogo
              // Considerar si navegar atrás automáticamente o no
              // if (sessionToUpdate.value != null) Get.back(); // Volver si veníamos de dashboard
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // --- Utilidades --- 

  int getElapsedTimeSeconds() {
    if (!workoutData.value.isWorkoutActive || workoutStartTime.value == null) {
      return 0;
    }
    return DateTime.now().difference(workoutStartTime.value!).inSeconds;
  }

  String getFormattedElapsedTime() {
    final seconds = getElapsedTimeSeconds();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void logWorkoutStatus({bool detailed = false}) {
    if (!_isDebugMode) return;
    logger.d("📊 (WorkoutCtrl) Estado:");
    logger.d("  🏃‍♂️ Activo: ${workoutData.value.isWorkoutActive}");
    logger.d("  📍 Posición: ${workoutData.value.currentPosition}");
    logger.d("  📏 Dist: ${workoutData.value.distanceMeters.toStringAsFixed(1)} m");
    logger.d("  ⏱️ Tiempo: ${getFormattedElapsedTime()}");
    logger.d("  🛣️ Puntos: ${workoutData.value.polylineCoordinates.length}");

    if (detailed) {
      logger.d("  🧮 Detalles:");
      logger.d("    🚶‍♂️ Vel: ${workoutData.value.speedMetersPerSecond.toStringAsFixed(2)} m/s");
      logger.d("    ⏲️ Ritmo: ${workoutData.value.getPaceFormatted()} min/km");
      if (workoutData.value.previousPosition != null) {
        logger.d("    📌 Precisión: ${workoutData.value.previousPosition!.accuracy.toStringAsFixed(1)}m");
      }
      if (workoutData.value.goal != null) {
        logger.d("    🎯 Objetivo: ${workoutData.value.goal!.targetDistanceKm} km");
        logger.d("    ✅ Comp: ${workoutData.value.goal!.isCompleted}");
      }
    }
  }

  // Método para crear un objetivo a partir de la sesión (copiado de TrainingCard)
  WorkoutGoal? _createWorkoutGoalFromSession(Session session) {
    try {
      logger.i("📊 (WorkoutCtrl) Creando WorkoutGoal a partir de: ${session.description}");
      String description = session.description.toLowerCase();
      double targetDistanceKm = 5.0; // Valor predeterminado
      int targetTimeMinutes = 30; // Valor predeterminado

      RegExp distanceRegExp = RegExp(r'(\d+(?:\.\d+)?)\s*km');
      var distanceMatch = distanceRegExp.firstMatch(description);
      if (distanceMatch != null) {
        targetDistanceKm = double.tryParse(distanceMatch.group(1) ?? '5.0') ?? 5.0;
        logger.i("📏 (WorkoutCtrl) Distancia detectada: $targetDistanceKm km");
      }

      RegExp timeRegExp = RegExp(r'(\d+)\s*min');
      var timeMatch = timeRegExp.firstMatch(description);
      if (timeMatch != null) {
        targetTimeMinutes = int.tryParse(timeMatch.group(1) ?? '30') ?? 30;
         logger.i("⏱️ (WorkoutCtrl) Tiempo detectado: $targetTimeMinutes min");
      }
      // Solo crear objetivo si se detectó al menos distancia o tiempo
      if (distanceMatch != null || timeMatch != null) {
         return WorkoutGoal(
            targetDistanceKm: targetDistanceKm,
            targetTimeMinutes: targetTimeMinutes,
         );
      } else {
          logger.w("⚠️ (WorkoutCtrl) No se detectó distancia ni tiempo en la descripción para crear objetivo.");
          return null;
      }

    } catch (e) {
      logger.e('❌ (WorkoutCtrl) Error creando WorkoutGoal: $e');
      return null; // Devolver null si hay error o no se puede parsear
    }
  }

  @override
  void onClose() {
    logger.i("(WorkoutCtrl) onClose - Limpiando...");
    _locationService.dispose();
    _goalCheckTimer?.cancel();
    super.onClose();
  }
}
