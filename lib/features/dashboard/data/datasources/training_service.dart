import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';
import 'package:runap/features/map/utils/training_local_storage.dart';
import 'package:runap/utils/http/http_client.dart';

import '../../domain/entities/training_data.dart';

class TrainingService {
  // Singleton pattern
  static final TrainingService _instance = TrainingService._internal();

  factory TrainingService() => _instance;

  TrainingService._internal();

  // Endpoint para obtener los datos del dashboard
  static const String _dashboardEndpoint = 'api/dashboard/obtener-plan?userId=';
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
    print("💡 getDashboardData - Iniciando obtención de datos");

    // 1. Verificar caché en memoria si no es forzado
    if (!forceRefresh && _cachedTrainingData != null && _lastFetchTime != null) {
      final minutesSinceLastFetch = DateTime.now().difference(_lastFetchTime!).inMinutes;
      if (minutesSinceLastFetch < TrainingLocalStorage.cacheValidityMinutes) {
        print("💡 getDashboardData - Usando caché en memoria (${minutesSinceLastFetch} minutos)");
        return _modificarSesionesDescansoParaHoy(_cachedTrainingData!);
      }
    }

    // 2. Verificar almacenamiento local si no es forzado
    if (!forceRefresh) {
      final localData = await TrainingLocalStorage.getTrainingData();
      if (localData != null) {
        print("💡 getDashboardData - Usando caché del almacenamiento local");
        _cachedTrainingData = TrainingData.fromJson(localData);
        _lastFetchTime = DateTime.now();
        
        // Aplicar modificaciones de datos aleatorios
        _cachedTrainingData = _modificarSesionesDescansoParaHoy(_cachedTrainingData!);
        
        // Notificar a los oyentes
        _trainingDataController.add(_cachedTrainingData!);
        return _cachedTrainingData!;
      }
    }

    // 3. Solo si no hay datos en caché o es forzado, obtener de la API
    if (forceRefresh || _cachedTrainingData == null) {
      try {
        print("💡 getDashboardData - Obteniendo datos del servidor");
        final data = await THttpHelper.get('$_dashboardEndpoint$userId');

        // Procesar y guardar los datos
        _cachedTrainingData = TrainingData.fromJson(data);
        _lastFetchTime = DateTime.now();

        // Aplicar modificaciones de datos aleatorios
        _cachedTrainingData = _modificarSesionesDescansoParaHoy(_cachedTrainingData!);

        // Guardar en el almacenamiento local
        await TrainingLocalStorage.saveTrainingData(data);

        // Notificar a los oyentes
        _trainingDataController.add(_cachedTrainingData!);

        return _cachedTrainingData!;
      } catch (e) {
        print("❌ Error al obtener datos del servidor: $e");
        
        // Si hay error con la API y no hay datos en caché, propagar el error
        if (_cachedTrainingData == null) {
          throw Exception('Error al obtener datos del entrenamiento: ${e.toString()}');
        }
        
        // Si hay error pero tenemos datos en caché, usarlos
        print("⚠️ Usando caché en memoria debido a error de servidor");
        return _modificarSesionesDescansoParaHoy(_cachedTrainingData!);
      }
    }

