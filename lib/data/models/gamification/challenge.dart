import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final int id;
  final String name;
  final String description;
  final String type;
  final int points;
  final DateTime startDate;
  final DateTime endDate;
  final double goalValue;
  final String goalUnit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.points,
    required this.startDate,
    required this.endDate,
    required this.goalValue,
    required this.goalUnit,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      points: json['points'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      goalValue: json['goal_value'].toDouble(),
      goalUnit: json['goal_unit'],
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'points': points,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'goal_value': goalValue,
      'goal_unit': goalUnit,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Challenge.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return Challenge(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      type: data['type'],
      points: data['points'],
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate: (data['end_date'] as Timestamp).toDate(),
      goalValue: data['goal_value'].toDouble(),
      goalUnit: data['goal_unit'],
      isActive: data['is_active'] == 1,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  // Método para crear un objeto Challenge vacío para inicialización
  static Challenge empty() => Challenge(
    id: 0,
    name: '',
    description: '',
    type: '',
    points: 0,
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 7)),
    goalValue: 0.0,
    goalUnit: 'km',
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
} 