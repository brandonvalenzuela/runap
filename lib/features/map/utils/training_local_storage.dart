import 'dart:convert';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingLocalStorage {
  static const String _trainingDataKey = 'training_data';
  static const String _lastFetchTimeKey = 'last_fetch_time';

  // Tiempo de caché en minutos
  static const int _cacheValidityMinutes = 15; // 1 hora

  // Guardar los datos de entrenamiento en el almacenamiento local
  static Future<void> saveTrainingData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = json.encode(data);
    await prefs.setString(_trainingDataKey, jsonData);

    // Guardar el tiempo de la última actualización
    await prefs.setInt(
        _lastFetchTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Obtener los datos de entrenamiento del almacenamiento local
  static Future<Map<String, dynamic>?> getTrainingData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_trainingDataKey);

    if (jsonData != null) {
      return json.decode(jsonData) as Map<String, dynamic>;
    }

    return null;
  }

  // Verificar si los datos en caché son válidos o si deberían actualizarse
  static Future<bool> isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchTime = prefs.getInt(_lastFetchTimeKey);

    if (lastFetchTime == null) {
      return false;
    }

    final now = DateTime.now();
    final lastFetch = DateTime.fromMillisecondsSinceEpoch(lastFetchTime);
    final difference = now.difference(lastFetch).inMinutes;

    return difference < _cacheValidityMinutes;
  }

  // Limpiar datos de entrenamiento (útil para logout)
  static Future<void> clearTrainingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_trainingDataKey);
    await prefs.remove(_lastFetchTimeKey);
  }

  // Actualizar una sesión específica (por ejemplo, marcarla como completada)
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

      // Encontrar y actualizar la sesión en la lista
      List<dynamic> sessions = data['dashboard']['nextWeekSessions'];
      for (int i = 0; i < sessions.length; i++) {
        // Comparar por fecha (que usamos como identificador único)
        if (sessions[i]['sessionDate'] ==
            updatedSession.sessionDate.toIso8601String()) {
          sessions[i]['completed'] = updatedSession.completed;

          // Actualizar la tasa de completado y sesiones completadas
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

          // Guardar los datos actualizados
          await prefs.setString(_trainingDataKey, json.encode(data));
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error al actualizar la sesión en el almacenamiento local: $e');
      return false;
    }
  }
}
