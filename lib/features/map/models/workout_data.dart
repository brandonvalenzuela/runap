import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
  }

  String getSpeedFormatted() => (speedMetersPerSecond * 3.6).toStringAsFixed(2);
  String getDistanceFormatted() => (distanceMeters / 1000).toStringAsFixed(2);
}
