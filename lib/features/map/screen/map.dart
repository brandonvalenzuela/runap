// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';
import 'package:runap/features/map/controller/map_controller.dart';
import 'package:runap/features/map/controller/workout_controller.dart';
import 'package:runap/features/map/controller/goal_controller.dart';
import 'package:runap/features/map/models/workout_goal.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/utils/helpers/helper_functions.dart';
import 'package:runap/utils/validators/validation.dart';
import 'package:runap/features/map/controller/location_permission_controller.dart';

class MapScreen extends StatefulWidget {
  final WorkoutGoal? initialWorkoutGoal;
  final Session? sessionToUpdate;
  final Function? onMapInitialized;
  
  // Añadir GlobalKey para medir el panel de información
  final GlobalKey infoPanelKey = GlobalKey();

  MapScreen({
    super.key,
    this.initialWorkoutGoal,
    this.sessionToUpdate,
    this.onMapInitialized,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late MapController mapController;
  late WorkoutController workoutController;
  late GoalController goalController;
  bool _isSimulating = false;
  Timer? _simulationTimer;
  Position? _lastSimulatedPosition;
  double _simulatedBearing = 0.0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    mapController = Get.find<MapController>();
    workoutController = Get.find<WorkoutController>();
    goalController = Get.find<GoalController>();
    
    workoutController.initializeWithSession(widget.sessionToUpdate);
    
    _initializeSimulationPosition();

    bool wasActive = workoutController.workoutData.value.isWorkoutActive;
    ever(workoutController.workoutData, (callback) {
      final bool isActive = workoutController.workoutData.value.isWorkoutActive;
      if (wasActive && !isActive) {
        // Workout just finished
        // Capture data *immediately* after state change, before reset might fully complete
        final data = workoutController.workoutData.value; 
        final duration = workoutController.workoutStartTime.value != null 
            ? DateTime.now().difference(workoutController.workoutStartTime.value!) 
            : Duration.zero;

        // Ensure data is valid before showing dialog
        if (data.distanceMeters > 0 || duration > Duration.zero) { 
            final completionInfo = WorkoutCompletionInfo(
               hadGoal: data.goal != null,
               goalAchieved: data.goal?.isCompleted ?? false, 
               distanceMeters: data.distanceMeters,
               duration: duration,
               averagePaceMinutesPerKm: data.averagePaceMinutesPerKm
            );
            print("Workout finished, showing completion dialog.");
            // Use addPostFrameCallback to ensure build context is ready
            WidgetsBinding.instance.addPostFrameCallback((_) { 
               if (mounted) { // Check if widget is still in the tree
                  _showCompletionDialog(completionInfo);
               }
            });
        } else {
           print("Workout finished but data seems invalid, not showing dialog.");
        }
      }
      wasActive = isActive; // Update state for next check
    });

    if (widget.onMapInitialized != null) {
        widget.onMapInitialized!();
    }
    print("🗺️ MapScreen - InitState");
  }
  
  @override
  void dispose() {
    _simulationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // No eliminar controladores si son globales (gestionados por AppBindings con lazyPut/put permanent)
    // Get.delete<MapController>(); // Solo si fue puesto localmente en esta pantalla con Get.put
    // Get.delete<WorkoutController>(); // WorkoutController es global via AppBindings

    print("🗺️ MapScreen - Dispose");
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("🗺️ MapScreen - AppLifecycleState: $state");
    if (state == AppLifecycleState.resumed) {
      // Al volver a la app, asegurarse de que el mapa esté centrado y actualizado
      print("🗺️ MapScreen - App resumed - Checking map state...");
      // Consider checking permissions again or other updates if needed
      // mapController.checkGpsStatus(); // Example
    } else if (state == AppLifecycleState.paused) {
      // App is going to background
      print("🗺️ MapScreen - App paused");
      // Stop simulation if running? 
      // if (_isSimulating) { _toggleSimulation(); }
    }
  }

  Future<void> _initializeSimulationPosition() async {
    Position? initialPos;
    final currentLatLng = workoutController.workoutData.value.currentPosition;
    if (currentLatLng != null) {
      initialPos = Position(
          latitude: currentLatLng.latitude,
          longitude: currentLatLng.longitude,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 10.0,
          heading: 0.0,
          headingAccuracy: 10.0,
          speed: 0.0,
          speedAccuracy: 0.0);
    }
    if (initialPos == null) {
       try {
          initialPos = await mapController.locationService.getCurrentPosition();
       } catch (e) {
          print("Error getting initial position for simulation: $e");
       }
    }
    _lastSimulatedPosition = initialPos ?? Position(
        latitude: 40.416775,
        longitude: -3.703790,
        timestamp: DateTime.now(),
        accuracy: 50.0,
        altitude: 0.0,
        altitudeAccuracy: 50.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0);
     print("🗺️ MapScreen - Initial simulation position set: ${_lastSimulatedPosition?.latitude}, ${_lastSimulatedPosition?.longitude}");
  }

  void _toggleSimulation() async {
    if (_isSimulating) {
      _simulationTimer?.cancel();
      _simulationTimer = null;
      _lastSimulatedPosition = null;
      setState(() {
        _isSimulating = false;
      });
      print("🛑 Simulation Stopped");
      workoutController.resumeRealLocationUpdates();
      workoutController.setSimulationMode(false);
    } else {
      if (workoutController.workoutData.value.isWorkoutActive == false) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Inicia un entrenamiento para simular la ubicación."))
         );
         return;
      }

      workoutController.pauseRealLocationUpdates();

      // Get the VERY LATEST known position before starting simulation
      LatLng? currentPosition = workoutController.workoutData.value.currentPosition;
      if (currentPosition == null && mapController.lastKnownPosition != null) {
          currentPosition = LatLng(mapController.lastKnownPosition!.latitude, mapController.lastKnownPosition!.longitude);
      }

      // If still no position, try to fetch it one last time (might happen if map opened without location)
      if (currentPosition == null) {
          print("SimToggle: Last known position is null, attempting to fetch current...");
          try {
            final pos = await mapController.locationService.getCurrentPosition();
            currentPosition = LatLng(pos.latitude, pos.longitude);
            mapController.lastKnownPosition = pos; // Update MapController's knowledge too
          } catch (e) {
             print("SimToggle: Cannot start simulation: Failed to get current position: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No se pudo obtener ubicación actual para simular."))
              );
              workoutController.resumeRealLocationUpdates();
              return;
          }
      }
      
      // Update the simulation starting point
      _lastSimulatedPosition = Position(
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: workoutController.workoutData.value.previousPosition?.altitude ?? mapController.lastKnownPosition?.altitude ?? 0.0,
        altitudeAccuracy: 10.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0
      );
      
      print("▶️ Starting Simulation from ACTUAL: ${_lastSimulatedPosition?.latitude}, ${_lastSimulatedPosition?.longitude}");

      // Reset workout controller's route state with this starting position
      workoutController.resetRouteStateForSimulation(currentPosition);
      workoutController.setSimulationMode(true);

      _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_lastSimulatedPosition == null) return; 

        const double metersPerSecond = 5.0;
        const double secondsInterval = 2.0;
        const double distance = metersPerSecond * secondsInterval; 

        _simulatedBearing += (Random().nextDouble() - 0.5) * 10; 
        _simulatedBearing = _simulatedBearing % 360; 

        const double earthRadius = 6371000; 
        final double lat1 = _toRadians(_lastSimulatedPosition!.latitude);
        final double lon1 = _toRadians(_lastSimulatedPosition!.longitude);
        final double bearingRad = _toRadians(_simulatedBearing);

        final double lat2 = asin(sin(lat1) * cos(distance / earthRadius) +
                             cos(lat1) * sin(distance / earthRadius) * cos(bearingRad));
        final double lon2 = lon1 + atan2(sin(bearingRad) * sin(distance / earthRadius) * cos(lat1),
                                      cos(distance / earthRadius) - sin(lat1) * sin(lat2));

        final Position newPosition = Position(
           latitude: _toDegrees(lat2),
           longitude: _toDegrees(lon2),
           timestamp: DateTime.now(),
           accuracy: 5.0 + Random().nextDouble() * 5, 
           altitude: _lastSimulatedPosition!.altitude + (Random().nextDouble() - 0.5), 
           altitudeAccuracy: 5.0 + Random().nextDouble() * 5, 
           heading: _simulatedBearing,
           headingAccuracy: 5.0 + Random().nextDouble() * 10, 
           speed: metersPerSecond + (Random().nextDouble() - 0.5), 
           speedAccuracy: 0.5,
        );

        workoutController.handleMetricsUpdate(newPosition); 
        workoutController.handleLocationUpdate(LatLng(newPosition.latitude, newPosition.longitude));
        _lastSimulatedPosition = newPosition; 

      });

      setState(() {
        _isSimulating = true;
      });
    }
  }
  
  double _toRadians(double degrees) => degrees * pi / 180.0;
  double _toDegrees(double radians) => radians * 180.0 / pi;

  @override
  Widget build(BuildContext context) {
    final bool dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, goalController),
      body: Obx(() {
          if (mapController.isLoading.value || goalController.isLoadingGoals.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              Obx(() => GoogleMap(
                key: const ValueKey("google_map"),
                mapType: MapType.normal,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(40.416775, -3.703790), // Madrid as fallback initial center
                  zoom: 14.0,
                ),
                onMapCreated: mapController.setMapControllerInstance,
                // Make myLocationEnabled reactive to permission status
                myLocationEnabled: mapController.permissionController.permissionStatus.value == LocationPermissionStatus.granted,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                polylines: workoutController.workoutData.value.polylines,
                markers: const <Marker>{}, // Add markers if needed later
              )),
            Positioned(
                top: TSizes.appBarHeight + TSizes.md,
                left: TSizes.md,
                right: TSizes.md,
                child: _buildTopControls(dark),
              ),
              if (goalController.showGoalSelector.value)
                Positioned.fill(
                  child: _buildGoalSelectionOverlay(dark, goalController),
                ),
            ],
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleSimulation,
        tooltip: _isSimulating ? 'Detener Simulación' : 'Iniciar Simulación',
        child: Icon(_isSimulating ? Icons.stop : Icons.play_arrow),
      ),
      bottomNavigationBar: Obx(() => goalController.showGoalSelector.value 
          ? const SizedBox.shrink() 
          : _buildBottomInfoPanel(workoutController)),
    );
  }

  AppBar _buildAppBar(BuildContext context, GoalController goalCtrl) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.back(),
      ),
      title: Obx(() => Text(workoutController.sessionToUpdate.value?.workoutName ?? 'Entrenamiento')),
      actions: [
        Obx(() => IconButton(
              icon: Icon(goalCtrl.showGoalSelector.value ? Icons.close : Icons.flag_outlined),
              onPressed: goalCtrl.toggleGoalSelector,
            )),
      ],
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _buildTopControls(bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: mapController.resetMapView, icon: const Icon(Icons.my_location)),
        ],
      ),
    );
  }

  Widget _buildGoalSelectionOverlay(bool dark, GoalController goalCtrl) {
    return Container(
      color: dark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.9),
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Center(
        child: Material(
           color: Colors.transparent,
        child: Container(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
          decoration: BoxDecoration(
                 color: dark ? TColors.darkerGrey : Colors.white,
                 borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                  const Text("Seleccionar Objetivo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Obx(() {
                    if (goalCtrl.isLoadingGoals.value) {
                       return const Center(child: CircularProgressIndicator());
                    }
                    if (goalCtrl.availableGoals.isEmpty) {
                       return const Text("No hay objetivos disponibles.");
                    }
                    return ListView.builder(
                           shrinkWrap: true,
                           itemCount: goalCtrl.availableGoals.length,
                           itemBuilder: (context, index) {
                              final goal = goalCtrl.availableGoals[index];
                              final bool isSelected = workoutController.workoutData.value.goal == goal;
                              return ListTile(
                                 leading: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined,
                                                color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
                                 title: Text('${goal.formattedTargetDistance} km en ${goal.targetTimeMinutes} min'),
                                 onTap: () => goalCtrl.selectGoal(goal),
                                 tileColor: isSelected ? Theme.of(context).primaryColor.withAlpha(30) : null,
                              );
                           }
                       );
                    }
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  TextButton(onPressed: goalCtrl.toggleGoalSelector, child: const Text("Cerrar")),
                ],
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfoPanel(WorkoutController workoutCtrl) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [ BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)) ]
      ),
      child: Obx(() => Column(
        mainAxisSize: MainAxisSize.min,
              children: [
             Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _buildMetricDisplay("Distancia", "${(workoutCtrl.workoutData.value.distanceMeters / 1000).toStringAsFixed(2)} km"),
                _buildMetricDisplay("Tiempo", workoutCtrl.getFormattedElapsedTime()),
                _buildMetricDisplay("Ritmo", workoutCtrl.workoutData.value.getPaceFormatted()),
             ]),
             const SizedBox(height: TSizes.spaceBtwItems),
             ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: workoutCtrl.workoutData.value.isWorkoutActive ? Colors.red : Theme.of(context).primaryColor,
                      minimumSize: const Size(double.infinity, 50)
                  ),
                  onPressed: workoutCtrl.workoutData.value.isWorkoutActive
                      ? workoutCtrl.stopWorkout
                      : workoutCtrl.startWorkout,
                  child: Text(
                     workoutCtrl.workoutData.value.isWorkoutActive ? 'DETENER' : 'INICIAR',
                     style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
             ),
         ]
      )),
    );
  }

  Widget _buildMetricDisplay(String label, String value) {
     return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
           Text(value, style: Theme.of(context).textTheme.headlineSmall),
           Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
    );
  }

  void _showCompletionDialog(WorkoutCompletionInfo info) {
    Get.dialog(
      AlertDialog(
        title: Text(info.hadGoal && info.goalAchieved ? '¡Objetivo Cumplido!' : 'Entrenamiento Finalizado'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              _buildCompletionMessage(info),
              const SizedBox(height: 16),
              _buildMetricRow('Distancia', "${(info.distanceMeters / 1000).toStringAsFixed(2)} km"),
              _buildMetricRow('Tiempo', "${info.duration.inMinutes}:${(info.duration.inSeconds % 60).toString().padLeft(2, '0')}"),
              _buildMetricRow('Ritmo Prom.', "${info.averagePaceMinutesPerKm.toStringAsFixed(2)} min/km"),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Aceptar'),
            onPressed: () {
              Get.back();
            },
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusLg)),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildCompletionMessage(WorkoutCompletionInfo info) {
    if (info.hadGoal && info.goalAchieved) {
      return const Text('¡Felicidades! Has completado tu objetivo.');
    } else if (info.hadGoal && !info.goalAchieved) {
      return const Text('No alcanzaste tu objetivo, ¡pero completaste el entrenamiento!');
    } else {
      return const Text('Has finalizado tu entrenamiento.');
    }
  }

  Widget _buildMetricRow(String label, String value) {
     return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
              Text(label, style: const TextStyle(color: Colors.black54)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
           ],
      ),
    );
  }
}
