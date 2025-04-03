import 'package:get/get.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import '../models/training_data.dart';
import '../controllers/training_service.dart';

enum LoadingStatus { initial, loading, loaded, error }

class TrainingViewModel extends GetxController {
  // Servicio para obtener datos de entrenamiento
  final TrainingService _trainingService = TrainingService();

  // Variables observables (reactivas)
  final Rx<TrainingData?> _trainingData = Rx<TrainingData?>(null);
  final Rx<LoadingStatus> _status = LoadingStatus.initial.obs;
  final RxString _errorMessage = ''.obs;

  // ID del usuario actual (podría venir de un servicio de autenticación)
  final int _userId = 1; // Por defecto usamos el usuario 1

  // Getters
  TrainingData? get trainingData => _trainingData.value;
  LoadingStatus get status => _status.value;
  String get errorMessage => _errorMessage.value;

  // Constructor - llamado cuando GetX instancia este controller
  @override
  void onInit() {
    super.onInit();
    print("🚀 TrainingViewModel - onInit");

    // Suscribirnos al stream de datos de entrenamiento
    _trainingService.trainingDataStream.listen((data) {
      print("📡 TrainingViewModel - Recibiendo datos del stream");
      _trainingData.value = data;
      _status.value = LoadingStatus.loaded;

      // IMPORTANTE: Llamar a update() para notificar a GetBuilder
      update();

      // Verificar si hay datos y sesiones
      if (data != null && data.dashboard.nextWeekSessions.isNotEmpty) {
        print(
            "✅ TrainingViewModel (stream) - Datos recibidos con ${data.dashboard.nextWeekSessions.length} sesiones");
      } else {
        print(
            "⚠️ TrainingViewModel (stream) - Datos recibidos sin sesiones o nulos");
      }

      // Solo llamar a actualizar sesiones pasadas si no estamos ya en ese proceso
      if (!_isUpdatingPastSessions) {
        _updatePastSessions();
      }
    });

    // Cargar datos iniciales
    loadDashboardData();
  }

  // Método para cargar los datos del dashboard
  Future<void> loadDashboardData(
      {bool forceRefresh = false, int? userId}) async {
    try {
      print(
          "🔄 TrainingViewModel - Iniciando carga de datos. ForceRefresh: $forceRefresh");

      // Actualizar estado
      _status.value = LoadingStatus.loading;
      update(); // IMPORTANTE: Notificar a GetBuilder

      // Usamos el userId proporcionado o el valor por defecto
      final userIdToUse = userId ?? _userId;

      // Cargar datos
      final data = await _trainingService.getDashboardData(
          forceRefresh: forceRefresh, userId: userIdToUse);

      // Actualizar estado
      _trainingData.value = data;
      _status.value = LoadingStatus.loaded;

      // Imprimir información para debug
      if (data != null && data.dashboard.nextWeekSessions.isNotEmpty) {
        print("✅ TrainingViewModel - Datos cargados exitosamente");
        print(
            "📊 Total de sesiones: ${data.dashboard.nextWeekSessions.length}");
        print(
            "📊 Primera sesión: ${data.dashboard.nextWeekSessions[0].workoutName}");

        // Verificar si hay sesiones para hoy
        _verificarSesionesHoy(data.dashboard.nextWeekSessions);

        // IMPORTANTE: Verificar si la lista contiene elementos después de ordenarla
        List<Session> testSessions = List.from(data.dashboard.nextWeekSessions);
        testSessions.sort((a, b) => a.sessionDate.compareTo(b.sessionDate));
        print("📊 Después de ordenar: ${testSessions.length} sesiones");
        if (testSessions.isNotEmpty) {
          print("📊 Primera sesión ordenada: ${testSessions[0].workoutName}");
        }
      } else {
        print(
            "⚠️ TrainingViewModel - No hay sesiones disponibles o datos nulos");
      }

      // IMPORTANTE: Llamar a update() DESPUÉS de modificar los datos
      update();

      // Verificar sesiones pasadas
      _updatePastSessions();
    } catch (e) {
      print("❌ TrainingViewModel - Error al cargar datos: $e");

      _status.value = LoadingStatus.error;
      _errorMessage.value = e.toString();

      // IMPORTANTE: Notificar a GetBuilder sobre el error
      update();
    }
  }