    // Si llegamos aquí, significa que tenemos datos en caché y no es forzado
    return _modificarSesionesDescansoParaHoy(_cachedTrainingData!);
  }

  // Método para modificar las sesiones de descanso para hoy con datos aleatorios
  TrainingData _modificarSesionesDescansoParaHoy(TrainingData trainingData) {
    final DateTime hoy = DateTime.now();
    final random = math.Random();
    
    print("🔄 INICIO: Modificando sesiones de descanso para hoy (${hoy.day}/${hoy.month})");
    
    // Variable para contar modificaciones
    int modificacionesRealizadas = 0;
    bool haySessionesHoy = false;
    
    // Primero verificamos si hay alguna sesión para hoy
    for (var session in trainingData.dashboard.nextWeekSessions) {
      final esHoy = session.sessionDate.year == hoy.year &&
                   session.sessionDate.month == hoy.month &&
                   session.sessionDate.day == hoy.day;
      
      if (esHoy) {
        haySessionesHoy = true;
        print("📅 ENCONTRADA: Sesión para hoy - ${session.workoutName}");
      }
    }
    
    if (!haySessionesHoy) {
      print("⚠️ ALERTA: No hay sesiones programadas para hoy");
      // Si no hay sesiones para hoy, crear una sesión aleatoria
      _agregarSesionAleatoriaParaHoy(trainingData, hoy);
      return trainingData;
    }
    
    // Comprobar si hay sesiones de descanso para hoy y modificarlas
    for (var i = 0; i < trainingData.dashboard.nextWeekSessions.length; i++) {
      final session = trainingData.dashboard.nextWeekSessions[i];
      
      // Verificar si es una sesión de hoy 
      final esHoy = session.sessionDate.year == hoy.year &&
                   session.sessionDate.month == hoy.month &&
                   session.sessionDate.day == hoy.day;
                   
      final esDescanso = session.workoutName.toLowerCase().contains('descanso');
      
      if (esHoy) {
        print("🔍 REVISANDO: Sesión de hoy - ${session.workoutName} - ¿Es descanso? $esDescanso");
        
        if (esDescanso) {
          print("🔄 MODIFICANDO: Sesión de descanso para hoy");
          
          // Generar datos aleatorios para esta sesión
          final tiposEntrenamiento = [
            'Carrera ligera',
            'Entrenamiento cruzado',
            'Caminata recuperativa',
            'Entrenamiento de fuerza suave',
            'Carrera de recuperación'
          ];
          
          final distanciasKm = [3, 4, 5, 6, 7];
          final tiemposMin = [20, 25, 30, 35, 40];
          final ritmos = ['6:00', '6:30', '7:00', '7:30', '8:00'];
          
          // Seleccionar valores aleatorios
          final tipoEntrenamiento = tiposEntrenamiento[random.nextInt(tiposEntrenamiento.length)];
          final distanciaKm = distanciasKm[random.nextInt(distanciasKm.length)];
          final tiempoMin = tiemposMin[random.nextInt(tiemposMin.length)];
          final ritmo = ritmos[random.nextInt(ritmos.length)];
          
          // Crear una nueva sesión con los datos aleatorios
          final nuevaSesion = Session(
            sessionDate: session.sessionDate,
            workoutName: tipoEntrenamiento,
            description: 'Sesión opcional (día de descanso): Correr $distanciaKm km en $tiempoMin min a ritmo $ritmo min/km',
            completed: session.completed,
          );
          
          // Reemplazar la sesión en la lista
          trainingData.dashboard.nextWeekSessions[i] = nuevaSesion;
          modificacionesRealizadas++;
          
          print("✅ ÉXITO: Sesión modificada: ${nuevaSesion.workoutName} - ${nuevaSesion.description}");
        }
      }
    }
    
    print("✅ FIN: Proceso terminado. Sesiones modificadas: $modificacionesRealizadas");
    
    return trainingData;
  }
  
  // Nuevo método para agregar una sesión aleatoria para hoy si no hay ninguna
  void _agregarSesionAleatoriaParaHoy(TrainingData trainingData, DateTime hoy) {
    final random = math.Random();
    
    // Generar datos aleatorios
    final tiposEntrenamiento = [
      'Carrera ligera',
      'Entrenamiento cruzado',
      'Caminata recuperativa',
      'Entrenamiento de fuerza suave',
      'Carrera de recuperación'
    ];
    
    final distanciasKm = [3, 4, 5, 6, 7];
    final tiemposMin = [20, 25, 30, 35, 40];
    final ritmos = ['6:00', '6:30', '7:00', '7:30', '8:00'];
    
    // Seleccionar valores aleatorios
    final tipoEntrenamiento = tiposEntrenamiento[random.nextInt(tiposEntrenamiento.length)];
    final distanciaKm = distanciasKm[random.nextInt(distanciasKm.length)];
    final tiempoMin = tiemposMin[random.nextInt(tiemposMin.length)];
    final ritmo = ritmos[random.nextInt(ritmos.length)];
    
    // Crear sesión para hoy con hora actual
    final DateTime fechaHoy = DateTime(hoy.year, hoy.month, hoy.day, 
                                      DateTime.now().hour, DateTime.now().minute);
    
    // Crear una nueva sesión aleatoria
    final nuevaSesion = Session(
      sessionDate: fechaHoy,
      workoutName: tipoEntrenamiento,
      description: 'Sesión generada: Correr $distanciaKm km en $tiempoMin min a ritmo $ritmo min/km',
      completed: false,
    );
    
    // Agregar la sesión a la lista
    trainingData.dashboard.nextWeekSessions.add(nuevaSesion);
    
    print("✅ CREADA: Nueva sesión para hoy - ${nuevaSesion.workoutName}");
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
          // Si el estado ya está igual al que se quiere establecer, no hacer nada
          if (_cachedTrainingData!
                  .dashboard.nextWeekSessions[index].completed ==
              completed) {
            return true; // Ya está en el estado deseado, no hay cambios
          }

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

  // Método público para forzar la generación de datos aleatorios para hoy
  Future<TrainingData?> generarDatosAleatoriosParaHoy() async {
    print("🚀 TrainingService - Generando datos aleatorios para hoy");
    
    if (_cachedTrainingData == null) {
      print("❌ No hay datos en caché para modificar");
      return null;
    }
    
    // Hacer una copia profunda para no afectar los datos originales
    // hasta que estemos seguros de los cambios
    TrainingData datosModificados = TrainingData(
      dashboard: Dashboard(
        raceType: _cachedTrainingData!.dashboard.raceType,
        targetPace: _cachedTrainingData!.dashboard.targetPace,
        goalTime: _cachedTrainingData!.dashboard.goalTime,
        weeksToRace: _cachedTrainingData!.dashboard.weeksToRace,
        totalSessions: _cachedTrainingData!.dashboard.totalSessions,
        completedSessions: _cachedTrainingData!.dashboard.completedSessions,
        completionRate: _cachedTrainingData!.dashboard.completionRate,
        nextWeekSessions: List.from(_cachedTrainingData!.dashboard.nextWeekSessions),
      ),
    );
    
    // Aplicar la modificación
    final DateTime hoy = DateTime.now();
    
    // Verificar si hay sesiones para hoy
    bool haySessionesHoy = false;
    for (var session in datosModificados.dashboard.nextWeekSessions) {
      final esHoy = session.sessionDate.year == hoy.year &&
                   session.sessionDate.month == hoy.month &&
                   session.sessionDate.day == hoy.day;
      
      if (esHoy) {
        haySessionesHoy = true;
        break;
      }
    }
    
    if (!haySessionesHoy) {
      // Si no hay sesiones para hoy, crear una
      print("⚠️ No hay sesiones para hoy, creando una nueva...");
      _agregarSesionAleatoriaParaHoy(datosModificados, hoy);
    } else {
      // Si hay sesiones, intentar modificar las de descanso
      print("✅ Hay sesiones para hoy, modificando según sea necesario...");
      bool hayDescansoHoy = false;
      
      // Verificar si hay sesiones de descanso para hoy
      for (var session in datosModificados.dashboard.nextWeekSessions) {
        final esHoy = session.sessionDate.year == hoy.year &&
                     session.sessionDate.month == hoy.month &&
                     session.sessionDate.day == hoy.day;
        
        if (esHoy && session.workoutName.toLowerCase().contains('descanso')) {
          hayDescansoHoy = true;
          break;
        }
      }
      
      if (hayDescansoHoy) {
        // Si hay sesiones de descanso, modificarlas
        print("🔄 Hay sesiones de descanso para hoy, cambiándolas...");
        datosModificados = _modificarSesionesDescansoParaHoy(datosModificados);
      } else {
        // Si no hay sesiones de descanso, no hacemos nada
        print("💡 Las sesiones para hoy no son de descanso, no es necesario modificarlas");
      }
    }
    
    // Actualizar en caché
    _cachedTrainingData = datosModificados;
    _lastFetchTime = DateTime.now();
    
    // Notificar a los listeners
    _trainingDataController.add(datosModificados);
    
    print("✅ TrainingService - Datos aleatorios generados y notificados");
    
    return datosModificados;
  }

  // Sincronizar datos pendientes con el servidor
  Future<void> syncPendingChanges(int userId) async {
    // Implementar lógica para sincronizar cambios pendientes
    // Por ejemplo, verificar sesiones marcadas como completadas localmente
    // pero que aún no se han enviado al servidor
  }

  // Método para actualizar una sesión
  Future<void> updateSession(Session session) async {
    try {
      final response = await THttpHelper.put(
        '$_sessionEndpoint/${session.sessionDate.millisecondsSinceEpoch}',
        session.toJson(),
      );

      if (response == null) {
        throw Exception('Error al actualizar la sesión');
      }
    } catch (e) {
      throw Exception('Error al actualizar la sesión: $e');
    }
  }

  // Método para guardar los datos en el almacenamiento local
  Future<void> saveLocalDashboardData(TrainingData data) async {
    try {
      await TrainingLocalStorage.saveTrainingData(data.toJson());
    } catch (e) {
      throw Exception('Error al guardar los datos localmente: $e');
    }
  }

  // Método para obtener los datos del almacenamiento local
  Future<TrainingData?> getLocalDashboardData() async {
    try {
      final jsonData = await TrainingLocalStorage.getTrainingData();
      if (jsonData == null) return null;
      return TrainingData.fromJson(jsonData);
    } catch (e) {
      throw Exception('Error al obtener los datos locales: $e');
    }
  }
}
