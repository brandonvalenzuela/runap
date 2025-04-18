import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/utils/constants/colors.dart';

// Enum para definir el tipo de notificación y su color asociado
enum NotificationType {
  info(TColors.info), // Azul por defecto para info
  success(TColors.success), // Verde para éxito
  warning(TColors.warning), // Naranja para advertencia
  error(TColors.error), // Rojo para error
  connectivity(TColors.colorBlack); // Negro para notificaciones de conectividad

  final Color color;
  const NotificationType(this.color);
}

class NotificationController extends GetxController {
  // Variables observables
  final RxBool isVisible = false.obs;
  final RxString message = ''.obs;
  final Rx<NotificationType> notificationType = NotificationType.info.obs;

  // Timer para ocultar automáticamente
  Timer? _hideTimer;

  // Método para mostrar la notificación
  void show(
    String msg, {
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3), // Duración por defecto
  }) {
    // Cancelar timer anterior si existe
    _hideTimer?.cancel();

    // Actualizar mensaje y tipo
    message.value = msg;
    notificationType.value = type;

    // Mostrar la notificación
    isVisible.value = true;

    // Iniciar timer para ocultar automáticamente
    _hideTimer = Timer(duration, () {
      hide();
    });
  }

  // Método para ocultar la notificación
  void hide() {
    isVisible.value = false;
    _hideTimer?.cancel(); // Cancelar timer si se oculta manualmente
  }

  @override
  void onClose() {
    _hideTimer?.cancel();
    super.onClose();
  }
} 