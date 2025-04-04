import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:runap/features/dashboard/viewmodels/training_view_model.dart';
import 'package:runap/features/map/models/workout_data.dart';
import 'package:runap/features/map/models/workout_goal.dart';
import 'package:runap/features/map/services/location_service.dart';
import 'package:runap/features/map/services/map_workout_data_provider.dart';
import 'package:runap/features/map/utils/location_permission_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:runap/features/map/screen/map.dart';
import 'package:logger/logger.dart';

class MapController extends GetxController {
  final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  // Variables observables
  final Rx<WorkoutData> workoutData = WorkoutData().obs;
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool showGoalSelector = false.obs;
  final RxList<WorkoutGoal> availableGoals = <WorkoutGoal>[].obs;

  // Servicios y helpers
  late LocationService locationService;
  LocationPermissionHelper permissionHelper = LocationPermissionHelper();
  WorkoutDatabaseService databaseService = WorkoutDatabaseService();

  // Variables de control
  int _stabilizationCount = 0;
  LatLng? _lastStablePosition;

  // Controlador del mapa de Google
  Rxn<GoogleMapController> mapController = Rxn<GoogleMapController>();

  // Variables para el entrenamiento
  Rxn<DateTime> workoutStartTime = Rxn<DateTime>();
  Timer? goalCheckTimer;

  // Sesión a actualizar (si viene del dashboard)
  final Rxn<Session> sessionToUpdate = Rxn<Session>();

  // Añadir un flag para controlar el logging
  final bool _isDebugMode = false; // Cambiar a false en producción

  // Agregar campo para controlar si estamos simulando
  bool _isSimulatingLocation = false;
  Timer? _simulationTimer;

  // Constructor
  MapController({Session? initialSession, WorkoutGoal? initialWorkoutGoal}) {
    if (initialSession != null) {
      sessionToUpdate.value = initialSession;
    }

    if (initialWorkoutGoal != null) {
      workoutData.value.setGoal(initialWorkoutGoal);
    }

    locationService = LocationService(
      onLocationUpdate: _handleLocationUpdate,
      onMetricsUpdate: _handleMetricsUpdate,
    );
  }

