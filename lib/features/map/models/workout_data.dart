import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'workout_goal.dart';

class WorkoutData {
  final List<LatLng> polylineCoordinates = [];
  final Set<Polyline> polylines = {};
  double distanceMeters = 0;
  double speedMetersPerSecond = 0;
  int cadenceStepsPerMinute = 0;
  Position? previousPosition;
  DateTime? previousTime;
  bool isWorkoutActive = false;
  LatLng? currentPosition;
  WorkoutGoal? goal;

  void updatePolyline() {
    polylines.add(
      Polyline(
        polylineId: const PolylineId('workout_route'),
        points: polylineCoordinates,
        color: Colors.blue,
        width: 5,
      ),
    );
  }

  void reset() {
    polylineCoordinates.clear();
    polylines.clear();
    distanceMeters = 0;
    speedMetersPerSecond = 0;
    isWorkoutActive = false;
    // No reseteamos el goal, ya que eso se maneja separadamente
  }

  void setGoal(WorkoutGoal newGoal) {
    goal = newGoal;
  }

  void checkGoalCompletion() {
    if (goal != null && !goal!.isCompleted) {
      // Verificar si se alcanzó la distancia objetivo
      double currentDistanceKm = distanceMeters / 1000;
      if (currentDistanceKm >= goal!.targetDistanceKm) {
        goal!.isCompleted = true;
      }
    }
  }

  double getGoalDistanceCompletionPercentage() {
    if (goal == null) return 0.0;
    double currentDistanceKm = distanceMeters / 1000;
    double percentage = (currentDistanceKm / goal!.targetDistanceKm) * 100;
    return percentage > 100 ? 100 : percentage;
  }

  String getSpeedFormatted() => (speedMetersPerSecond * 3.6).toStringAsFixed(2);
  String getDistanceFormatted() => (distanceMeters / 1000).toStringAsFixed(2);

  double getAverageSpeedKmh() {
    if (previousTime == null || !isWorkoutActive) return 0.0;

    Duration duration = DateTime.now().difference(previousTime!);
    if (duration.inSeconds == 0) return 0.0;

    double hours = duration.inSeconds / 3600;
    double distanceKm = distanceMeters / 1000;
    return distanceKm / hours;
  }

  String getEstimatedCompletionTime() {
    if (goal == null || !isWorkoutActive || speedMetersPerSecond <= 0) {
      return "--:--";
    }

    double remainingDistanceMeters =
        (goal!.targetDistanceKm * 1000) - distanceMeters;
    if (remainingDistanceMeters <= 0) return "00:00";

    int estimatedSecondsLeft =
        (remainingDistanceMeters / speedMetersPerSecond).round();
    int minutes = estimatedSecondsLeft ~/ 60;
    int seconds = estimatedSecondsLeft % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
