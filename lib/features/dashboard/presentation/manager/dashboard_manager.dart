import 'package:get/get.dart';
import 'package:runap/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';
import 'package:runap/features/dashboard/domain/entities/training_data.dart';

class DashboardManager extends GetxController {
  final DashboardRepositoryImpl _repository;
  final _trainingData = Rxn<TrainingData>();
  final _isLoading = false.obs;
  final _error = Rxn<String>();

  DashboardManager({DashboardRepositoryImpl? repository})
      : _repository = repository ?? DashboardRepositoryImpl();

  TrainingData? get trainingData => _trainingData.value;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;

  // Método para cargar los datos del dashboard
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    _isLoading.value = true;
    _error.value = null;

    try {
      _trainingData.value = await _repository.getDashboardData(forceRefresh: forceRefresh);
      _error.value = null;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  // Método para actualizar una sesión
  Future<void> updateSession(Session session) async {
    try {
      await _repository.updateSession(session);
      await loadDashboardData(forceRefresh: true);
    } catch (e) {
      _error.value = e.toString();
    }
  }

  // Método para marcar una sesión como completada
  Future<void> toggleSessionCompletion(Session session) async {
    session.completed = !session.completed;
    await updateSession(session);
  }
} 