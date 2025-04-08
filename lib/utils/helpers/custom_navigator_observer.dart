// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

/// Un NavigatorObserver personalizado para interceptar y modificar las transiciones de navegación
class CustomNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Imprimir información de depuración sobre la ruta que se está cerrando
    print('🔄 CustomNavigatorObserver: didPop - ${route.settings.name}');
    // No podemos modificar la animación de pop aquí, pero podemos registrarla
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Imprimir información de depuración sobre la ruta que se está abriendo
    print('🔄 CustomNavigatorObserver: didPush - ${route.settings.name}');
    super.didPush(route, previousRoute);
  }
}

/// Clase que proporciona una transición personalizada que se desliza hacia abajo al salir
class CustomDownwardPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  CustomDownwardPageRoute({
    required this.page,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Para entrada: deslizarse desde abajo hacia arriba
            final primaryAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            
            // Para salida: deslizarse hacia abajo
            final secondaryAnimationCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInCubic,
            );
            
            return Stack(
              children: [
                // Cuando se está abriendo la pantalla (entrada)
                if (animation.status != AnimationStatus.dismissed)
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1), // Empieza desde abajo
                      end: Offset.zero,          // Termina en el centro
                    ).animate(primaryAnimation),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(primaryAnimation),
                      child: child,
                    ),
                  ),
                
                // Cuando se está cerrando la pantalla (salida)
                if (secondaryAnimation.status != AnimationStatus.dismissed)
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset.zero,        // Empieza en el centro
                      end: const Offset(0, 1),   // Se va hacia abajo
                    ).animate(secondaryAnimationCurved),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(secondaryAnimationCurved),
                      child: child,
                    ),
                  ),
              ],
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 500),
        );
}

/// Función para crear una ruta personalizada con animación hacia abajo al salir
Route<T> createRouteWithDownwardExit<T>(Widget page, [RouteSettings? settings]) {
  return CustomDownwardPageRoute<T>(
    page: page,
    settings: settings,
  );
} 