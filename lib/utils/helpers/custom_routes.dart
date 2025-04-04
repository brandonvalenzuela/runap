import 'package:flutter/material.dart';

/// Clase para crear rutas con transiciones personalizadas.
class TCustomRoutes {
  /// Ruta con transición de abajo hacia arriba (entrada)
  static Route<T> upwardRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Animación de entrada: desde abajo hacia arriba
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        // Combinamos con una transición de opacidad
        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut)
        );
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }
  
  /// Ruta con transición de arriba hacia abajo (salida)
  static Route<T> downwardRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Para la animación de salida, necesitamos manejar el secundaryAnimation
        // que controla la animación de la pantalla que se está abandonando
        
        // La pantalla actual se desliza hacia abajo cuando se está saliendo
        var downward = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.0, 1.0),
        ).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeInOutCubic,
          ),
        );
        
        // También se desvanece
        var fadeOut = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeInOut,
          ),
        );
        
        // La nueva pantalla se desliza desde abajo
        var upward = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );
        
        // Y aparece gradualmente
        var fadeIn = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeIn,
          ),
        );
        
        // Combinamos ambas animaciones
        return Stack(
          children: [
            // La pantalla que se está cerrando
            FadeTransition(
              opacity: fadeOut,
              child: SlideTransition(
                position: downward,
                child: secondaryAnimation.status == AnimationStatus.reverse 
                    ? child : const SizedBox(),
              ),
            ),
            // La nueva pantalla que se está abriendo
            FadeTransition(
              opacity: fadeIn,
              child: SlideTransition(
                position: upward,
                child: animation.status == AnimationStatus.forward 
                    ? child : const SizedBox(),
              ),
            ),
          ],
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 500),
    );
  }
  
  /// Método para navegar hacia atrás con una transición personalizada
  static void pop(BuildContext context) {
    Navigator.of(context).pop();
  }
} 