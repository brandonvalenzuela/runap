class Dashboard {
  final String raceType;
  final String targetPace;
  final String goalTime;
  final int weeksToRace;
  final int totalSessions;
  // Estas propiedades ya no son finales para permitir actualizaciones
  int completedSessions;
  int completionRate;
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

  // Método de conveniencia para actualizar las estadísticas basadas en sesiones completadas
  void updateStats() {
    completedSessions =
        nextWeekSessions.where((session) => session.completed).length;
    completionRate = totalSessions > 0
        ? (completedSessions / totalSessions * 100).round()
        : 0;
  }

  // Método para comparar si dos fechas son el mismo día
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  // Método para determinar si una fecha es anterior a hoy
  bool isBeforeToday(DateTime date) {
    final now = DateTime.now();
    return date.year < now.year || 
          (date.year == now.year && date.month < now.month) ||
          (date.year == now.year && date.month == now.month && date.day < now.day);
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
