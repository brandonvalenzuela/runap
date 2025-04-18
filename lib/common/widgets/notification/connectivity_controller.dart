import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/common/widgets/notification/notification_controller.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/text_strings.dart';

/// Controlador que maneja la notificación de estado de conectividad
class ConnectivityController extends GetxController {
  static ConnectivityController get instance => Get.find();

  // Variables observables
  final _isConnected = true.obs;
  final _showingNoConnectionNotification = false.obs;
  
  // Instancia de Connectivity
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  
  // Referencia al controlador de notificaciones
  late NotificationController _notificationController;
  
  // Timer interno para gestionar la notificación de conexión restaurada
  Timer? _connectionRestoredTimer;

  /// Inicializa el controlador de conectividad y configura la escucha de cambios en la conexión
  @override
  void onInit() {
    super.onInit();
    _notificationController = Get.find<NotificationController>();
    _initConnectivity();
  }

  /// Verifica el estado inicial de la conectividad
  Future<void> _initConnectivity() async {
    // Verificar el estado inicial de la conexión
    var result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Escuchar cambios en la conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Actualiza el estado de la conexión y muestra/oculta notificaciones según sea necesario
  void _updateConnectionStatus(ConnectivityResult result) {
    final wasConnected = _isConnected.value;
    
    // Actualizar el estado de la conexión
    _isConnected.value = result != ConnectivityResult.none;
    
    // Manejar cambios en el estado de la conexión
    if (!_isConnected.value && !_showingNoConnectionNotification.value) {
      // No hay conexión y no se está mostrando la notificación
      _showNoConnectionNotification();
    } else if (_isConnected.value && !wasConnected) {
      // La conexión fue restaurada
      _showConnectionRestoredNotification();
    }
  }

  /// Muestra una notificación persistente de que no hay conexión a internet
  void _showNoConnectionNotification() {
    _showingNoConnectionNotification.value = true;
    
    // Cancelar cualquier temporizador existente
    _connectionRestoredTimer?.cancel();
    
    // Mostrar notificación de "Sin conexión" manualmente configurando los valores
    // en lugar de usar el método show() para evitar el timer de ocultación automática
    _notificationController.message.value = TTexts.noInternet;
    _notificationController.notificationType.value = NotificationType.connectivity;
    _notificationController.isVisible.value = true;
  }

  /// Muestra una notificación temporal de que se ha restaurado la conexión
  void _showConnectionRestoredNotification() {
    if (_showingNoConnectionNotification.value) {
      _showingNoConnectionNotification.value = false;
      
      // Cancelar cualquier temporizador existente
      _connectionRestoredTimer?.cancel();
      
      // Mostrar notificación de "Conexión restaurada"
      _notificationController.message.value = TTexts.connectionRestored;
      _notificationController.notificationType.value = NotificationType.success;
      _notificationController.isVisible.value = true;
      
      // Configurar temporizador para ocultar la notificación después de unos segundos
      _connectionRestoredTimer = Timer(const Duration(seconds: 3), () {
        _notificationController.hide();
      });
    }
  }

  /// Retorna el estado actual de la conexión
  bool get isConnected => _isConnected.value;

  /// Libera recursos al cerrar el controlador
  @override
  void onClose() {
    _connectivitySubscription.cancel();
    _connectionRestoredTimer?.cancel();
    super.onClose();
  }
} 