import 'package:get/get.dart';
import 'package:runap/data/models/gamification/achievement.dart';
import 'package:runap/data/models/gamification/challenge.dart';
import 'package:runap/data/models/gamification/leaderboard.dart';
import 'package:runap/data/models/gamification/leaderboard_entry.dart';
import 'package:runap/data/models/gamification/level.dart';
import 'package:runap/data/models/gamification/user_achievement.dart';
import 'package:runap/data/models/gamification/user_challenge.dart';
import 'package:runap/data/models/gamification/user_gamification_profile.dart';
import 'package:runap/data/models/gamification/user_points.dart';
import 'package:runap/data/repositories/gamification/gamification_repository.dart';

enum LoadingStatus { initial, loading, loaded, error }

class GamificationViewModel extends GetxController {
  // Repositorio para acceder a los datos
  final GamificationRepository _repository = GamificationRepository.instance;

  // Variables observables
  final Rx<UserGamificationProfile?> _profile = Rx<UserGamificationProfile?>(null);
  final Rx<LoadingStatus> _profileStatus = LoadingStatus.initial.obs;
  
  final RxList<Achievement> _achievements = <Achievement>[].obs;
  final Rx<LoadingStatus> _achievementsStatus = LoadingStatus.initial.obs;
  
  final RxList<UserAchievement> _userAchievements = <UserAchievement>[].obs;
  final Rx<LoadingStatus> _userAchievementsStatus = LoadingStatus.initial.obs;
  
  final RxList<Challenge> _challenges = <Challenge>[].obs;
  final Rx<LoadingStatus> _challengesStatus = LoadingStatus.initial.obs;
  
  final RxList<UserChallenge> _userChallenges = <UserChallenge>[].obs;
  final Rx<LoadingStatus> _userChallengesStatus = LoadingStatus.initial.obs;
  
  final RxList<Level> _levels = <Level>[].obs;
  final Rx<LoadingStatus> _levelsStatus = LoadingStatus.initial.obs;
  
  final RxList<UserPoints> _pointsHistory = <UserPoints>[].obs;
  final Rx<LoadingStatus> _pointsHistoryStatus = LoadingStatus.initial.obs;
  
  final RxList<Leaderboard> _leaderboards = <Leaderboard>[].obs;
  final Rx<LoadingStatus> _leaderboardsStatus = LoadingStatus.initial.obs;
  
  final RxList<LeaderboardEntry> _leaderboardEntries = <LeaderboardEntry>[].obs;
  final Rx<LoadingStatus> _leaderboardEntriesStatus = LoadingStatus.initial.obs;
  
  final RxString _errorMessage = ''.obs;
  
  // ID del usuario actual - Esto debe venir del sistema de autenticación
  int _userId = 1; // Valor por defecto para desarrollo
  
  // Getters
  UserGamificationProfile? get profile => _profile.value;
  LoadingStatus get profileStatus => _profileStatus.value;
  
  List<Achievement> get achievements => _achievements;
  LoadingStatus get achievementsStatus => _achievementsStatus.value;
  
  List<UserAchievement> get userAchievements => _userAchievements;
  LoadingStatus get userAchievementsStatus => _userAchievementsStatus.value;
  
  List<Challenge> get challenges => _challenges;
  LoadingStatus get challengesStatus => _challengesStatus.value;
  
  List<UserChallenge> get userChallenges => _userChallenges;
  LoadingStatus get userChallengesStatus => _userChallengesStatus.value;
  
  List<Level> get levels => _levels;
  LoadingStatus get levelsStatus => _levelsStatus.value;
  
  List<UserPoints> get pointsHistory => _pointsHistory;
  LoadingStatus get pointsHistoryStatus => _pointsHistoryStatus.value;
  
  List<Leaderboard> get leaderboards => _leaderboards;
  LoadingStatus get leaderboardsStatus => _leaderboardsStatus.value;
  
  List<LeaderboardEntry> get leaderboardEntries => _leaderboardEntries;
  LoadingStatus get leaderboardEntriesStatus => _leaderboardEntriesStatus.value;
  
  String get errorMessage => _errorMessage.value;
  
  // Setter para el ID del usuario (útil para cambiar de usuario)
  set userId(int id) {
    _userId = id;
    // Recargar datos para el nuevo usuario
    loadUserData();
  }
  
  @override
  void onInit() {
    super.onInit();
    // Cargar datos iniciales al inicializar el controlador
    loadUserData();
  }
  
  // Método principal para cargar todos los datos del usuario
  Future<void> loadUserData() async {
    loadUserProfile();
    loadAchievements();
    loadUserAchievements();
    loadChallenges();
    loadUserChallenges();
    loadLevels();
    loadPointsHistory();
    loadLeaderboards();
  }
  
