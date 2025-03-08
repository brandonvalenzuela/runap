import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:runap/features/map/models/workout_data.dart';
import 'package:runap/features/map/models/workout_goal.dart';
import 'package:runap/features/map/services/location_service.dart';
import 'package:runap/features/map/services/workout_database_service.dart';
import 'package:runap/features/map/utils/location_permission_helper.dart';

class MapWorkoutController {
  final WorkoutData workoutData = WorkoutData();
  late LocationService locationService;
  final LocationPermissionHelper permissionHelper = LocationPermissionHelper();
  final WorkoutDatabaseService databaseService = WorkoutDatabaseService();
  GoogleMapController? mapController;
  final Function(WorkoutData) onWorkoutDataChanged;
  DateTime? workoutStartTime;
  Timer? goalCheckTimer;

  MapWorkoutController({required this.onWorkoutDataChanged}) {
    locationService = LocationService(
      onLocationUpdate: _handleLocationUpdate,
      onMetricsUpdate: _handleMetricsUpdate,
    );
  }

  void _handleLocationUpdate(LatLng position) {
    workoutData.currentPosition = position;
    if (workoutData.isWorkoutActive) {
      workoutData.polylineCoordinates.add(position);
      workoutData.updatePolyline();
      mapController?.animateCamera(CameraUpdate.newLatLng(position));
    }
    onWorkoutDataChanged(workoutData);
  }

  void _handleMetricsUpdate(Position position) {
    locationService.updateMetrics(workoutData, position);

    // Verificar si se ha alcanzado el objetivo después de actualizar métricas
    if (workoutData.isWorkoutActive && workoutData.goal != null) {
      workoutData.checkGoalCompletion();
    }

    onWorkoutDataChanged(workoutData);
  }

  Future<void> initialize() async {
    await checkLocationPermissions();

    // Cargar objetivo recomendado al iniciar
    try {
      final recommendedGoal = await databaseService.getRecommendedWorkoutGoal();
      if (recommendedGoal != null) {
        workoutData.setGoal(recommendedGoal);
        onWorkoutDataChanged(workoutData);
      }
    } catch (e) {
      // Manejar error al cargar el objetivo recomendado
    }
  }

  Future<List<WorkoutGoal>> getAvailableGoals() async {
    return await databaseService.getAvailableWorkoutGoals();
  }

  void setWorkoutGoal(WorkoutGoal goal) {
    workoutData.setGoal(goal);
    onWorkoutDataChanged(workoutData);
  }

  Future<void> checkLocationPermissions() async {
    bool serviceEnabled = await permissionHelper.checkLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission =
        await permissionHelper.checkLocationPermission();
    bool isPermanentlyDenied = await permissionHelper.isPermanentlyDenied();

    if (isPermanentlyDenied) {
      return;
    } else if (permission == LocationPermission.denied) {
      return;
    }

    await getCurrentLocationAndAnimateCamera();
  }

  Future<void> getCurrentLocationAndAnimateCamera() async {
    try {
      Position position = await locationService.getCurrentPosition();
      LatLng latLng = LatLng(position.latitude, position.longitude);
      workoutData.currentPosition = latLng;

      if (workoutData.currentPosition != null) {
        mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(workoutData.currentPosition!, 17.0));
      }

      onWorkoutDataChanged(workoutData);
    } catch (e) {
      // Manejo de errores
    }
  }

  void startWorkout() async {
    LocationPermission permission =
        await permissionHelper.checkLocationPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return;
    }

    workoutData.reset();
    workoutData.isWorkoutActive = true;
    workoutStartTime = DateTime.now();

    // Si hay un objetivo, actualizar su tiempo de inicio
    if (workoutData.goal != null) {
      workoutData.setGoal(WorkoutGoal(
        targetDistanceKm: workoutData.goal!.targetDistanceKm,
        targetTimeMinutes: workoutData.goal!.targetTimeMinutes,
        startTime: workoutStartTime,
      ));
    }

    if (workoutData.currentPosition != null) {
      workoutData.polylineCoordinates.add(workoutData.currentPosition!);
    }

    locationService.startLocationUpdates();

    // Iniciar timer para verificar el objetivo cada segundo
    goalCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!workoutData.isWorkoutActive) {
        timer.cancel();
        return;
      }

      onWorkoutDataChanged(workoutData);
    });

    onWorkoutDataChanged(workoutData);
  }

  void stopWorkout() async {
    workoutData.isWorkoutActive = false;
    locationService.stopLocationUpdates();
    goalCheckTimer?.cancel();

    // Calcular tiempo total de entrenamiento
    if (workoutStartTime != null) {
      final durationSeconds =
          DateTime.now().difference(workoutStartTime!).inSeconds;
      final distanceKm = workoutData.distanceMeters / 1000;
      final goalCompleted = workoutData.goal?.isCompleted ?? false;

      // Guardar resultados en la base de datos
      try {
        await databaseService.saveWorkoutResult(
            distanceKm, durationSeconds, goalCompleted);
      } catch (e) {
        // Manejar error al guardar
      }
    }

    onWorkoutDataChanged(workoutData);
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }

  void dispose() {
    locationService.dispose();
    mapController?.dispose();
    goalCheckTimer?.cancel();
  }

  int getElapsedTimeSeconds() {
    if (!workoutData.isWorkoutActive || workoutStartTime == null) return 0;
    return DateTime.now().difference(workoutStartTime!).inSeconds;
  }

  String getFormattedElapsedTime() {
    final seconds = getElapsedTimeSeconds();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
