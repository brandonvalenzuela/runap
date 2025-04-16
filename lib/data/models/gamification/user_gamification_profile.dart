import 'package:cloud_firestore/cloud_firestore.dart';
import 'level.dart';
import 'user_achievement.dart';
import 'user_challenge.dart';

class UserGamificationProfile {
  final int userId;
  final int totalPoints;
  final int currentLevel;
  final Level? level;
  final int achievementsCount;
  final int challengesCompletedCount;
  final List<UserAchievement>? recentAchievements;
  final List<UserChallenge>? activeChallenges;
  
  UserGamificationProfile({
    required this.userId,
    required this.totalPoints,
    required this.currentLevel,
    this.level,
    required this.achievementsCount,
    required this.challengesCompletedCount,
    this.recentAchievements,
    this.activeChallenges,
  });

  factory UserGamificationProfile.fromJson(Map<String, dynamic> json) {
    List<UserAchievement>? achievements;
    if (json['recent_achievements'] != null) {
      achievements = (json['recent_achievements'] as List)
          .map((item) => UserAchievement.fromJson(item))
          .toList();
    }

    List<UserChallenge>? challenges;
    if (json['active_challenges'] != null) {
      challenges = (json['active_challenges'] as List)
          .map((item) => UserChallenge.fromJson(item))
          .toList();
    }

    return UserGamificationProfile(
      userId: json['user_id'],
      totalPoints: json['total_points'],
      currentLevel: json['current_level'],
      level: json['level'] != null ? Level.fromJson(json['level']) : null,
      achievementsCount: json['achievements_count'],
      challengesCompletedCount: json['challenges_completed_count'],
      recentAchievements: achievements,
      activeChallenges: challenges,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_points': totalPoints,
      'current_level': currentLevel,
      'level': level?.toJson(),
      'achievements_count': achievementsCount,
      'challenges_completed_count': challengesCompletedCount,
      'recent_achievements': recentAchievements?.map((a) => a.toJson()).toList(),
      'active_challenges': activeChallenges?.map((c) => c.toJson()).toList(),
    };
  }

  factory UserGamificationProfile.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    
    List<UserAchievement>? achievements;
    if (data['recent_achievements'] != null) {
      achievements = (data['recent_achievements'] as List)
          .map((item) => UserAchievement.fromJson(item))
          .toList();
    }

    List<UserChallenge>? challenges;
    if (data['active_challenges'] != null) {
      challenges = (data['active_challenges'] as List)
          .map((item) => UserChallenge.fromJson(item))
          .toList();
    }

    return UserGamificationProfile(
      userId: data['user_id'],
      totalPoints: data['total_points'],
      currentLevel: data['current_level'],
      level: data['level'] != null ? Level.fromJson(data['level']) : null,
      achievementsCount: data['achievements_count'],
      challengesCompletedCount: data['challenges_completed_count'],
      recentAchievements: achievements,
      activeChallenges: challenges,
    );
  }

  // Método para crear un objeto UserGamificationProfile vacío para inicialización
  static UserGamificationProfile empty() => UserGamificationProfile(
    userId: 0,
    totalPoints: 0,
    currentLevel: 1,
    achievementsCount: 0,
    challengesCompletedCount: 0,
  );
} 