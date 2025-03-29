import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:runap/features/dashboard/viewmodels/training_view_model.dart';
import 'package:runap/features/map/models/workout_data.dart';
import 'package:runap/features/map/models/workout_goal.dart';
import 'package:runap/features/map/services/location_service.dart';
import 'package:runap/features/map/services/map_workout_data_provider.dart';
import 'package:runap/features/map/utils/location_permission_helper.dart';

class MapController extends GetxController {
  // Variables observables
  final Rx<WorkoutData> workoutData = WorkoutData().obs;
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool showGoalSelector = false.obs;
  final RxList<WorkoutGoal> availableGoals = <WorkoutGoal>[].obs;

  // Servicios y helpers
  late LocationService locationService;
  final LocationPermissionHelper permissionHelper = LocationPermissionHelper();
  final WorkoutDatabaseService databaseService = WorkoutDatabaseService();

  // Variables de control
  bool _isInitializing = false;
  int _stabilizationCount = 0;
  LatLng? _lastStablePosition;

  // Controlador del mapa de Google
  Rxn<GoogleMapController> mapController = Rxn<GoogleMapController>();

  // Variables para el entrenamiento
  Rxn<DateTime> workoutStartTime = Rxn<DateTime>();
  Timer? goalCheckTimer;

  // Sesión a actualizar (si viene del dashboard)
  final Rxn<Session> sessionToUpdate = Rxn<Session>();

  // Constructor
  MapController({Session? initialSession, WorkoutGoal? initialWorkoutGoal}) {
    if (initialSession != null) {
      sessionToUpdate.value = initialSession;
    }

    if (initialWorkoutGoal != null) {
      workoutData.value.setGoal(initialWorkoutGoal);
    }

    locationService = LocationService(
      onLocationUpdate: _handleLocationUpdate,
      onMetricsUpdate: _handleMetricsUpdate,
    );
  }