  // Nuevo método para verificar si hay sesiones de hoy
  void _verificarSesionesHoy(List<Session> sessions) {
    final now = DateTime.now();
    int sesionesHoy = 0;
    int sesionesDescansoHoy = 0;
    
    for (var session in sessions) {
      final isToday = session.sessionDate.year == now.year &&
                    session.sessionDate.month == now.month &&
                    session.sessionDate.day == now.day;
                    
      if (isToday) {
        sesionesHoy++;
        if (session.workoutName.toLowerCase().contains('descanso')) {
          sesionesDescansoHoy++;
        }
      }
    }
    
    print("📊 Sesiones para hoy: $sesionesHoy (descanso: $sesionesDescansoHoy)");
  }

  // Método para marcar una sesión como completada o no
  Future<bool> toggleSessionCompletion(Session session) async {
    print(
        "🔄 TrainingViewModel - Cambiando estado de sesión: ${session.workoutName}");

    final newStatus = !session.completed;

    // Si la sesión es de hoy o futura, permitimos cambiar su estado
    final now = DateTime.now();
    final isSessionInFuture = session.sessionDate.isAfter(now) ||
        (session.sessionDate.year == now.year &&
            session.sessionDate.month == now.month &&
            session.sessionDate.day == now.day);

    // Solo permitimos marcar como completadas sesiones presentes o futuras
    if (!isSessionInFuture && newStatus) {
      print("⛔ No se permite cambiar estado de sesión pasada");
      return false;
    }

    final success = await _trainingService
        .markSessionAsCompleted(session, newStatus, userId: _userId);

    if (success) {
      print("✅ Sesión actualizada exitosamente");

      // Actualizar localmente
      session.completed = newStatus;

      // IMPORTANTE: Notificar a GetBuilder
      update();
      return true;
    }

    print("❌ Error al actualizar sesión");
    return false;
  }

  // Variable para controlar si estamos en medio de una actualización
  bool _isUpdatingPastSessions = false;

  // Método para actualizar el estado de sesiones pasadas
  void _updatePastSessions() {
    // Si ya estamos actualizando o no hay datos, salir
    if (_isUpdatingPastSessions || _trainingData.value == null) return;

    try {
      _isUpdatingPastSessions = true;

      final now = DateTime.now();
      bool anyUpdated = false;
      List<Session> sessionsToUpdate = [];

      for (var session in _trainingData.value!.dashboard.nextWeekSessions) {
        // Verificar si la sesión ya pasó y no está completada
        if (session.sessionDate.isBefore(now) && !session.completed) {
          // Agregar a la lista de sesiones a actualizar en el backend
          sessionsToUpdate.add(session);
          anyUpdated = true;
        }
      }

      // Actualizar en el backend las sesiones pasadas no completadas
      if (sessionsToUpdate.isNotEmpty) {
        print("🔄 Actualizando ${sessionsToUpdate.length} sesiones pasadas");
        _markPastSessionsAsNotCompleted(sessionsToUpdate);
      }

      // Solo notificar si realmente hubo cambios
      if (anyUpdated) {
        update();
      }
    } finally {
      _isUpdatingPastSessions = false;
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

                                      // Método para forzar la generación de datos aleatorios para pruebas
  Future<void> generarDatosAleatorios() async {
    print("🚀 Generando datos aleatorios para pruebas");
    
    try {
      // Actualizar estado
      _status.value = LoadingStatus.loading;
      update();
      
      // Usar el método específico del TrainingService
      final datos = await _trainingService.generarDatosAleatoriosParaHoy();
      
      if (datos != null) {
        _trainingData.value = datos;
        _status.value = LoadingStatus.loaded;
        print("✅ Datos aleatorios cargados exitosamente");
      } else {
        print("⚠️ No se pudieron generar datos aleatorios");
        // Si falló, intentar con el método normal
        await loadDashboardData(forceRefresh: true);
      }
      
      // Notificar cambios
      update();
    } catch (e) {
      print("❌ Error al generar datos aleatorios: $e");
      _status.value = LoadingStatus.error;
      _errorMessage.value = e.toString();
      update();
    }
  }

  @override
  void onClose() {
    print("🔄 TrainingViewModel - onClose");
    _trainingService.dispose();
    super.onClose();
  }
}
