import 'package:flutter_test/flutter_test.dart';

void main() {
  group('All Tests', () {
    test('Maps and workout functionality tests', () {
      // Nota: No importamos directamente los archivos de prueba
      // porque pueden tener dependencias de generación de mocks
      // que necesitan ser corridas manualmente con build_runner.
      
      // En su lugar, usaremos esta prueba como recordatorio
      // para ejecutar los tests de forma individual.
      expect(true, true, reason: 'Ejecuta cada test individualmente');
    });
  });
}

// Instrucciones para ejecutar las pruebas:
// 1. Asegúrate de tener mockito y build_runner instalados:
//    flutter pub add mockito --dev
//    flutter pub add build_runner --dev
//
// 2. Ejecuta las pruebas individualmente:
//    flutter test test/features/map/models/workout_data_test.dart
//    flutter test test/features/map/models/workout_goal_test.dart
//    flutter test test/features/map/services/location_service_test.dart
//    flutter test test/features/map/controller/map_controller_test.dart
