import 'package:cloud_firestore/cloud_firestore.dart';

class Achievement {
  final int id;
  final String name;
  final String description;
  final String category;
  final String? iconUrl;
  final int points;
  final String difficulty;
  final DateTime createdAt;
  final DateTime updatedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.iconUrl,
    required this.points,
    required this.difficulty,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      iconUrl: json['icon_url'],
      points: json['points'],
      difficulty: json['difficulty'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'icon_url': iconUrl,
      'points': points,
      'difficulty': difficulty,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Achievement.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return Achievement(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      category: data['category'],
      iconUrl: data['icon_url'],
      points: data['points'],
      difficulty: data['difficulty'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  // Método para crear un objeto Achievement vacío para inicialización
  static Achievement empty() => Achievement(
    id: 0,
    name: '',
    description: '',
    category: '',
    points: 0,
    difficulty: 'easy',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
} 