  // Cargar el perfil de gamificación del usuario
  Future<void> loadUserProfile() async {
    try {
      _profileStatus.value = LoadingStatus.loading;
      
      // --- INICIO: Datos de ejemplo ---
      await Future.delayed(const Duration(milliseconds: 500)); // Simular carga
      
      // Crear un Nivel de ejemplo
      final exampleLevel = Level(
        id: 2,
        name: 'Corredor Intermedio',
        minPoints: 1000,
        maxPoints: 5000,
        iconUrl: null, // Puedes poner una URL si tienes una
        benefits: 'Desbloquea nuevos avatares y planes de entrenamiento.',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      
      // Crear Logros Recientes de ejemplo
      final exampleRecentAchievements = [
        UserAchievement(
          id: 101,
          userId: _userId,
          achievementId: 5,
          achievement: Achievement(
            id: 5,
            name: '¡Primeros 5K!',
            description: 'Completaste tu primera carrera de 5 kilómetros.',
            category: 'Distancia',
            iconUrl: null,
            points: 100,
            difficulty: 'Media',
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
            updatedAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
          unlockedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        UserAchievement(
          id: 102,
          userId: _userId,
          achievementId: 8,
          achievement: Achievement(
            id: 8,
            name: 'Madrugador',
            description: 'Completaste 3 entrenamientos antes de las 7 AM.',
            category: 'Consistencia',
            iconUrl: null,
            points: 50,
            difficulty: 'Fácil',
            createdAt: DateTime.now().subtract(const Duration(days: 20)),
            updatedAt: DateTime.now().subtract(const Duration(days: 20)),
          ),
          unlockedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];
      
      // Crear Retos Activos de ejemplo
      final exampleActiveChallenges = [
        UserChallenge(
          id: 201,
          userId: _userId,
          challengeId: 15,
          challenge: Challenge(
            id: 15,
            name: 'Reto Semanal: 20K',
            description: 'Acumula 20 kilómetros corriendo esta semana.',
            type: 'distance',
            points: 150,
            startDate: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)), // Inicio de semana
            endDate: DateTime.now().add(Duration(days: 7 - DateTime.now().weekday)), // Fin de semana
            goalValue: 20.0,
            goalUnit: 'km',
            isActive: true,
            createdAt: DateTime.now().subtract(const Duration(days: 15)),
            updatedAt: DateTime.now().subtract(const Duration(days: 15)),
          ),
          currentValue: 12.5,
          completed: false,
          completedAt: null,
        ),
      ];
      
      // Crear el perfil de ejemplo
      _profile.value = UserGamificationProfile(
        userId: _userId,
        totalPoints: 1850,
        currentLevel: exampleLevel.id,
        level: exampleLevel,
        achievementsCount: 15, // Número total de logros
        challengesCompletedCount: 8, // Número total de retos completados
        recentAchievements: exampleRecentAchievements,
        activeChallenges: exampleActiveChallenges,
      );
      // --- FIN: Datos de ejemplo ---
      
      // Comentamos la llamada real al repositorio
      // _profile.value = await _repository.getUserGamificationProfile(_userId);
      
      _profileStatus.value = LoadingStatus.loaded;
    } catch (e) {
      _profileStatus.value = LoadingStatus.error;
      _errorMessage.value = "Error cargando perfil (ejemplo): ${e.toString()}";
    }
  }
  
  // Cargar todos los logros disponibles
  Future<void> loadAchievements() async {
    try {
      _achievementsStatus.value = LoadingStatus.loading;
      _achievements.value = await _repository.getAchievements();
      _achievementsStatus.value = LoadingStatus.loaded;
    } catch (e) {
      _achievementsStatus.value = LoadingStatus.error;
      _errorMessage.value = e.toString();
    }
  }
  
  // Cargar los logros del usuario
  Future<void> loadUserAchievements() async {
    try {
      _userAchievementsStatus.value = LoadingStatus.loading;
      _userAchievements.value = await _repository.getUserAchievements(_userId);
      _userAchievementsStatus.value = LoadingStatus.loaded;
    } catch (e) {
      _userAchievementsStatus.value = LoadingStatus.error;
      _errorMessage.value = e.toString();
    }
  }
  
  // Cargar todos los retos disponibles
  Future<void> loadChallenges() async {
    try {
      _challengesStatus.value = LoadingStatus.loading;
      _challenges.value = await _repository.getChallenges();
      _challengesStatus.value = LoadingStatus.loaded;
    } catch (e) {
      _challengesStatus.value = LoadingStatus.error;
      _errorMessage.value = e.toString();
    }
  }
  
  // Cargar los retos del usuario
  Future<void> loadUserChallenges() async {
    try {
      _userChallengesStatus.value = LoadingStatus.loading;
      _userChallenges.value = await _repository.getUserChallenges(_userId);
      _userChallengesStatus.value = LoadingStatus.loaded;
    } catch (e) {
      _userChallengesStatus.value = LoadingStatus.error;
      _errorMessage.value = e.toString();
    }
  }
  
  // Actualizar el progreso de un reto
  Future<void> updateChallengeProgress(UserChallenge challenge, double newValue) async {
    try {
      // Crear una copia del reto con el nuevo valor
      final updatedChallenge = UserChallenge(
        id: challenge.id,
        userId: challenge.userId,
        challengeId: challenge.challengeId,
        challenge: challenge.challenge,
        currentValue: newValue,
        completed: newValue >= (challenge.challenge?.goalValue ?? 0),
        completedAt: newValue >= (challenge.challenge?.goalValue ?? 0) ? DateTime.now() : null,
      );
      
      await _repository.updateChallengeProgress(updatedChallenge);
      
      // Actualizar la lista local para reflejar el cambio inmediatamente
      final index = _userChallenges.indexWhere((c) => c.id == updatedChallenge.id);
      if (index >= 0) {
        _userChallenges[index] = updatedChallenge;
      }
      
      // Recargar el perfil del usuario para reflejar posibles cambios de puntos
      loadUserProfile();
      
    } catch (e) {
      _errorMessage.value = e.toString();
    }
  }
  
  // Cargar todos los niveles disponibles
  Future<void> loadLevels() async {
    try {
      _levelsStatus.value = LoadingStatus.loading;
      _levels.value = await _repository.getLevels();
      _levelsStatus.value = LoadingStatus.loaded;
    } catch (e) {
      _levelsStatus.value = LoadingStatus.error;
      _errorMessage.value = e.toString();
    }
  }
  
  // Cargar el historial de puntos del usuario
  Future<void> loadPointsHistory() async {
    try {
      _pointsHistoryStatus.value = LoadingStatus.loading;
      _pointsHistory.value = await _repository.getUserPointsHistory(_userId);
      _pointsHistoryStatus.value = LoadingStatus.loaded;
    } catch (e) {
      _pointsHistoryStatus.value = LoadingStatus.error;
      _errorMessage.value = e.toString();
    }
  }
  
  // Cargar todas las tablas de clasificación disponibles
  Future<void> loadLeaderboards() async {
    try {
      _leaderboardsStatus.value = LoadingStatus.loading;
      _leaderboards.value = await _repository.getLeaderboards();
      _leaderboardsStatus.value = LoadingStatus.loaded;
      
      // Si hay tablas de clasificación, cargar la primera por defecto
      if (_leaderboards.isNotEmpty) {
        loadLeaderboardEntries(_leaderboards.first.id);
      }
    } catch (e) {
      _leaderboardsStatus.value = LoadingStatus.error;
      _errorMessage.value = e.toString();
    }
  }
  
  // Cargar las entradas de una tabla de clasificación específica
  Future<void> loadLeaderboardEntries(int leaderboardId) async {
    try {
      _leaderboardEntriesStatus.value = LoadingStatus.loading;
      _leaderboardEntries.value = await _repository.getLeaderboardEntries(leaderboardId);
      _leaderboardEntriesStatus.value = LoadingStatus.loaded;
    } catch (e) {
      _leaderboardEntriesStatus.value = LoadingStatus.error;
      _errorMessage.value = e.toString();
    }
  }
  
  // Añadir puntos a un usuario (por ejemplo, después de completar una actividad)
  Future<void> addPoints(int points, String source, {int? sourceId, String? description}) async {
    try {
      final userPoints = UserPoints(
        id: 0, // El backend asignará un ID
        userId: _userId,
        points: points,
        source: source,
        sourceId: sourceId,
        description: description,
        earnedAt: DateTime.now(),
      );
      
      await _repository.addUserPoints(userPoints);
      
      // Recargar datos relevantes
      loadUserProfile();
      loadPointsHistory();
      
      // Si fuera necesario, recargar tablas de clasificación
      if (_leaderboards.isNotEmpty) {
        final currentLeaderboardId = _leaderboards.first.id;
        loadLeaderboardEntries(currentLeaderboardId);
      }
    } catch (e) {
      _errorMessage.value = e.toString();
    }
  }
  
  @override
  void onClose() {
    // Limpieza si es necesario
    super.onClose();
  }
} 