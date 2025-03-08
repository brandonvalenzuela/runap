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
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10,
    );

    _locationStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) {
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
      double distance = Geolocator.distanceBetween(
        data.previousPosition!.latitude,
        data.previousPosition!.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );

      data.distanceMeters += distance;

      DateTime currentTime = DateTime.now();
      Duration timeDifference = currentTime.difference(data.previousTime!);
      double timeSeconds = timeDifference.inSeconds.toDouble();

      if (timeSeconds > 0) {
        data.speedMetersPerSecond = distance / timeSeconds;
      }
    }

    data.previousPosition = currentPosition;
    data.previousTime = DateTime.now();
  }

  void dispose() {
    stopLocationUpdates();
  }
}
