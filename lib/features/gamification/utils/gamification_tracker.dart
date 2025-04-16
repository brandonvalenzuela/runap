import 'package:get/get.dart';
import 'package:runap/features/gamification/presentation/manager/gamification_view_model.dart';

/// Utilidad para realizar seguimiento de acciones que pueden desbloquear logros o sumar puntos.
class GamificationTracker {
  // Singleton pattern
  static final GamificationTracker _instance = GamificationTracker._internal();
  factory GamificationTracker() => _instance;
  GamificationTracker._internal();

  // Referencia al ViewModel
  late final GamificationViewModel _viewModel;

  // Inicializar el rastreador
  void initialize() {
    try {
      _viewModel = Get.find<GamificationViewModel>();
    } catch (e) {
      // Si no se ha inicializado el ViewModel, podríamos manejarlo de forma silenciosa
      print('GamificationViewModel aún no está disponible: $e');
    }
  }

  // Registrar una distancia recorrida
  void trackDistance(double distanceKm) {
    try {
      _updateChallengesForDistance(distanceKm);
      _addPointsForDistance(distanceKm);
    } catch (e) {
      print('Error al rastrear distancia: $e');
    }
  }

  // Registrar tiempo de actividad
  void trackActivityTime(int minutes) {
    try {
      _updateChallengesForTime(minutes);
      _addPointsForTime(minutes);
    } catch (e) {
      print('Error al rastrear tiempo de actividad: $e');
    }
  }

  // Registrar entrenamiento completado
  void trackWorkoutCompleted(String workoutType, {double? distance, int? minutes}) {
    try {
      // Sumar puntos por completar un entrenamiento
      _viewModel.addPoints(
        50, 
        'workout_completed',
        description: 'Entrenamiento $workoutType completado',
      );
      
      // Si se proporcionan valores adicionales, rastrearlos también
      if (distance != null) {
        trackDistance(distance);
      }
      
      if (minutes != null) {
        trackActivityTime(minutes);
      }
      
      // Recargar datos del usuario para reflejar cambios inmediatamente
      _viewModel.loadUserData();
    } catch (e) {
      print('Error al rastrear entrenamiento completado: $e');
    }
  }

  // Actualizar progreso en retos relacionados con distancia
  void _updateChallengesForDistance(double distanceKm) {
    if (!Get.isRegistered<GamificationViewModel>()) return;
    
    try {
      // Obtener los retos activos del usuario
      final distanceChallenges = _viewModel.userChallenges.where(
        (challenge) => challenge.challenge?.type == 'distance' && !challenge.completed
      ).toList();
      
      // Actualizar cada reto con la nueva distancia
      for (final challenge in distanceChallenges) {
        final newValue = challenge.currentValue + distanceKm;
        _viewModel.updateChallengeProgress(challenge, newValue);
      }
    } catch (e) {
      print('Error al actualizar retos por distancia: $e');
    }
  }

  // Actualizar progreso en retos relacionados con tiempo
  void _updateChallengesForTime(int minutes) {
    if (!Get.isRegistered<GamificationViewModel>()) return;
    
    try {
      // Obtener los retos activos del usuario
      final timeChallenges = _viewModel.userChallenges.where(
        (challenge) => challenge.challenge?.type == 'time' && !challenge.completed
      ).toList();
      
      // Actualizar cada reto con el nuevo tiempo
      for (final challenge in timeChallenges) {
        final newValue = challenge.currentValue + minutes;
        _viewModel.updateChallengeProgress(challenge, newValue);
      }
    } catch (e) {
      print('Error al actualizar retos por tiempo: $e');
    }
  }

  // Añadir puntos por distancia recorrida
  void _addPointsForDistance(double distanceKm) {
    if (!Get.isRegistered<GamificationViewModel>()) return;
    
    try {
      // Calcular puntos: 10 puntos por cada kilómetro
      final points = (distanceKm * 10).round();
      
      if (points > 0) {
        _viewModel.addPoints(
          points, 
          'distance',
          description: 'Distancia recorrida: ${distanceKm.toStringAsFixed(2)} km',
        );
      }
    } catch (e) {
      print('Error al añadir puntos por distancia: $e');
    }
  }

  // Añadir puntos por tiempo de actividad
  void _addPointsForTime(int minutes) {
    if (!Get.isRegistered<GamificationViewModel>()) return;
    
    try {
      // Calcular puntos: 5 puntos por cada 10 minutos
      final points = (minutes / 10 * 5).round();
      
      if (points > 0) {
        _viewModel.addPoints(
          points, 
          'activity_time',
          description: 'Tiempo de actividad: $minutes minutos',
        );
      }
    } catch (e) {
      print('Error al añadir puntos por tiempo: $e');
    }
  }
} 