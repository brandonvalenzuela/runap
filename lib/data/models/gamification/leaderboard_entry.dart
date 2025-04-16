import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final int id;
  final int leaderboardId;
  final int userId;
  final double score;
  final int rank;
  final DateTime lastUpdated;
  final String? userName; // Nombre del usuario (para mostrar en la tabla)
  final String? userPhotoUrl; // Foto de perfil (opcional)

  LeaderboardEntry({
    required this.id,
    required this.leaderboardId,
    required this.userId,
    required this.score,
    required this.rank,
    required this.lastUpdated,
    this.userName,
    this.userPhotoUrl,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'],
      leaderboardId: json['leaderboard_id'],
      userId: json['user_id'],
      score: json['score'].toDouble(),
      rank: json['rank'],
      lastUpdated: DateTime.parse(json['last_updated']),
      userName: json['user_name'],
      userPhotoUrl: json['user_photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leaderboard_id': leaderboardId,
      'user_id': userId,
      'score': score,
      'rank': rank,
      'last_updated': lastUpdated.toIso8601String(),
      'user_name': userName,
      'user_photo_url': userPhotoUrl,
    };
  }

  factory LeaderboardEntry.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return LeaderboardEntry(
      id: data['id'],
      leaderboardId: data['leaderboard_id'],
      userId: data['user_id'],
      score: data['score'].toDouble(),
      rank: data['rank'],
      lastUpdated: (data['last_updated'] as Timestamp).toDate(),
      userName: data['user_name'],
      userPhotoUrl: data['user_photo_url'],
    );
  }

  // Método para crear un objeto LeaderboardEntry vacío para inicialización
  static LeaderboardEntry empty() => LeaderboardEntry(
    id: 0,
    leaderboardId: 0,
    userId: 0,
    score: 0.0,
    rank: 0,
    lastUpdated: DateTime.now(),
  );
} 