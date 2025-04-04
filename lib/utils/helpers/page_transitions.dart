import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Un conjunto de transiciones personalizadas para la navegación de páginas
class TPageTransitions {
  /// Transición personalizada para abrir una página desde abajo y salir hacia abajo
  static Route<T> slideUpDownRoute<T>(
    Widget page, {
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 400),
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Animación de entrada (desde abajo hacia arriba)
        final enterAnim = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));
        
        // Animación de salida (desde arriba hacia abajo)
        final exitAnim = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, 1),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInCubic,
        ));
        
        return Stack(
          children: [
            // Animación de salida (para la pantalla actual cuando se cierra)
            SlideTransition(
              position: exitAnim,
              child: secondaryAnimation.status == AnimationStatus.forward
                  ? Container(
                      color: Colors.white,
                      child: const SizedBox.expand(),
                    )
                  : const SizedBox(),
            ),
            
            // Animación de entrada (para la nueva pantalla)
            SlideTransition(
              position: enterAnim,
              child: child,
            ),
          ],
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }
  
  /// Método para navegar a una página con la transición personalizada
  static Future<T?> navigateWithSlideUpDown<T>(
    BuildContext context,
    Widget page, {
    bool replace = false,
    Duration duration = const Duration(milliseconds: 400),
    bool fullscreenDialog = false,
  }) {
    final route = slideUpDownRoute<T>(
      page,
      duration: duration,
      fullscreenDialog: fullscreenDialog,
    );
    
    if (replace) {
      return Navigator.of(context).pushReplacement(route);
    } else {
      return Navigator.of(context).push(route);
    }
  }
  
  /// Método para navegar a una página con GetX usando la transición personalizada
  static Future<T?> to<T>(
    Widget page, {
    bool fullscreenDialog = false,
    Duration duration = const Duration(milliseconds: 400),
    bool replace = false,
  }) {
    // Crear la ruta personalizada
    final route = slideUpDownRoute<T>(
      page,
      duration: duration,
      fullscreenDialog: fullscreenDialog,
    );
    
    // Manejar la navegación directamente usando el contexto actual de GetX
    if (Get.key.currentContext != null) {
      if (replace) {
        return Navigator.of(Get.key.currentContext!).pushReplacement(route);
      } else {
        return Navigator.of(Get.key.currentContext!).push(route);
      }
    } else {
      // Fallback a GetX si no tenemos contexto
      return replace 
          ? Get.off(() => page) as Future<T?> 
          : Get.to(() => page) as Future<T?>;
    }
  }
  
  /// Método para cerrar la página actual con transición hacia abajo
  static void back<T>([T? result]) {
    if (Get.key.currentContext != null && Navigator.canPop(Get.key.currentContext!)) {
      Navigator.of(Get.key.currentContext!).pop(result);
    } else {
      Get.back(result: result);
    }
  }
} 