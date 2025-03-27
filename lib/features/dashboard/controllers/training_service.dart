import 'dart:async';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:runap/features/map/utils/training_local_storage.dart';
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
    // Verificar si es necesario actualizar desde el servidor
    bool shouldFetchFromServer = forceRefresh;

    print("💡 getDashboardData - ForceRefresh: $forceRefresh");

    // Si no es forzado, comprobar si hay caché en memoria
    if (!shouldFetchFromServer &&
        _cachedTrainingData != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 5) {
      print("💡 getDashboardData - Usando caché en memoria");
      return _cachedTrainingData!;
    }

    // Si no hay caché en memoria, verificar el almacenamiento local
    if (!shouldFetchFromServer) {
      bool isCacheValid = await TrainingLocalStorage.isCacheValid();
      print("💡 getDashboardData - Cache local válido: $isCacheValid");

      if (isCacheValid) {
        final localData = await TrainingLocalStorage.getTrainingData();
        if (localData != null) {
          print("💡 getDashboardData - Usando caché local");
          final trainingData = TrainingData.fromJson(localData);

          // IMPORTANTE: Verificar si las sesiones están cargadas
          print(
              "💡 getDashboardData - Sesiones cargadas: ${trainingData.dashboard.nextWeekSessions.length}");

          // Actualizar caché en memoria
          _cachedTrainingData = trainingData;
          _lastFetchTime = DateTime.now();

          // Notificar a los listeners
          _trainingDataController.add(trainingData);

          return trainingData;
        }
      }

      // Si llegamos aquí, necesitamos obtener datos del servidor
      shouldFetchFromServer = true;
    }

    // Obtener datos del servidor
    if (shouldFetchFromServer) {
      try {
        print("💡 getDashboardData - Obteniendo datos del servidor");
        // Construimos la URL con el parámetro userId
        final endpoint = '$_dashboardEndpoint?userId=$userId';

        // Obtenemos los datos frescos de la API
        final response = await THttpHelper.get(endpoint);
        final trainingData = TrainingData.fromJson(response);

        // IMPORTANTE: Verificar si las sesiones están cargadas desde el servidor
        print(
            "💡 getDashboardData - Sesiones cargadas desde servidor: ${trainingData.dashboard.nextWeekSessions.length}");

        // Actualizar datos en el almacenamiento local
        await TrainingLocalStorage.saveTrainingData(response);

        // Actualizar caché en memoria
        _cachedTrainingData = trainingData;
        _lastFetchTime = DateTime.now();

        // Notificar a los listeners
        _trainingDataController.add(trainingData);

        return trainingData;
      } catch (e) {
        print("❌ getDashboardData - Error al obtener datos: $e");
        // Si hay error y tenemos datos en caché, los devolvemos
        if (_cachedTrainingData != null) {
          print("💡 getDashboardData - Fallback a caché en memoria");
          return _cachedTrainingData!;
        }

        // Intentar obtener del almacenamiento local como último recurso
        final localData = await TrainingLocalStorage.getTrainingData();
        if (localData != null) {
          print("💡 getDashboardData - Fallback a caché local");
          return TrainingData.fromJson(localData);
        }

        // Si no hay caché, propagamos el error
        throw Exception('Error al obtener datos del entrenamiento: $e');
      }
    }

    // Este punto nunca debería alcanzarse, pero por seguridad lanzamos un error
    throw Exception('Error inesperado al obtener datos del entrenamiento');
  }

  // Método para marcar una sesión como completada o no completada
  Future<bool> markSessionAsCompleted(Session session, bool completed,
      {int userId = 1}) async {
    try {
      // Verificar si la sesión ya pasó y asegurarnos de que se marque como no completada
      final now = DateTime.now();
      final sessionDate = session.sessionDate;
      if (sessionDate.isBefore(now) && completed) {
        // Si la sesión ya pasó, no permitir marcarla como completada
        final stackTrace = StackTrace.current.toString();
        if (!stackTrace.contains('_markPastSessionsAsNotCompleted')) {
          // Si es una acción del usuario (no automática), no permitir marcar como completada
          return false;
        }
      }

      // Crear los datos a enviar
      final data = {
        'sessionId': session.sessionDate
            .toIso8601String(), // Suponiendo que usas la fecha como identificador
        'completed': completed,
        'userId': userId, // Incluimos el ID del usuario
        'isPastSession':
            sessionDate.isBefore(now) // Indicar si es una sesión pasada
      };

      // Primero actualizar localmente para mejor experiencia de usuario
      session.completed = completed;

      // Actualizar en el almacenamiento local
      await TrainingLocalStorage.updateSession(session);

      // Si hay datos en caché, actualizamos también el caché en memoria
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

          // Actualizar valores en el objeto caché
          _cachedTrainingData!.dashboard.completedSessions = completedCount;
          if (_cachedTrainingData!.dashboard.totalSessions > 0) {
            _cachedTrainingData!.dashboard.completionRate = (completedCount /
                    _cachedTrainingData!.dashboard.totalSessions *
                    100)
                .round();
          }

          // Notificar a los listeners
          _trainingDataController.add(_cachedTrainingData!);
        }
      }

      // Enviar la actualización al servidor (en segundo plano)
      THttpHelper.put(
              '$_sessionEndpoint/${session.sessionDate.toIso8601String()}',
              data)
          .then((serverResponse) {
        // Actualización exitosa en el servidor
        // Podríamos hacer algo aquí si es necesario
      }).catchError((error) {
        // Error al actualizar en el servidor
        // Podemos manejar la sincronización más tarde
        print('Error al actualizar sesión en el servidor: $error');
      });

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

  // Sincronizar datos pendientes con el servidor
  Future<void> syncPendingChanges(int userId) async {
    // Implementar lógica para sincronizar cambios pendientes
    // Por ejemplo, verificar sesiones marcadas como completadas localmente
    // pero que aún no se han enviado al servidor
  }
}
