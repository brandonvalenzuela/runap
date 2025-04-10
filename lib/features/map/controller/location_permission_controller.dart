import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:runap/features/map/utils/location_permission_helper.dart';
import 'package:logger/logger.dart';

// Enum para representar el estado del permiso de manera clara
enum LocationPermissionStatus { unknown, granted, denied, deniedForever, serviceDisabled }

class LocationPermissionController extends GetxController {
  final LocationPermissionHelper _permissionHelper = LocationPermissionHelper();
  final Logger logger = Logger(printer: PrettyPrinter(methodCount: 0)); // Logger simple

  // Estado observable del permiso
  final Rx<LocationPermissionStatus> permissionStatus = LocationPermissionStatus.unknown.obs;

  @override
  void onInit() {
    super.onInit();
    // Verificar estado inicial al iniciar el controlador
    logger.i("LocationPermissionController inicializado. Verificando permisos...");
    checkPermissions();
  }

  /// Verifica el estado actual de servicios y permisos y actualiza el estado observable.
  /// [requestIfNeeded]: Si es true y el permiso está 'denied', intentará solicitarlo.
  Future<void> checkPermissions({bool requestIfNeeded = false}) async {
    bool serviceEnabled = await _permissionHelper.checkLocationServiceEnabled();
    if (!serviceEnabled) {
      permissionStatus.value = LocationPermissionStatus.serviceDisabled;
      logger.w("Permiso Estado: Servicio de ubicación deshabilitado.");
      return;
    }

    LocationPermission permission = await _permissionHelper.checkLocationPermission();

    if (permission == LocationPermission.deniedForever) {
      permissionStatus.value = LocationPermissionStatus.deniedForever;
      logger.w("Permiso Estado: Denegado permanentemente.");
    } else if (permission == LocationPermission.denied) {
      permissionStatus.value = LocationPermissionStatus.denied;
      logger.w("Permiso Estado: Denegado.");
      if (requestIfNeeded) {
         logger.i("Permiso solicitado porque requestIfNeeded=true.");
         await requestPermission(); // Intentar solicitar si se denegó
      }
    } else {
      // always o whileInUse
      permissionStatus.value = LocationPermissionStatus.granted;
      logger.i("Permiso Estado: Concedido (${permission.name}).");
    }
  }

  /// Solicita el permiso de ubicación al usuario.
  Future<void> requestPermission() async {
     logger.i("Solicitando permiso de ubicación...");
     LocationPermission permission = await _permissionHelper.requestLocationPermission();
     logger.i("Resultado de la solicitud: ${permission.name}");
     // Actualizar estado después de la solicitud
     await checkPermissions(); // Volver a verificar para actualizar el estado observable
  }

  /// Abre la configuración de la aplicación.
  void openAppSettings() {
    _permissionHelper.openAppSettings();
  }

  /// Abre la configuración de ubicación del sistema.
  void openLocationSettings() {
    _permissionHelper.openLocationSettings();
  }

  /// Muestra el diálogo o Snackbar apropiado basado en el estado actual del permiso.
  void showPermissionDialogIfNeeded() {
    switch (permissionStatus.value) {
      case LocationPermissionStatus.serviceDisabled:
        _showLocationServiceDisabledDialog();
        break;
      case LocationPermissionStatus.deniedForever:
        _showPermissionDeniedDialogForever();
        break;
      case LocationPermissionStatus.denied:
        _showPermissionDeniedDialog();
        break;
      case LocationPermissionStatus.granted:
        logger.i("showPermissionDialogIfNeeded: Permiso ya concedido.");
        break;
      case LocationPermissionStatus.unknown:
        logger.i("showPermissionDialogIfNeeded: Estado desconocido, esperando chequeo.");
        // Podría mostrar un loader o esperar a que onInit complete checkPermissions
        break;
    }
  }

  // --- Métodos privados para mostrar diálogos ---

  void _showPermissionDeniedDialogForever() {
    Get.dialog(
      AlertDialog(
        title: const Text('Permisos Denegados Permanentemente'),
        content: const Text(
            'Para usar el mapa, necesitas otorgar permisos de ubicación en la configuración de la aplicación.'),
        actions: [
           TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: const Text('Abrir Configuración'),
            onPressed: () {
              openAppSettings();
              Get.back();
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showPermissionDeniedDialog() {
     Get.dialog(
      AlertDialog(
        title: const Text('Permisos Denegados'),
        content: const Text(
            'Necesitamos permiso para acceder a la ubicación para rastrear tu entrenamiento.'),
        actions: [
           TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: const Text('Solicitar Permisos'),
            onPressed: () async {
              Get.back();
              await requestPermission(); // Solicitar de nuevo
              // Si el permiso sigue denegado después de esto, el usuario tendrá que ir a configuración.
              // Se podría añadir lógica para detectar si es la segunda vez que se muestra y
              // ofrecer directamente ir a configuración si se niega de nuevo.
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

    void _showLocationServiceDisabledDialog() {
     Get.dialog(
      AlertDialog(
        title: const Text('Servicios de Ubicación Deshabilitados'),
        content: const Text(
            'Los servicios de ubicación están deshabilitados. Por favor, actívalos para poder usar el mapa.'),
        actions: [
           TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Get.back(),
          ),
           TextButton(
            child: const Text('Abrir Configuración'),
            onPressed: () {
              openLocationSettings();
              Get.back();
            },
          ),
        ],
      ),
       barrierDismissible: false,
    );
  }
}
