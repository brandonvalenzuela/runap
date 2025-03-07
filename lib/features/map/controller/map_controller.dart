import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:runap/features/map/models/workout_data.dart';
import 'package:runap/features/map/services/location_service.dart';
import 'package:runap/features/map/utils/location_permission_helper.dart';

class MapWorkoutController {
  final WorkoutData workoutData = WorkoutData();
  late LocationService locationService;
  final LocationPermissionHelper permissionHelper = LocationPermissionHelper();
  GoogleMapController? mapController;
  final Function(WorkoutData) onWorkoutDataChanged;

  MapWorkoutController({required this.onWorkoutDataChanged}) {
    locationService = LocationService(
      onLocationUpdate: _handleLocationUpdate,
      onMetricsUpdate: _handleMetricsUpdate,
    );
  }

  void _handleLocationUpdate(LatLng position) {
    workoutData.currentPosition = position;
    if (workoutData.isWorkoutActive) {
      workoutData.polylineCoordinates.add(position);
      workoutData.updatePolyline();
      mapController?.animateCamera(CameraUpdate.newLatLng(position));
    }
    onWorkoutDataChanged(workoutData);
  }

  void _handleMetricsUpdate(Position position) {
    locationService.updateMetrics(workoutData, position);
    onWorkoutDataChanged(workoutData);
  }

  Future<void> initialize() async {
    await checkLocationPermissions();
  }

  Future<void> checkLocationPermissions() async {
    bool serviceEnabled = await permissionHelper.checkLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission =
        await permissionHelper.checkLocationPermission();
    bool isPermanentlyDenied = await permissionHelper.isPermanentlyDenied();

    if (isPermanentlyDenied) {
      return;
    } else if (permission == LocationPermission.denied) {
      return;
    }

    await getCurrentLocationAndAnimateCamera();
  }

  Future<void> getCurrentLocationAndAnimateCamera() async {
    try {
      Position position = await locationService.getCurrentPosition();
      LatLng latLng = LatLng(position.latitude, position.longitude);
      workoutData.currentPosition = latLng;

      if (workoutData.currentPosition != null) {
        mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(workoutData.currentPosition!, 17.0));
      }

      onWorkoutDataChanged(workoutData);
    } catch (e) {
      // Manejo de errores
    }
  }

  void startWorkout() async {
    LocationPermission permission =
        await permissionHelper.checkLocationPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return;
    }

    workoutData.reset();
    workoutData.isWorkoutActive = true;
    if (workoutData.currentPosition != null) {
      workoutData.polylineCoordinates.add(workoutData.currentPosition!);
    }
    locationService.startLocationUpdates();
    onWorkoutDataChanged(workoutData);
  }

  void stopWorkout() {
    workoutData.isWorkoutActive = false;
    locationService.stopLocationUpdates();
    onWorkoutDataChanged(workoutData);
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }

  void dispose() {
    locationService.dispose();
    mapController?.dispose();
  }
}
