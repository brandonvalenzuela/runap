import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/location_permission_helper.dart';

class LocationDialogs {
  final BuildContext context;
  final LocationPermissionHelper permissionHelper;
  final Function onPermissionGranted;

  LocationDialogs({
    required this.context,
    required this.permissionHelper,
    required this.onPermissionGranted,
  });

  void showPermissionDeniedDialogForever() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permisos de Ubicación Denegados Permanentemente'),
        content: const Text(
            'Para usar esta función, necesitas otorgar permisos de ubicación. Por favor, actívalos en la configuración de la aplicación.'),
        actions: [
          TextButton(
            child: const Text('Abrir Configuración'),
            onPressed: () {
              permissionHelper.openAppSettings();
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permisos de Ubicación Denegados'),
        content: const Text(
            'Necesitamos permiso para acceder a la ubicación para rastrear tu entrenamiento.'),
        actions: [
          TextButton(
            child: const Text('Solicitar Permisos'),
            onPressed: () async {
              Navigator.pop(context);
              LocationPermission permission =
                  await permissionHelper.requestLocationPermission();
              if (permission == LocationPermission.always ||
                  permission == LocationPermission.whileInUse) {
                onPermissionGranted();
              } else {
                showPermissionDeniedDialog();
              }
            },
          ),
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Servicios de Ubicación Deshabilitados'),
        content: const Text(
            'Los servicios de ubicación están deshabilitados. Por favor, actívalos para usar esta función.'),
        actions: [
          TextButton(
            child: const Text('Abrir Configuración'),
            onPressed: () {
              permissionHelper.openLocationSettings();
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
