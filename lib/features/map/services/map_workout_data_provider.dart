// ignore_for_file: avoid_print

import 'package:runap/features/map/models/workout_goal.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WorkoutDatabaseService {
  // En una implementación real, aquí conectarías con tu base de datos
  // Por ahora usamos datos de prueba

  Future<List<WorkoutGoal>> getAvailableWorkoutGoals() async {
    // Simular retraso de red o base de datos
    await Future.delayed(const Duration(milliseconds: 300));

    // Datos de prueba
    return [
      WorkoutGoal(targetDistanceKm: 2.5, targetTimeMinutes: 15),
      WorkoutGoal(targetDistanceKm: 5.0, targetTimeMinutes: 30),
      WorkoutGoal(targetDistanceKm: 10.0, targetTimeMinutes: 60),
    ];
  }

  Future<WorkoutGoal?> getRecommendedWorkoutGoal() async {
    // Simular retraso de red o base de datos
    await Future.delayed(const Duration(milliseconds: 200));

    // Simplemente devolvemos el primer objetivo como recomendado para pruebas
    return WorkoutGoal(targetDistanceKm: 5.0, targetTimeMinutes: 30);
  }

  Future<void> saveWorkoutResult(
      double distanceKm, int durationSeconds, bool goalCompleted) async {
    // Simular guardado en base de datos
    await Future.delayed(const Duration(milliseconds: 500));

    // En una implementación real, aquí guardarías los datos en la base de datos
    print(
        'Workout saved: $distanceKm km in $durationSeconds seconds. Goal completed: $goalCompleted');
  }

  Future<void> saveWorkoutRoute(List<LatLng> routePoints) async {
    // Simulate saving to database
    await Future.delayed(const Duration(milliseconds: 500));

    // In a real implementation, you would save the route points to the database
    print('Workout route saved with ${routePoints.length} points');
  }
}
