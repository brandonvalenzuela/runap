// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';
import '../../domain/entities/training_data.dart';
import '../../data/datasources/training_service.dart';

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

  // final _storage = GetStorage(); // Solo si usas GetStorage directamente aquí

  // Constructor - llamado cuando GetX instancia este controller
  @override
  void onInit() {
    super.onInit();
    print("🚀 TrainingViewModel - onInit");

    // La suscripción al stream es importante para actualizaciones post-carga inicial
    _trainingService.trainingDataStream.listen((data) {
      print("📡 TrainingViewModel - Recibiendo datos del stream");
      if (data != null) {
        _trainingData.value = data;
        // Solo cambiar a 'loaded' si no estaba ya en 'error'
        if (_status.value != LoadingStatus.error) {
          _status.value = LoadingStatus.loaded;
        }
        update(); // Notificar a GetBuilder
        print("✅ TrainingViewModel (stream) - Datos procesados");
         if (!_isUpdatingPastSessions) {
             _updatePastSessions();
         }
      } else {
         print("⚠️ TrainingViewModel (stream) - Stream devolvió datos nulos");
         // Decide si quieres manejar nulls del stream como error
      }
    });

    // Cargar datos iniciales
    loadDashboardData();
  }

  // Método para cargar los datos del dashboard
  Future<void> loadDashboardData(
      {bool forceRefresh = false, int? userId}) async {
    print("🔄 TrainingViewModel - Iniciando carga. ForceRefresh: $forceRefresh");
    final userIdToUse = userId ?? _userId;
    bool loadedFromCache = false;

    // 1. Intentar cargar desde caché local SIN mostrar loading si no es forceRefresh
    if (!forceRefresh) {
      try {
        // Usamos el método del servicio que lee la caché local
        final cachedData = await _trainingService.getLocalDashboardData();
        if (cachedData != null) {
          print("💾 TrainingViewModel - Datos encontrados en caché local del servicio.");
          _trainingData.value = cachedData;
          _status.value = LoadingStatus.loaded;
          loadedFromCache = true;
          update(); // ¡Actualizar UI INMEDIATAMENTE con la caché!
          print("✅ TrainingViewModel - UI actualizada con caché local.");
        }
      } catch (e) {
        print("⚠️ TrainingViewModel - Error leyendo caché local del servicio: $e");
        // Continuar para intentar cargar desde la red/Firestore
      }
    }

    // 2. Si no se cargó de caché O se forzó el refresco, mostrar loading
    if (!loadedFromCache) {
      print("⏳ TrainingViewModel - No hay caché / Forzado. Mostrando loading.");
      _status.value = LoadingStatus.loading;
      update();
    }

    // 3. Intentar obtener datos del servicio (red/Firestore)
    // Si se cargó de caché, esto actúa como un refresco en segundo plano.
    // Si no, es la carga principal.
    try {
      print("☁️ TrainingViewModel - Obteniendo datos del servicio...");
      final data = await _trainingService.getDashboardData(
          forceRefresh: forceRefresh, userId: userIdToUse);

      // El stream listener debería manejar la actualización principal,
      // pero podemos asegurarnos aquí si el stream no emitió o por redundancia.
      // Solo actualizamos el estado si NO viene de un error previo
      // o si forzamos el refresco.
      if (_status.value != LoadingStatus.error || forceRefresh) {
         if (data != null) {
            // Podríamos comparar si data es diferente a _trainingData.value antes de actualizar
            _trainingData.value = data;
            _status.value = LoadingStatus.loaded;
            print("✅ TrainingViewModel - Datos obtenidos/refrescados del servicio.");
            update();
            _verificarSesionesHoy(data.dashboard.nextWeekSessions);
            _updatePastSessions();
         } else if (!loadedFromCache) {
            // Si no cargamos de caché y el servicio devuelve null -> Error
            print("❌ TrainingViewModel - Servicio devolvió null y no había caché.");
            _status.value = LoadingStatus.error;
            _errorMessage.value = "No se pudieron obtener datos.";
            update();
         }
      }

    } catch (e) {
      print("❌ TrainingViewModel - Error llamando a getDashboardData: $e");
      // Solo establecer error si NO habíamos cargado de caché previamente
      if (!loadedFromCache) {
        _status.value = LoadingStatus.error;
        _errorMessage.value = e.toString();
        update();
      } else {
         print("ℹ️ TrainingViewModel - Error al refrescar datos, manteniendo caché: $e");
         // Opcional: mostrar mensaje no bloqueante (Toast/Snackbar)
      }
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

      // Actualizar localmente (el servicio ya debería haberlo hecho y notificado vía stream)
      // session.completed = newStatus; // Comentado, el stream debería manejarlo

      // IMPORTANTE: Notificar a GetBuilder (redundante si el stream funciona bien, pero seguro)
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

      // Usar una copia de la lista para evitar problemas de concurrencia si el stream la modifica
      final currentSessions = List<Session>.from(_trainingData.value!.dashboard.nextWeekSessions);

      for (var session in currentSessions) {
        // Verificar si la sesión ya pasó y no está completada
        // Asegurarse que la comparación de fecha ignora la hora
        final sessionDateOnly = DateTime(session.sessionDate.year, session.sessionDate.month, session.sessionDate.day);
        final nowDateOnly = DateTime(now.year, now.month, now.day);

        if (sessionDateOnly.isBefore(nowDateOnly) && !session.completed) {
          // Agregar a la lista de sesiones a actualizar en el backend
          sessionsToUpdate.add(session);
          // Marcar localmente como no completada (si no lo estaba ya)
          if (session.completed != false) {
              session.completed = false; // Actualizar el objeto en la copia local
              anyUpdated = true;
          }
        }
      }

      // Actualizar en el backend las sesiones pasadas no completadas
      if (sessionsToUpdate.isNotEmpty) {
        print("🔄 Actualizando ${sessionsToUpdate.length} sesiones pasadas como no completadas en backend");
        _markPastSessionsAsNotCompleted(sessionsToUpdate);
      }

      // Solo notificar si realmente hubo cambios locales
      if (anyUpdated) {
         print("📊 Notificando UI por actualización de sesiones pasadas.");
        // Es importante actualizar _trainingData.value con la lista modificada si es necesario
        // O confiar en que el servicio emitirá los cambios si _markPast... los notifica.
        // Por seguridad, llamamos update() aquí.
        update();
      }
    } finally {
      _isUpdatingPastSessions = false;
    }
  }

  // Método para marcar sesiones pasadas como no completadas en el backend
  Future<void> _markPastSessionsAsNotCompleted(List<Session> sessions) async {
    // Iterar sobre una copia para evitar problemas si la lista original cambia
    for (var session in List<Session>.from(sessions)) {
      // Marca como no completada en el backend
      // El servicio ya debería manejar la lógica de no reenviar si ya está false
       await _trainingService.markSessionAsCompleted(
          session, false, // Explícitamente marcamos como no completada
          userId: _userId);
        // No es necesario actualizar localmente aquí, _updatePastSessions ya lo hizo
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
    // Considera si necesitas cerrar el stream controller DENTRO del servicio
    // _trainingService.dispose(); // Llama a dispose si existe en el servicio
    super.onClose();
  }
}
