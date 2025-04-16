import 'package:cloud_firestore/cloud_firestore.dart';

class Leaderboard {
  final int id;
  final String name;
  final String? description;
  final String type;
  final String period;
  final bool isActive;
  final DateTime createdAt;

  Leaderboard({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.period,
    required this.isActive,
    required this.createdAt,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      period: json['period'],
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'period': period,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Leaderboard.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return Leaderboard(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      type: data['type'],
      period: data['period'],
      isActive: data['is_active'] == 1,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  // Método para crear un objeto Leaderboard vacío para inicialización
  static Leaderboard empty() => Leaderboard(
    id: 0,
    name: '',
    type: 'distance',
    period: 'weekly',
    isActive: true,
    createdAt: DateTime.now(),
  );
} 