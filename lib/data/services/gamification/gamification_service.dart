import 'package:runap/data/models/gamification/achievement.dart';
import 'package:runap/data/models/gamification/challenge.dart';
import 'package:runap/data/models/gamification/level.dart';
import 'package:runap/data/models/gamification/leaderboard.dart';
import 'package:runap/data/models/gamification/leaderboard_entry.dart';
import 'package:runap/data/models/gamification/user_achievement.dart';
import 'package:runap/data/models/gamification/user_challenge.dart';
import 'package:runap/data/models/gamification/user_gamification_profile.dart';
import 'package:runap/data/models/gamification/user_points.dart';
import 'package:runap/utils/http/http_client.dart';
import 'package:get_storage/get_storage.dart';

/// Servicio para manejar las operaciones de gamificación con la API.
class GamificationService {
  // Singleton pattern
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  // Almacenamiento local
  final GetStorage _storage = GetStorage();

  // Endpoints para las peticiones
  static const String _baseEndpoint = 'api/gamification';
  static const String _profileEndpoint = '$_baseEndpoint/profile';
  static const String _achievementsEndpoint = '$_baseEndpoint/achievements';
  static const String _userAchievementsEndpoint = '$_baseEndpoint/user-achievements';
  static const String _challengesEndpoint = '$_baseEndpoint/challenges';
  static const String _userChallengesEndpoint = '$_baseEndpoint/user-challenges';
  static const String _levelsEndpoint = '$_baseEndpoint/levels';
  static const String _pointsEndpoint = '$_baseEndpoint/points';
  static const String _leaderboardsEndpoint = '$_baseEndpoint/leaderboards';
  
  // Tiempo de caché en minutos
  static const int _cacheValidityMinutes = 30;

  // Obtener el perfil de gamificación del usuario
  Future<UserGamificationProfile> getUserGamificationProfile(int userId) async {
    try {
      // Verificar si hay datos en caché
      final key = 'gamification_profile_$userId';
      final cachedData = _storage.read<Map<String, dynamic>>(key);
      final timestamp = _storage.read<int>('${key}_timestamp');
      
      if (cachedData != null && timestamp != null) {
        final minutesSinceLastFetch = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(timestamp)
        ).inMinutes;
        
        if (minutesSinceLastFetch < _cacheValidityMinutes) {
          return UserGamificationProfile.fromJson(cachedData);
        }
      }
      
      // Obtener datos frescos de la API
      final response = await THttpHelper.get('$_profileEndpoint/$userId');
      
      // Guardar en caché
      await _storage.write(key, response);
      await _storage.write('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      return UserGamificationProfile.fromJson(response);
    } catch (e) {
      // Si hay un error, intentar usar la caché sin importar su antigüedad
      final key = 'gamification_profile_$userId';
      final cachedData = _storage.read<Map<String, dynamic>>(key);
      
      if (cachedData != null) {
        return UserGamificationProfile.fromJson(cachedData);
      }
      
      rethrow;
    }
  }

  // Obtener los logros disponibles
  Future<List<Achievement>> getAchievements() async {
    try {
      // Verificar caché para logros
      const key = 'achievements_list';
      final cachedData = _storage.read<List<dynamic>>(key);
      final timestamp = _storage.read<int>('${key}_timestamp');
      
      if (cachedData != null && timestamp != null) {
        final minutesSinceLastFetch = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(timestamp)
        ).inMinutes;
        
        if (minutesSinceLastFetch < _cacheValidityMinutes) {
          return cachedData.map((item) => Achievement.fromJson(item)).toList();
        }
      }
      
      // Obtener datos frescos
      final response = await THttpHelper.get(_achievementsEndpoint);
      
      // Guardar en caché
      await _storage.write(key, response);
      await _storage.write('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      return (response as List).map((item) => Achievement.fromJson(item)).toList();
    } catch (e) {
      // Si hay error, intentar usar caché
      const key = 'achievements_list';
      final cachedData = _storage.read<List<dynamic>>(key);
      
      if (cachedData != null) {
        return cachedData.map((item) => Achievement.fromJson(item)).toList();
      }
      
      rethrow;
    }
  }

  // Obtener los logros de un usuario
  Future<List<UserAchievement>> getUserAchievements(int userId) async {
    try {
      final response = await THttpHelper.get('$_userAchievementsEndpoint/$userId');
      return (response as List).map((item) => UserAchievement.fromJson(item)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Obtener los retos disponibles
  Future<List<Challenge>> getChallenges() async {
    try {
      final response = await THttpHelper.get(_challengesEndpoint);
      return (response as List).map((item) => Challenge.fromJson(item)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Obtener los retos de un usuario
  Future<List<UserChallenge>> getUserChallenges(int userId) async {
    try {
      final response = await THttpHelper.get('$_userChallengesEndpoint/$userId');
      return (response as List).map((item) => UserChallenge.fromJson(item)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar el progreso de un reto
  Future<void> updateChallengeProgress(UserChallenge challenge) async {
    try {
      await THttpHelper.put(
        '$_userChallengesEndpoint/${challenge.id}',
        challenge.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Obtener los niveles disponibles
  Future<List<Level>> getLevels() async {
    try {
      // Verificar caché para niveles
      const key = 'levels_list';
      final cachedData = _storage.read<List<dynamic>>(key);
      final timestamp = _storage.read<int>('${key}_timestamp');
      
      if (cachedData != null && timestamp != null) {
        final minutesSinceLastFetch = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(timestamp)
        ).inMinutes;
        
        if (minutesSinceLastFetch < _cacheValidityMinutes) {
          return cachedData.map((item) => Level.fromJson(item)).toList();
        }
      }
      
      // Obtener datos frescos
      final response = await THttpHelper.get(_levelsEndpoint);
      
      // Guardar en caché
      await _storage.write(key, response);
      await _storage.write('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      return (response as List).map((item) => Level.fromJson(item)).toList();
    } catch (e) {
      // Si hay error, intentar usar caché
      const key = 'levels_list';
      final cachedData = _storage.read<List<dynamic>>(key);
      
      if (cachedData != null) {
        return cachedData.map((item) => Level.fromJson(item)).toList();
      }
      
      rethrow;
    }
  }

  // Añadir puntos a un usuario
  Future<void> addUserPoints(UserPoints points) async {
    try {
      await THttpHelper.post(
        _pointsEndpoint,
        points.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Obtener el historial de puntos de un usuario
  Future<List<UserPoints>> getUserPointsHistory(int userId) async {
    try {
      final response = await THttpHelper.get('$_pointsEndpoint/$userId');
      return (response as List).map((item) => UserPoints.fromJson(item)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Obtener las tablas de clasificación disponibles
  Future<List<Leaderboard>> getLeaderboards() async {
    try {
      final response = await THttpHelper.get(_leaderboardsEndpoint);
      return (response as List).map((item) => Leaderboard.fromJson(item)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Obtener las entradas de una tabla de clasificación
  Future<List<LeaderboardEntry>> getLeaderboardEntries(int leaderboardId) async {
    try {
      final response = await THttpHelper.get('$_leaderboardsEndpoint/$leaderboardId/entries');
      return (response as List).map((item) => LeaderboardEntry.fromJson(item)).toList();
    } catch (e) {
      rethrow;
    }
  }
} 