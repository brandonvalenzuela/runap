import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:runap/features/map/controller/map_controller.dart';
import 'package:runap/features/map/dialogs/location_dialogs.dart';
import 'package:runap/features/map/screen/widget/draggable_info_sheet.dart';
import 'package:runap/features/map/utils/location_permission_helper.dart';
import 'dart:ui';

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
  String _elapsedTime = "0:00";

  @override
  void initState() {
    super.initState();
    _permissionHelper = LocationPermissionHelper();
    _mapController = MapWorkoutController(
      onWorkoutDataChanged: (_) {
        setState(() {
          _elapsedTime = _mapController.getFormattedElapsedTime();
        });
      },
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
    _mapController.initialize();
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
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final headerHeight = statusBarHeight + 60; // Altura total del encabezado

    return Scaffold(
      body: Stack(
        children: [
          // Mapa de Google como fondo
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            myLocationEnabled: true,
            polylines: _mapController.workoutData.polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Gradiente con blur en la parte superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight + 30, // Altura adicional para el degradado
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(102),
                    Colors.black.withAlpha(76),
                    Colors.black.withAlpha(26),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 0.8, 1.0],
                ),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter:
                      ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Blur más sutil
                  child: Container(
                    color: Colors.transparent, // Sin color adicional
                    padding: EdgeInsets.only(
                      top: statusBarHeight + 16,
                      bottom: 16,
                    ),
                    child: const Center(
                      child: Text(
                        "Mapa",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black54,
                              offset: Offset(1, 1),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Panel deslizable de información
          DraggableInfoSheet(
            workoutData: _mapController.workoutData,
            onStartWorkout: _startWorkout,
            onStopWorkout: _stopWorkout,
            elapsedTime: _elapsedTime,
          ),
        ],
      ),
    );
  }
}