  @override
  void onInit() {
    super.onInit();

    // Verificar si la sesión debe ser accesible (SOLO HOY)
    if (sessionToUpdate.value != null) {
      final now = DateTime.now();
      final isToday = now.year == sessionToUpdate.value!.sessionDate.year &&
          now.month == sessionToUpdate.value!.sessionDate.month &&
          now.day == sessionToUpdate.value!.sessionDate.day;

      final canAccess = isToday &&
          !sessionToUpdate.value!.workoutName
              .toLowerCase()
              .contains('descanso');

      if (!canAccess) {
        // No debería acceder a este entrenamiento, regresar
        Get.back();
        Get.snackbar(
          'Acceso denegado',
          'Solo puedes iniciar entrenamientos programados para hoy',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }
    }

    // Inicializar en un futuro para no bloquear la UI
    Future.microtask(() => initialize());

    // // Detectar si estamos en emulador (esto es una aproximación, puedes mejorarla)
    // bool isEmulator = false;
    // try {
    //   isEmulator = Platform.environment.containsKey('ANDROID_EMULATOR') || 
    //                Platform.environment.containsKey('VIRTUAL_DEVICE') ||
    //                Platform.environment.containsKey('SIMULATOR');
    // } catch (e) {
    //   // Si hay error al verificar, asumir que no es emulador
    // }
    
    // // Si es emulador o modo debug, activar simulación
    // if (isEmulator || kDebugMode) {
    //   Future.delayed(Duration(seconds: 2), () {
    //     simulateLocation();
    //   });
    // }
  }

  void _handleLocationUpdate(LatLng position) {
    logger.d("📍 Nueva posición recibida: $position");
    
    workoutData.update((val) {
      val?.currentPosition = position;

      if (val?.isWorkoutActive == true) {
        // Estabilización de ruta al inicio
        if (_stabilizationCount < 3) {
          _stabilizationCount++;

          // Si tenemos un punto estable previo, verificamos la distancia
          if (_lastStablePosition != null) {
            double distance = Geolocator.distanceBetween(
                _lastStablePosition!.latitude,
                _lastStablePosition!.longitude,
                position.latitude,
                position.longitude);

            if (distance > 50) {
              // Si hay un salto grande, resetear el contador
              _stabilizationCount = 0;
              logger.d(
                  "⚠️ MapController - Saltó GPS detectado (${distance.toStringAsFixed(1)}m), esperando estabilización");
              return;
            }
          }

          // Actualizar última posición estable
          _lastStablePosition = position;

          // En fase de estabilización, no añadimos puntos a la ruta
          if (_stabilizationCount < 3) {
            logger.d(
                "🔍 MapController - Estabilizando GPS: $_stabilizationCount/3");
            return;
          } else {
            logger.d(
                "✅ MapController - GPS estabilizado, iniciando trazado de ruta");
          }
        }

        // Una vez estabilizado, añadimos puntos a la polilínea
        val?.polylineCoordinates.add(position);
        val?.updatePolyline();
        
        // Verificar que la polilínea se esté actualizando
        if (val?.polylines.isNotEmpty == true) {
          logger.d("✅ Polilínea actualizada - ${val?.polylineCoordinates.length} puntos");
        } else {
          logger.d("⚠️ Error: polylines está vacío después de updatePolyline()");
        }
        
        // Centrar el mapa en la posición actual
        mapController.value?.moveCamera(
          CameraUpdate.newLatLng(workoutData.value.currentPosition!),
        );
      }
    });
  }

  void _handleMetricsUpdate(Position position) {
    // Ejecutar en isolate o computeAsync si es posible
    Future.microtask(() {
      locationService.updateMetrics(workoutData.value, position);
      
      // Verificar objetivo solo si es necesario
      if (workoutData.value.isWorkoutActive && workoutData.value.goal != null) {
        workoutData.value.checkGoalCompletion();
      }
      
      // Actualizar UI sólo después de completar cálculos
      workoutData.refresh();
    });
  }

  Future<void> initialize() async {
    isLoading.value = true;
    
    try {
      // Ejecutar en paralelo para optimizar
      await Future.wait([
        checkLocationPermissions(),
        _loadGoals(),
      ]);
    } catch (e) {
      logger.d('Error en inicialización: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadGoals() async {
    try {
      final recommendedGoal = await databaseService.getRecommendedWorkoutGoal();
      final goals = await databaseService.getAvailableWorkoutGoals();
      
      // Actualizar todo de una vez
      workoutData.update((val) {
        if (recommendedGoal != null && val?.goal == null) {
          val?.setGoal(recommendedGoal);
        }
      });
      
      availableGoals.value = goals;
    } catch (e) {
      logger.d('Error al cargar objetivos: $e');
    }
  }

  void setWorkoutGoal(WorkoutGoal goal) {
    workoutData.update((val) {
      val?.setGoal(goal);
    });
    showGoalSelector.value = false;
  }

  Future<void> checkLocationPermissions() async {
    bool serviceEnabled = await permissionHelper.checkLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Servicio de ubicación desactivado',
        'Por favor activa el servicio de ubicación para usar esta función',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return;
    }

    LocationPermission permission =
        await permissionHelper.checkLocationPermission();
    bool isPermanentlyDenied = await permissionHelper.isPermanentlyDenied();

    if (isPermanentlyDenied) {
      Get.dialog(
        AlertDialog(
          title: Text('Permiso de ubicación denegado permanentemente'),
          content: Text(
              'Para usar esta función, necesitas otorgar permisos de ubicación en la configuración de la aplicación.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                permissionHelper.openAppSettings();
                Get.back();
              },
              child: Text('Abrir Configuración'),
            ),
          ],
        ),
      );
      return;
    } else if (permission == LocationPermission.denied) {
      Get.dialog(
        AlertDialog(
          title: Text('Permiso de ubicación denegado'),
          content: Text(
              'Necesitamos permiso para acceder a la ubicación para rastrear tu entrenamiento.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Get.back();
                LocationPermission permission =
                    await permissionHelper.requestLocationPermission();
                if (permission == LocationPermission.always ||
                    permission == LocationPermission.whileInUse) {
                  await getCurrentLocationAndAnimateCamera();
                }
              },
              child: Text('Solicitar Permisos'),
            ),
          ],
        ),
      );
      return;
    }

    await getCurrentLocationAndAnimateCamera();
  }

  Future<void> getCurrentLocationAndAnimateCamera() async {
    try {
      // Ejecutar en paralelo para optimizar
      Position position = await locationService.getCurrentPosition();
      LatLng latLng = LatLng(position.latitude, position.longitude);

      workoutData.update((val) {
        val?.currentPosition = latLng;
      });

      if (workoutData.value.currentPosition != null &&
          mapController.value != null) {
        mapController.value!.moveCamera(
          CameraUpdate.newLatLngZoom(
            workoutData.value.currentPosition!, 17.0),
        );
      }
    } catch (e) {
      logger.d('Error al obtener la ubicación: $e');
    }
  }

  Future<bool> checkGpsStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'GPS desactivado',
        'Por favor activa el GPS para un mejor seguimiento',
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      );
      return false;
    }
    
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 3),
        )
      );
      
      if (position.accuracy > 50) {
        Get.snackbar(
          'Señal GPS débil',
          'La precisión actual es baja (${position.accuracy.toStringAsFixed(1)}m). Intenta en un área abierta.',
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        );
      }
      
      return true;
    } catch (e) {
      logger.d("⚠️ Error al verificar GPS: $e");
      return false;
    }
  }

  void startWorkout() async {
    // Verificar permisos
    LocationPermission permission =
        await permissionHelper.checkLocationPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return;
    }

    // Mostrar indicador de inicialización
    _stabilizationCount = 0;
    _lastStablePosition = null;
    update();

    // Verificar si tenemos posición actual
    if (workoutData.value.currentPosition == null) {
      // Intentar obtener posición actual
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 5),
          )
        );
        workoutData.update((val) {
          val?.currentPosition = LatLng(position.latitude, position.longitude);
        });
        logger.d("✅ Posición inicial obtenida: ${position.latitude}, ${position.longitude}");
      } catch (e) {
        logger.d("⚠️ No se pudo obtener posición inicial: $e");
        
        // Si estamos en emulador o modo debug, usar posición por defecto
        if (kDebugMode) {
          workoutData.update((val) {
            val?.currentPosition = LatLng(20.651464, -103.392958);
          });
          logger.d("🔮 Usando posición por defecto para el emulador");
        } else {
          // Informar al usuario
          Get.snackbar(
            'GPS no disponible',
            'Por favor, verifica que el GPS está activado y sal al exterior para mejor señal',
            backgroundColor: Colors.orange,
          );
        }
      }
    }

    // Inicialización de estado
    _stabilizationCount = 0;
    _lastStablePosition = null;
    update();

    // Obtener una ubicación estable antes de iniciar la ruta
    logger.d("🔄 MapController - Estabilizando ubicación GPS...");

    // Esperar 2 segundos para que el GPS obtenga una buena señal
    Future.delayed(Duration(seconds: 2));

    try {
      // Obtener posición actual
      final initialPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 5),
          ));

      // Verificar que la precisión sea buena
      if (initialPosition.accuracy <= 20) {
        // Precisión de 20 metros o mejor
        _lastStablePosition =
            LatLng(initialPosition.latitude, initialPosition.longitude);
        logger.d(
            "✅ MapController - Ubicación inicial estable: ${initialPosition.accuracy}m");
      } else {
        logger.d(
            "⚠️ MapController - Precisión inicial insuficiente: ${initialPosition.accuracy}m");
        // Continuaremos de todos modos, pero con una advertencia
      }
    } catch (e) {
      logger.d("⚠️ MapController - Error al obtener ubicación estable: $e");
    }

    // Resetear datos del workout de manera completa
    workoutData.update((val) {
      val?.reset();
      val?.isWorkoutActive = true;
      
      // Inicializar explícitamente valores críticos
      val?.distanceMeters = 0;
      val?.speedMetersPerSecond = 0;
      val?.polylineCoordinates.clear();
      val?.polylines.clear();
      val?.previousTime = DateTime.now(); // ¡IMPORTANTE! Inicializar el tiempo previo

      // Si hay un objetivo, actualizar su tiempo de inicio
      if (val?.goal != null) {
        val?.setGoal(WorkoutGoal(
          targetDistanceKm: val.goal!.targetDistanceKm,
          targetTimeMinutes: val.goal!.targetTimeMinutes,
          startTime: DateTime.now(),
        ));
      }

      // SOLO agregar el punto inicial si tenemos una posición estable
      if (_lastStablePosition != null && val?.currentPosition != null) {
        // Verificar si ambas posiciones están muy cercanas
        double distanceBetween = Geolocator.distanceBetween(
            _lastStablePosition!.latitude,
            _lastStablePosition!.longitude,
            val!.currentPosition!.latitude,
            val.currentPosition!.longitude);

        // Solo añadir si las posiciones están razonablemente cerca (menos de 30m)
        if (distanceBetween < 30) {
          val.polylineCoordinates.add(_lastStablePosition!);
          logger.d("✅ MapController - Punto inicial añadido a la ruta");
          val.updatePolyline(); // Asegurarse de actualizar la polilínea
        } else {
          logger.d(
              "⚠️ MapController - Diferencia grande entre posiciones, no se añade punto inicial");
        }
      }
    });

    workoutStartTime.value = DateTime.now();
    update();

    // Forzar actualización de la UI antes de iniciar
    workoutData.refresh();
    
    // Imprimir estado inicial
    logger.d("▶️ Iniciando entrenamiento - Estado inicial:");
    logger.d("  🏃‍♂️ Activo: ${workoutData.value.isWorkoutActive}");
    logger.d("  📍 Posición actual: ${workoutData.value.currentPosition}");
    logger.d("  📏 Distancia: ${workoutData.value.distanceMeters} metros");
    logger.d("  ⏱️ Tiempo: ${getFormattedElapsedTime()}");
    logger.d("  🛣️ Puntos en ruta: ${workoutData.value.polylineCoordinates.length}");
    logger.d("  🛣️ Polilíneas activas: ${workoutData.value.polylines.length}");

    // Log detallado al iniciar
    logWorkoutStatus(detailed: true);

    // Iniciar actualizaciones de ubicación
    locationService.startLocationUpdates();

    // Configurar actualizaciones periódicas del mapa
    setupPeriodicMapUpdates();

    // Iniciar timer para verificar el objetivo cada segundo
    goalCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!workoutData.value.isWorkoutActive) {
        timer.cancel();
        return;
      }

      // Asegurarse de que la UI se actualice constantemente
      workoutData.refresh();
    });
  }

  Future<void> stopWorkout() async {
    isSaving.value = true;

    workoutData.update((val) {
      val?.isWorkoutActive = false;
    });

    locationService.stopLocationUpdates();
    goalCheckTimer?.cancel();

    // Calcular tiempo total de entrenamiento
    if (workoutStartTime.value != null) {
      final durationSeconds =
          DateTime.now().difference(workoutStartTime.value!).inSeconds;
      final distanceKm = workoutData.value.distanceMeters / 1000;
      final goalCompleted = workoutData.value.goal?.isCompleted ?? false;

      // Guardar resultados en la base de datos
      try {
        await databaseService.saveWorkoutResult(
            distanceKm, durationSeconds, goalCompleted);
      } catch (e) {
        logger.d('Error al guardar resultados: $e');
      }
    }

    // Guardar la ruta si hay suficientes puntos
    if (workoutData.value.polylineCoordinates.length > 5) {
      try {
        // Almacenar en la base de datos
        await databaseService.saveWorkoutRoute(workoutData.value.polylineCoordinates);
      } catch (e) {
        logger.d("⚠️ Error al guardar la ruta: $e");
      }
    }

    // Si hay una sesión a actualizar (viniendo del dashboard)
    if (sessionToUpdate.value != null) {
      try {
        // Obtener el TrainingViewModel usando GetX
        final trainingViewModel = Get.find<TrainingViewModel>();

        // Marcar la sesión como completada
        await trainingViewModel.toggleSessionCompletion(sessionToUpdate.value!);

        // Mostrar diálogo de éxito
        await _showCompletionDialog();

        // Volver al dashboard
        Get.back();
      } catch (e) {
        Get.snackbar(
          'Error',
          'Error al actualizar el entrenamiento: $e',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    }

    isSaving.value = false;
  }

  Future<void> _showCompletionDialog() async {
    return Get.dialog(
      AlertDialog(
        title: const Text('¡Entrenamiento completado!'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Has completado tu entrenamiento de hoy.'),
              SizedBox(height: 8),
              Text(
                'Distancia: ${(workoutData.value.distanceMeters / 1000).toStringAsFixed(2)} km',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Tiempo: ${getFormattedElapsedTime()}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Volver al Dashboard'),
            onPressed: () {
              Get.back();
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void toggleGoalSelector() {
    showGoalSelector.value = !showGoalSelector.value;
  }

  void setMapControllerInstance(GoogleMapController controller) {
    mapController.value = controller;
    
    // Registrar el momento en que el controlador del mapa está disponible
    logger.d("🗺️ MapController - Controlador de mapa inicializado");
    
    // Iniciar una carga asíncrona del mapa para no bloquear la UI
    Future.microtask(() {
      // Verificar si tenemos una posición conocida
      if (workoutData.value.currentPosition == null) {
        // Intentar obtener la ubicación actual primero
        getCurrentLocationAndAnimateCamera();
      } else {
        // Ajustar la vista inicial con la posición conocida
        try {
          final padding = EdgeInsets.only(
            top: 60,
            bottom: 220,
            left: 20,
            right: 20,
          );
          
          controller.moveCamera(
            CameraUpdate.newLatLngZoom(
              workoutData.value.currentPosition!,
              17.0,
            ),
          );
        } catch (e) {
          logger.e("🗺️ Error al configurar vista inicial: $e");
        }
      }
      
      // Indicar que el mapa ya no está cargando
      isLoading.value = false;
    });
  }

  int getElapsedTimeSeconds() {
    if (!workoutData.value.isWorkoutActive || workoutStartTime.value == null)
      return 0;
    return DateTime.now().difference(workoutStartTime.value!).inSeconds;
  }

  String getFormattedElapsedTime() {
    final seconds = getElapsedTimeSeconds();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    locationService.dispose();
    mapController.value?.dispose();
    goalCheckTimer?.cancel();
    _simulationTimer?.cancel();
    super.onClose();
  }

  void forceMapUpdate() {
    if (workoutData.value.currentPosition != null && mapController.value != null) {
      // Usar animateCamera con duración corta para mayor rendimiento
      mapController.value!.moveCamera(
        CameraUpdate.newLatLng(workoutData.value.currentPosition!),
      );
      
      // Actualizar polylines solo si hay cambios reales
      if (workoutData.value.polylineCoordinates.isNotEmpty && 
          (workoutData.value.polylines.isEmpty || workoutData.value.polylines.length < 2)) {
        workoutData.update((val) {
          val?.updatePolyline();
        });
      }
      
      workoutData.refresh();
    } else {
      getCurrentLocationAndAnimateCamera();
    }
  }

  void setupPeriodicMapUpdates() {
    // Reducir frecuencia a cada 15 segundos
    Timer.periodic(Duration(seconds: 15), (timer) {
      if (!workoutData.value.isWorkoutActive) {
        timer.cancel();
        return;
      }
      
      logger.d("🔄 Forzando actualización periódica del mapa");
      forceMapUpdate();
    });
  }

  void logWorkoutStatus({bool detailed = false}) {
    if (!_isDebugMode) return;
    
    logger.d("📊 Estado del entrenamiento:");
    logger.d("  🏃‍♂️ Activo: ${workoutData.value.isWorkoutActive}");
    logger.d("  📍 Posición actual: ${workoutData.value.currentPosition}");
    logger.d("  📏 Distancia: ${workoutData.value.distanceMeters} metros");
    logger.d("  ⏱️ Tiempo: ${getFormattedElapsedTime()}");
    logger.d("  🛣️ Puntos en ruta: ${workoutData.value.polylineCoordinates.length}");
    
    if (detailed) {
      logger.d("  🧮 Detalles de cálculos:");
      logger.d("    🚶‍♂️ Velocidad: ${workoutData.value.speedMetersPerSecond} m/s");
      logger.d("    ⏲️ Ritmo: ${workoutData.value.getPaceFormatted()} min/km");
      if (workoutData.value.previousPosition != null) {
        logger.d("    📌 Precisión GPS: ${workoutData.value.previousPosition!.accuracy}m");
      }
      if (workoutData.value.goal != null) {
        logger.d("    🎯 Objetivo: ${workoutData.value.goal!.targetDistanceKm} km");
        logger.d("    ✅ Completado: ${workoutData.value.goal!.isCompleted}");
      }
    }
  }

  // Método para actualizar la vista del mapa según la posición actual
  void resetMapView() {
    if (workoutData.value.currentPosition != null && mapController.value != null) {
      print("🗺️ Actualizando vista del mapa a posición actual");
      
      // Crear los límites para la cámara
      mapController.value!.animateCamera(
        CameraUpdate.newLatLngZoom(
          workoutData.value.currentPosition!,
          17.0,
        ),
      );
      
      workoutData.refresh();
    } else {
      logger.d("⚠️ No se puede actualizar el mapa: posición actual nula");
      
      // Intentar obtener la posición actual
      getCurrentLocationAndAnimateCamera().then((_) {
        if (workoutData.value.currentPosition != null) {
          // Si ahora tenemos posición, intentar actualizar de nuevo
          resetMapView();
        } else {
          // Informar al usuario que no se puede obtener la ubicación
          Get.snackbar(
            'Ubicación no disponible',
            'Esperando señal GPS...',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: Duration(seconds: 2),
          );
        }
      });
    }
  }

  // Método para reiniciar el mapa si es necesario (después de un cambio en el ciclo de vida)
  void resetMapIfNeeded() {
    print("🗺️ Verificando si es necesario reiniciar el mapa");
    
    // Si el controlador del mapa existe, intentar actualizar la vista
    if (mapController.value != null) {
      // Pequeña pausa para que el mapa se cargue completamente
      Future.delayed(Duration(milliseconds: 300), () {
        resetMapView();
        
        // También actualizamos los datos
        refreshLocationData();
      });
    } else {
      print("⚠️ No se puede reiniciar el mapa: controlador nulo");
    }
  }

  // Método para actualizar los datos de ubicación
  void refreshLocationData() {
    print("🗺️ Actualizando datos de ubicación");
    
    // Solo si el servicio de ubicación existe
    if (locationService != null) {
      // Reiniciar las actualizaciones de ubicación
      locationService.startLocationUpdates();
      
      // Como no tenemos un método para solicitar una actualización única,
      // simplemente esperamos a que llegue la próxima actualización
      print("🗺️ Esperando próxima actualización de ubicación...");
    }
  }

  String getGpsQualityIndicator() {
    if (workoutData.value.previousPosition == null) return "⚪"; // Sin datos
    
    double accuracy = workoutData.value.previousPosition!.accuracy;
    
    if (accuracy <= 10) return "🟢"; // Excelente
    if (accuracy <= 20) return "🟡"; // Buena
    if (accuracy <= 40) return "🟠"; // Regular
    return "🔴"; // Mala
  }

  // Método para simular movimiento en el emulador
  void simulateLocation() {
    if (_isSimulatingLocation) return;
    _isSimulatingLocation = true;
    
    // Posición inicial (puedes ajustarla a una posición realista)
    final initialLat = 20.651464;
    final initialLng = -103.392958;
    
    // Simular posición inicial
    final initialPosition = LatLng(initialLat, initialLng);
    workoutData.update((val) {
      val?.currentPosition = initialPosition;
    });
    
    // Forzar actualización inicial
    if (mapController.value != null) {
      mapController.value!.moveCamera(
        CameraUpdate.newLatLngZoom(initialPosition, 17.0)
      );
    }
    
    // Simular movimiento cada 2 segundos
    _simulationTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      // Solo simular si el entrenamiento está activo
      if (!workoutData.value.isWorkoutActive) {
        return;
      }
      
      // Obtener última posición
      final lastPosition = workoutData.value.currentPosition!;
      
      // Generar un pequeño desplazamiento (unos 10-20 metros)
      final newLat = lastPosition.latitude + (0.0001 * (0.5 + 0.5 * Random().nextDouble()));
      final newLng = lastPosition.longitude + (0.0001 * (0.5 + 0.5 * Random().nextDouble()));
      
      // Crear nueva posición
      final newPosition = LatLng(newLat, newLng);
      
      // Crear posición con datos completos para la actualización de métricas
      final position = Position(
        latitude: newLat,
        longitude: newLng,
        timestamp: DateTime.now(),
        accuracy: 8.0, // Buena precisión simulada
        altitude: 0,
        heading: 0,
        speed: 2.0, // ~7.2 km/h
        speedAccuracy: 1.0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      
      // Simular actualización
      _handleLocationUpdate(newPosition);
      _handleMetricsUpdate(position);
      
      logger.d("🔮 Posición simulada: $newPosition");
    });
    
    // Mostrar indicador
    Get.snackbar(
      'Modo de simulación',
      'Usando ubicaciones simuladas para pruebas',
      backgroundColor: Colors.purple.withAlpha(179),
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }

  // Método para centrar el mapa en el recorrido
  void centerMapOnRoute() {
    if (workoutData.value.polylineCoordinates.isEmpty ||
        mapController.value == null) {
      return;
    }

    // Crear un bounds que incluya todos los puntos del recorrido
    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;

    for (LatLng point in workoutData.value.polylineCoordinates) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Definir el padding (en píxeles) para cada lado del mapa
    // Ajusta estos valores según el tamaño de tus paneles
    const double topPadding = 60.0;    // Espacio para AppBar
    const double bottomPadding = 220.0; // Espacio estimado para panel de información
    const double sidePadding = 20.0;

    try {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      // Centrar el mapa con padding
      mapController.value!.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          sidePadding, // Padding general
        ),
      );
    } catch (e) {
      logger.e("❌ Error al centrar el mapa en la ruta: $e");

      // Si hay un error, intentar un enfoque más simple
      if (workoutData.value.polylineCoordinates.isNotEmpty) {
        final center = workoutData.value.polylineCoordinates[
            workoutData.value.polylineCoordinates.length ~/ 2];
        mapController.value!.animateCamera(
          CameraUpdate.newLatLngZoom(center, 15),
        );
      }
    }
  }

  // Añadir un método de precarga del mapa para acelerar la inicialización
  void preloadMapResources() {
    // Este método debería llamarse desde onInit()
    
    // Precalcular algunos valores comunes
    final initialPosition = workoutData.value.currentPosition ?? LatLng(20.651464, -103.392958);
    
    // Preparar polylines con un conjunto vacío pero ya inicializado
    workoutData.update((val) {
      if (val?.polylines.isEmpty == true) {
        // Inicializar con un conjunto vacío pero ya configurado
        val?.polylines.clear();
      }
    });
    
    // Preparar la posición inicial si es posible
    Future.microtask(() async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        workoutData.update((val) {
          val?.currentPosition = LatLng(position.latitude, position.longitude);
        });
      } catch (e) {
        logger.d("⚠️ No se pudo obtener posición inicial: $e");
      }
    });
  }

  // Añadir un método para gestionar estilos del mapa
  void setMapStyle(String styleName) {
    if (mapController.value == null) return;

    String styleJson = "";
    
    switch (styleName) {
      case "running_simple":
        styleJson = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "transit",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  }
]
        ''';
        break;
        
      case "running_detailed":
        styleJson = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "poi.business",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c1e7c1"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c9c9c9"
      }
    ]
  }
]
        ''';
        break;
        
      case "terrain":
        styleJson = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ebe3cd"
      }
    ]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dfd2ae"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#a5b076"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f1e6"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#b9d3c2"
      }
    ]
  }
]
        ''';
        break;
        
      case "night":
        styleJson = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#38414e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#212a37"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  }
]
        ''';
        break;
    }
    
    if (styleJson.isNotEmpty) {
      mapController.value!.setMapStyle(styleJson);
      
      // También actualizamos el color de las polilíneas según el estilo
      if (styleName == "night") {
        workoutData.update((val) {
          val?.updatePolyline(primaryColor: Colors.cyan, outlineColor: Colors.white);
        });
      } else {
        workoutData.update((val) {
          val?.updatePolyline(); // Usar colores por defecto
        });
      }
    }
  }
}
