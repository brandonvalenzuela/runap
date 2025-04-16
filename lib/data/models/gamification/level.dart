import 'package:cloud_firestore/cloud_firestore.dart';

class Level {
  final int id;
  final String name;
  final int minPoints;
  final int maxPoints;
  final String? iconUrl;
  final String? benefits;
  final DateTime createdAt;

  Level({
    required this.id,
    required this.name,
    required this.minPoints,
    required this.maxPoints,
    this.iconUrl,
    this.benefits,
    required this.createdAt,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'],
      name: json['name'],
      minPoints: json['min_points'],
      maxPoints: json['max_points'],
      iconUrl: json['icon_url'],
      benefits: json['benefits'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'min_points': minPoints,
      'max_points': maxPoints,
      'icon_url': iconUrl,
      'benefits': benefits,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Level.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return Level(
      id: data['id'],
      name: data['name'],
      minPoints: data['min_points'],
      maxPoints: data['max_points'],
      iconUrl: data['icon_url'],
      benefits: data['benefits'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  // Método para crear un objeto Level vacío para inicialización
  static Level empty() => Level(
    id: 0,
    name: 'Principiante',
    minPoints: 0,
    maxPoints: 100,
    createdAt: DateTime.now(),
  );
} 