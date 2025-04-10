// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingLocalStorage {
  static const String _trainingDataKey = 'training_data';
  static const String _lastFetchTimeKey = 'last_fetch_time';
  static const String _cacheVersionKey = 'cache_version';

  // Tiempo de caché en minutos (consistente en toda la app)
  static const int cacheValidityMinutes = 15;

  // Versión del caché para manejar migraciones
  static const int _currentCacheVersion = 1;

  // Guardar los datos de entrenamiento en el almacenamiento local
  static Future<void> saveTrainingData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Guardar datos
      final jsonData = json.encode(data);
      await prefs.setString(_trainingDataKey, jsonData);

      // Guardar tiempo de actualización
      await prefs.setInt(_lastFetchTimeKey, DateTime.now().millisecondsSinceEpoch);
      
      // Guardar versión del caché
      await prefs.setInt(_cacheVersionKey, _currentCacheVersion);
      
      print("💾 Datos guardados en almacenamiento local");
    } catch (e) {
      print("❌ Error al guardar datos en almacenamiento local: $e");
      throw Exception('Error al guardar datos en almacenamiento local: $e');
    }
  }

  // Obtener los datos de entrenamiento del almacenamiento local
  static Future<Map<String, dynamic>?> getTrainingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar versión del caché
      final cacheVersion = prefs.getInt(_cacheVersionKey);
      if (cacheVersion != _currentCacheVersion) {
        print("⚠️ Versión de caché desactualizada, limpiando...");
        await clearTrainingData();
        return null;
      }

      // NO verificar validez aquí, solo obtener datos si existen.
      // La lógica de expiración se maneja en el Service/ViewModel.
      final lastFetchTime = prefs.getInt(_lastFetchTimeKey); // Necesario para el log

      // Obtener datos
      final jsonData = prefs.getString(_trainingDataKey);
      if (jsonData == null || lastFetchTime == null) {
        return null;
      }

      // Calcular diferencia solo para el log
      final now = DateTime.now();
      final lastFetch = DateTime.fromMillisecondsSinceEpoch(lastFetchTime);
      final difference = now.difference(lastFetch).inMinutes;

      print("📥 Datos recuperados del almacenamiento local (antigüedad: $difference minutos)");
      return json.decode(jsonData) as Map<String, dynamic>;
    } catch (e) {
      print("❌ Error al obtener datos del almacenamiento local: $e");
      return null;
    }
  }

  // Verificar si los datos en caché son válidos
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchTime = prefs.getInt(_lastFetchTimeKey);

      if (lastFetchTime == null) {
        return false;
      }

      final now = DateTime.now();
      final lastFetch = DateTime.fromMillisecondsSinceEpoch(lastFetchTime);
      final difference = now.difference(lastFetch).inMinutes;

      return difference < cacheValidityMinutes;
    } catch (e) {
      print("❌ Error al verificar validez del caché: $e");
      return false;
    }
  }

  // Limpiar datos de entrenamiento
  static Future<void> clearTrainingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_trainingDataKey);
      await prefs.remove(_lastFetchTimeKey);
      await prefs.remove(_cacheVersionKey);
      print("🧹 Datos de entrenamiento limpiados");
    } catch (e) {
      print("❌ Error al limpiar datos de entrenamiento: $e");
      throw Exception('Error al limpiar datos de entrenamiento: $e');
    }
  }

  // Actualizar una sesión específica
  static Future<bool> updateSession(Session updatedSession) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_trainingDataKey);

      if (jsonData == null) {
        return false;
      }

      Map<String, dynamic> data = json.decode(jsonData);

      if (!data.containsKey('dashboard') ||
          !data['dashboard'].containsKey('nextWeekSessions')) {
        return false;
      }

      // Encontrar y actualizar la sesión
      List<dynamic> sessions = data['dashboard']['nextWeekSessions'];
      for (int i = 0; i < sessions.length; i++) {
        if (sessions[i]['sessionDate'] ==
            updatedSession.sessionDate.toIso8601String()) {
          sessions[i]['completed'] = updatedSession.completed;

          // Actualizar estadísticas
          int completedCount = 0;
          for (var session in sessions) {
            if (session['completed'] == true) {
              completedCount++;
            }
          }

          data['dashboard']['completedSessions'] = completedCount;
          if (data['dashboard']['totalSessions'] > 0) {
            data['dashboard']['completionRate'] =
                (completedCount / data['dashboard']['totalSessions'] * 100)
                    .round();
          }

          // Guardar datos actualizados
          await saveTrainingData(data);
          return true;
        }
      }

      return false;
    } catch (e) {
      print("❌ Error al actualizar sesión en almacenamiento local: $e");
      return false;
    }
  }
}
