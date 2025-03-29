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
    // Aumentar el distanceFilter a un valor más razonable (15-20 metros)
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best, // Cambiado de bestForNavigation a best
      distanceFilter: 5, // 15 metros
      timeLimit: Duration(
          seconds:
              1), // Añadir un límite de tiempo entre actualizaciones 3 segundos
    );

    _locationStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) {
      // Verificar la precisión - ignorar lecturas malas
      if (position.accuracy > 30) {
        // Ignorar lecturas con precisión peor que 30 metros
        print(
            "⚠️ LocationService - Ignorando lectura imprecisa (${position.accuracy}m)");
        return;
      }

      final latLng = LatLng(position.latitude, position.longitude);
      onLocationUpdate(latLng);
      onMetricsUpdate(position);
    });
  }

  void stopLocationUpdates() {
    _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;
  }

  void updateMetrics(WorkoutData data, Position currentPosition) {
    if (data.previousPosition != null && data.previousTime != null) {
      // Calcular distancia entre posiciones
      double distance = Geolocator.distanceBetween(
        data.previousPosition!.latitude,
        data.previousPosition!.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );

      // MEJORADO: Validar la distancia - si hay un salto muy grande podría ser un error GPS
      // 100 metros en un segundo es bastante rápido para un corredor (360 km/h)
      if (distance > 100) {
        print(
            "⚠️ Detección de salto grande en distancia: $distance metros. Ignorando esta actualización.");
        // No acumular esta distancia, probablemente es un error
        return;
      }

      data.distanceMeters += distance;

      DateTime currentTime = DateTime.now();
      Duration timeDifference = currentTime.difference(data.previousTime!);
      double timeSeconds =
          timeDifference.inMilliseconds / 1000; // Más preciso usar milisegundos

      // MEJORADO: Solo actualizar velocidad si hay suficiente tiempo transcurrido
      if (timeSeconds > 0.1) {
        // Al menos 100ms entre actualizaciones
        // Calcular velocidad en m/s
        double newSpeed = distance / timeSeconds;

        // MEJORADO: Filtrar valores anómalos usando un filtro de suavizado
        // Combinamos 30% de la nueva medición con 70% del valor anterior
        if (data.speedMetersPerSecond > 0) {
          data.speedMetersPerSecond =
              data.speedMetersPerSecond * 0.7 + newSpeed * 0.3;
        } else {
          data.speedMetersPerSecond = newSpeed;
        }

        // MEJORADO: Aplicar límites razonables (8.3 m/s = 30 km/h, que ya es muy rápido)
        if (data.speedMetersPerSecond > 8.3) {
          data.speedMetersPerSecond = 0; // Reiniciar para velocidades irreales
        }
      }
    }

    data.previousPosition = currentPosition;
    data.previousTime = DateTime.now();
  }

  void dispose() {
    stopLocationUpdates();
  }
}
