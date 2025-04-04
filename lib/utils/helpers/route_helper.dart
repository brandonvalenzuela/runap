import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/utils/helpers/custom_navigator_observer.dart';

/// Clase que proporciona métodos para navegar con animaciones personalizadas
class TRouteHelper {
  /// Navegar a una nueva pantalla con transición personalizada
  static Future<T?> navigateTo<T>(
    BuildContext context,
    Widget page, {
    String? routeName,
    bool replace = false,
  }) {
    // Crear una ruta personalizada con nuestra transición hacia abajo
    final route = createRouteWithDownwardExit<T>(
      page,
      RouteSettings(name: routeName),
    );
    
    // Decidir si reemplazar la ruta actual o agregar una nueva
    if (replace) {
      return Navigator.of(context).pushReplacement(route);
    } else {
      return Navigator.of(context).push(route);
    }
  }
  
  /// Navegar hacia atrás con transición personalizada
  static void goBack<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }
  
  /// Método para ser usado con GetX para navegar a una nueva pantalla
  static Future<T?> getxNavigateTo<T>(
    Widget page, {
    bool replace = false,
    Transition customTransition = Transition.downToUp,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
  }) {
    if (replace) {
      return Get.off<T>(
        () => page,
        transition: customTransition,
        duration: duration,
        curve: curve,
      ) as Future<T?>;
    } else {
      return Get.to<T>(
        () => page,
        transition: customTransition,
        duration: duration,
        curve: curve,
      ) as Future<T?>;
    }
  }
  
  /// Reemplazar toda la pila de navegación con una nueva pantalla
  static Future<T?> replaceAllWith<T>(
    BuildContext context,
    Widget page, {
    String? routeName,
  }) {
    // Crear una ruta personalizada
    final route = createRouteWithDownwardExit<T>(
      page,
      RouteSettings(name: routeName),
    );
    
    // Limpiar toda la pila y agregar la nueva ruta
    return Navigator.of(context).pushAndRemoveUntil(
      route,
      (route) => false, // Eliminar todas las rutas existentes
    );
  }
} 