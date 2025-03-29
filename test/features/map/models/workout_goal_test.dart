import 'package:flutter_test/flutter_test.dart';
import 'package:runap/features/map/models/workout_goal.dart';

void main() {
  group('WorkoutGoal', () {
    test('should initialize with correct values', () {
      final goal = WorkoutGoal(
        targetDistanceKm: 5.0,
        targetTimeMinutes: 30,
      );
      
      expect(goal.targetDistanceKm, 5.0);
      expect(goal.targetTimeMinutes, 30);
      expect(goal.isCompleted, isFalse);
      expect(goal.formattedTargetDistance, '5.00');
    });
    
    test('isCompleted should be settable', () {
      final goal = WorkoutGoal(
        targetDistanceKm: 5.0,
        targetTimeMinutes: 30,
      );
      
      goal.isCompleted = true;
      
      expect(goal.isCompleted, isTrue);
      expect(goal.completionPercentage, 100.0);
    });

    test('remainingTimeSeconds should calculate correctly', () {
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
    
    test('formattedRemainingTime should format time correctly', () {
      final startTime = DateTime.now();
      final goal = WorkoutGoal(
        targetDistanceKm: 5.0,
        targetTimeMinutes: 30,
        startTime: startTime,
      );
      
      final remainingTime = goal.formattedRemainingTime;
      // Formato esperado: "minutos:segundos" (por ejemplo "30:00" o "29:59")
      expect(remainingTime, matches(r'^\d+:\d{2}$'));
    });
  });
}
