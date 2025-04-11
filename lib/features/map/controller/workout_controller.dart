import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';
import 'package:runap/features/dashboard/presentation/manager/training_view_model.dart';
import 'package:runap/features/map/models/workout_data.dart';
import 'package:runap/features/map/models/workout_goal.dart';
import 'package:runap/features/map/services/location_service.dart';
import 'location_permission_controller.dart';
import 'package:runap/features/dashboard/data/datasources/training_service.dart';

// ADDED: Class to hold completion info for the UI listener
class WorkoutCompletionInfo {
  final bool hadGoal;
  final bool goalAchieved;
  final double distanceMeters;
  final Duration duration;
  final double averagePaceMinutesPerKm;

  WorkoutCompletionInfo({
    required this.hadGoal,
    required this.goalAchieved,
    required this.distanceMeters,
    required this.duration,
    required this.averagePaceMinutesPerKm,
  });
}

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
  final TrainingViewModel _trainingViewModel = Get.find<TrainingViewModel>();

  // Variables de control internas
  int _stabilizationCount = 0;
  LatLng? _lastStablePosition;
  Timer? _goalCheckTimer;
  bool _processingFirstRealGpsAfterSimulation = false;
  // ADDED: Flag to indicate if updates are simulated
  bool _isSimulatingUpdates = false;

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
    if (_processingFirstRealGpsAfterSimulation) {
       logger.i("🛰️ Ignorando la primera ubicación GPS real después de reanudar desde simulación.");
       _processingFirstRealGpsAfterSimulation = false;
       return;
    }

    logger.d("📍 (WorkoutCtrl) Nueva posición recibida: $position");

    workoutData.update((val) {
      if (val == null) return;

      val.currentPosition = position;

      if (val.isWorkoutActive == true) {
          // --- ADDED: Distance check before adding to polyline --- 
          bool addPoint = true;
          if (val.polylineCoordinates.isNotEmpty) {
              final lastPoint = val.polylineCoordinates.last;
              double distance = Geolocator.distanceBetween(
                  lastPoint.latitude,
                  lastPoint.longitude,
                  position.latitude,
                  position.longitude);
              
              // Use a threshold (e.g., 100m) to detect large jumps
              const double jumpThreshold = 100.0; 
              if (distance > jumpThreshold) {
                 logger.w("⚠️ Salto de GPS detectado en handleLocationUpdate (${distance.toStringAsFixed(1)}m). Punto NO añadido a polilínea.");
                 addPoint = false;
              }
          }
          // --- END OF ADDED CHECK ---

          // Only add point if distance check passed
          if (addPoint) {
              // --- MODIFIED: Stabilization only for REAL GPS updates --- 
              if (!_isSimulatingUpdates && _stabilizationCount < 3) {
                _stabilizationCount++;
                if (_lastStablePosition != null) {
                  double distanceStable = Geolocator.distanceBetween(
                      _lastStablePosition!.latitude,
                      _lastStablePosition!.longitude,
                      position.latitude,
                      position.longitude);
                  if (distanceStable > 50) { // Stabilization threshold remains
                    _stabilizationCount = 0;
                    logger.d("⚠️ (WorkoutCtrl-Stabilization) Saltó GPS detectado (${distanceStable.toStringAsFixed(1)}m), esperando estabilización");
                    return; // Don't add point during stabilization reset
                  }
                }
                _lastStablePosition = position;
                if (_stabilizationCount < 3) {
                  logger.d("🔍 (WorkoutCtrl) Estabilizando GPS: $_stabilizationCount/3");
                  return; // Don't add point yet
                } else {
                  logger.d("✅ (WorkoutCtrl-Sim/Stabilized) GPS estabilizado o simulando, iniciando trazado de ruta");
                  // If stabilization just finished OR simulating, ensure the stable point is the first one added IF the list is empty
                  if (val.polylineCoordinates.isEmpty) {
                     val.polylineCoordinates.add(position);
                     logger.d("(WorkoutCtrl) Punto estabilizado/simulado añadido como inicial.");
                  } // Otherwise, the normal flow below will add it if needed
                }
              }
              // --- END OF MODIFICATION ---
      
              // Añadir punto a la ruta (if check passed and stabilization allows)
              // --- MODIFIED: Ensure point is added if simulating or stabilized ---
              // If simulating, we always add (addPoint is true, stabilization skipped)
              // If real GPS, add only if stabilization is complete (_stabilizationCount >= 3)
              if (_isSimulatingUpdates || _stabilizationCount >= 3) {
                 // Avoid adding duplicate points (can happen during stabilization transition)
                 if (val.polylineCoordinates.isEmpty || val.polylineCoordinates.last != position) {
                    val.polylineCoordinates.add(position);
                    val.updatePolyline(); 
                    logger.d("✅ (WorkoutCtrl - ${_isSimulatingUpdates ? 'Sim' : 'Real'}) Polilínea actualizada - ${val.polylineCoordinates.length} puntos");
                 } else {
                    logger.d("ℹ️ (WorkoutCtrl) Punto duplicado detectado, no añadido.");
                 }
              } else {
                  logger.d("ℹ️ (WorkoutCtrl) Punto no añadido (Esperando estabilización: ${_stabilizationCount}/3)");
              }
              // --- END OF MODIFICATION ---
          }
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

    _stabilizationCount = 0;
    _lastStablePosition = null;
    
    // Obtain initial position BEFORE starting listeners
    Position? initialPosition;
    try {
       logger.d("🔄 (WorkoutCtrl) Obteniendo posición inicial...");
       initialPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best, // Use best for initial fix
            timeLimit: Duration(seconds: 7), // Increase timeout slightly
          )
       );
       logger.d("✅ (WorkoutCtrl) Posición inicial obtenida: ${initialPosition.latitude}, ${initialPosition.longitude}");
    } catch (e) {
       logger.e("❌ Error al obtener posición inicial: $e");
       Get.snackbar(
          'Error de ubicación', 
          'No se pudo obtener la ubicación inicial. Inténtalo de nuevo.',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
       return; // Do not start workout if initial position fails
    }

    // Set workout as active and update initial state
    workoutData.update((val) {
      val?.reset(); // Reset previous data
      // Call _createWorkoutGoalFromSession only if session is not null
      if (sessionToUpdate.value != null) { 
          val?.goal = _createWorkoutGoalFromSession(sessionToUpdate.value!); // Pass non-null session
      }
      val?.isWorkoutActive = true;
      val?.currentPosition = LatLng(initialPosition!.latitude, initialPosition.longitude);
      val?.previousPosition = initialPosition; // Set previous for metrics
      val?.previousTime = DateTime.now();      // Set time for metrics
      // Add the very first point to the polyline
      if (initialPosition != null) {
         val?.polylineCoordinates.add(LatLng(initialPosition.latitude, initialPosition.longitude));
         val?.updatePolyline();
      }
    });
    workoutStartTime.value = DateTime.now();
    _startGoalCheckTimer();

    // **** Start real location updates AFTER workout is active ****
    _locationService.startLocationUpdates(); 
    logger.i("▶️ (WorkoutCtrl) Entrenamiento iniciado.");
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
    logger.i("⏹️ (WorkoutCtrl) Deteniendo entrenamiento...");
    
    _locationService.stopLocationUpdates(); 
    _goalCheckTimer?.cancel(); 
    
    final endTime = DateTime.now();
    final startTime = workoutStartTime.value;
    Duration? duration;
    if (startTime != null) {
      duration = endTime.difference(startTime);
    }

    // --- Capture final data BEFORE resetting workoutData --- 
    final currentWorkoutData = workoutData.value;
    final finalDistanceMeters = currentWorkoutData.distanceMeters;
    final finalDuration = duration ?? Duration.zero;
    final finalAvgPace = currentWorkoutData.averagePaceMinutesPerKm;
    final finalCalories = currentWorkoutData.calories;
    final finalGoalCompleted = currentWorkoutData.goal?.isCompleted ?? false;
    final finalRouteCoordinates = List<LatLng>.from(currentWorkoutData.polylineCoordinates);
    final Session? sessionBeingUpdated = sessionToUpdate.value; // Keep a reference before clearing
    // --- End of capture --- 

    workoutData.update((val) {
      val?.isWorkoutActive = false;
    });

    if (finalDistanceMeters < 10 && finalDuration.inSeconds < 5) {
       logger.w("⚠️ Entrenamiento demasiado corto. No se guardará.");
       Get.snackbar(
          'Entrenamiento corto', 
          'El entrenamiento fue demasiado corto para ser guardado.',
          backgroundColor: Colors.orange,
        );
       workoutData.value.reset();
       workoutStartTime.value = null;
       sessionToUpdate.value = null; 
       return; 
    }

    isSaving.value = true;
    try {
      logger.d("💾 Preparando datos para guardar...");

      // --- 1. Guardado Local --- 
      final localData = {
        'distanceMeters': finalDistanceMeters,
        'durationSeconds': finalDuration.inSeconds,
        'averagePaceMinutesPerKm': finalAvgPace,
        'calories': finalCalories,
        'goalCompleted': finalGoalCompleted,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        // Convert LatLng list to a JSON encodable format
        'route': finalRouteCoordinates
            .map((coord) => {'latitude': coord.latitude, 'longitude': coord.longitude})
            .toList(),
        // Include session info if available
        'sessionInfo': sessionBeingUpdated?.toJson() 
      };

      // --- UPDATED: Use endTime for filename --- 
      final formattedEndTime = endTime.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final filename = sessionBeingUpdated != null 
          ? 'workout_session_${sessionBeingUpdated.sessionId}_${formattedEndTime}.json' 
          : 'workout_free_${formattedEndTime}.json';
      // --- END UPDATED --- 
      
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/workouts'; // Subdirectory for workouts
      await Directory(path).create(recursive: true); // Ensure directory exists
      final file = File('$path/$filename');
      
      await file.writeAsString(jsonEncode(localData));
      logger.i("💾 Datos del entrenamiento guardados localmente en: $filename");
      
      // --- 2. Actualización Simple de Estado (Compatible con Servicio Actual) ---
      if (sessionBeingUpdated != null) {
          logger.d("🔄 Marcando sesión como completada en TrainingService...");
          // Use the existing service method (assumes TrainingViewModel exposes or uses TrainingService)
          // We might need to access the service directly if ViewModel doesn't expose markSessionAsCompleted
          // For now, let's assume we call it through the ViewModel as a proxy if possible,
          // otherwise we might need TrainingService here.
          // Let's try calling the service directly for simplicity here.
          final trainingService = TrainingService(); // Get instance (assuming singleton)
          bool success = await trainingService.markSessionAsCompleted(sessionBeingUpdated, true);
          if (success) {
             logger.i("✅ Sesión marcada como completada en el servicio.");
             // Trigger UI update if needed (TrainingViewModel listener should handle this)
          } else {
             logger.e("❌ Error al marcar sesión como completada en el servicio.");
             // Maybe show a specific snackbar?
          }
      } else {
         logger.i("ℹ️ Entrenamiento libre completado (no asociado a sesión específica).");
      }

    } catch (e, stacktrace) {
      logger.e("❌ Error durante el proceso de guardado: $e", stackTrace: stacktrace);
      Get.snackbar('Error', 'No se pudo guardar el entrenamiento. $e');
    } finally {
      isSaving.value = false;
      workoutData.value.reset(); 
      workoutStartTime.value = null;
      sessionToUpdate.value = null; 
    }
  }

  // --- Methods to control LocationService from outside (e.g., MapScreen) ---

  void pauseRealLocationUpdates() {
    logger.d("⏸️ (WorkoutCtrl) Pausando actualizaciones GPS reales (LocationService)");
    _locationService.stopLocationUpdates();
  }

  void resumeRealLocationUpdates() {
    if (workoutData.value.isWorkoutActive) {
      logger.d("▶️ (WorkoutCtrl) Reanudando actualizaciones GPS reales (LocationService)");
      _processingFirstRealGpsAfterSimulation = true;
      _locationService.startLocationUpdates();
    } else {
       logger.d("🚫 (WorkoutCtrl) No se reanudan actualizaciones GPS reales (entrenamiento no activo)");
    }
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

  // Método para crear un objetivo a partir de la sesión (ACTUALIZADO)
  WorkoutGoal? _createWorkoutGoalFromSession(Session session) {
    try {
      logger.i("📊 (WorkoutCtrl) Creando WorkoutGoal a partir de: ${session.description}");
      String description = session.description.toLowerCase();
      double? targetDistanceKm;
      int? targetTimeMinutes;
      double? targetPaceMinutesPerKm;

      // --- Regex mejoradas --- 
      // 1. Buscar distancia (e.g., "10 km", "5.5km")
      RegExp distanceRegExp = RegExp(r'(\d+(?:\.\d+)?)\s*k(?:ilo)?m(?:etros)?\b');
      var distanceMatch = distanceRegExp.firstMatch(description);
      if (distanceMatch != null) {
        targetDistanceKm = double.tryParse(distanceMatch.group(1) ?? '');
        if (targetDistanceKm != null) {
           logger.i("📏 (WorkoutCtrl) Distancia detectada: $targetDistanceKm km");
        }
      }

      // 2. Buscar ritmo (e.g., "ritmo 5:30 min/km", "a 6:15/km")
      RegExp paceRegExp = RegExp(r'(\d{1,2}):(\d{2})\s*m(?:in)?\/km\b');
      var paceMatch = paceRegExp.firstMatch(description);
      if (paceMatch != null) {
        int paceMinutes = int.tryParse(paceMatch.group(1) ?? '') ?? 0;
        int paceSeconds = int.tryParse(paceMatch.group(2) ?? '') ?? 0;
        targetPaceMinutesPerKm = paceMinutes + (paceSeconds / 60.0);
        logger.i("⏱️ (WorkoutCtrl) Ritmo detectado: ${paceMatch.group(0)} ($targetPaceMinutesPerKm min/km)");
      }

      // 3. Buscar tiempo total (e.g., "30 min", "45 minutos") - SOLO si NO se encontró ritmo
      if (targetPaceMinutesPerKm == null) { 
        RegExp timeRegExp = RegExp(r'\b(\d+)\s*m(?:inutos)?\b');
        var timeMatch = timeRegExp.firstMatch(description);
        if (timeMatch != null) {
          targetTimeMinutes = int.tryParse(timeMatch.group(1) ?? '');
          if (targetTimeMinutes != null) {
             logger.i("⏱️ (WorkoutCtrl) Tiempo total detectado: $targetTimeMinutes min");
          }
        }
      }

      // --- Lógica de creación del objetivo --- 

      // Caso 1: Distancia y Ritmo -> Calcular Tiempo
      if (targetDistanceKm != null && targetPaceMinutesPerKm != null) {
        targetTimeMinutes = (targetDistanceKm * targetPaceMinutesPerKm).round();
        logger.i("🎯 Objetivo D+R: $targetDistanceKm km a $targetPaceMinutesPerKm min/km => Tiempo calculado: $targetTimeMinutes min");
        return WorkoutGoal(
            targetDistanceKm: targetDistanceKm,
            targetTimeMinutes: targetTimeMinutes,
            targetPaceMinutesPerKm: targetPaceMinutesPerKm, // Guardar ritmo detectado
        );
      }
      // Caso 2: Solo Distancia -> Usar distancia, tiempo por defecto (o 0?)
      else if (targetDistanceKm != null) {
         logger.i("🎯 Objetivo D: $targetDistanceKm km (sin tiempo/ritmo específico)");
         // Podríamos poner un tiempo muy alto o 0 para indicar que no hay límite de tiempo
         return WorkoutGoal(
            targetDistanceKm: targetDistanceKm,
            targetTimeMinutes: 0, // 0 indica sin límite de tiempo
         );
      }
      // Caso 3: Solo Tiempo -> Usar tiempo, distancia por defecto (o 0?)
      else if (targetTimeMinutes != null) { 
         logger.i("🎯 Objetivo T: $targetTimeMinutes min (sin distancia específica)");
         // Podríamos poner distancia 0 para indicar que no hay objetivo de distancia
         return WorkoutGoal(
            targetDistanceKm: 0, // 0 indica sin objetivo de distancia
            targetTimeMinutes: targetTimeMinutes,
         );
      }
      // Caso 4: No se detectó nada útil
      else {
          logger.w("⚠️ (WorkoutCtrl) No se detectó distancia, tiempo ni ritmo útil en la descripción para crear objetivo.");
          return null;
      }

    } catch (e) {
      logger.e('❌ (WorkoutCtrl) Error creando WorkoutGoal: $e');
      return null; // Devolver null si hay error
    }
  }

  // --- ADDED: Reset state specifically for simulation start ---
  void resetRouteStateForSimulation(LatLng startPosition) {
    logger.i("🔄 (WorkoutCtrl) Reseteando estado de ruta para inicio de simulación en $startPosition");
    workoutData.update((val) {
      if (val == null) return;
      val.polylineCoordinates.clear();
      val.polylineCoordinates.add(startPosition); // Add the first simulated point
      val.previousPosition = null; // Clear previous real position
      val.previousTime = null;
      val.currentPosition = startPosition; // Set current to the start
      // Keep distance, duration etc. as they are, simulation adds to them
      val.updatePolyline(); 
    });
    // Reset stabilization flags as well, if applicable
    _stabilizationCount = 0;
    _lastStablePosition = null;
    _processingFirstRealGpsAfterSimulation = false; // Ensure this is reset
  }

  // --- ADDED: Method to toggle simulation state internally ---
  void setSimulationMode(bool isSimulating) {
    logger.i("🕹️ (WorkoutCtrl) Simulation mode set to: $isSimulating");
    _isSimulatingUpdates = isSimulating;
    if (!isSimulating) {
      // Reset stabilization count when stopping simulation?
      // Or let it be handled by resumeRealLocationUpdates/startWorkout?
      // Let's reset it here for clarity when switching back to real GPS.
       _stabilizationCount = 0;
       _lastStablePosition = null;
       // Set flag to ignore first real update AFTER simulation
       _processingFirstRealGpsAfterSimulation = true; 
    } else {
        // When starting simulation, ensure stabilization isn't active
        _stabilizationCount = 3; // Mark stabilization as complete for simulation
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
