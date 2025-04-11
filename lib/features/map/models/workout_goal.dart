class WorkoutGoal {
  final double targetDistanceKm;
  final int targetTimeMinutes;
  final double? targetPaceMinutesPerKm;
  final DateTime startTime;
  bool isCompleted = false;

  WorkoutGoal({
    required this.targetDistanceKm,
    required this.targetTimeMinutes,
    this.targetPaceMinutesPerKm,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  int get remainingTimeSeconds {
    final targetEndTime = startTime.add(Duration(minutes: targetTimeMinutes));
    final now = DateTime.now();
    final remaining = targetEndTime.difference(now).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  String get formattedTargetDistance => targetDistanceKm.toStringAsFixed(2);

  String get formattedRemainingTime {
    final minutes = remainingTimeSeconds ~/ 60;
    final seconds = remainingTimeSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  double get completionPercentage {
    return isCompleted ? 100.0 : 0.0;
  }
}
