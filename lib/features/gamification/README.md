# Implementación de Gamificación en RunAP

Este módulo implementa la funcionalidad de gamificación en la aplicación RunAP, permitiendo a los usuarios ganar puntos, desbloquear logros, participar en retos y competir en tablas de clasificación.

## Estructura de la Implementación

### Modelos de Datos

Los modelos se encuentran en `lib/data/models/gamification/`:

- **Achievement**: Representa un logro que los usuarios pueden desbloquear.
- **UserAchievement**: Relaciona usuarios con los logros que han desbloqueado.
- **Challenge**: Representa un reto en el que los usuarios pueden participar.
- **UserChallenge**: Relaciona usuarios con los retos en los que participan.
- **Level**: Define los niveles que los usuarios pueden alcanzar basados en sus puntos.
- **UserPoints**: Registra los puntos ganados por un usuario.
- **Leaderboard**: Representa una tabla de clasificación.
- **LeaderboardEntry**: Representa una entrada en una tabla de clasificación.
- **UserGamificationProfile**: Modelo que agrupa toda la información de gamificación de un usuario.

### Acceso a Datos

- **GamificationRepository** (`lib/data/repositories/gamification/gamification_repository.dart`): Repositorio que gestiona el acceso a los datos de gamificación.
- **GamificationService** (`lib/data/services/gamification/gamification_service.dart`): Servicio que maneja las peticiones HTTP para obtener y actualizar datos de gamificación.

### Lógica de Presentación

- **GamificationViewModel** (`lib/features/gamification/presentation/manager/gamification_view_model.dart`): Gestiona la lógica de presentación y el estado de la UI relacionada con la gamificación.
- **GamificationBinding** (`lib/features/gamification/presentation/manager/binding/gamification_binding.dart`): Configura la inyección de dependencias para el módulo de gamificación.

### Utilidades

- **GamificationTracker** (`lib/features/gamification/utils/gamification_tracker.dart`): Utilidad para rastrear acciones que pueden resultar en puntos o logros.

### Interfaces de Usuario

- **GamificationProfileScreen** (`lib/features/gamification/presentation/screens/gamification_profile_screen.dart`): Pantalla que muestra el perfil de gamificación de un usuario.

## Cómo Usar

### Configuración Inicial

Para inicializar el módulo de gamificación, añade el `GamificationBinding` a tu lista de bindings:

```dart
void main() {
  // ... otras inicializaciones ...
  Get.put(GamificationBinding());
  // ...
  runApp(MyApp());
}
```

### Integración con Actividades de Usuario

Para registrar actividades que generan puntos o progreso en retos:

```dart
// En tu controlador de actividad física o entrenamiento
final GamificationTracker tracker = GamificationTracker();

void onWorkoutCompleted(String workoutType, double distance, int minutes) {
  // Registrar la actividad para gamificación
  tracker.trackWorkoutCompleted(
    workoutType, 
    distance: distance, 
    minutes: minutes,
  );
  
  // Resto de la lógica de tu aplicación...
}
```

### Acceder a la Pantalla de Perfil de Gamificación

Para mostrar la pantalla del perfil de gamificación:

```dart
Get.to(() => const GamificationProfileScreen());
```

## Extensiones Futuras

Posibles mejoras para el módulo de gamificación:

1. Añadir pantallas para mostrar todas las categorías de logros disponibles.
2. Implementar un sistema de notificaciones para alertar a los usuarios sobre nuevos logros desbloqueados.
3. Crear una pantalla dedicada para las tablas de clasificación.
4. Añadir un sistema de recompensas que los usuarios puedan canjear con sus puntos.
5. Implementar eventos temporales con recompensas especiales. 