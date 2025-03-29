import 'package:flutter_test/flutter_test.dart';
import 'package:runap/features/map/models/workout_data.dart';
import 'package:runap/features/map/models/workout_goal.dart';

void main() {
  group('WorkoutData Model Tests', () {
    test('WorkoutData initializes with default values', () {
      final workoutData = WorkoutData();
      
      expect(workoutData.distanceMeters, equals(0));
      expect(workoutData.speedMetersPerSecond, equals(0));
      expect(workoutData.isWorkoutActive, equals(false));
    });
    
    test('WorkoutData currentSpeed converts m/s to km/h correctly', () {
      final workoutData = WorkoutData();
      workoutData.speedMetersPerSecond = 2.5; // 2.5 m/s
      
      expect(workoutData.currentSpeed, equals(9.0)); // 9 km/h (2.5 * 3.6)
    });
    
    test('WorkoutData formats distance correctly', () {
      final workoutData = WorkoutData();
      workoutData.distanceMeters = 5250; // 5.25 km
      
      expect(workoutData.getDistanceFormatted(), equals('5.25'));
    });
  });
  
  group('WorkoutGoal Model Tests', () {
    test('WorkoutGoal initializes correctly', () {
      final goal = WorkoutGoal(
        targetDistanceKm: 5.0,
        targetTimeMinutes: 30,
      );
      
      expect(goal.targetDistanceKm, equals(5.0));
      expect(goal.targetTimeMinutes, equals(30));
      expect(goal.isCompleted, isFalse);
      expect(goal.formattedTargetDistance, equals('5.00'));
    });
    
    test('WorkoutGoal calculates remaining time correctly', () {
      // Crear un objetivo con tiempo de inicio fijo para la prueba
      final startTime = DateTime.now();
      final goal = WorkoutGoal(
        targetDistanceKm: 5.0,
        targetTimeMinutes: 30,
        startTime: startTime,
      );
      
      // El tiempo restante debe ser cercano a 30 minutos (1800 segundos)
      // Permitimos un pequeño margen debido al tiempo de ejecución
      expect(goal.remainingTimeSeconds, greaterThan(1790));
      expect(goal.remainingTimeSeconds, lessThanOrEqualTo(1800));
    });
  });
}
