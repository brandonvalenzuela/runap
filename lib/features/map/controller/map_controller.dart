// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math' as math; // Import math library
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:runap/features/map/services/location_service.dart';
import 'location_permission_controller.dart';
import 'package:logger/logger.dart';
import 'workout_controller.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';
import 'package:runap/features/map/models/workout_data.dart';
import 'package:runap/features/map/models/workout_goal.dart';

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

  // Variables observables (UI state for map view)
  final RxBool isLoading = true.obs;

  // Controllers Delegados
  final LocationPermissionController permissionController = Get.find<LocationPermissionController>();
  final WorkoutController workoutController = Get.find<WorkoutController>();

  // Servicios y helpers (Solo los que usa directamente MapController)
  late LocationService locationService;

  // Controlador del mapa de Google
  final Rxn<GoogleMapController> mapController = Rxn<GoogleMapController>();

  // Variables de control (map view)
  Timer? _periodicMapUpdateTimer;
  Position? lastKnownPosition; // Keep track of last position for initial simulation/centering

  // Variables para la simulación
  Timer? _simulationTimer;
  double _currentSimulationSpeedMps = 1.4; // Default: walking speed m/s
  double _currentSimulationBearing = 0.0;  // Current direction degrees
  bool _isFirstSimulationStep = true;
  final Duration _simulationInterval = const Duration(seconds: 1); // How often to simulate

  // Añadir un flag para controlar el logging
  final bool _isDebugMode = false; // Cambiar a false en producción

  // Constructor (simplificado)
  MapController();

  @override
  void onInit() {
    super.onInit();
    locationService = LocationService(
      onLocationUpdate: (_) {}, // Assuming these are handled by WorkoutController now
      onMetricsUpdate: (_) {},
    );
    Future.microtask(() => initialize());

    // --- ADDED REACTIVE LISTENER ---
    // Listen for changes in the permission status
    ever<LocationPermissionStatus>(permissionController.permissionStatus, (status) {
      logger.i("MapController: Permission status changed to: $status");
      if (status == LocationPermissionStatus.granted) {
        logger.i("MapController: Permission granted! Attempting to get location and center map...");
        // Use a small delay to ensure map controller might be ready if this happens early
        Future.delayed(const Duration(milliseconds: 100), () {
           getCurrentLocationAndAnimateCamera();
        });
      }
      // Optionally handle other statuses if needed (e.g., show error if denied again)
    });
    // --- END OF ADDED LISTENER ---

    // --- MODIFIED LISTENER (Keep existing listener for workout state) ---
    bool wasWorkoutActive = workoutController.workoutData.value.isWorkoutActive;
    ever<WorkoutData>(workoutController.workoutData, (WorkoutData workoutData) {
      // Update map based on workout state changes
      _updateMapCameraBasedOnWorkoutState(workoutData, wasWorkoutActive);
      // Update the previous state for the next change detection
      wasWorkoutActive = workoutData.isWorkoutActive;
    });
    // --- END OF MODIFIED LISTENER ---
  }

  // Renamed method to be more descriptive and receive previous state
  void _updateMapCameraBasedOnWorkoutState(WorkoutData currentWorkoutData, bool wasActive) {
     if (currentWorkoutData.isWorkoutActive) {
         // Workout is active: follow user position
         if (currentWorkoutData.currentPosition != null && mapController.value != null) {
             mapController.value!.animateCamera(
                  CameraUpdate.newLatLng(currentWorkoutData.currentPosition!),
             );
         }
     } else if (wasActive && !currentWorkoutData.isWorkoutActive) {
         // Workout JUST ended (was active, now is not): Zoom to route
         logger.d("Workout ended. Zooming to route bounds...");
         final routePoints = currentWorkoutData.polylineCoordinates;
         if (routePoints.length > 1 && mapController.value != null) { // Need at least 2 points for bounds
            final bounds = _calculateBounds(routePoints);
            if (bounds != null) {
               // Use a slight delay to ensure map is ready after state changes
               Future.delayed(const Duration(milliseconds: 500), () {
                 try {
                    mapController.value?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60.0)); // Add padding
                 } catch (e) { // Catch potential errors if map disposed etc.
                    logger.e("Error animating camera to bounds: $e");
                 }
               });
          } else {
               logger.w("Could not calculate bounds for the route.");
            }
        } else {
            logger.d("Not zooming to bounds: No route or map controller not ready.");
         }
     } 
     // If workout is not active and wasn't active before, do nothing with the camera automatically.
  }

  // --- ADDED HELPER TO CALCULATE BOUNDS ---
  LatLngBounds? _calculateBounds(List<LatLng> points) {
    if (points.isEmpty) return null;
    if (points.length == 1) {
       // Handle single point case: maybe zoom slightly?
       // For now, return null as bounds require two points.
       return null; 
    }
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Add small tolerance to avoid issues with points exactly on the boundary
    minLat -= 0.0001;
    maxLat += 0.0001;
    minLng -= 0.0001;
    maxLng += 0.0001;
    
    // Ensure northeast lat is greater than southwest lat
    if (minLat > maxLat) { 
       final temp = minLat;
       minLat = maxLat;
       maxLat = temp;
    }
    // Ensure northeast lon is greater than southwest lon
     if (minLng > maxLng) { 
       final temp = minLng;
       minLng = maxLng;
       maxLng = temp;
    }

    // Check for invalid bounds (e.g., all points identical)
    if (minLat == maxLat && minLng == maxLng && points.length > 1) { 
       // All points are the same, create a small bound around the point
        const delta = 0.001; // Adjust as needed
        return LatLngBounds(
          southwest: LatLng(minLat - delta, minLng - delta),
          northeast: LatLng(maxLat + delta, maxLng + delta),
        );
    }
    
    try {
        return LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );
    } catch (e) {
       logger.e("Error creating LatLngBounds: $e - minLat:$minLat, maxLat:$maxLat, minLng:$minLng, maxLng:$maxLng");
       return null;
    }
  }
  // --- END OF HELPER --- 

  Future<void> initialize() async {
    isLoading.value = true;
    try {
      // Check initial status but don't request here, let the listener handle reaction
      await permissionController.checkPermissions(requestIfNeeded: false);
      if (permissionController.permissionStatus.value != LocationPermissionStatus.granted) {
         logger.i("MapController.initialize: Permission not granted initially. Waiting for status change or dialog interaction.");
         // Don't show dialog here directly, permission controller handles that if needed
         // permissionController.showPermissionDialogIfNeeded(); // Removed - Let permission controller manage dialogs
         // ADDED BACK: Show dialog if permissions aren't granted on init
         permissionController.showPermissionDialogIfNeeded();
         isLoading.value = false; // Still need to stop loading indicator
         return;
      }
      // If granted initially, proceed to get location
      logger.i("MapController.initialize: Permission granted initially. Getting location.");
      await getCurrentLocationAndAnimateCamera();
    } catch (e) {
      logger.e('Error en inicialización: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getCurrentLocationAndAnimateCamera() async {
    // Add check if mapController is ready
    if (mapController.value == null) {
       logger.w("getCurrentLocationAndAnimateCamera: Map controller not ready yet.");
       return; // Don't proceed if map isn't ready
    }

    if (permissionController.permissionStatus.value != LocationPermissionStatus.granted) {
       logger.w("getCurrentLocationAndAnimateCamera: Permission not granted.");
       // Don't show dialog here, listener or initial check should handle it.
       // permissionController.showPermissionDialogIfNeeded(); // Removed
       return;
    }
    logger.i("getCurrentLocationAndAnimateCamera: Permission granted. Fetching location...");
    try {
      Position position = await locationService.getCurrentPosition();
      lastKnownPosition = position; // Store the position
      LatLng latLng = LatLng(position.latitude, position.longitude);
      logger.i("getCurrentLocationAndAnimateCamera: Location obtained: $latLng. Animating camera.");
      if (mapController.value != null) { // Double check mapController is still valid
        mapController.value!.animateCamera( // Use animate for smooth initial centering
          CameraUpdate.newLatLngZoom(latLng, 17.0),
        );
      }
    } catch (e) {
      logger.e('Error al obtener la ubicación: $e');
      // Consider showing a snackbar error here?
      // Get.snackbar('Error', 'No se pudo obtener la ubicación actual.');
    }
  }

  Future<bool> checkGpsStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'GPS desactivado',
        'Por favor activa el GPS para un mejor seguimiento',
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
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
      lastKnownPosition = position; // Update last known position
      if (position.accuracy > 50) {
        Get.snackbar(
          'Señal GPS débil',
          'La precisión actual es baja (${position.accuracy.toStringAsFixed(1)}m). Intenta en un área abierta.',
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        );
      }
      return true;
    } catch (e) {
      logger.w("⚠️ Error al verificar GPS: $e");
      return false;
    }
  }

  void setMapControllerInstance(GoogleMapController controller) {
    mapController.value = controller;
    logger.d("🗺️ MapController - Controlador de mapa inicializado");
    setMapStyle("minimalist_streets"); 
    // Keep this call - ensures centering happens if permission was already granted
    // before listener fired, or as a final check once map is ready.
    Future.microtask(() {
       logger.d("MapController.setMapControllerInstance: Calling getCurrentLocationAndAnimateCamera.");
       getCurrentLocationAndAnimateCamera();
    });
  }

  void resetMapView() {
    if (mapController.value == null) return;
    if (workoutController.workoutData.value.currentPosition != null) {
      mapController.value!.animateCamera(
        CameraUpdate.newLatLngZoom(workoutController.workoutData.value.currentPosition!, 17.0),
      );
    } else if (lastKnownPosition != null) { 
       mapController.value!.animateCamera(
         CameraUpdate.newLatLngZoom(LatLng(lastKnownPosition!.latitude, lastKnownPosition!.longitude), 17.0),
       );
      } else {
      getCurrentLocationAndAnimateCamera();
    }
  }

  void setMapStyle(String styleName) {
    if (mapController.value == null) return;
    String styleJson = "";
    
    switch (styleName) {
      case "minimalist_streets": 
        styleJson = '''
[
  { "elementType": "geometry", "stylers": [{ "color": "#f5f5f5" }] },
  { "elementType": "labels.icon", "stylers": [{ "visibility": "off" }] },
  { "elementType": "labels.text.fill", "stylers": [{ "color": "#616161" }] },
  { "elementType": "labels.text.stroke", "stylers": [{ "color": "#f5f5f5" }] },
  { "featureType": "administrative", "elementType": "geometry", "stylers": [{ "visibility": "off" }] },
  { "featureType": "administrative.land_parcel", "stylers": [{ "visibility": "off" }] },
  { "featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{ "color": "#bdbdbd" }] },
  { "featureType": "administrative.neighborhood", "stylers": [{ "visibility": "off" }] },
  { "featureType": "landscape", "stylers": [{ "visibility": "off" }] }, 
  { "featureType": "poi", "elementType": "all", "stylers": [{ "visibility": "off" }] }, 
  { "featureType": "poi.park", "elementType": "geometry", "stylers": [{ "visibility": "on" }, { "color": "#e5e5e5" }] }, 
  { "featureType": "poi.park", "elementType": "labels.text", "stylers": [{ "visibility": "on" }] }, 
  { "featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{ "color": "#9e9e9e" }] }, 
  { "featureType": "road", "elementType": "geometry", "stylers": [{ "color": "#ffffff" }] },
  { "featureType": "road.arterial", "elementType": "labels", "stylers": [{ "visibility": "on" }] }, 
  { "featureType": "road.arterial", "elementType": "labels.text.fill", "stylers": [{ "color": "#757575" }] },
  { "featureType": "road.highway", "elementType": "geometry", "stylers": [{ "color": "#dadada" }] },
  { "featureType": "road.highway", "elementType": "labels", "stylers": [{ "visibility": "on" }] }, 
  { "featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{ "color": "#616161" }] },
  { "featureType": "road.local", "elementType": "labels", "stylers": [{ "visibility": "on" }] }, 
  { "featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{ "color": "#9e9e9e" }] },
  { "featureType": "transit", "elementType": "all", "stylers": [{ "visibility": "off" }] }, 
  { "featureType": "water", "elementType": "geometry", "stylers": [{ "color": "#c9c9c9" }] },
  { "featureType": "water", "elementType": "labels.text.fill", "stylers": [{ "color": "#9e9e9e" }] }
]
        ''';
        break;
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
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "administrative.neighborhood",
    "stylers": [
      {
        "visibility": "simplified"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.attraction",
    "stylers": [
      {
        "visibility": "off"
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
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
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
    "featureType": "road.arterial",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels",
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
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
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
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
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
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "administrative.neighborhood",
    "stylers": [
      {
        "visibility": "simplified"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.attraction",
    "stylers": [
      {
        "visibility": "off"
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
    "featureType": "poi.government",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.medical",
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
    "featureType": "poi.park",
    "elementType": "labels.text",
    "stylers": [
      {
        "visibility": "simplified"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "poi.place_of_worship",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.school",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.sports_complex",
    "stylers": [
      {
        "visibility": "simplified"
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
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
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
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
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
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
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
        "color": "#ffffff"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#cfcfcf"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#efefef"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
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
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
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
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
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
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#263c3f"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#6b9a76"
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
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9ca5b3"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1f2835"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#f3d19c"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#2f3948"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
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
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#515c6d"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
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
      if (styleName == "night") {
          workoutController.workoutData.update((val) {
          val?.updatePolyline(primaryColor: Colors.cyan, outlineColor: Colors.white);
        });
      } else {
          Color polylinePrimary = styleName == "minimalist_streets" ? Colors.blue.shade700 : TColors.primaryColor; 
          Color polylineOutline = styleName == "minimalist_streets" ? Colors.white : TColors.primaryColor.withAlpha(80);
          workoutController.workoutData.update((val) {
            val?.updatePolyline(primaryColor: polylinePrimary, outlineColor: polylineOutline); 
          });
      }
      logger.d("🎨 Estilo de mapa '$styleName' aplicado."); 
    } else {
      logger.w("⚠️ Estilo de mapa '$styleName' no encontrado."); 
    }
  }

  // --- SIMULATION CONTROL METHODS ---

  void startSimulation() {
    if (_simulationTimer != null && _simulationTimer!.isActive) {
      logger.w("Simulation already running.");
      return;
    }
    
    logger.i("▶️ Iniciando simulación...");
    workoutController.pauseRealLocationUpdates(); // Pausar GPS real

    // Determinar velocidad basada en el objetivo actual
    final goal = workoutController.workoutData.value.goal;
    if (goal?.targetPaceMinutesPerKm != null && goal!.targetPaceMinutesPerKm! > 0) {
      _currentSimulationSpeedMps = 1000.0 / (goal.targetPaceMinutesPerKm! * 60.0);
      logger.d("🎯 Velocidad de simulación basada en objetivo: ${_currentSimulationSpeedMps.toStringAsFixed(2)} m/s (Ritmo ${goal.targetPaceMinutesPerKm!.toStringAsFixed(2)} min/km)");
    } else {
      _currentSimulationSpeedMps = 1.4; // Usar velocidad de caminata por defecto
      logger.d("🚶‍♀️ Usando velocidad de simulación por defecto (caminata): ${_currentSimulationSpeedMps} m/s");
    }

    _isFirstSimulationStep = true; // Resetear para la nueva simulación

    // Cancelar timer anterior por si acaso
    _simulationTimer?.cancel();

    // Iniciar nuevo timer
    _simulationTimer = Timer.periodic(_simulationInterval, _simulateMovement);

    logger.d("⏱️ Timer de simulación iniciado (intervalo: ${_simulationInterval.inSeconds}s)");
  }

  void stopSimulation() {
    if (_simulationTimer == null || !_simulationTimer!.isActive) {
       logger.w("Simulation not running or already stopped.");
       return;
    }
    logger.i("⏹️ Deteniendo simulación...");
    _simulationTimer?.cancel();
    _simulationTimer = null;
    workoutController.resumeRealLocationUpdates(); // Reanudar GPS real
    logger.d("✅ Simulación detenida y GPS real reanudado.");
  }

  // --- SIMULATION MOVEMENT LOGIC (Refactored) ---
  void _simulateMovement(Timer timer) {
    // 1. Obtener la última posición conocida del WorkoutController
    LatLng? lastPos = workoutController.workoutData.value.currentPosition;
    double lastAltitude = workoutController.workoutData.value.previousPosition?.altitude ?? 0.0;

    // Usar la posición conocida por MapController como fallback si WorkoutController no tiene una
    if (lastPos == null && lastKnownPosition != null) {
       lastPos = LatLng(lastKnownPosition!.latitude, lastKnownPosition!.longitude);
       lastAltitude = lastKnownPosition!.altitude;
    } 
    
    // Si aún no hay posición, no se puede simular
    if (lastPos == null) {
      logger.e("Error de simulación: No se puede obtener la posición inicial.");
      stopSimulation();
      return;
    }

    // 2. Establecer o actualizar la dirección (bearing)
    if (_isFirstSimulationStep) {
      // Elegir una dirección aleatoria inicial
      _currentSimulationBearing = math.Random().nextDouble() * 360.0;
      _isFirstSimulationStep = false;
      logger.d("(Simulate) Primera ejecución, Dirección inicial: ${_currentSimulationBearing.toStringAsFixed(1)}°");
    } else {
      // Añadir una pequeña variación aleatoria a la dirección para simular cambios
      // Ajustar el multiplicador (e.g., 10) para más o menos variación por segundo
      double bearingChange = (math.Random().nextDouble() - 0.5) * 10.0; 
      _currentSimulationBearing += bearingChange;
      // Normalizar bearing a [0, 360)
      _currentSimulationBearing = (_currentSimulationBearing % 360.0 + 360.0) % 360.0;
      // logger.d("(Simulate) Cambio de dirección: ${bearingChange.toStringAsFixed(1)}°, Nueva: ${_currentSimulationBearing.toStringAsFixed(1)}°");
    }

    // 3. Calcular distancia a mover en este intervalo
    double distanceMoved = _currentSimulationSpeedMps * _simulationInterval.inSeconds;

    // 4. Calcular el nuevo punto geográfico
    LatLng nextPosition = _calculateDestinationPoint(lastPos, _currentSimulationBearing, distanceMoved);

    // 5. Crear un objeto Position simulado completo
    final now = DateTime.now();
    final simulatedPosition = Position(
      latitude: nextPosition.latitude,
      longitude: nextPosition.longitude,
      timestamp: now,
      accuracy: 5.0, // Precisión simulada razonable
      altitude: lastAltitude, // Mantener altitud anterior (simulación simple)
      altitudeAccuracy: 10.0,
      heading: _currentSimulationBearing, // Dirección simulada actual
      headingAccuracy: 5.0, // Precisión de dirección simulada
      speed: _currentSimulationSpeedMps, // Velocidad simulada actual
      speedAccuracy: 0.5, // Precisión de velocidad simulada
    );

    // 6. Notificar al WorkoutController con los nuevos datos
    // Usar Future.microtask para evitar posibles problemas de estado durante el build/frame
    Future.microtask(() {
        workoutController.handleLocationUpdate(nextPosition);
        workoutController.handleMetricsUpdate(simulatedPosition);
        // logger.d("(Simulate) Nueva Pos: ${nextPosition.latitude.toStringAsFixed(5)}, ${nextPosition.longitude.toStringAsFixed(5)}");
    });
  }
  
  // --- HELPER FUNCTION (IMPLEMENTED) --- 
  LatLng _calculateDestinationPoint(LatLng start, double bearing, double distanceMeters) {
    const double earthRadiusMeters = 6371000.0;
    
    // Convertir lat/lon a radianes
    double lat1Rad = start.latitude * (math.pi / 180.0);
    double lon1Rad = start.longitude * (math.pi / 180.0);
    // Convertir rumbo a radianes
    double bearingRad = bearing * (math.pi / 180.0);
    // Distancia angular
    double angularDistance = distanceMeters / earthRadiusMeters;

    // Calcular nueva latitud
    double lat2Rad = math.asin(math.sin(lat1Rad) * math.cos(angularDistance) +
                           math.cos(lat1Rad) * math.sin(angularDistance) * math.cos(bearingRad));

    // Calcular nueva longitud
    double lon2Rad = lon1Rad + math.atan2(math.sin(bearingRad) * math.sin(angularDistance) * math.cos(lat1Rad),
                                     math.cos(angularDistance) - math.sin(lat1Rad) * math.sin(lat2Rad));

    // Convertir de nuevo a grados
    double lat2Deg = lat2Rad * (180.0 / math.pi);
    double lon2Deg = lon2Rad * (180.0 / math.pi);

    // Normalizar longitud a [-180, 180]
    lon2Deg = (lon2Deg + 540.0) % 360.0 - 180.0;

    return LatLng(lat2Deg, lon2Deg);
  }

  @override
  void onClose() {
    _periodicMapUpdateTimer?.cancel(); // Cancel timer when controller is closed
    mapController.value?.dispose();    // Dispose GoogleMapController if exists
    super.onClose();
  }
}
