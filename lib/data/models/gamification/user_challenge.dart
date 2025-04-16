import 'package:cloud_firestore/cloud_firestore.dart';
import 'challenge.dart';

class UserChallenge {
  final int id;
  final int userId;
  final int challengeId;
  final Challenge? challenge; // Objeto completo del reto (opcional)
  final double currentValue;
  final bool completed;
  final DateTime? completedAt;

  UserChallenge({
    required this.id,
    required this.userId,
    required this.challengeId,
    this.challenge,
    required this.currentValue,
    required this.completed,
    this.completedAt,
  });

  factory UserChallenge.fromJson(Map<String, dynamic> json) {
    return UserChallenge(
      id: json['id'],
      userId: json['user_id'],
      challengeId: json['challenge_id'],
      challenge: json['challenge'] != null 
          ? Challenge.fromJson(json['challenge']) 
          : null,
      currentValue: json['current_value'].toDouble(),
      completed: json['completed'] == 1,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'challenge_id': challengeId,
      'challenge': challenge?.toJson(),
      'current_value': currentValue,
      'completed': completed ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory UserChallenge.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return UserChallenge(
      id: data['id'],
      userId: data['user_id'],
      challengeId: data['challenge_id'],
      challenge: data['challenge'] != null 
          ? Challenge.fromJson(data['challenge']) 
          : null,
      currentValue: data['current_value'].toDouble(),
      completed: data['completed'] == 1,
      completedAt: data['completed_at'] != null 
          ? (data['completed_at'] as Timestamp).toDate() 
          : null,
    );
  }

  // Método para crear un objeto UserChallenge vacío para inicialización
  static UserChallenge empty() => UserChallenge(
    id: 0,
    userId: 0,
    challengeId: 0,
    currentValue: 0.0,
    completed: false,
  );
} 