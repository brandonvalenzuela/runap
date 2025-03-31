import 'dart:math';

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

  // Getter para velocidad actual en km/h (para compatibilidad con código existente)
  double get currentSpeed {
    // Aplicar un límite máximo razonable (50 km/h es prácticamente imposible para un corredor)
    double speedKmh = speedMetersPerSecond * 3.6;

    // Si la velocidad es mayor a 50 km/h, probablemente es un error de cálculo
    if (speedKmh > 50) {
      return 0.0; // Devolver 0 para velocidades irreales
    }

    return speedKmh;
  }

  // NUEVO: Método para obtener el ritmo en formato min/km (lo que usan los corredores)
  String getPaceFormatted() {
    if (speedMetersPerSecond <= 0.1) {
      // Velocidad muy baja o cero
      return "--:--"; // No hay ritmo que mostrar
    }

    // Calcular minutos por kilómetro
    double minutesPerKm = 60 / (speedMetersPerSecond * 3.6);

    // Si el ritmo es menor a 2 min/km o mayor a 20 min/km, probablemente es un error
    if (minutesPerKm < 2 || minutesPerKm > 20) {
      return "--:--";
    }

    int minutes = minutesPerKm.floor();
    int seconds = ((minutesPerKm - minutes) * 60).round();

    // Formatear como min:seg
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  // Getter para ritmo actual en km/h
  double getAverageSpeedKmh() {
    if (previousTime == null || !isWorkoutActive) return 0.0;

    Duration duration = DateTime.now().difference(previousTime!);
    if (duration.inSeconds == 0) return 0.0;

    double hours = duration.inSeconds / 3600;
    double distanceKm = distanceMeters / 1000;

    double speed = distanceKm / hours;

    // Aplicar un límite razonable
    if (speed > 50) {
      return 0.0;
    }

    return speed;
  }

  // NUEVO: Método para obtener el ritmo promedio en formato min/km
  String getAveragePaceFormatted() {
    double averageSpeed = getAverageSpeedKmh();

    if (averageSpeed <= 0.1) {
      return "--:--";
    }

    // Calcular minutos por kilómetro
    double minutesPerKm = 60 / averageSpeed;

    // Validar el rango
    if (minutesPerKm < 2 || minutesPerKm > 20) {
      return "--:--";
    }

    int minutes = minutesPerKm.floor();
    int seconds = ((minutesPerKm - minutes) * 60).round();

    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  // Getters para mantener compatibilidad
  double get distance => distanceMeters;
  int get calories => _calculateCalories();
  int get heartRate => 0; // Valor ficticio, necesitaría un sensor para datos reales

  void addPolylineCoordinate(LatLng coordinate) {
    polylineCoordinates.add(coordinate);
    currentPosition = coordinate;
    updatePolyline();
  }

  void updateDistance(LatLng newPosition) {
    if (currentPosition != null) {
      double newDistance = Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );
      distanceMeters += newDistance;
    }
    currentPosition = newPosition;
  }

  void updatePolyline({Color? primaryColor, Color? outlineColor}) {
    if (polylineCoordinates.length < 2) return;
    
    // Usar colores pasados o por defecto
    final Color runningColor = primaryColor ?? Colors.blue.shade600;
    final Color runningOutlineColor = outlineColor ?? Colors.black;
    
    // Crear polilíneas con estilo deportivo
    final Polyline backgroundLine = Polyline(
      polylineId: PolylineId('workout_route_bg'),
      color: runningOutlineColor,
      width: 9,
      points: polylineCoordinates,
      zIndex: 1,
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
    
    final Polyline foregroundLine = Polyline(
      polylineId: PolylineId('workout_route_fg'),
      color: runningColor,
      width: 6,
      points: polylineCoordinates,
      zIndex: 2,
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
    
    // Añadir ambas polilíneas
    polylines.clear();
    polylines.add(backgroundLine);
    polylines.add(foregroundLine);
  }

  // También, añade un método para limpiar puntos duplicados o muy cercanos
  // para mejorar el rendimiento y la precisión de la ruta
  void optimizeRoute() {
    if (polylineCoordinates.length <= 2) return;

    List<LatLng> optimized = [polylineCoordinates.first];

    for (int i = 1; i < polylineCoordinates.length; i++) {
      LatLng current = polylineCoordinates[i];
      LatLng previous = optimized.last;

      // Calcular distancia aproximada (no necesitamos precisión perfecta aquí)
      double distanceApprox = sqrt(
              pow(current.latitude - previous.latitude, 2) +
                  pow(current.longitude - previous.longitude, 2)) *
          111000; // Factor aproximado para convertir grados a metros

      // Solo añadir puntos que estén a más de 5 metros del punto anterior
      if (distanceApprox > 5) {
        optimized.add(current);
      }
    }

    // Si hemos eliminado puntos, actualizar la lista y la polilínea
    if (optimized.length < polylineCoordinates.length) {
      polylineCoordinates.clear();
      polylineCoordinates.addAll(optimized);
      updatePolyline();
    }
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

  // Método para calcular calorías quemadas (estimación básica)
  int _calculateCalories() {
    // Fórmula simple: aproximadamente 1 caloría por kg de peso por km recorrido
    // Asumimos un peso promedio de 70kg
    const double weightKg = 70.0;
    double distanceKm = distanceMeters / 1000;
    return (distanceKm * weightKg).round();
  }
}