  @override
  void onInit() {
    super.onInit();

    // Verificar si la sesión debe ser accesible (SOLO HOY)
    if (sessionToUpdate.value != null) {
      final now = DateTime.now();
      final isToday = now.year == sessionToUpdate.value!.sessionDate.year &&
          now.month == sessionToUpdate.value!.sessionDate.month &&
          now.day == sessionToUpdate.value!.sessionDate.day;

      final canAccess = isToday &&
          !sessionToUpdate.value!.workoutName
              .toLowerCase()
              .contains('descanso');

      if (!canAccess) {
        // No debería acceder a este entrenamiento, regresar
        Get.back();
        Get.snackbar(
          'Acceso denegado',
          'Solo puedes iniciar entrenamientos programados para hoy',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }
    }

    initialize();
  }

// Añade este nuevo método a MapController para filtrar puntos GPS iniciales
  void _handleLocationUpdate(LatLng position) {
    workoutData.update((val) {
      val?.currentPosition = position;

      if (val?.isWorkoutActive == true) {
        // Estabilización de ruta al inicio
        if (_stabilizationCount < 3) {
          _stabilizationCount++;

          // Si tenemos un punto estable previo, verificamos la distancia
          if (_lastStablePosition != null) {
            double distance = Geolocator.distanceBetween(
                _lastStablePosition!.latitude,
                _lastStablePosition!.longitude,
                position.latitude,
                position.longitude);

            if (distance > 50) {
              // Si hay un salto grande, resetear el contador
              _stabilizationCount = 0;
              print(
                  "⚠️ MapController - Saltó GPS detectado (${distance.toStringAsFixed(1)}m), esperando estabilización");
              return;
            }
          }

          // Actualizar última posición estable
          _lastStablePosition = position;

          // En fase de estabilización, no añadimos puntos a la ruta
          if (_stabilizationCount < 3) {
            print(
                "🔍 MapController - Estabilizando GPS: ${_stabilizationCount}/3");
            return;
          } else {
            print(
                "✅ MapController - GPS estabilizado, iniciando trazado de ruta");
          }
        }

        // Una vez estabilizado, añadimos puntos a la polilínea
        val?.polylineCoordinates.add(position);
        val?.updatePolyline();
        mapController.value?.animateCamera(CameraUpdate.newLatLng(position));
      }
    });
  }

  void _handleMetricsUpdate(Position position) {
    locationService.updateMetrics(workoutData.value, position);

    // Verificar si se ha alcanzado el objetivo después de actualizar métricas
    if (workoutData.value.isWorkoutActive && workoutData.value.goal != null) {
      workoutData.value.checkGoalCompletion();
    }

    // Forzar actualización de la UI
    workoutData.refresh();
  }

  Future<void> initialize() async {
    isLoading.value = true;

    await checkLocationPermissions();

    // Cargar objetivo recomendado al iniciar
    try {
      final recommendedGoal = await databaseService.getRecommendedWorkoutGoal();
      if (recommendedGoal != null && workoutData.value.goal == null) {
        workoutData.update((val) {
          val?.setGoal(recommendedGoal);
        });
      }
    } catch (e) {
      // Manejar error al cargar el objetivo recomendado
      print('Error al cargar objetivo recomendado: $e');
    }

    // Cargar objetivos disponibles
    try {
      availableGoals.value = await databaseService.getAvailableWorkoutGoals();
    } catch (e) {
      print('Error al cargar objetivos disponibles: $e');
    }

    isLoading.value = false;
  }

  void setWorkoutGoal(WorkoutGoal goal) {
    workoutData.update((val) {
      val?.setGoal(goal);
    });
    showGoalSelector.value = false;
  }

  Future<void> checkLocationPermissions() async {
    bool serviceEnabled = await permissionHelper.checkLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Servicio de ubicación desactivado',
        'Por favor activa el servicio de ubicación para usar esta función',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    LocationPermission permission =
        await permissionHelper.checkLocationPermission();
    bool isPermanentlyDenied = await permissionHelper.isPermanentlyDenied();

    if (isPermanentlyDenied) {
      Get.dialog(
        AlertDialog(
          title: Text('Permiso de ubicación denegado permanentemente'),
          content: Text(
              'Para usar esta función, necesitas otorgar permisos de ubicación en la configuración de la aplicación.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                permissionHelper.openAppSettings();
                Get.back();
              },
              child: Text('Abrir Configuración'),
            ),
          ],
        ),
      );
      return;
    } else if (permission == LocationPermission.denied) {
      Get.dialog(
        AlertDialog(
          title: Text('Permiso de ubicación denegado'),
          content: Text(
              'Necesitamos permiso para acceder a la ubicación para rastrear tu entrenamiento.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Get.back();
                LocationPermission permission =
                    await permissionHelper.requestLocationPermission();
                if (permission == LocationPermission.always ||
                    permission == LocationPermission.whileInUse) {
                  await getCurrentLocationAndAnimateCamera();
                }
              },
              child: Text('Solicitar Permisos'),
            ),
          ],
        ),
      );
      return;
    }

    await getCurrentLocationAndAnimateCamera();
  }

  Future<void> getCurrentLocationAndAnimateCamera() async {
    try {
      Position position = await locationService.getCurrentPosition();
      LatLng latLng = LatLng(position.latitude, position.longitude);

      workoutData.update((val) {
        val?.currentPosition = latLng;
      });

      if (workoutData.value.currentPosition != null &&
          mapController.value != null) {
        mapController.value!.animateCamera(CameraUpdate.newLatLngZoom(
            workoutData.value.currentPosition!, 17.0));
      }
    } catch (e) {
      print('Error al obtener la ubicación: $e');
    }
  }

  void startWorkout() async {
    LocationPermission permission =
        await permissionHelper.checkLocationPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return;
    }

    // Mostrar indicador de inicialización
    _isInitializing = true;
    _stabilizationCount = 0;
    _lastStablePosition = null;
    update(); // Si usas GetX

    // Obtener una ubicación estable antes de iniciar la ruta
    print("🔄 MapController - Estabilizando ubicación GPS...");

    // Esperar 2 segundos para que el GPS obtenga una buena señal
    await Future.delayed(Duration(seconds: 2));

    try {
      // Obtener posición actual
      final initialPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 5));

      // Verificar que la precisión sea buena
      if (initialPosition.accuracy <= 20) {
        // Precisión de 20 metros o mejor
        _lastStablePosition =
            LatLng(initialPosition.latitude, initialPosition.longitude);
        print(
            "✅ MapController - Ubicación inicial estable: ${initialPosition.accuracy}m");
      } else {
        print(
            "⚠️ MapController - Precisión inicial insuficiente: ${initialPosition.accuracy}m");
        // Continuaremos de todos modos, pero con una advertencia
      }
    } catch (e) {
      print("⚠️ MapController - Error al obtener ubicación estable: $e");
    }

    // Resetear datos del workout
    workoutData.update((val) {
      val?.reset();
      val?.isWorkoutActive = true;

      // Si hay un objetivo, actualizar su tiempo de inicio
      if (val?.goal != null) {
        val?.setGoal(WorkoutGoal(
          targetDistanceKm: val.goal!.targetDistanceKm,
          targetTimeMinutes: val.goal!.targetTimeMinutes,
          startTime: DateTime.now(),
        ));
      }

      // SOLO agregar el punto inicial si tenemos una posición estable
      if (_lastStablePosition != null && val?.currentPosition != null) {
        // Verificar si ambas posiciones están muy cercanas
        double distanceBetween = Geolocator.distanceBetween(
            _lastStablePosition!.latitude,
            _lastStablePosition!.longitude,
            val!.currentPosition!.latitude,
            val.currentPosition!.longitude);

        // Solo añadir si las posiciones están razonablemente cerca (menos de 30m)
        if (distanceBetween < 30) {
          val.polylineCoordinates.add(_lastStablePosition!);
          print("✅ MapController - Punto inicial añadido a la ruta");
        } else {
          print(
              "⚠️ MapController - Diferencia grande entre posiciones, no se añade punto inicial");
          // No añadir ningún punto, esperaremos a la primera actualización estable
        }
      }
    });

    workoutStartTime.value = DateTime.now();
    _isInitializing = false;
    update(); // Si usas GetX

    locationService.startLocationUpdates();

    // Iniciar timer para verificar el objetivo cada segundo
    goalCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!workoutData.value.isWorkoutActive) {
        timer.cancel();
        return;
      }

      workoutData.refresh(); // Actualizar la UI
    });
  }

  Future<void> stopWorkout() async {
    isSaving.value = true;

    workoutData.update((val) {
      val?.isWorkoutActive = false;
    });

    locationService.stopLocationUpdates();
    goalCheckTimer?.cancel();

    // Calcular tiempo total de entrenamiento
    if (workoutStartTime.value != null) {
      final durationSeconds =
          DateTime.now().difference(workoutStartTime.value!).inSeconds;
      final distanceKm = workoutData.value.distanceMeters / 1000;
      final goalCompleted = workoutData.value.goal?.isCompleted ?? false;

      // Guardar resultados en la base de datos
      try {
        await databaseService.saveWorkoutResult(
            distanceKm, durationSeconds, goalCompleted);
      } catch (e) {
        print('Error al guardar resultados: $e');
      }
    }

    // Si hay una sesión a actualizar (viniendo del dashboard)
    if (sessionToUpdate.value != null) {
      try {
        // Obtener el TrainingViewModel usando GetX
        final trainingViewModel = Get.find<TrainingViewModel>();

        // Marcar la sesión como completada
        await trainingViewModel.toggleSessionCompletion(sessionToUpdate.value!);

        // Mostrar diálogo de éxito
        await _showCompletionDialog();

        // Volver al dashboard
        Get.back();
      } catch (e) {
        Get.snackbar(
          'Error',
          'Error al actualizar el entrenamiento: $e',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    }

    isSaving.value = false;
  }

  Future<void> _showCompletionDialog() async {
    return Get.dialog(
      AlertDialog(
        title: const Text('¡Entrenamiento completado!'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Has completado tu entrenamiento de hoy.'),
              SizedBox(height: 8),
              Text(
                'Distancia: ${(workoutData.value.distanceMeters / 1000).toStringAsFixed(2)} km',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Tiempo: ${getFormattedElapsedTime()}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Volver al Dashboard'),
            onPressed: () {
              Get.back();
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void toggleGoalSelector() {
    showGoalSelector.value = !showGoalSelector.value;
  }

  void setMapControllerInstance(GoogleMapController controller) {
    mapController.value = controller;
  }

  int getElapsedTimeSeconds() {
    if (!workoutData.value.isWorkoutActive || workoutStartTime.value == null)
      return 0;
    return DateTime.now().difference(workoutStartTime.value!).inSeconds;
  }

  String getFormattedElapsedTime() {
    final seconds = getElapsedTimeSeconds();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    locationService.dispose();
    mapController.value?.dispose();
    goalCheckTimer?.cancel();
    super.onClose();
  }
}
