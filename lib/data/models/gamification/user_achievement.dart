import 'package:cloud_firestore/cloud_firestore.dart';
import 'achievement.dart';

class UserAchievement {
  final int id;
  final int userId;
  final int achievementId;
  final Achievement? achievement; // Objeto completo del logro (opcional)
  final DateTime unlockedAt;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    this.achievement,
    required this.unlockedAt,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'],
      userId: json['user_id'],
      achievementId: json['achievement_id'],
      achievement: json['achievement'] != null 
          ? Achievement.fromJson(json['achievement']) 
          : null,
      unlockedAt: DateTime.parse(json['unlocked_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'achievement': achievement?.toJson(),
      'unlocked_at': unlockedAt.toIso8601String(),
    };
  }

  factory UserAchievement.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return UserAchievement(
      id: data['id'],
      userId: data['user_id'],
      achievementId: data['achievement_id'],
      achievement: data['achievement'] != null 
          ? Achievement.fromJson(data['achievement']) 
          : null,
      unlockedAt: (data['unlocked_at'] as Timestamp).toDate(),
    );
  }

  // Método para crear un objeto UserAchievement vacío para inicialización
  static UserAchievement empty() => UserAchievement(
    id: 0,
    userId: 0,
    achievementId: 0,
    unlockedAt: DateTime.now(),
  );
} 