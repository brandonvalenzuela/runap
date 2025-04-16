import 'package:get/get.dart';
import 'package:runap/data/models/gamification/achievement.dart';
import 'package:runap/data/models/gamification/challenge.dart';
import 'package:runap/data/models/gamification/level.dart';
import 'package:runap/data/models/gamification/leaderboard.dart';
import 'package:runap/data/models/gamification/leaderboard_entry.dart';
import 'package:runap/data/models/gamification/user_achievement.dart';
import 'package:runap/data/models/gamification/user_challenge.dart';
import 'package:runap/data/models/gamification/user_gamification_profile.dart';
import 'package:runap/data/models/gamification/user_points.dart';
import 'package:runap/data/services/gamification/gamification_service.dart';

/// Repositorio para operaciones relacionadas con la gamificación.
class GamificationRepository extends GetxController {
  static GamificationRepository get instance => Get.find();

  // Instancia del servicio de gamificación
  final GamificationService _service = GamificationService();

  // Obtener el perfil de gamificación del usuario
  Future<UserGamificationProfile> getUserGamificationProfile(int userId) async {
    try {
      final profile = await _service.getUserGamificationProfile(userId);
      return profile;
    } catch (e) {
      // Manejo de errores centralizado
      rethrow;
    }
  }

  // Obtener los logros disponibles
  Future<List<Achievement>> getAchievements() async {
    try {
      return await _service.getAchievements();
    } catch (e) {
      rethrow;
    }
  }

  // Obtener los logros de un usuario
  Future<List<UserAchievement>> getUserAchievements(int userId) async {
    try {
      return await _service.getUserAchievements(userId);
    } catch (e) {
      rethrow;
    }
  }

  // Obtener los retos disponibles
  Future<List<Challenge>> getChallenges() async {
    try {
      return await _service.getChallenges();
    } catch (e) {
      rethrow;
    }
  }

  // Obtener los retos de un usuario
  Future<List<UserChallenge>> getUserChallenges(int userId) async {
    try {
      return await _service.getUserChallenges(userId);
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar el progreso de un reto
  Future<void> updateChallengeProgress(UserChallenge challenge) async {
    try {
      await _service.updateChallengeProgress(challenge);
    } catch (e) {
      rethrow;
    }
  }

  // Obtener los niveles disponibles
  Future<List<Level>> getLevels() async {
    try {
      return await _service.getLevels();
    } catch (e) {
      rethrow;
    }
  }

  // Añadir puntos a un usuario
  Future<void> addUserPoints(UserPoints points) async {
    try {
      await _service.addUserPoints(points);
    } catch (e) {
      rethrow;
    }
  }

  // Obtener el historial de puntos de un usuario
  Future<List<UserPoints>> getUserPointsHistory(int userId) async {
    try {
      return await _service.getUserPointsHistory(userId);
    } catch (e) {
      rethrow;
    }
  }

  // Obtener las tablas de clasificación disponibles
  Future<List<Leaderboard>> getLeaderboards() async {
    try {
      return await _service.getLeaderboards();
    } catch (e) {
      rethrow;
    }
  }

  // Obtener las entradas de una tabla de clasificación
  Future<List<LeaderboardEntry>> getLeaderboardEntries(int leaderboardId) async {
    try {
      return await _service.getLeaderboardEntries(leaderboardId);
    } catch (e) {
      rethrow;
    }
  }
} 