import 'package:flutter_test/flutter_test.dart';
import 'package:runap/features/map/models/workout_data.dart';
import 'package:runap/features/map/models/workout_goal.dart';

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
  });
}
