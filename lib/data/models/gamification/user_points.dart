import 'package:cloud_firestore/cloud_firestore.dart';

class UserPoints {
  final int id;
  final int userId;
  final int points;
  final String source;
  final int? sourceId;
  final String? description;
  final DateTime earnedAt;

  UserPoints({
    required this.id,
    required this.userId,
    required this.points,
    required this.source,
    this.sourceId,
    this.description,
    required this.earnedAt,
  });

  factory UserPoints.fromJson(Map<String, dynamic> json) {
    return UserPoints(
      id: json['id'],
      userId: json['user_id'],
      points: json['points'],
      source: json['source'],
      sourceId: json['source_id'],
      description: json['description'],
      earnedAt: DateTime.parse(json['earned_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'points': points,
      'source': source,
      'source_id': sourceId,
      'description': description,
      'earned_at': earnedAt.toIso8601String(),
    };
  }

  factory UserPoints.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return UserPoints(
      id: data['id'],
      userId: data['user_id'],
      points: data['points'],
      source: data['source'],
      sourceId: data['source_id'],
      description: data['description'],
      earnedAt: (data['earned_at'] as Timestamp).toDate(),
    );
  }

  // Método para crear un objeto UserPoints vacío para inicialización
  static UserPoints empty() => UserPoints(
    id: 0,
    userId: 0,
    points: 0,
    source: '',
    earnedAt: DateTime.now(),
  );
} 