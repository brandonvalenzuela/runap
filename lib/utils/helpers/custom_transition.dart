import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Clase que implementa una transición personalizada de desvanecimiento hacia abajo
/// Esta transición es ideal para ser usada al salir de una pantalla (pop)
class DownwardFadeTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Creamos dos animaciones combinadas:
    // 1. Una animación de traslación hacia abajo
    // 2. Una animación de opacidad que disminuye
    
    // Animación de deslizamiento hacia abajo
    final slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 1.0), // Deslizar hacia abajo
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: curve ?? Curves.easeInOutBack,
      ),
    );
    
    // Animación de opacidad
    final fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0, // Desaparecer
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: curve ?? Curves.easeOut,
      ),
    );
    
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}

/// Clase personalizada para crear una ruta con transición de desvanecimiento hacia abajo
class DownwardFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  DownwardFadeRoute({required this.page})
      : super(
          pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
            return page;
          },
          transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutBack,
            );
            
            // Transición deslizando hacia abajo y desvaneciéndose
            return FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.0).animate(curvedAnimation),
              child: SlideTransition(
                position: Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, 1.0)).animate(curvedAnimation),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 500),
        );
}

/// Función personalizada para extender GetX y agregar soporte para animación de desvanecimiento hacia abajo
/// Reemplaza los botones de retroceso estándar y la navegación de Get.back()
class CustomNavigation {
  /// Navegar hacia atrás con animación de desvanecimiento hacia abajo
  static void back(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// Extensión para la navegación personalizada en Navigator
extension NavigatorExtension on Navigator {
  static Future<void> popWithDownwardFade(BuildContext context) async {
    Navigator.of(context).pop();
  }
} 