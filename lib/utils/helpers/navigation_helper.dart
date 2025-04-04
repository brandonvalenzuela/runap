import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/utils/helpers/custom_navigator_observer.dart';

/// Clase para extender la funcionalidad de navegación de GetX
class TNavigationHelper {
  /// Navegación personalizada para salir con transición hacia abajo
  static void back({
    dynamic result,
    bool closeOverlays = false,
    bool canPop = true,
    int? id,
  }) {
    if (Get.isDialogOpen == true) {
      Get.back(closeOverlays: closeOverlays, canPop: canPop, result: result);
      return;
    }

    // Usar una transición personalizada para salir
    // Verificar si podemos usar el Navigator directamente
    if (Get.key.currentContext != null && Navigator.canPop(Get.key.currentContext!)) {
      // Crear una transición personalizada con animación hacia abajo
      Navigator.of(Get.key.currentContext!).pop(result);
    } else {
      // Fallback al método estándar
      Get.back(
        result: result,
        closeOverlays: closeOverlays,
        canPop: canPop,
        id: id,
      );
    }
  }

  /// Configura comportamiento para transición personalizada de salida
  static void setupCustomBackTransition() {
    // No hacer configuración global en GetX, ya que puede interferir
    // Usaremos transiciones personalizadas específicas en cada caso
  }
  
  /// Método para navegar a una nueva pantalla con animación personalizada (abajo hacia arriba)
  static Future<T?> to<T>(
    Widget page, {
    bool fullscreenDialog = false,
    Transition? transition,
    Curve? curve,
    Duration? duration,
  }) async {
    // Usar una transición personalizada para ir a la nueva pantalla
    return Get.to<T>(
      () => page,
      fullscreenDialog: fullscreenDialog,
      transition: transition ?? Transition.downToUp, // De abajo hacia arriba al entrar
      curve: curve ?? Curves.easeOut,
      duration: duration ?? const Duration(milliseconds: 400),
    );
  }
  
  /// Método para reemplazar la pantalla actual con una nueva (con animación de abajo hacia arriba)
  static Future<T?> off<T>(
    Widget page, {
    bool fullscreenDialog = false,
    Transition? transition,
    Curve? curve,
    Duration? duration,
  }) async {
    // Usar una transición personalizada para ir a la nueva pantalla
    return Get.off<T>(
      () => page,
      fullscreenDialog: fullscreenDialog,
      transition: transition ?? Transition.downToUp, // De abajo hacia arriba al entrar
      curve: curve ?? Curves.easeOut,
      duration: duration ?? const Duration(milliseconds: 400),
    );
  }
}

/// Extendemos GetX para facilitar el uso de nuestra transición personalizada
extension GetWithCustomTransitions on GetInterface {
  /// Navegar hacia atrás con una animación personalizada hacia abajo
  void backWithDownwardAnimation({
    dynamic result,
    bool closeOverlays = false,
    bool canPop = true,
    int? id,
  }) {
    TNavigationHelper.back(
      result: result,
      closeOverlays: closeOverlays,
      canPop: canPop,
      id: id,
    );
  }
  
  /// Navegar a una nueva pantalla con animación personalizada hacia arriba (al entrar)
  Future<T?> toWithCustomAnimation<T>(
    Widget page, {
    bool fullscreenDialog = false,
    Transition? transition,
    Curve? curve,
    Duration? duration,
  }) {
    return TNavigationHelper.to<T>(
      page,
      fullscreenDialog: fullscreenDialog,
      transition: transition,
      curve: curve,
      duration: duration,
    );
  }
} 