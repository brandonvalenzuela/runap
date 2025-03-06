import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:runap/features/map/controller/map_controller.dart';
import 'package:runap/features/map/screen/widget/draggable_info_sheet.dart';
import '../dialogs/location_dialogs.dart';
import '../utils/location_permission_helper.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late MapWorkoutController _mapController;
  late LocationDialogs _locationDialogs;
  late LocationPermissionHelper _permissionHelper;
  final LatLng _center = const LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    _permissionHelper = LocationPermissionHelper();
    _mapController = MapWorkoutController(
      onWorkoutDataChanged: (_) => setState(() {}),
    );
    _locationDialogs = LocationDialogs(
      context: context,
      permissionHelper: _permissionHelper,
      onPermissionGranted: _getCurrentLocationAndAnimateCamera,
    );
    _checkLocationServiceAndPermissionAndInitialize();
  }

  Future<void> _checkLocationServiceAndPermissionAndInitialize() async {
    bool serviceEnabled = await _permissionHelper.checkLocationServiceEnabled();
    if (!serviceEnabled) {
      _locationDialogs.showLocationServiceDisabledDialog();
      return;
    }

    LocationPermission permission =
        await _permissionHelper.checkLocationPermission();
    bool isPermanentlyDenied = await _permissionHelper.isPermanentlyDenied();

    if (isPermanentlyDenied) {
      _locationDialogs.showPermissionDeniedDialogForever();
      return;
    } else if (permission == LocationPermission.denied) {
      _locationDialogs.showPermissionDeniedDialog();
      return;
    }

    _getCurrentLocationAndAnimateCamera();
  }

  Future<void> _getCurrentLocationAndAnimateCamera() async {
    await _mapController.getCurrentLocationAndAnimateCamera();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController.setMapController(controller);
  }

  void _startWorkout() async {
    LocationPermission permission =
        await _permissionHelper.checkLocationPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      _locationDialogs.showPermissionDeniedDialog();
      return;
    }

    _mapController.startWorkout();
  }

  void _stopWorkout() {
    _mapController.stopWorkout();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            myLocationEnabled: true,
            polylines: _mapController.workoutData.polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          DraggableInfoSheet(
            workoutData: _mapController.workoutData,
            onStartWorkout: _startWorkout,
            onStopWorkout: _stopWorkout,
          ),
        ],
      ),
    );
  }
}
