import 'package:flutter_test/flutter_test.dart';
import 'package:runap/features/map/models/workout_data.dart';
import 'package:runap/features/map/models/workout_goal.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('WorkoutData', () {
    late WorkoutData workoutData;

    setUp(() {
      workoutData = WorkoutData();
    });

    test('should initialize with default values', () {
      expect(workoutData.polylineCoordinates, isEmpty);
      expect(workoutData.polylines, isEmpty);
      expect(workoutData.distanceMeters, 0);
      expect(workoutData.speedMetersPerSecond, 0);
      expect(workoutData.cadenceStepsPerMinute, 0);
      expect(workoutData.previousPosition, isNull);
      expect(workoutData.previousTime, isNull);
      expect(workoutData.isWorkoutActive, false);
      expect(workoutData.currentPosition, isNull);
      expect(workoutData.goal, isNull);
    });

    test('currentSpeed should return speed in km/h', () {
      workoutData.speedMetersPerSecond = 2.5; // 2.5 m/s
      expect(workoutData.currentSpeed, equals(9.0)); // 9 km/h
    });

    test('currentSpeed should return 0 for unreasonable speeds', () {
      workoutData.speedMetersPerSecond = 20; // 20 m/s = 72 km/h, demasiado alto
      expect(workoutData.currentSpeed, equals(0.0));
    });

    test('getPaceFormatted should format pace correctly', () {
      // 3 m/s = 10.8 km/h, ritmo ~ 5:33 min/km
      workoutData.speedMetersPerSecond = 3.0;
      expect(workoutData.getPaceFormatted(), equals('5:33'));
      
      // Velocidad muy baja
      workoutData.speedMetersPerSecond = 0.05;
      expect(workoutData.getPaceFormatted(), equals('--:--'));
    });

    test('reset should clear workout data', () {
      // Configurar datos
      workoutData.distanceMeters = 1000;
      workoutData.speedMetersPerSecond = 2.5;
      workoutData.isWorkoutActive = true;
      
      // Resetear
      workoutData.reset();
      
      // Verificar reset
      expect(workoutData.polylineCoordinates, isEmpty);
      expect(workoutData.polylines, isEmpty);
      expect(workoutData.distanceMeters, 0);
      expect(workoutData.speedMetersPerSecond, 0);
      expect(workoutData.isWorkoutActive, false);
    });

    test('setGoal should set workout goal', () {
      final goal = WorkoutGoal(
        targetDistanceKm: 5.0,
        targetTimeMinutes: 30,
      );
      
      workoutData.setGoal(goal);
      
      expect(workoutData.goal, equals(goal));
    });

    test('getDistanceFormatted should format distance correctly', () {
      workoutData.distanceMeters = 5250; // 5.25 km
      expect(workoutData.getDistanceFormatted(), '5.25');
    });

    // Nuevos tests para polilíneas y cálculos de ritmo
    test('should add polyline coordinates correctly', () {
      final coordinate1 = LatLng(19.4326, -99.1332);
      final coordinate2 = LatLng(19.4327, -99.1333);
      
      workoutData.addPolylineCoordinate(coordinate1);
      workoutData.addPolylineCoordinate(coordinate2);
      
      expect(workoutData.polylineCoordinates.length, equals(2));
      expect(workoutData.polylineCoordinates.first, equals(coordinate1));
      expect(workoutData.polylineCoordinates.last, equals(coordinate2));
    });

    test('should update polylines when adding coordinates', () {
      final coordinate1 = LatLng(19.4326, -99.1332);
      final coordinate2 = LatLng(19.4327, -99.1333);
      
      workoutData.addPolylineCoordinate(coordinate1);
      workoutData.addPolylineCoordinate(coordinate2);
      
      expect(workoutData.polylines.isNotEmpty, true);
      final polyline = workoutData.polylines.first;
      expect(polyline.points, equals([coordinate1, coordinate2]));
    });

    test('should calculate pace correctly for different speeds', () {
      // Test para 12 km/h (3.33 m/s) = 5:00 min/km
      workoutData.speedMetersPerSecond = 3.33;
      expect(workoutData.getPaceFormatted(), equals('5:00'));

      // Test para 8 km/h (2.22 m/s) = 7:30 min/km
      workoutData.speedMetersPerSecond = 2.22;
      expect(workoutData.getPaceFormatted(), equals('7:30'));

      // Test para velocidad cero
      workoutData.speedMetersPerSecond = 0;
      expect(workoutData.getPaceFormatted(), equals('--:--'));
    });

    test('should calculate distance correctly when adding coordinates', () {
      // Coordenadas aproximadamente a 100 metros de distancia
      final coordinate1 = LatLng(19.4326, -99.1332);
      final coordinate2 = LatLng(19.4327, -99.1333);
      
      workoutData.addPolylineCoordinate(coordinate1);
      workoutData.updateDistance(coordinate2);
      
      expect(workoutData.distanceMeters, greaterThan(0));
      expect(workoutData.getDistanceFormatted(), isNot('0.00'));
    });
  });
}
