import 'package:flutter/foundation.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import '../models/training_data.dart';
import '../controllers/training_service.dart';

enum LoadingStatus { initial, loading, loaded, error }

class TrainingViewModel extends ChangeNotifier {
  final TrainingService _trainingService = TrainingService();

  TrainingData? _trainingData;
  LoadingStatus _status = LoadingStatus.initial;
  String _errorMessage = '';

  // ID del usuario actual (podría venir de un servicio de autenticación)
  final int _userId = 1; // Por defecto usamos el usuario 1

  // Getters
  TrainingData? get trainingData => _trainingData;
  LoadingStatus get status => _status;
  String get errorMessage => _errorMessage;

  // Constructor
  TrainingViewModel() {
    // Suscribirnos al stream de datos de entrenamiento
    _trainingService.trainingDataStream.listen((data) {
      _trainingData = data;
      _status = LoadingStatus.loaded;

      // Verificar sesiones pasadas
      _updatePastSessions();

      notifyListeners();
    });

    // Cargar datos iniciales
    loadDashboardData();
  }

  // Método para cargar los datos del dashboard
  Future<void> loadDashboardData(
      {bool forceRefresh = false, int? userId}) async {
    try {
      _status = LoadingStatus.loading;
      notifyListeners();

      // Usamos el userId proporcionado o el valor por defecto
      final userIdToUse = userId ?? _userId;

      _trainingData = await _trainingService.getDashboardData(
          forceRefresh: forceRefresh, userId: userIdToUse);

      _status = LoadingStatus.loaded;

      // Verificar sesiones pasadas
      _updatePastSessions();
    } catch (e) {
      _status = LoadingStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // Método para marcar una sesión como completada o no
  Future<bool> toggleSessionCompletion(Session session) async {
    final newStatus = !session.completed;

    // Si la sesión es de hoy o futura, permitimos cambiar su estado
    final now = DateTime.now();
    final isSessionInFuture = session.sessionDate.isAfter(now) ||
        (session.sessionDate.year == now.year &&
            session.sessionDate.month == now.month &&
            session.sessionDate.day == now.day);

    // Solo permitimos marcar como completadas sesiones presentes o futuras
    if (!isSessionInFuture && newStatus) {
      return false;
    }

    final success = await _trainingService
        .markSessionAsCompleted(session, newStatus, userId: _userId);

    if (success) {
      // También actualizamos localmente mientras esperamos la actualización del servicio
      session.completed = newStatus;
      notifyListeners();
      return true;
    }

    return false;
  }

  // Método para actualizar el estado de sesiones pasadas
  void _updatePastSessions() {
    if (_trainingData == null) return;

    final now = DateTime.now();
    bool anyUpdated = false;
    List<Session> sessionsToUpdate = [];

    for (var session in _trainingData!.dashboard.nextWeekSessions) {
      // Verificar si la sesión ya pasó y no está completada
      if (session.sessionDate.isBefore(now) && !session.completed) {
        // Agregar a la lista de sesiones a actualizar en el backend
        sessionsToUpdate.add(session);
        anyUpdated = true;
      }
    }

    // Actualizar en el backend las sesiones pasadas no completadas
    if (sessionsToUpdate.isNotEmpty) {
      // Actualizamos cada sesión pasada para marcarla explícitamente como no completada
      _markPastSessionsAsNotCompleted(sessionsToUpdate);
    }

    if (anyUpdated) {
      notifyListeners();
    }
  }

  // Método para marcar sesiones pasadas como no completadas en el backend
  Future<void> _markPastSessionsAsNotCompleted(List<Session> sessions) async {
    for (var session in sessions) {
      // Marca como no completada en el backend si ya pasó la fecha
      // Solo si ya no estaba marcada como completada
      if (!session.completed) {
        await _trainingService.markSessionAsCompleted(
            session, false, // Explícitamente marcamos como no completada
            userId: _userId);

        // Para evitar múltiples actualizaciones, marcamos localmente
        session.completed = false;
      }
    }
  }

  // Método para sincronizar cambios pendientes con el servidor
  Future<void> syncPendingChanges() async {
    await _trainingService.syncPendingChanges(_userId);
  }

  @override
  void dispose() {
    _trainingService.dispose();
    super.dispose();
  }
}
