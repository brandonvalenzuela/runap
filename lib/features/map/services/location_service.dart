// ignore_for_file: avoid_print

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:runap/features/map/models/workout_data.dart';

class LocationService {
  StreamSubscription<Position>? _locationStreamSubscription;
  final Function(LatLng) onLocationUpdate;
  final Function(Position) onMetricsUpdate;

  LocationService({
    required this.onLocationUpdate,
    required this.onMetricsUpdate,
  });

  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  void startLocationUpdates() {
    // Configuración más eficiente
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 8, // Aumentar a 8 metros para reducir eventos
      timeLimit:
          Duration(seconds: 2), // Máximo una actualización cada 2 segundos
    );

    // Añadir log para confirmar inicio
    print("🛰️ LocationService - Iniciando actualizaciones GPS");

    _locationStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) {
      // Verificar la precisión - ignorar lecturas malas
      if (position.accuracy > 30) {
        print(
            "⚠️ LocationService - Ignorando lectura imprecisa (${position.accuracy}m)");
        return;
      }

      final latLng = LatLng(position.latitude, position.longitude);
      print(
          "📍 LocationService - Nueva posición: $latLng (precisión: ${position.accuracy}m)");

      onLocationUpdate(latLng);
      onMetricsUpdate(position);
    });
  }

  void stopLocationUpdates() {
    _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;
  }

  void updateMetrics(WorkoutData data, Position currentPosition) {
    // Imprimir datos para depuración
    print(
        "📊 Actualizando métricas. Velocidad GPS: ${currentPosition.speed} m/s");

    bool shouldAddDistance = true;

    if (data.previousPosition != null && data.previousTime != null) {
      // Calcular distancia entre posiciones
      double distance = Geolocator.distanceBetween(
        data.previousPosition!.latitude,
        data.previousPosition!.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );

      // Verificar tiempo transcurrido para cálculos precisos
      DateTime currentTime = DateTime.now();
      Duration timeDifference = currentTime.difference(data.previousTime!);
      double timeSeconds = timeDifference.inMilliseconds / 1000;

      // Calcular velocidad instantánea en m/s
      double instantSpeed = distance / timeSeconds;

      // MEJORADO: Filtrado más completo
      if (distance > 100) {
        // Filtro 1: Saltos demasiado grandes
        print("⚠️ Salto de distancia ignorado: $distance metros");
        shouldAddDistance = false;
      } else if (instantSpeed > 8.3) {
        // Filtro 2: Velocidad irreal (> 30 km/h)
        print(
            "⚠️ Velocidad irreal ignorada: ${(instantSpeed * 3.6).toStringAsFixed(1)} km/h");
        shouldAddDistance = false;
      } else if (distance < 1.0 && timeSeconds < 1.0) {
        // Filtro 3: Micromovimientos por imprecisión del GPS
        print("🔍 Micromovimiento ignorado: $distance m");
        shouldAddDistance = false;
      } else if (currentPosition.accuracy > 25) {
        // Filtro 4: Baja precisión del GPS
        print("⚠️ Lectura de baja precisión: ${currentPosition.accuracy}m");
        // Considerar si añadir o no esta distancia según el contexto
        if (distance > currentPosition.accuracy * 0.5) {
          // Si la distancia es significativamente mayor que la imprecisión, añadirla
          print(
              "✅ Distancia considerada significativa a pesar de la baja precisión");
        } else {
          shouldAddDistance = false;
        }
      }

      // Solo sumamos la distancia si pasó todas las validaciones
      if (shouldAddDistance) {
        data.distanceMeters += distance;
        print("✅ Distancia acumulada: ${data.distanceMeters} metros");

        // Calcular velocidad en m/s solo si hay distancia medible
        if (distance > 0 && timeSeconds > 0) {
          double instantSpeed = distance / timeSeconds;

          // Aplicar filtro de suavizado para evitar fluctuaciones bruscas
          if (data.speedMetersPerSecond > 0) {
            // 70% valor anterior + 30% nueva medición
            data.speedMetersPerSecond =
                data.speedMetersPerSecond * 0.7 + instantSpeed * 0.3;
          } else {
            // Primera medición
            data.speedMetersPerSecond = instantSpeed;
          }

          // Imprimir velocidad calculada
          print("🏃‍♂️ Velocidad actual: ${data.speedMetersPerSecond} m/s");
          print("🏃‍♂️ Ritmo actual: ${data.getPaceFormatted()} min/km");
        }
      }
    } else {
      print(
          "⚠️ Primera medición - no hay datos previos para calcular métricas");
    }

    // Actualizar posición y tiempo previos para la siguiente medición
    data.previousPosition = currentPosition;
    data.previousTime = DateTime.now();

    // Si hay un salto grande pero estamos en medio de un entrenamiento activo,
    // podríamos interpolar puntos para mantener la continuidad
    if (!shouldAddDistance &&
        data.isWorkoutActive &&
        data.polylineCoordinates.length > 5) {
      final distance = Geolocator.distanceBetween(
          data.previousPosition!.latitude,
          data.previousPosition!.longitude,
          currentPosition.latitude,
          currentPosition.longitude);

      if (distance > 100 && distance < 500) {
        // Salto grande pero aún plausible
        // Interpolar puntos entre la última posición conocida y la actual
        final lastPoint = LatLng(
            data.previousPosition!.latitude, data.previousPosition!.longitude);
        final currentPoint =
            LatLng(currentPosition.latitude, currentPosition.longitude);

        // Número de puntos a interpolar basado en la distancia
        final pointsToAdd = (distance / 20).round(); // Un punto cada ~20m

        if (pointsToAdd > 1 && pointsToAdd < 20) {
          // Límite razonable
          for (int i = 1; i < pointsToAdd; i++) {
            final fraction = i / pointsToAdd;
            final interpolatedLat = lastPoint.latitude +
                (currentPoint.latitude - lastPoint.latitude) * fraction;
            final interpolatedLng = lastPoint.longitude +
                (currentPoint.longitude - lastPoint.longitude) * fraction;

            data.polylineCoordinates
                .add(LatLng(interpolatedLat, interpolatedLng));

            // Añadir distancia interpolada
            data.distanceMeters += distance / pointsToAdd;
          }

          print(
              "🔄 Interpolados $pointsToAdd puntos para mantener continuidad de ruta");
          data.updatePolyline();
        }
      }
    }
  }

  void dispose() {
    stopLocationUpdates();
  }
}
