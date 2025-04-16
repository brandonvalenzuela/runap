import 'package:get_storage/get_storage.dart';

class SurveyService {
  static final SurveyService _instance = SurveyService._internal();
  factory SurveyService() => _instance;
  SurveyService._internal();

  final GetStorage _storage = GetStorage();
  final String _pendingSurveyKey = 'pendingSurveyAnswers';
  final String _surveyCompletedKey = 'SurveyCompleted';

  /// Lee los datos de la encuesta almacenados (si existen)
  Map<String, dynamic>? readPendingSurvey() {
    return _storage.read<Map<String, dynamic>>(_pendingSurveyKey);
  }

  /// Guarda los datos de la encuesta
  Future<void> savePendingSurvey(Map<String, dynamic> data) async {
    await _storage.write(_pendingSurveyKey, data);
  }

  /// Elimina los datos de la encuesta
  Future<void> removePendingSurvey() async {
    await _storage.remove(_pendingSurveyKey);
  }

  /// Marca la encuesta como completada
  Future<void> setSurveyCompleted(bool value) async {
    await _storage.write(_surveyCompletedKey, value);
  }

  /// Verifica si la encuesta fue completada
  bool isSurveyCompleted() {
    return _storage.read<bool>(_surveyCompletedKey) ?? false;
  }
} 