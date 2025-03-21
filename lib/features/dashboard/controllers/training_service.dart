// training_service.dart
import 'dart:async';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:runap/utils/http/http_client.dart';

import '../models/training_data.dart';

class TrainingService {
  // Singleton pattern
  static final TrainingService _instance = TrainingService._internal();

  factory TrainingService() => _instance;

  TrainingService._internal();

  // Endpoint para obtener los datos del dashboard
  static const String _dashboardEndpoint = 'api/dashboard/obtener-plan';
  // Endpoint para actualizar una sesión
  static const String _sessionEndpoint = 'api/sessions';

  // Cache de los datos de entrenamiento
  TrainingData? _cachedTrainingData;
  // Tiempo en que se cachearon los datos
  DateTime? _lastFetchTime;

  // Stream controller para notificar cambios en los datos
  final _trainingDataController = StreamController<TrainingData>.broadcast();
  Stream<TrainingData> get trainingDataStream => _trainingDataController.stream;

  // Método para obtener los datos del dashboard
  Future<TrainingData> getDashboardData(
      {bool forceRefresh = false, int userId = 1}) async {
    // Si tenemos datos en caché y no se fuerza la actualización
    // y los datos tienen menos de 5 minutos, devolvemos el caché
    if (!forceRefresh &&
        _cachedTrainingData != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 5) {
      return _cachedTrainingData!;
    }

    try {
      // Construimos la URL con el parámetro userId
      final endpoint = '$_dashboardEndpoint?userId=$userId';

      // Obtenemos los datos frescos de la API
      final response = await THttpHelper.get(endpoint);
      final trainingData = TrainingData.fromJson(response);

      // Actualizamos el caché y el tiempo
      _cachedTrainingData = trainingData;
      _lastFetchTime = DateTime.now();

      // Notificamos a los listeners
      _trainingDataController.add(trainingData);

      return trainingData;
    } catch (e) {
      // Si hay error y tenemos datos en caché, los devolvemos
      if (_cachedTrainingData != null) {
        return _cachedTrainingData!;
      }
      // Si no hay caché, propagamos el error
      rethrow;
    }
  }

  // Método para marcar una sesión como completada o no completada
  Future<bool> markSessionAsCompleted(Session session, bool completed,
      {int userId = 1}) async {
    try {
      // Verificar si la sesión ya pasó y asegurarnos de que se marque como no completada
      final now = DateTime.now();
      if (session.sessionDate.isBefore(now) && completed) {
        // Si la sesión ya pasó y estamos intentando marcarla como completada,
        // verificamos si esto se está haciendo explícitamente (por el usuario)
        // o automáticamente (por la aplicación)
        final stackTrace = StackTrace.current.toString();
        if (stackTrace.contains('_markPastSessionsAsNotCompleted')) {
          // Es una actualización automática, permitimos que se marque como no completada
          completed = false;
        }
      }

      // Crear los datos a enviar
      final data = {
        'sessionId': session.sessionDate
            .toIso8601String(), // Suponiendo que usas la fecha como identificador
        'completed': completed,
        'userId': userId, // Incluimos el ID del usuario
        'isPastSession':
            session.sessionDate.isBefore(now) // Indicar si es una sesión pasada
      };

      // Enviar la actualización
      await THttpHelper.put(
          '$_sessionEndpoint/${session.sessionDate.toIso8601String()}', data);

      // Si tenemos datos en caché, actualizamos también el caché
      if (_cachedTrainingData != null) {
        final index = _cachedTrainingData!.dashboard.nextWeekSessions
            .indexWhere(
                (s) => s.sessionDate.isAtSameMomentAs(session.sessionDate));

        if (index != -1) {
          _cachedTrainingData!.dashboard.nextWeekSessions[index].completed =
              completed;

          // Actualizar estadísticas del dashboard
          int completedCount = _cachedTrainingData!.dashboard.nextWeekSessions
              .where((s) => s.completed)
              .length;

          // Notificar a los listeners
          _trainingDataController.add(_cachedTrainingData!);
        }
      }

      // Forzar una actualización completa de los datos
      getDashboardData(forceRefresh: true);

      return true;
    } catch (e) {
      print('Error al marcar la sesión como completada: $e');
      return false;
    }
  }

  // Método para limpiar recursos al cerrar la aplicación
  void dispose() {
    _trainingDataController.close();
  }
}
