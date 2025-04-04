# Guía de Uso: Transiciones Personalizadas en RunAP

Este documento explica cómo utilizar correctamente el sistema de transiciones personalizadas implementado en RunAP para conseguir animaciones consistentes en toda la aplicación.

## Problema Resuelto

Hemos implementado un sistema unificado de transiciones que asegura:

1. Las pantallas entran desde abajo hacia arriba
2. Al volver atrás, las pantallas salen deslizándose hacia abajo
3. Las transiciones son consistentes en toda la aplicación
4. Funcionan tanto con Navigator como con GetX

## Cómo Navegar a una Nueva Pantalla

Para navegar a una nueva pantalla, usa el método `to` de la clase `TPageTransitions`:

```dart
// Importa el helper
import 'package:runap/utils/helpers/page_transitions.dart';

// Navega a una nueva pantalla
TPageTransitions.to(
  NuevaScreen(), // La página a la que quieres navegar
  duration: Duration(milliseconds: 500), // Opcional: duración personalizada
);
```

## Cómo Volver Atrás

Para volver atrás, usa el método `back` de la clase `TPageTransitions`:

```dart
// Importa el helper
import 'package:runap/utils/helpers/page_transitions.dart';

// Vuelve a la pantalla anterior
TPageTransitions.back();

// Si necesitas devolver un resultado:
TPageTransitions.back<bool>(true);
```

## En Botones de la AppBar

La barra de aplicación ya está configurada para usar estas transiciones. No necesitas hacer nada especial si usas `TAppBar`.

## Uso con Contexto Explícito

Si necesitas proporcionar un contexto explícito, puedes usar el método `navigateWithSlideUpDown`:

```dart
TPageTransitions.navigateWithSlideUpDown(
  context,
  NuevaScreen(),
  replace: false, // Opcional: si quieres reemplazar la pantalla actual
);
```

## Transiciones Personalizadas

Este sistema proporciona una transición unificada que siempre funciona de la misma manera:

- Entrada: Deslizamiento desde abajo hacia arriba con desvanecimiento
- Salida: Deslizamiento hacia abajo con desvanecimiento

Esta coherencia visual mejora significativamente la experiencia de usuario en toda la aplicación.

## Ejemplos de Implementación

### Ejemplo 1: Navegación desde una Tarjeta

```dart
void onCardTap() {
  TPageTransitions.to(
    DetalleScreen(id: item.id),
    duration: Duration(milliseconds: 400),
  );
}
```

### Ejemplo 2: Botón de Acción Flotante

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () {
    TPageTransitions.to(NuevaEntradaScreen());
  },
  child: Icon(Icons.add),
),
```

### Ejemplo 3: Botón de Volver Personalizado

```dart
IconButton(
  icon: Icon(Icons.arrow_back),
  onPressed: () {
    TPageTransitions.back();
  },
),
``` 