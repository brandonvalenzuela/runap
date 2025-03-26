class Dashboard {
  final String raceType;
  final String targetPace;
  final String goalTime;
  final int weeksToRace;
  final int totalSessions;
  final int completedSessions;
  final int completionRate;
  final List<Session> nextWeekSessions;

  Dashboard({
    required this.raceType,
    required this.targetPace,
    required this.goalTime,
    required this.weeksToRace,
    required this.totalSessions,
    required this.completedSessions,
    required this.completionRate,
    required this.nextWeekSessions,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      raceType: json['raceType'] ?? '',
      targetPace: json['targetPace'] ?? '',
      goalTime: json['goalTime'] ?? '',
      weeksToRace: json['weeksToRace'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
      completedSessions: json['completedSessions'] ?? 0,
      completionRate: json['completionRate'] ?? 0,
      nextWeekSessions: (json['nextWeekSessions'] as List?)
              ?.map((e) => Session.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'raceType': raceType,
      'targetPace': targetPace,
      'goalTime': goalTime,
      'weeksToRace': weeksToRace,
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'completionRate': completionRate,
      'nextWeekSessions': nextWeekSessions.map((e) => e.toJson()).toList(),
    };
  }
}

class Session {
  final DateTime sessionDate;
  final String workoutName;
  final String description;
  bool completed;

  Session({
    required this.sessionDate,
    required this.workoutName,
    required this.description,
    this.completed = false,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      sessionDate: json['sessionDate'] != null
          ? DateTime.parse(json['sessionDate'])
          : DateTime.now(),
      workoutName: json['workoutName'] ?? '',
      description: json['description'] ?? '',
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionDate': sessionDate.toIso8601String(),
      'workoutName': workoutName,
      'description': description,
      'completed': completed,
    };
  }
}
